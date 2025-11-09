output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = module.certificate.certificate_arn
}