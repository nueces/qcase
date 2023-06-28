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
