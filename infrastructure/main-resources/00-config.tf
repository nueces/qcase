terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }

# Configuration values are set via command line options
  backend "s3" {
  }
}

#############################################################################
## Providers configuration
##
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Owner       = "DevOps"
      Project     = local.project_name
      Terraform   = "true"
    }
  }
}

#############################################################################
## Data resources
##

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

#############################################################################
## locals and project wide configuration
##

locals {
  availability_zones = coalesce(var.availability_zones, slice(data.aws_availability_zones.available.names, 0, var.availability_zones_amount))
  project_root       = join("/", [path.root, "..", ".."])
  configurations     = yamldecode(file(join("/", [local.project_root, "configuration.yml"])))
  project_name       = local.configurations.project_name
  cluster_name       = local.configurations.project_name
}

#############################################################################
