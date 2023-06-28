#############################################################################
## Helm deployments
##
#############################################################################

#############################################################################
## Load balancer
##

resource "helm_release" "load-balancer" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  #  depends_on = [
  #    kubernetes_service_account.aws-load-balancer-controller
  #  ]

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.cluster.vpc_config.0.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws-load-balancer-controller.metadata.0.name
  }

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.id
  }
}

#############################################################################
## Applications
##

# TODO: Use an object map to declare the charts to be deployed and implement a for_each to replace hardcoded values.
resource "helm_release" "qweb" {
  name = "qweb"

  chart = join("/", [local.project_charts, "qweb"])

  set {
    name  = "replicaCount"
    value = var.deployment_replicas
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
