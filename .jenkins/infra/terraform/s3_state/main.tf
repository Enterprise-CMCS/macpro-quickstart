##############################################
# Build this example in US East (N. Virginia)
##############################################

provider "aws" {
  region  = "us-east-1"
  version = "2.58.0"
}

##############################################
# Build a bucket to hold TF state
##############################################

resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = var.bucket
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  force_destroy = true
  tags = {
    Name = var.bucket
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_bucket" {
  bucket              = aws_s3_bucket.tf_state_bucket.id
  block_public_acls   = true
  block_public_policy = true
}
