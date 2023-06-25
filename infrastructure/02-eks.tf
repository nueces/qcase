module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.configurations.project_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    web_applications = {
      name        = "qweb"
      description = "EKS managed node group for web applications"

      instance_types = ["t3.micro", "t3.small"]
      capacity_type  = "SPOT"

      min_size     = 1 # 3
      max_size     = 6 # <= min * (100/max_unavailable_percentage)
      desired_size = 1 # 3 one per az

      update_config = {
        max_unavailable_percentage = 50
      }
    }
  }
}
