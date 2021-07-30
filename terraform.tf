terraform {
  backend "s3" {
    profile        = "default"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
  experiments      = [variable_validation]
  required_version = "0.12.26"
  required_providers {
    aws      = "= 2.70.0"
    external = "= 1.2.0"
    null     = "= 2.1.2"
    random   = "= 2.2.1"
    template = "= 2.1.2"
  }
}
