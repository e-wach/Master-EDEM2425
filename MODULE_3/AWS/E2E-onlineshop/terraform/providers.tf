# terraform {
#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       version = "5.92.0"
#     }
#   }
# }

provider "aws" {
    alias = "master_region"
    region = "eu-central-1"
}