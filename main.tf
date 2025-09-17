provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

#  Main S3 bucket
resource "aws_s3_bucket" "demo" {
  bucket = "devsecops-demo-${random_pet.name.id}"

  tags = {
    Name = "devsecops-demo"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "demo_rule"
    enabled = true
  }

  acl = "private"
}

#  Replica bucket (for cross-region replication)
resource "aws_s3_bucket" "replica" {
  bucket = "devsecops-demo-replica-${random_pet.name.id}"
  acl    = "private"
  region = "us-west-2"
}

#  IAM Role for replication
resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

#  Replication configuration
resource "aws_s3_bucket_replication_configuration" "demo" {
  depends_on = [aws_s3_bucket.demo, aws_s3_bucket.replica]

  bucket = aws_s3_bucket.demo.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}

#  KMS Key
resource "aws_kms_key" "demo" {
  description             = "KMS key for DevSecOps demo"
  deletion_window_in_days = 10
}

#  Encrypt S3 with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.demo.arn
    }
  }
}

#  SNS Topic with KMS encryption
resource "aws_sns_topic" "demo" {
  name              = "devsecops-demo-s3-events"
  kms_master_key_id = aws_kms_key.demo.arn
}
