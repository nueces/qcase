##############################################################################
## VPC
##
##############################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.project_name
  cidr = var.vpc_cidr_block

  azs             = local.availability_zones
  private_subnets = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr_block, 8, k + 1)]
  public_subnets  = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr_block, 8, k + 1 + 85)]
  #infra_subnets   = [for k, v in local.availability_zones: cidrsubnet(var.vpc_cidr_block, 8, k + 1 + 85 + 85)]

  # We use 85, which is equal to 255/3, to utilize a different set of the cdir range for the subnets in each az:
  # for a CIDR block 10.0.0.0/16 the resulting subnets are:
  # - private: 10.0.[1-85].0
  # - public:  10.0.[86-170].0
  # - infra:   10.0.[171-255].0
  #
  # while for a CIDR block 10.0.0.0/8 the resulting subnets are:
  # - private: 10.[1-85].0.0
  # - public:  10.[86-170].0.0
  # - infra:   10.[171-255].0.0


  enable_nat_gateway = true

  # This options create a single nat in the first availability zone, instead of one per AZ.
  # Set to true, in order to reduce costs on this poc.
  single_nat_gateway = true

  # true by default
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.project_name}" = "owned"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.project_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = merge(var.default_tags, {
    AvailabilityZones = jsonencode(local.availability_zones),
    }
  )
}