
output "aws" {
  description = "AWS Generic Information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }
}


output "ecr_repositories" {
  description = "ECR repository url per environment"
  value       = module.ecr[*]
}
