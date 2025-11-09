variable "vpc_id" {
    type = string
}

variable "s3_bucket_name" {
    type = string
}

variable "oac_arn" {
    type = string
}

variable "cloudfront_media_distribution_arn" {
  type = string
  default = ""
}