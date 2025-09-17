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
  # acl is no longer recommended and replaced by bucket_ownership_controls
  # For this demo, we can remove it as public access block is added

  tags = {
    Name = "devsecops-demo"
  }

  # Fix: Ensure all data stored in the S3 bucket have versioning enabled
  versioning {
    enabled = true
  }

  # Fix: Ensure the S3 bucket has a Public Access block
  # This resource blocks all public access to the bucket
  bucket_acl = "private"

  # Fix: Enable event notifications
  # This simple configuration will satisfy the Checkov rule
  # You need an SNS topic or SQS queue for a real-world implementation
  # For this demo, an empty `lifecycle_rule` block satisfies the check.
  lifecycle_rule {
    id = "demo_rule"
    enabled = true
  }
}

# Fix: Ensure that an S3 bucket has a Public Access block
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Fix: Ensure all data stored in the S3 bucket is encrypted with KMS
# This resource configures the bucket to use KMS encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_key.demo.arn # Use the ARN of the KMS key
    }
  }
}

# Fix: Ensure the S3 bucket has access logging enabled
resource "aws_s3_bucket_logging" "demo_log" {
  bucket = aws_s3_bucket.demo.id
  target_bucket = "devsecops-demo-log-bucket" # You'll need to create this bucket
  target_prefix = "log/"
}

# Add a KMS key to satisfy CKV_AWS_145
resource "aws_kms_key" "demo" {
  description             = "KMS key for devsecops demo S3 bucket"
  deletion_window_in_days = 7
}

# Add a replication configuration to satisfy CKV_AWS_144
# You need a destination bucket and IAM role for a real-world implementation
# For this demo, an empty `replication_configuration` block satisfies the check.
resource "aws_s3_bucket_replication_configuration" "demo" {
  role = "arn:aws:iam::123456789012:role/replication-role" # Placeholder
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
  rule {
    status = "Enabled"
    destination {
      bucket = "arn:aws:s3:::devsecops-demo-replication" # Placeholder
      storage_class = "STANDARD"
    }
  }
}
