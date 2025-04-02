variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "lambda-api"
}

variable "source_path" {
  description = "Path to the Lambda function source code"
  type        = string
  default     = "lambda"
}

variable "path_include" {
  description = "Patterns to include when packaging Lambda function"
  type        = list(string)
  default     = ["**"]
}

variable "path_exclude" {
  description = "Patterns to exclude when packaging Lambda function"
  type        = list(string)
  default     = ["**/__pycache__/**"]
}

variable "lambda_architecture" {
  description = "Lambda function architecture"
  type        = list(string)
  default     = ["x86_64"]
}

variable "lambda_environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = {
    NODE_ENV = "production"
  }
}

variable "ecr_repo_max_images" {
  description = "Maximum number of images to keep in ECR repository"
  type        = number
  default     = 2
}

variable "docker_platform" {
  description = "Platform for Docker image build"
  type        = string
  default     = "linux/x86_64"
}

variable "ecr_tags" {
  description = "Tags for the ECR repository"
  type        = map(string)
  default     = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 3
}
