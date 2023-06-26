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
    key    = "organization.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner     = "Org"
      Terraform = "true"
    }
  }
}

# Load project wide configuration
locals {
  project_root   = dirname(abspath(path.root))
  configurations = yamldecode(file(join("/", [local.project_root, "configuration.yml"])))
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
