//=============================================================================================================
//     Infrastructure Variables
//=============================================================================================================

vpc_config = {
    name = "WordPress-DR-VPC"
    cidr_block = "172.16.0.0/16"    
}

subnet_config = {
    DR-Pub-1A ={
        cidr_block = "172.16.0.0/20"
        availability_zone = "ca-central-1a"
        map_public_ip_on_launch = true
    }
    DR-Pub-1B ={
        cidr_block = "172.16.16.0/20"
        availability_zone = "ca-central-1b"
        map_public_ip_on_launch = true
    }
    DR-Prv-1A ={
        cidr_block = "172.16.48.0/20"
        availability_zone = "ca-central-1a"
        map_public_ip_on_launch = false
    }
    DR-Prv-1B ={
        cidr_block = "172.16.64.0/20"
        availability_zone = "ca-central-1b"
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
        subnets_names = ["DR-Pub-1A", "DR-Pub-1B"]
    }
    DR-Private-RT = {
        subnets_names = ["DR-Prv-1A", "DR-Prv-1B"]
    }
}

