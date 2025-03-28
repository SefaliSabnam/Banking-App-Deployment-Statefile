resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for Banking App
resource "aws_s3_bucket" "banking_app" {
  bucket = "${var.bucket_prefix}-${random_id.bucket_suffix.id}"

  tags = {
    Name        = "BankingAppBucket"
    Environment = "Production"
  }
}

# Ownership Controls (required for ACLs to work properly)
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.banking_app.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set ACL for Public Read Access
resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.ownership]
  bucket     = aws_s3_bucket.banking_app.id
  acl        = "public-read"
}

# Block Public Access Configuration (Set to allow public access for website hosting)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.banking_app.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.banking_app.id

  index_document {
    suffix = "index.html"
  }
}

# Public Read Access Policy for Static Website
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.banking_app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.banking_app.arn}/*"
      }
    ]
  })
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.banking_app.id
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
