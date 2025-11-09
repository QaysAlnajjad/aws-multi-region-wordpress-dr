module "certificate" {
  source = "../../../modules/acm"
  
  domain_name = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  hosted_zone_id = var.hosted_zone_id
  environment = "dr"
}