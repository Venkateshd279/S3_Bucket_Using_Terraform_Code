# terraform init
# terraform plan -var-file="variable.tfvars"
# terraform apply -var-file="variable.tfvars" -auto-approve
# terraform destroy -var-file="variable.tfvars" -auto-approve

provider "aws" {
  region = var.region  # Specify the region
}

# Variables
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-west-2"
}

variable "iam_role" {
  description = "IAM Role associated with S3 bucket (optional)"
  type        = string
  default     = ""
}

variable "versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}

variable "public_access" {
  description = "Allow public access to the bucket"
  type        = bool
  default     = false
}


variable "acl" {
  description = "Access control list for the bucket"
  type        = string
  default     = "private"
} 

variable "encryption" {
  description = "Enable server-side encryption (SSE-S3)"
  type        = bool
  default     = false
}

# S3 Bucket creation
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  

  tags = {
    Name = var.bucket_name
  }
}


# S3 Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.my_bucket.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket ACL (Access Control List)
resource "aws_s3_bucket_acl" "bucket_acl" {

    depends_on = [aws_s3_bucket_ownership_controls.example]
  bucket = aws_s3_bucket.my_bucket.bucket
  acl    = var.acl == "public" ? "public-read" : "private"
}

# Enable versioning if specified
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my_bucket.bucket

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

# Server-Side Encryption Configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count  = var.encryption ? 1 : 0
  bucket = aws_s3_bucket.my_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block - Conditionally block public access
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.my_bucket.id
  block_public_acls       = !var.public_access
  ignore_public_acls      = !var.public_access
  block_public_policy     = !var.public_access
  restrict_public_buckets = !var.public_access
}

# S3 Bucket Policy (if public access is enabled)
resource "aws_s3_bucket_policy" "public_access_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  count = var.public_access ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "s3:GetObject",
        Effect    = "Allow",
        Resource  = "arn:aws:s3:::${var.bucket_name}/*",
        Principal = "*"
      }
    ]
  })
}


# Output the bucket name and ARN
output "bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}
