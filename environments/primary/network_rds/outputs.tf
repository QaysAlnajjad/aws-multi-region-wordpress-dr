output "vpc_id" {
    value = module.network.vpc_id
}

output "public_subnets_ids" {
    value = module.network.public_subnets_ids
}

output "private_subnets_ids" {
    value = module.network.private_subnets_ids
}

output "subnets" {
    value = module.network.subnets
}




output "rds_name" {
    value = module.rds.rds_name
}

output "wordpress_secret_arn" {
    value = module.rds.wordpress_secret_arn
}


