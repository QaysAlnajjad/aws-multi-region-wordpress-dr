//==================================================================================
// 1. Create ALB
//==================================================================================

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/dr/network.tfstate"
    region = "eu-central-1"
  }  
}

data "terraform_remote_state" "certificate" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/dr/certificate.tfstate"
    region = "eu-central-1"
  }
}

module "sg_alb" {
  source = "../../../modules/sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  security_group = var.alb_security_group_config
  stage_tag = "ALB"
}

module "alb" {
  source = "../../../modules/alb"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  target_group = var.target_group_config
  public_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets_ids
  alb_name = var.alb_name_config
  alb_security_group_id = module.sg_alb.alb_security_group_id
  ssl_certificate_arn = data.terraform_remote_state.certificate.outputs.certificate_arn
}

