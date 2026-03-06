
#!/usr/bin/env bash
set -eo pipefail

CONFIG_FILE="${1:-$(dirname "$0")/../config.yaml}"

command -v yq >/dev/null 2>&1 || {
  echo "❌ ERROR: yq is required but not installed"
  exit 1
}

PRIMARY_REGION=$(yq -r '.regions.primary' "$CONFIG_FILE")
DR_REGION=$(yq -r '.regions.dr' "$CONFIG_FILE")

TF_STATE_BUCKET_NAME=$(yq -r '.terraform.backend.bucket_name' "$CONFIG_FILE")
TF_STATE_BUCKET_REGION=$(yq -r '.terraform.backend.region' "$CONFIG_FILE")

DOCKERHUB_IMAGE=$(yq -r '.docker.dockerhub_image' "$CONFIG_FILE")
ECR_REPO_NAME=$(yq -r '.ecr.repository' "$CONFIG_FILE")

PRIMARY_MEDIA_S3_BUCKET=$(yq -r '.s3.media.primary_bucket' "$CONFIG_FILE")
DR_MEDIA_S3_BUCKET=$(yq -r '.s3.media.dr_bucket' "$CONFIG_FILE")

RDS_IDENTIFIER=$(yq -r '.rds.identifier' "$CONFIG_FILE")

HOSTED_ZONE_ID=$(yq -r '.domain.hosted_zone_id' "$CONFIG_FILE")
PRIMARY_DOMAIN=$(yq -r '.domain.primary_domain' "$CONFIG_FILE")
CERTIFICATE_SANs=$(yq -c '.domain.certificate_sans' "$CONFIG_FILE")

PRIMARY_ALB_SSL_CERTIFICATE_ARN=$(yq -r '.certificates.primary_alb' "$CONFIG_FILE")
DR_ALB_SSL_CERTIFICATE_ARN=$(yq -r '.certificates.dr_alb' "$CONFIG_FILE")
CLOUDFRONT_SSL_CERTIFICATE_ARN=$(yq -r '.certificates.cloudfront' "$CONFIG_FILE")



export PRIMARY_REGION
export DR_REGION
export TF_STATE_BUCKET_NAME
export TF_STATE_BUCKET_REGION
export DOCKERHUB_IMAGE
export ECR_REPO_NAME
export PRIMARY_MEDIA_S3_BUCKET
export DR_MEDIA_S3_BUCKET
export RDS_IDENTIFIER
export HOSTED_ZONE_ID
export PRIMARY_DOMAIN
export CERTIFICATE_SANs
export PRIMARY_ALB_SSL_CERTIFICATE_ARN
export DR_ALB_SSL_CERTIFICATE_ARN
export CLOUDFRONT_SSL_CERTIFICATE_ARN
