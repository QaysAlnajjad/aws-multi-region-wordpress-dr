//==========================================================================================================================================
//                                                                 S3
//==========================================================================================================================================

# S3 Bucket for WordPress Media
resource "aws_s3_bucket" "wordpress_media" {
  bucket = var.s3_bucket_name
  tags = { 
    Name = var.s3_bucket_name
    Description = "WordPress media storage"
    Project = "wordpress"
    Component = "s3"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuratio
resource "aws_s3_bucket_lifecycle_configuration" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id  
  rule {
    id = "intelligent_tiering"
    status = "Enabled"
    filter {
      prefix = ""   
    }
    transition {
      days = 0                       
      storage_class = "INTELLIGENT_TIERING" 
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}



resource "aws_s3_bucket_policy" "wordpress_media" {
  count = length(coalesce(var.cloudfront_distribution_arns, [])) > 0 ? 1 : 0

  bucket = aws_s3_bucket.wordpress_media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.wordpress_media.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arns
          }
        }
      }
    ]
  })
}