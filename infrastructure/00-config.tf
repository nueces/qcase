terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }

  # TODO: Set this values via the -backend-config arguments to support multiples environments
  #   using different tfstate files. And reading the bucket name from the configuration.yml file.
  backend "s3" {
    bucket = "887012142425-eu-central-1-terraform-backend-qcase"
    key    = "qcase.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Owner       = "DevOps"
      Project     = local.configurations.project_name
      Terraform   = "true"
    }
  }
}

# Load project wide configuration
locals {
  availability_zones = coalesce(var.availability_zones, slice(data.aws_availability_zones.available.names, 0, var.availability_zones_amount))
  configurations     = yamldecode(file(join("/", [path.root, "..", "configuration.yml"])))
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

output "aws" {
  value = {
    account_id         = data.aws_caller_identity.current.account_id
    region             = data.aws_region.current.name
    availability_zones = local.availability_zones
    configurations     = local.configurations
  }
}

