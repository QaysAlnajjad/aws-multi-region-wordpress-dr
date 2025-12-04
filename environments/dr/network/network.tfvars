//=============================================================================================================
//     Infrastructure Variables
//=============================================================================================================

vpc_config = {
    name = "WordPress-DR-VPC"
    cidr_block = "172.16.0.0/16"    
}

subnet_config = {
    DR-Pub-A ={
        cidr_block = "172.16.0.0/20"
        availability_zone = local.az_map["A"]
        map_public_ip_on_launch = true
    }
    DR-Pub-B ={
        cidr_block = "172.16.16.0/20"
        availability_zone = local.az_map["B"]
        map_public_ip_on_launch = true
    }
    DR-Prv-A ={
        cidr_block = "172.16.48.0/20"
        availability_zone = local.az_map["A"]
        map_public_ip_on_launch = false
    }
    DR-Prv-B ={
        cidr_block = "172.16.64.0/20"
        availability_zone = local.az_map["B"]
        map_public_ip_on_launch = false
    }
}

route_table_config = {
    DR-Public-RT = {
        routes = {
            default = {
                cidr_block = "0.0.0.0/0"
                gateway = true
            }
        }
        subnets_names = ["DR-Pub-A", "DR-Pub-B"]
    }
    DR-Private-RT = {
        subnets_names = ["DR-Prv-A", "DR-Prv-B"]
    }
}

