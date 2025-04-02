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
- Docker installed (for local testing)

## Quick Start

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   cd terraform-lambda-api-container
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform apply
   ```

4. **Test the API**:
   ```bash
   curl $(terraform output -raw api_endpoint)
   ```

## Project Structure

```
.
├── lambda/                # Lambda function source code
│   ├── Dockerfile         # Docker configuration for Lambda
│   ├── package.json       # Node.js dependencies
│   └── src/               # Source code files
│       └── index.js       # Lambda handler function
├── iam-policy.json        # IAM policy for Lambda CloudWatch access
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions
├── outputs.tf             # Output definitions
├── versions.tf            # Terraform and provider versions
└── view-logs.sh           # Helper script to view Lambda logs
```

## Configuration

The project uses variables to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region to deploy resources | `eu-west-3` |
| `project_name` | Name of the project, used for resource naming | `lambda-api` |
| `source_path` | Path to the Lambda function source code | `lambda` |
| `lambda_architecture` | Lambda function architecture | `["x86_64"]` |
| `ecr_repo_max_images` | Maximum number of images to keep in ECR | `2` |

## Lambda Function

The Lambda function uses the Hono framework to handle HTTP requests. The implementation is in `lambda/src/index.js` and exposes several endpoints:

- `GET /` - Simple health check endpoint
- `GET /hello/:name` - Returns a greeting message
- `POST /echo` - Echoes back the request body

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

Modify the `lambda_environment_variables` variable in `variables.tf`:

```terraform
variable "lambda_environment_variables" {
  default = {
    NODE_ENV = "production"
    MY_VAR   = "my-value"
  }
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

## Cleanup

To remove all resources created by this project:

```bash
terraform destroy
```

## Tags

All resources are tagged with:
- `Environment = "prod"`
- `ManagedBy = "terraform"`
- `Project = "{project_name}"`

You can filter resources with these tags in the AWS Console using Resource Groups & Tag Editor.

To find all resources with these tags using the AWS CLI:

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=lambda-api Key=Environment,Values=prod \
  --region eu-west-3
```