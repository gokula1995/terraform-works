provider "aws" {
  region  = var.region
  profile = var.account_id
}

data "external" "fetch_ami" {
  program = ["python3", "../scripts/fetch_ami.py"]
  query = {
    region           = var.region
    ami_response_url = var.ami_response_url
    ami              = var.ami_name
    autoscale_ami    = var.autoscale_ami_name
  }
}

locals {
  ami_id       = var.ami_id != null ? var.ami_id : data.external.fetch_ami.result.ami_id
  auto_scale_ami_id = var.autoscale_ami_id != null ? var.auto_scale_ami_id : data.external.fetch_ami.result.auto_scale_ami_id
}



locals {
  availability_zone    = "${var.region}${var.zone}"
  ec2_resources_tags  = var.tags
  vpc_public_subnet_id = var.subnet_id
  vpc_sg_1             = var.sg_1
  vpc_sg_2             = var.sg_2
  vpc_sg_3             = var.sg_3

  lambda_arn      = var.lambda_arn
#   ses_access_key = var.ses_access_key
#   ses_secret_key = var.ses_secret_key
}

## instance changes

resource "random_uuid" "token" {}

resource "aws_eip" "eip_main" {
  instance = aws_instance.ec2.id
  vpc      = "true"
  tags     = local.ec2_resources_tags
}

data "template_file" "init" {
  template = file("../templates/ec2_instance_user_data.sh.tmpl")

  vars = {
  }
}


data "template_file" "configure_script" {
  template = file("../templates/ec2_instance_configure.sh.tmpl")

  vars = {
  }
}


resource "aws_instance" "ec2" {
  tags                        = local.ec2_resources_tags
  volume_tags                 = local.ec2_resources_tags
  ami                         = local.ami_id
  associate_public_ip_address = "true"
  #availability_zone           = local.availability_zone
  instance_type               = var.instance_type
  key_name                    = var.key_name
  disable_api_termination     = var.disable_api_termination
  user_data                   = data.template_file.init.rendered

  root_block_device {
    volume_type = var.root_vol_type
    volume_size = var.root_vol_size
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  vpc_security_group_ids = [aws_security_group.resource-sg.id, local.vpc_sg_1, local.vpc_sg_2, local.vpc_sg_3]
  subnet_id              = local.vpc_public_subnet_id
  monitoring             = "true"
  connection {
    host        = self.public_ip
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = file("~/.ssh/ec2.pem")
  }


  provisioner "remote-exec" {
    inline = [data.template_file.configure_script.rendered]
  }
}

resource "aws_route53_record" "route_main" {
  zone_id  = var.hosted_zone_id
  name     = var.customer
  type     = "A"
  ttl      = "60"
  records  = [aws_eip.eip_main.public_ip]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_cloudwatch_metric_alarm" "auto_recovery_alarm" {
  alarm_name          = "awsec2-${aws_instance.blip.id}-High-Status-Check-Failed-System-"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Recover the instance if status check failed"
  alarm_actions       = ["arn:aws:automate:${var.region}:ec2:recover"]
  dimensions          = map("InstanceId", aws_instance.ec2.id)
}

resource "aws_cloudwatch_metric_alarm" "auto_recovery_alarm_instance" {
  alarm_name          = "awsec2-${aws_instance.blip.id}-High-Status-Check-Failed-Instance-"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Recover the instance if the instance status check failed"
  alarm_actions       = ["arn:aws:automate:${var.region}:ec2:reboot"]
  dimensions          = map("InstanceId", aws_instance.ec2.id)
}

resource "aws_security_group" "resource-sg" {
  name                   = var.customer
  description            = "Allow all inbound traffic from office and oscar"
  tags                   = local.blip_resources_tags
  vpc_id                 = var.vpc
  revoke_rules_on_delete = "true"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["XX.XX.XX.XX/32", "XXX.XXX.XXX.XXX/32"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["XX.XX.XX.XX/32", "XXX.XXX.XXX.XXX/32"]
  }
}

resource "null_resource" "execute_ec2_changes" {
  triggers = {
    blip_with_rds = aws_instance.ec2.id
  }

  connection {
    host        = aws_eip.eip_main.public_ip
    type        = "ssh"
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = file("~/.ssh/ec2.pem")

  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y apache2"
    ]
  }
}


output instance_id {
  value = aws_instance.ec2.id
}

output ip {
  value = aws_eip.eip_main.public_ip
}

output one_time_token {
  value = random_uuid.token.result
}

output hostname {
  value = aws_route53_record.route_main.name
}
