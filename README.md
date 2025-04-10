# Terraform Lambda API Container

A Terraform project that deploys a containerized Node.js Lambda function with API Gateway integration.

## Architecture

This project creates the following AWS resources:

- **Lambda Function**: Runs a containerized Node.js application using Hono framework
- **API Gateway**: HTTP API Gateway that exposes the Lambda function
- **ECR Repository**: Stores the Docker container image for the Lambda function
- **IAM Role & Policies**: Necessary permissions for Lambda to write logs

## Requirements

- Terraform >= 1.0 ([Install Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- AWS CLI configured with appropriate credentials for local execution (e.g., via `aws configure`). [See AWS CLI configuration guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).
- For deployment via GitHub Actions, see the separate guide: [GITHUB_ACTIONS_AWS_CREDENTIALS.md](./GITHUB_ACTIONS_AWS_CREDENTIALS.md).
- Docker installed (for building the container image)
- **An existing S3 bucket** for storing Terraform state (specified in `backend_config/*.config` files). This bucket must exist *before* you run `terraform init`.

## Quick Start

1. **Clone this repository**:

   ```bash
   git clone <repository-url>
   cd terraform-lambda-api-container
   ```

2. **Update configuration**:
   Edit `backend_config/*.config` files to update the backend S3 bucket configuration (see [Terraform partial configuration docs](https://developer.hashicorp.com/terraform/language/backend#partial-configuration)):

   ```config
    bucket = "BUCKET_NAME" 
    key    = "PROJECT_NAME/terraform.tfstate"
    region = "AWS_REGION"
   ```

   Also update the variables in `terraform/variables.tf`:

   ```terraform
   variable "company_name" {
     description = "The name of the company"
     type        = string
     default     = "COMPANY_NAME"  # Replace with your company name
   }
   
   variable "project_name" {
     description = "Name of the project, used for resource naming"
     type        = string
     default     = "PROJECT_NAME"  # Replace with your project name
   }
   ```

   This ensures that both your S3 state storage and your resource names use consistent naming conventions.

   Terraform automatically handles creating separate state files for each workspace in S3:
   - Default workspace: `PROJECT_NAME/terraform.tfstate`
   - `dev` workspace: `env:/dev/PROJECT_NAME/terraform.tfstate`
   - `prod` workspace: `env:/prod/PROJECT_NAME/terraform.tfstate`

3. **Initialize Terraform**:
   **Note:** Ensure the S3 bucket specified in `terraform/main.tf` exists before running this command:

   ```bash
   cd terraform
   terraform init -backend-config="./config/backend.config"
   ```

4. **Select or create workspace for environment**:
   See the [Working with Environments](#working-with-environments) section below for details on using Terraform workspaces.

5. **Deploy the infrastructure**:

   ```bash
   terraform apply
   ```

6. **Test the API**:

   ```bash
   curl $(terraform output -raw api_endpoint)
   ```

## Working with Environments

This project uses Terraform workspaces to manage different environments (dev, staging, prod, etc.). Each workspace maintains its own separate state file, allowing you to have different configurations for each environment.

### Managing Workspaces

Terraform workspaces allow you to manage multiple distinct states for the same configuration (e.g., `dev`, `stag`, `prod`).

- **List workspaces:** `terraform workspace list`
- **Create a new workspace:** `terraform workspace new <workspace_name>`
- **Select a workspace:** `terraform workspace select <workspace_name>`
- **Delete a workspace:** `terraform workspace delete <workspace_name>`

**Only delete a workspace if you are absolutely sure you no longer need the state file and have already destroyed the associated infrastructure (`terraform destroy`) or plan to manage it differently.**

Example workflow:

```bash
# Initialize Terraform
terraform init -backend-config="./config/backend.config"
# Create and select a workspace for development
terraform workspace new dev
# Or select an existing workspace
terraform workspace select dev
# Apply changes to that environment
terraform apply
```

For more information on workspaces, see the [Terraform documentation](https://developer.hashicorp.com/terraform/language/state/workspaces).

## Project Structure

```txt
.
├── app/                   # Lambda function source code
│   ├── Dockerfile         # Docker configuration for Lambda
│   ├── package.json       # Node.js dependencies
│   └── src/               # Source code files
│       └── index.js       # Lambda handler function
├── terraform/             # Terraform configuration files
│   └── config/            # Config files
│       └── backend.config # Terraform backend configuration
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
