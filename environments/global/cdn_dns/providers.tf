terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }
}

variable "primary_region" {
  type = string
}

provider "aws" {
  region = var.primary_region
}
