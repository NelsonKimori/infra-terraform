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


  tags = {
    Name = "devsecops-demo"
  }

 
  versioning {
    enabled = true
  }


  bucket_acl = "private"
}


resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_logging" "demo_log" {
  bucket = aws_s3_bucket.demo.id
  target_bucket = "devsecops-demo-log-bucket" # You'll need to create this bucket
  target_prefix = "log/"
}
