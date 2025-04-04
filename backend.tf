resource "aws_s3_bucket" "terraform_state" {
  bucket        = "sefali-terraform-state-1234"
  force_destroy = true  

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
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

terraform {
  backend "s3" {
    bucket         = "sefali-terraform-state-1234"  # Fixed Bucket Name
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.id
}
