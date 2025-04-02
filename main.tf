data "aws_region" "current" {}

data "aws_caller_identity" "this" {}

data "aws_ecr_authorization_token" "token" {}

locals {
  project_name = var.project_name

  # Dynamic tags
  tags = merge(var.ecr_tags, {
    Project = var.project_name
  })

  source_path   = var.source_path
  path_include  = var.path_include
  path_exclude  = var.path_exclude
  files_include = setunion([for f in local.path_include : fileset(local.source_path, f)]...)
  files_exclude = setunion([for f in local.path_exclude : fileset(local.source_path, f)]...)
  files         = sort(setsubtract(local.files_include, local.files_exclude))

  dir_sha = sha1(join("", [for f in local.files : filesha1("${local.source_path}/${f}")]))
}

provider "aws" {
  region = var.aws_region

  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

provider "docker" {
  registry_auth {
    address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, data.aws_region.current.name)
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

module "docker_build" {
  source = "terraform-aws-modules/lambda/aws//modules/docker-build"

  create_ecr_repo = true
  ecr_repo        = local.project_name
  ecr_repo_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last ${var.ecr_repo_max_images} images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : var.ecr_repo_max_images
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })

  ecr_repo_tags = local.tags

  use_image_tag = false

  source_path = local.source_path
  platform    = var.docker_platform

  triggers = {
    dir_sha = local.dir_sha
  }
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.0"

  function_name = "${local.project_name}-function"
  description   = "Lambda function with container image"

  create_package = false

  # Container Image
  package_type  = "Image"
  architectures = var.lambda_architecture
  image_uri     = module.docker_build.image_uri

  # Add CloudWatch Logs permissions
  attach_policy_json = true
  policy_json        = file("${path.module}/iam-policy.json")

  cloudwatch_logs_retention_in_days = var.log_retention_days

  environment_variables = var.lambda_environment_variables
  
  tags = local.tags
}

# Create API Gateway
module "apigateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 1.1"

  name          = "${local.project_name}-gateway"
  protocol_type = "HTTP"

  create_api_domain_name = false

  integrations = {
    "$default" = {
      lambda_arn = module.lambda_function.lambda_function_arn
    }
  }
  
  tags = local.tags
}

# Add explicit permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.apigateway.apigatewayv2_api_execution_arn}/*/$default"
}
