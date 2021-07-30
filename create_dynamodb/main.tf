variable region {
    description = "region for dyanmodb.It should be same as s3 state bucket"
}

variable account_id {
    description = "aws profile"
}

provider "aws" {
  region  = var.region
  profile = var.account_id
}

resource "aws_dynamodb_table" "dynamodb-terraform-lock" {
   name = "terraform-lock"
   hash_key = "LockID"
   read_capacity = 20
   write_capacity = 20

   attribute {
      name = "LockID"
      type = "S"
   }

   tags = {
     Name = "Terraform Lock Table"
   }
}
