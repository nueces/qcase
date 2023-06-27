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

#############################################################################
## Providers configuration
##
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

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
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

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_name]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_name]
}

#############################################################################
## locals and project wide configuration
##

locals {
  project_charts     = join("/", [path.root, "..", "charts"])
  availability_zones = coalesce(var.availability_zones, slice(data.aws_availability_zones.available.names, 0, var.availability_zones_amount))
  configurations     = yamldecode(file(join("/", [path.root, "..", "configuration.yml"])))
}

#############################################################################
