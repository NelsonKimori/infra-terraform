terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "name" {}

resource "aws_s3_bucket" "demo" {
  bucket = "devsecops-demo-${random_pet.name.id}"
  acl    = "private"
  tags = {
    Name = "devsecops-demo"
  }
}
