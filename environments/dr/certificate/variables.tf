variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}