# AWS Credential Setup for Terraform

This document explains how to configure AWS credentials for running this Terraform project.

## Security Best Practice: Use IAM Users

It's crucial **not** to use your root AWS account credentials for programmatic access like running Terraform. Instead, create a dedicated IAM (Identity and Access Management) user with only the necessary permissions. This follows the principle of least privilege, enhancing the security of your AWS account.

The IAM user needs permissions to manage the resources defined in the Terraform configuration (e.g., Lambda, API Gateway, ECR, CloudWatch Logs, S3 for backend state, potentially IAM if Terraform creates roles/policies).

## Steps to Create an IAM User and Access Keys

1.  **Log in to the AWS Management Console:** Use your existing AWS account credentials.
2.  **Navigate to IAM:** Search for "IAM" in the service search bar and select it.
3.  **Go to Users:** In the IAM dashboard, click on "Users" in the left-hand navigation pane.
4.  **Create User:**
    *   Click the **"Create user"** button.
    *   Enter a **User name** (e.g., `github-actions-deployer`).
    *   **Do NOT** check the box for "Provide user access to the AWS Management Console" unless you specifically need this user to log in via the web interface (usually not needed for Terraform).
    *   Click **"Next"**.
5.  **Set Permissions:**
    *   Choose **"Attach policies directly"**.
    *   Search for and select appropriate permission policies. You'll need policies that grant access to manage the services used by this Terraform project. Some common managed policies include:
        *   `AmazonEC2ContainerRegistryFullAccess` (or a more restricted custom policy for ECR)
        *   `AWSLambda_FullAccess` (or a more restricted custom policy)
        *   `AmazonAPIGatewayAdministrator` (or a more restricted custom policy)
        *   `AmazonS3FullAccess` (if using S3 for backend state - **restrict this to the specific state bucket if possible**)
        *   `CloudWatchLogsFullAccess` (for Lambda logging)
        *   `IAMFullAccess` (only if Terraform needs to create/manage IAM roles/policies)
    *   **Important:** Granting `FullAccess` policies is convenient but less secure. For production environments, create custom policies granting only the specific actions required by Terraform on the specific resources.
    *   Click **"Next"**.
6.  **Review and Create:**
    *   Review the user details and attached policies.
    *   Click **"Create user"**.
7.  **Retrieve Access Keys:**
    *   On the user list page, click on the name of the user you just created.
    *   Go to the **"Security credentials"** tab.
    *   Scroll down to the **"Access keys"** section.
    *   Click **"Create access key"**.
    *   Choose the use case that best describes integrating with an external service like GitHub Actions. Common options might include **"Third-party service"**, **"Application running outside AWS"**, or similar. Select the most appropriate option presented.
    *   Acknowledge any recommendations regarding alternative connection methods if prompted (understand the security implications of using long-lived access keys).
    *   Click **"Next"**.
    *   (Optional) Set a description tag (e.g., `GitHub Actions Deploy Key`).
    *   Click **"Create access key"**.
    *   **Crucial:** This is your only chance to view and download the **Access key ID** and **Secret access key**. Copy them immediately and store them securely. You can also download the `.csv` file containing both keys. **Do not share these keys or commit them to version control.**
    *   Click **"Done"**.

## Configuring GitHub Actions Secrets

Once you have your Access Key ID and Secret Access Key, you need to add them as secrets to your GitHub repository so that your GitHub Actions workflows can authenticate with AWS.

**Do not commit your access keys directly into your code or configuration files.**

1.  **Navigate to your GitHub Repository:** Go to the main page of the repository where you want to run the Actions workflow.
2.  **Go to Settings:** Click on the "Settings" tab.
3.  **Access Secrets:** In the left sidebar, under the "Security" section, click on **"Secrets and variables"** -> **"Actions"**.
4.  **Add Access Key ID:**
    *   Click the **"New repository secret"** button.
    *   For **Name**, enter `AWS_ACCESS_KEY_ID`.
    *   For **Secret**, paste the **Access Key ID** you obtained from AWS IAM.
    *   Click **"Add secret"**.
5.  **Add Secret Access Key:**
    *   Click the **"New repository secret"** button again.
    *   For **Name**, enter `AWS_SECRET_ACCESS_KEY`.
    *   For **Secret**, paste the **Secret Access Key** you obtained from AWS IAM.
    *   Click **"Add secret"**.
