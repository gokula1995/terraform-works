variable "account_id" {
  description = "This will be used while assuming the role"
}

variable "region" {
  description = "please provide the region eg: us-east-1. defaults to us-east-1"
}

variable "vpc" {
  description = "please provide the vpc id"
}

variable "key_name" {
  description = "this keyfile will be attached to instances to allow access"
  default     = "ec2"
}

variable "customer" {
  description = "Please type custome name."
}

variable "zone" {
  description = "this is where the instance will be launched, default to be a"
  default     = "a"
}

variable "root_vol_type" {
  description = "volume type to be used for root. default to gp2"
  default     = "gp2"
}

variable "disable_api_termination" {
  default = "true"
}

variable "root_vol_size" {
  description = "volume size to be used for root. default to 100 due to ami requirement"
  default     = 50
}

variable "cpu_credits" {
  description = "this variable controls the type of cpu credit utilisation"
  default     = "unlimited"
}

variable "instance_type" {
  description = "this key decides which type of instance to be launched"
  default     = "t3.medium"
}

variable "tags" {
  description = "to be used to add a set of required static tags to all instances"
}

variable "ssh_port" {
  default = "22"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "lambda_arn" {
  description = "amazon resource number of lambda"
}


variable "tf_state_bucket" {}
variable "certificate" {}


variable subnet_id {
  type        = string
  description = "subnet in which blip instance will be created"
}


variable "ami_id" {
  type        = string
  description = "latest blip id"
  default = null
}

variable "autoscale_ami_id" {
  type        = string
  description = "auto scale ami id for blip"
  default = null
}


variable sg_1 {
  description = "amagi security group id in vpc"
}

variable sg_2 {
  description = "oscar security group id in vpc"
}

variable sg_3 {
  description = "security group for cloudport"
}

variable route53_profile {
  description = "profile for route53"
}

variable hosted_zone_id {
  description = "hosted zone id for route53"
}

variable ami_name {
  description = "ami name for instance"
}

variable autoscale_ami_name {
  description = "ami name for autoscale"
}

variable auto_scale_ami_id {
  default = null
}
