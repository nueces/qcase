#############################################################################
# Variables
#############################################################################

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "The environment name value must be \"dev\", \"stg\", or \"prd\"."
  }
}

# TODO: Remove default value and pass this value via config options or a separate tfvars file.
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
  # Select the desired regions to be used.
  # only us, non gov: can(regex("^us(-gov)?-(east|west)-[1-9]$", var.aws_region))
  # only us, non gov: can(regex("^us-(east|west)-[1-9]$", var.aws_region))
  # only us-gov:      can(regex("^us-gov-(east|west)-[1-9]$", var.aws_region))
  # only eu:          can(regex("^eu-(central|north|south|west)-[1-9]$", var.aws_region))
  # only ap:          can(regex("^ap-(east|northeast|south|southeast)-[1-9]$", var.aws_region))
  # ANY: can(regex("^(us(-gov)?|ap|ca|cn|eu|sa)-(central|(north|south)?(east|west)?)-[1-9]$", var.aws_region))
  validation {
    # Allow only us and eu regions
    condition = anytrue([
      can(regex("^us-(east|west)-[1-9]$", var.aws_region)),
      can(regex("^eu-(central|north|south|west)-[1-9]$", var.aws_region)),
    ])
    error_message = "The aws select is invalid or is not allowed to be used on this project."
  }
}

variable "availability_zones" {
  type        = any # null or list(string)
  description = "Availability Zones. If null terraform would select N `availability_zones_amount` AZ from the region."
  default     = null
}

variable "availability_zones_amount" {
  type        = number
  description = "The amount of availability zones to use."
  default     = 3

  validation {
    condition     = var.availability_zones_amount >= 1
    error_message = "The amount of availability zones to use must be at least 1."
  }
}

variable "default_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "DevOps"
    Project     = "qcase"
    Terraform   = "true"
  }
}

#############################################################################
# VPC
#############################################################################

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "The VPC CIDR block provided in invalid."
  }
}

#############################################################################
# EKS
#############################################################################

variable "eks_cluster_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.27"
}

variable "eks_key_name" {
  description = "The key name that should be used for the instances"
  type        = string
  default     = null
}


variable "eks_managed_node_group_defaults" {
  description = "Default configuration for the managed node groups"
  type = object({
    ami_type : string
    capacity_type : string
    instance_types : list(string)
    min_size : number
    max_size : number
    desired_size : number
  })
  default = {
    ami_type       = "AL2_x86_64"
    capacity_type  = "SPOT"
    instance_types = ["t3.micro"]
    min_size       = 1
    max_size       = 1
    desired_size   = 1
  }
}

# TODO, this should be a list or map of objects to keep all the apps configurations in a single variable.
variable "eks_managed_node_groups" {
  description = "Configurations per application to be deployed in the eks_managed_node_groups for the EKS cluster."
  type = object({
    name : string
    description : string
    capacity_type : string
    instance_types : list(string)
    min_size : number
    max_size : number
    desired_size : number
    max_unavailable_percentage : number
  })
  default = {
    name                       = "qweb"
    description                = "qweb nodes"
    capacity_type              = "SPOT"
    instance_types             = ["t3.micro", "t3.small"]
    min_size                   = 1
    max_size                   = 6
    desired_size               = 3
    max_unavailable_percentage = 50
  }
}

#############################################################################
