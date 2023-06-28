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
    key    = "kubernets-resources.tfstate"
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
      Project     = local.project_name
      Terraform   = "true"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
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

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

data "aws_iam_openid_connect_provider" "cluster" {
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

data "aws_ecr_repository" "qweb" {
  name = "${local.project_name}/qweb-${var.environment}"
}

data "aws_ecr_image" "qweb" {
  repository_name = "${local.project_name}/qweb-${var.environment}"
  image_tag       = var.helm_deployment_tag
}

#############################################################################
## locals and project wide configuration
##


locals {
  project_root   = join("/", [path.root, "..", ".."])
  configurations = yamldecode(file(join("/", [local.project_root, "configuration.yml"])))
  project_name   = local.configurations.project_name
  project_charts = join("/", [local.project_root, "charts"])
  cluster_name   = local.configurations.project_name
  commit_tag     = one([for tag in data.aws_ecr_image.qweb.image_tags : tag if can(regex("^[a-z0-9]{8}$", tag))])
}

#############################################################################
