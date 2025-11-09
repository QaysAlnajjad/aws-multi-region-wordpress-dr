data "terraform_remote_state" "oac" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/global/oac.tfstate"
    region = "eu-central-1"
  }  
}

data "terraform_remote_state" "primary_s3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/primary/s3.tfstate"
    region = "eu-central-1"
  }  
}

data "terraform_remote_state" "dr_s3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/dr/s3.tfstate"
    region = "eu-central-1"
  }  
}

data "terraform_remote_state" "primary_alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/primary/alb.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "dr_alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/dr/alb.tfstate"
    region = "eu-central-1"
  }
}

module "cdn" {
  source = "../../../modules/cdn"

  # Primary origins
  primary_alb_dns_name = data.terraform_remote_state.primary_alb.outputs.alb_dns_name
  primary_alb_zone_id = data.terraform_remote_state.primary_alb.outputs.alb_zone_id

  # DR origins
  dr_alb_dns_name = data.terraform_remote_state.dr_alb.outputs.alb_dns_name

  # S3 origins
  primary_bucket_regional_domain_name = data.terraform_remote_state.primary_s3.outputs.bucket_regional_domain_name
  dr_bucket_regional_domain_name = data.terraform_remote_state.dr_s3.outputs.bucket_regional_domain_name

  oac_id = data.terraform_remote_state.oac.outputs.oac_id
  cloudfront_distribution = var.cloudfront_distribution_config
  primary_domain = var.primary_domain
  hosted_zone_id = var.hosted_zone_id
  ssl_certificate_arn = var.ssl_certificate_arn
}