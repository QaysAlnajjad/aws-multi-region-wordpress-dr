# S3 Cross-Region Replication Role
module "s3_replication" {
  source = "../../../modules/iam"
  role_name = "s3-cross-region-replication-role"
  policy_name = "s3-cross-region-replication-policy"
  assume_role_services = ["s3.amazonaws.com"]
  
  managed_policy_arns = []

  inline_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ]
      Resource = [
        "arn:aws:s3:::wordpress-media-prod-200/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ]
      Resource = [
        "arn:aws:s3:::wordpress-media-dr-200/*"
      ]
    }
  ]
}