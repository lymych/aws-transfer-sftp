# terraform {
#   backend "s3" {
#     bucket         = "terraform"
#     key            = "terraform.state"
#     region         = "us-east-1"
#     encrypt        = true
#     acl            = "bucket-owner-full-control"
#   }
# }

provider "aws" {
  region = "us-east-1"
}

provider "tls" {
}
