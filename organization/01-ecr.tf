
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  # We want to create one registry per environment to have a simple way to control who can upload images that are going
  # to be deployed. Ideally for production only the CI would build and upload images to the registry.
  for_each = {
    for i in setproduct(var.projects, var.environments) : "${i[0]}-${i[1]}" => { project = i[0], env = i[1] }
  }

  repository_name = each.key

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  repository_image_tag_mutability   = "MUTABLE"
  create_lifecycle_policy           = true
  # See:
  #   - https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters
  #   - https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_examples.html#lp_example_difftype
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        "rulePriority" : 1,
        "description" : "Remove tagged images if there are more than ${lookup(var.ecr_keep_images_count, each.value.env)}",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPrefixList" : [each.value.env],
          "countType" : "imageCountMoreThan",
          "countNumber" : lookup(var.ecr_keep_images_count, each.value.env)
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 2,
        "description" : "Remove untagged images after ${lookup(var.ecr_keep_untagged_images_days, each.value.env)} day",
        "selection" : {
          "tagStatus" : "untagged",
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : lookup(var.ecr_keep_untagged_images_days, each.value.env)
        },
        "action" : {
          "type" : "expire"
        }
      },
    ]
  })

  repository_force_delete = true

  tags = merge(var.default_tags, {
    Name        = each.key
    Project     = each.value.project
    Environment = each.value.env
    }
  )
}
