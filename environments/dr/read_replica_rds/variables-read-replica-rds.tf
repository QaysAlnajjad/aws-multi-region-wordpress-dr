//=============================================================================================================
//     Read Replica RDS Variables
//=============================================================================================================


variable "rds_security_group_config" {
    type = map(object({
        vpc_name = string
        ingress = optional(map(object({
            ip_protocol = string
            from_port = number
            to_port = number
            cidr_block = optional(string)
            source_security_group_name = optional(string)
        })))
        egress = optional(map (object({
            ip_protocol = string
            from_port = number
            to_port = number
            cidr_block = optional(string)
            source_security_group_name = optional(string)
        })) )
    }))
}

variable "rds_config" {
    type = object({
        identifier = string
        engine_version = string
        instance_class = string 
        multi_az = bool  
        security_group_name = string
        username = string 
        db_username = string 
        db_name = string
        subnets_names = list(string)
    })
}

variable "secretsmanager_endpoint_sg_name_config" {
    type = string
}

variable "lambda_security_group_name_config" {
    type = string
}

/*
variable "bastion_host" {
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
