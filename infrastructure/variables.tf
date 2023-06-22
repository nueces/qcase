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

#############################################################################"