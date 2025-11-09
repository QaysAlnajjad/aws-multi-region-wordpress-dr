variable "cloudfront_distribution_config" {
    type = map(object({
        s3_bucket_name = optional(string)
        alb_origin = optional(bool)
        price_class = string
        cache_behavior = object({
          allowed_methods = list(string)
          cached_methods = list(string)
          ttl_min = number
          ttl_default = number
          ttl_max = number
          forward_headers = optional(list(string))
          forward_cookies = optional(string)
          forward_query_string = optional(bool)
        })
    }))
}

variable "ssl_certificate_arn" {                 # Used by CloudFront for SSL Termination
    description = "SSL certificate ARN for custom domain (required)"
    type = string
}

variable "hosted_zone_id" {                      # Used for creating DNS records that point the domain to CloudFront
    description = "Route 53 hosted zone ID"
    type = string
}

variable "primary_domain" {
    description = "Primary custom domain without www (e.g., yourdomain.com)"
    type = string
}