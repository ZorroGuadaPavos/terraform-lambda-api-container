# Terraform Lambda API Container

A Terraform project that deploys a containerized Node.js Lambda function with API Gateway integration.

## Architecture

This project creates the following AWS resources:

- **Lambda Function**: Runs a containerized Node.js application using Hono framework
- **API Gateway**: HTTP API Gateway that exposes the Lambda function
- **ECR Repository**: Stores the Docker container image for the Lambda function
- **IAM Role & Policies**: Necessary permissions for Lambda to write logs

## Requirements

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Docker installed (for building the container image)

## Quick Start

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   cd terraform-lambda-api-container
   ```

2. **Initialize Terraform with environment-specific backend**:
   ```bash
   # For development environment
   terraform init -backend-config="./terraform/config/dev.config"
   
   # For production environment
   terraform init -backend-config="./terraform/config/prd.config"
   ```

3. **Select or create workspace for environment**:
   ```bash
   # View available workspaces
   terraform workspace list
   
   # Create new workspace if needed
   terraform workspace new dev
   
   # Select existing workspace
   terraform workspace select dev
   ```

4. **Deploy the infrastructure**:
   ```bash
   terraform apply
   ```

5. **Test the API**:
   ```bash
   curl $(terraform output -raw api_endpoint)
   ```

## Working with Environments

This project uses Terraform workspaces to manage different environments (dev, staging, prod, etc.). Each workspace maintains its own separate state file, allowing you to have different configurations for each environment.

### Backend Configuration

We use partial backend configuration to keep environment-specific settings separate from the main configuration. The backend configuration files are stored in the `./terraform/config/` directory:

- `dev.config`: Development environment backend settings
- `prd.config`: Production environment backend settings

These files contain the S3 bucket details where Terraform state is stored for each environment.

To work with a specific environment, you need to:

1. Initialize with the appropriate backend configuration
2. Select the corresponding workspace
3. Apply changes to that environment

Example workflow for development:

```bash
terraform init -backend-config="./terraform/config/dev.config"
terraform workspace select dev
terraform apply
```

Example workflow for production:

```bash
terraform init -backend-config="./terraform/config/prd.config"
terraform workspace select prod
terraform apply
```

For more information on partial backend configuration, see the [Terraform documentation](https://developer.hashicorp.com/terraform/language/backend#partial-configuration).

## Project Structure

```
.
├── app/                   # Lambda function source code
│   ├── Dockerfile         # Docker configuration for Lambda
│   ├── package.json       # Node.js dependencies
│   └── src/               # Source code files
│       └── index.js       # Lambda handler function
├── terraform/             # Terraform configuration files
│   ├── config/            # Environment-specific backend configs
│   │   ├── dev.config     # Development environment config
│   │   └── prd.config     # Production environment config
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   └── versions.tf        # Terraform and provider versions
└── view-logs.sh           # Helper script to view Lambda logs
```

## Configuration

The project uses variables to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region to deploy resources | `eu-west-3` |
| `project_name` | Name of the project, used for resource naming | `tastethis` |
| `company_name` | Company name used in resource naming | `dijkwater` |
| `source_path` | Path to the Lambda function source code | `../app` |
| `lambda_architecture` | Lambda function architecture | `["x86_64"]` |
| `ecr_repo_max_images` | Maximum number of images to keep in ECR | `2` |
| `log_retention_days` | Number of days to retain CloudWatch logs | `3` |

## Lambda Function

The Lambda function uses the Hono framework to handle HTTP requests. The implementation is in `app/src/index.js` and exposes several endpoints:

- `GET /` - Simple health check endpoint
- `GET /hello/:name` - Returns a personalized greeting message
- `POST /echo` - Echoes back the request body
- `GET /error` - Deliberately triggers an error (for testing error handling)

## Viewing Logs

To view the Lambda function logs, use the included helper script:

```bash
./view-logs.sh
```

For more detailed logs:

```bash
./view-logs.sh --full
```

## Customization

### Adding Environment Variables

The Lambda function already includes the `ENVIRONMENT` variable set to the current workspace name. You can add more environment variables by modifying the `environment_variables` block in the Lambda module:

```terraform
environment_variables = {
  ENVIRONMENT = terraform.workspace
  DEBUG       = "true"
  API_VERSION = "1.0"
}
```

### Adding API Routes

The API Gateway is configured with a `$default` catch-all route that forwards all requests to the Lambda function. However, you can define specific routes for more granular control over API behavior:

```terraform
integrations = {
  "$default" = {
    lambda_arn = module.lambda_function.lambda_function_arn
  }
  "GET /api/example" = {
    lambda_arn = module.lambda_function.lambda_function_arn
    throttling_rate_limit  = 10    # Requests per second
    throttling_burst_limit = 5     # Concurrent requests
  }
  "POST /api/example" = {
    lambda_arn = module.lambda_function.lambda_function_arn
    authorization_type = "JWT"     # Add authorization
  }
}
```

This approach is useful when you need to:
- Apply different throttling rates to protect specific endpoints
- Configure authorization for certain routes only
- Add request validation or transformations to specific endpoints
- Route different endpoints to separate Lambda functions (for microservices)
- Set up detailed metrics and logging per endpoint

Note that your actual API routing logic is still handled by the Hono framework in your Lambda function code.

## Troubleshooting

### Provider Errors

If you encounter errors related to missing providers when running `terraform apply`, try the following:

1. Ensure all required providers are configured in `versions.tf`:
   ```terraform
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = ">= 5.79"
       }
       docker = {
         source  = "kreuzwerker/docker"
         version = ">= 3.0"
       }
       archive = {
         source  = "hashicorp/archive"
         version = ">= 2.0.0"
       }
     }
   }
   ```

2. Re-initialize Terraform with the correct backend configuration:
   ```bash
   terraform init -backend-config="./terraform/config/dev.config"
   ```

3. If you're still experiencing issues, try removing the `.terraform` directory and re-initializing:
   ```bash
   rm -rf .terraform
   terraform init -backend-config="./terraform/config/dev.config"
   ```

### Docker Issues

If you encounter Docker-related errors:

1. Make sure Docker Desktop is running
2. Check if your user has permissions to use Docker
3. Try building the Docker image manually to debug any issues:
   ```bash
   cd app
   docker build -t lambda-test .
   ```

### Backend Configuration Issues

If you're having issues with the backend configuration:

1. Ensure your AWS credentials have access to the S3 bucket specified in the config files
2. Verify that the bucket exists in the specified region
3. Check for typos in the bucket name, key, or region in your config files

## Cleanup

To remove all resources created by this project:

```bash
terraform destroy
```

## Tags

All resources are tagged with:
- `Environment = "${terraform.workspace}"`
- `ManagedBy = "Terraform"`
- `Project = "${var.project_name}"`
- `Company = "${var.company_name}"`

You can filter resources with these tags in the AWS Console using Resource Groups & Tag Editor.

To find all resources with these tags using the AWS CLI:

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=${var.project_name} Key=Environment,Values=${terraform.workspace} \
  --region ${var.aws_region}
```