variable "s3_bucket_name" {
    type = string
}

variable "cloudfront_media_distribution_arn" {
    type = string
    default = ""
}

variable "cloudfront_distribution_arns" {
  type    = list(string)
  default = []
  description = "List of CloudFront distribution ARNs to allow in S3 bucket policy"
}