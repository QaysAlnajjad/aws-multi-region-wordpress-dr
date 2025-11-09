//==========================================================================================================================================
//                                                         /modules/rds/variables.tf
//==========================================================================================================================================

variable "vpc_id" {                                            
    type = string
}

variable "subnets" {                                   
    type = map(string)
}

variable "rds" {
    type = object({
        identifier = string
        # Engine
        engine_version = string
        # Compute & Performance
        instance_class = string 
        multi_az = bool  
        # Security & Network
        security_group_name = string
        subnets_names = list(string)
        # Database Setup
        username = string                   # Master admin user name
        db_name = string
        db_username = string                # wordpress database username - it will be created using (Lambda / bastion host)
    })
}

variable "private_subnets_ids" {                     
    type = list(string)
}

variable "security_groups" {
    type = map(string)
}

variable "secretsmanager_endpoint_sg_name" {  
    type = string
}

variable "lambda_security_group_name" {
    type = string
}

variable "lambda_role_arn" {
    type = string
}

/*
variable "bastion_host" {                   # Secondary solution for RDS MySQL Database initialization 
    type = map(object({
        ami = string
        instance_type = string
        key_name = string
        subnet_name = string
        security_group_name = string
        associate_public_ip_address = bool
        iam_role_name = string
        rds_instance_name = string
        user_data = string
    }))
}
*/