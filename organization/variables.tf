#############################################################################
# Variables
#############################################################################

# A simple list of projects to express the idea.
variable "projects" {
  description = "List of projects in the organization"
  type        = list(string)
  default     = ["qcase/qweb"]
}

variable "environments" {
  description = "Environments name"
  type        = list(string)
  default     = ["dev"]

  validation {
    condition     = alltrue([for env in var.environments : contains(["dev", "stg", "prd"], env)])
    error_message = "The environments name values must be one or more of the following ones \"dev\", \"stg\", or \"prd\"."
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

variable "default_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Environment = "ToBeSet"
    Owner       = "Org"
    Terraform   = "true"
  }
}

#############################################################################
# ECR
#############################################################################

variable "ecr_keep_images_count" {
  description = "Total number of images to keep in the ECR repository. Defined per environment."
  type        = map(number)
  default = {
    dev = 3
    stg = 3
    prd = 6
  }
}

variable "ecr_keep_untagged_images_days" {
  description = "Number of days that untagged images are keep in the registry. Defined per environment."
  type        = map(number)
  default = {
    dev = 1
    stg = 1
    prd = 3
  }
}
