output "primary_domain" {                                       # For task definition (environment variables in container definition)
  value = var.primary_domain
}

output "media_distribution_id" {
  value = aws_cloudfront_distribution.main["wordpress-media"].id
}

output "media_distribution_domain" {
  value = aws_cloudfront_distribution.main["wordpress-media"].domain_name
}

output "media_distribution_arn" {
  value = aws_cloudfront_distribution.main["wordpress-media"].arn
}
  