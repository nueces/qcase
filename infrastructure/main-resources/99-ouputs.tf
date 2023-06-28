##############################################################################
## Module outputs to be reused by another modules
##
##############################################################################

output "aws" {
  description = "AWS Generic Information"
  value = {
    account_id         = data.aws_caller_identity.current.account_id
    region             = data.aws_region.current.name
    availability_zones = local.availability_zones
  }
}

output "configurations" {
  description = "Project configuration"
  value       = local.configurations
}
