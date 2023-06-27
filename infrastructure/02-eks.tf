#############################################################################
## Kubernetes Cluster
##

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.project_name
  cluster_version = var.eks_cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type       = var.eks_managed_node_group_defaults.ami_type
    instance_types = var.eks_managed_node_group_defaults.instance_types
    key_name       = coalesce(var.eks_key_name, local.configurations.key_name)

    min_size     = var.eks_managed_node_group_defaults.min_size
    max_size     = var.eks_managed_node_group_defaults.max_size # <= min * (100/max_unavailable_percentage) ?
    desired_size = var.eks_managed_node_group_defaults.desired_size
  }

  # TODO:
  #   replace with a dynamic block
  #   move default values to the previous section.
  eks_managed_node_groups = {
    apps = {
      name        = var.eks_managed_node_groups.name
      description = var.eks_managed_node_groups.description

      capacity_type  = var.eks_managed_node_groups.capacity_type
      instance_types = var.eks_managed_node_groups.instance_types

      min_size     = var.eks_managed_node_groups.min_size
      max_size     = var.eks_managed_node_groups.max_size # <= min * (100/max_unavailable_percentage) ?
      desired_size = var.eks_managed_node_groups.desired_size

      update_config = {
        max_unavailable_percentage = var.eks_managed_node_groups.max_unavailable_percentage
      }
    }
  }

  tags = var.default_tags
}

#############################################################################
## Load Balancer
##

module "load-balancer-role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${local.project_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.load-balancer-role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}
