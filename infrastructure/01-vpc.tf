
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.configurations.project_name
  cidr = var.vpc_cidr_block

  azs             = local.availability_zones
  private_subnets = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr_block, 8, k + 1)]
  public_subnets  = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr_block, 8, k + 1 + 85)]
  #infra_subnets   = [for k, v in local.availability_zones: cidrsubnet(var.vpc_cidr_block, 8, k + 1 + 85 + 85)]

  enable_nat_gateway = true

  tags = merge(var.default_tags, {
    AvailabilityZones = jsonencode(local.availability_zones),
    }
  )
}