resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for Banking App
resource "aws_s3_bucket" "banking_app" {
  bucket = "${var.bucket_prefix}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "BankingAppBucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.banking_app.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.banking_app.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.banking_app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.banking_app.id}/*"
      }
    ]
  })
}

# S3 Bucket for Storing Terraform State File
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.bucket_prefix}-state-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.banking_app.id
}

output "website_url" {
  value = aws_s3_bucket.banking_app.website_endpoint
}
