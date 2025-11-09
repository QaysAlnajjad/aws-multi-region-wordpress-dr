variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dr"
}