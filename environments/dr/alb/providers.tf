terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }
}


variable "dr_region" {
  type = string  
}

provider "aws" {
  region = var.dr_region
}

