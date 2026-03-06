############################################
# AWS Regions
############################################
regions:
  primary: us-east-1
  dr: ca-central-1

############################################
# Terraform Backend
############################################
terraform:
  backend:
    bucket_name: terraform-state-1011202555
    region: eu-central-1

############################################
# Container / Images
############################################
docker:
  dockerhub_image: qaysalnajjad/ecs-wordpress-app:v3.6
ecr:
  repository: ecs-wordpress-app

############################################
# Media Storage
############################################
s3:
  media:
    primary_bucket: wordpress-media-primary-2004
    dr_bucket: wordpress-media-dr-2004

############################################
# Database
############################################
rds:
  identifier: wordpress-rds

############################################
# Domain
############################################
domain:
  hosted_zone_id: ""
  primary_domain: example.com  # Primary custom domain without www (e.g., yourdomain.com)
  certificate_sans:
    - "*.example.com"

############################################
# SSL Certificates
############################################
certificates:
  primary_alb: ""
  dr_alb: ""
  cloudfront: ""


