terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
    aws_sns = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
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
  lifecycle_rule {
    id = "demo_rule"
    enabled = true
  }
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
  target_bucket = "devsecops-demo-log-bucket"
  target_prefix = "log/"
}

# Fix 1: Ensure rotation for KMS key is enabled
resource "aws_kms_key" "demo" {
  description             = "KMS key for devsecops demo S3 bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true  # <-- FIX IS HERE
}

# Fix 2: Ensure an S3 bucket has event notifications enabled
resource "aws_sns_topic" "demo" {
  name = "devsecops-demo-s3-events"
}

resource "aws_s3_bucket_notification" "demo" {
  bucket = aws_s3_bucket.demo.id
  topic {
    topic_arn = aws_sns_topic.demo.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Fix 3: Ensure KMS key Policy is defined
resource "aws_kms_key_policy" "demo" {
  key_id = aws_kms_key.demo.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "Allow administration of the key",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # You can use a more specific IAM principal here
        },
        Action    = "kms:*",
        Resource  = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
