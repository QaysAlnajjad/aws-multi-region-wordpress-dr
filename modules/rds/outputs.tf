//==========================================================================================================================================
//                                                         /modules/rds/outputs.tf
//==========================================================================================================================================

output "wordpress_secret_id" {                                 # For container secrets injection, referencing in DR region
    value = aws_secretsmanager_secret.wordpress.id
}
