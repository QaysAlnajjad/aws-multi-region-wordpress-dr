ecs_security_group_config = {
    wordpress-service-SG = {
        ingress = {
            http = {
                from_port = 80
                to_port = 80 
                ip_protocol = "tcp"
                source_security_group_name = "ALB-SG"
            }
        }
        egress = {
            all = {
                from_port = 0
                to_port = 0
                ip_protocol = "-1"
                cidr_block = "0.0.0.0/0"
            }
        }
    }
    vpc-endpoints-SG = {
        ingress = {
            https = {
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                source_security_group_name = "wordpress-service-SG"
            }
        }
    }
}

ecr_image_uri = ""

ecs_cluster_name_config = "wordpress-cluster"

ecs_task_definition_config = {
    wordpress-task-definition = {
        family = "wordpress-task"
        cpu = "1024"
        memory = "2048"
    }
}

ecs_service_config = {
    wordpress-service = {
        cluster = "wordpress-cluster"
        task_definition = "wordpress-task-definition"
        desired_count = 0
        network_configuration = {
          security_group_name = "wordpress-service-SG"
        }
    }
}

vpc_endpoints_config = {
    "logs" = "Interface",
    "s3" = "Gateway", 
    "ecs" = "Interface",
    "sts" = "Interface",
    "monitoring" = "Interface",
    "ecr.api" = "Interface",
    "ecr.dkr" = "Interface",
    "ssmmessages" = "Interface",
    "ssm" = "Interface",
    "ec2messages" = "Interface",
    "secretsmanager" = "Interface"
}


