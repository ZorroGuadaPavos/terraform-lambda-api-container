variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "PROJECT_NAME"
}

variable "company_name" {
  description = "The name of the company"
  type        = string
  default     = "COMPANY_NAME"
}


variable "source_path" {
  description = "Path to the Lambda function source code"
  type        = string
  default     = "../app"
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

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 3
}
