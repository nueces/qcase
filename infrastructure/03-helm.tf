#############################################################################
## Applications deployment using helm
##

locals {
  replica_count = length(local.availability_zones)
  commit_tag    = one([for tag in data.aws_ecr_image.qweb.image_tags : tag if can(regex("^[a-z0-9]{8}$", tag))])

}

data "aws_ecr_repository" "qweb" {
  name = "${local.project_name}/qweb-${var.environment}"
}

data "aws_ecr_image" "qweb" {
  repository_name = "${local.project_name}/qweb-${var.environment}"
  image_tag       = var.helm_deployment_tag
}

# TODO: Use an object map to declare the charts to be deployed and implement a for_each to replace hardcoded values.
resource "helm_release" "qweb" {
  name = "qweb"

  chart = join("/", [local.project_charts, "qweb"])

  set {
    name  = "replicaCount"
    value = local.replica_count
  }

  set {
    name  = "image.repository"
    value = data.aws_ecr_repository.qweb.repository_url
  }

  set {
    name  = "image.pullPolicy"
    value = "Always"
  }

  set {
    name  = "image.tag"
    value = local.commit_tag
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.port"
    value = "80"
  }

}

# NOTE:
#   There is another option that is creating a ECR repository for Helm packages and then use a Github workflow for
#   creating and publishing the package, but this looks simple at least a first look :)
