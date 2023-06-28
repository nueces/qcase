#############################################################################
## Kubernetes Cluster
##
##############################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
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
