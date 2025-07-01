
# Data Marketplace Infrastructure Deployment Guide

This guideline provides step-by-step instructions to **create**, **update**, and **destroy** the AWS infrastructure that hosts the services of the Data Marketplace platform.

## Environments

There are multiple environments:
- `gen` – Shared/general environment for common resources (must be deployed **first**)
- `dev` – Development environment
- `tst` – Test environment
- `stg` – Staging/Pre-production environment
- `pro` – Production environment

> `dev` and `tst` are deployed in the **development AWS account**.  
> `stg` and `pro` are deployed in the **production AWS account**.

## Infrastructure Overview

In this version, the deployment is managed via:
- A deployment server (an EC2 instance)
- Terraform
- GitHub Actions workflows

> A fully automated proper CI/CD pipeline will be introduced in future versions.

---

## Prerequisites

1. **General Environment Setup (gen)**:
   - Run the deployment for the `gen` environment **manually** on AWS (using CloudShell or EC2).
   - This deploys shared resources (S3 buckets, IAM roles, Secrets, Parameter Store entries) and a private subnet in the default VPC.

2. **Deployment Server Setup**:
   - Use **Amazon Linux 2023** EC2 instance, placed in the **private subnet** of the default VPC.
   - Attach the IAM role `dm-gen-ec2-profile-role` (soon to be renamed to `dm-gen-ec2-profile-deployment-role`).
   - Connect to the instance via **SSM Session Manager**.
   - Install the following tools:
     - AWS CLI: [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
     - Git: [Install Guide](https://linux.how2shout.com/how-to-install-git-on-aws-ec2-amazon-linux-2/)
     - Terraform v1.5.7: [Install Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
     - kubectl: [Install Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

3. **Additional Requirements**:
   - GitHub Actions IAM role defined in AWS.
   - A domain or subdomain name for each environment (e.g. `dev.datamarketplace.gov.uk`).
   - TLS Certificate for the domain.
   - SSO configuration on `security.gov.uk`.

---

## Environment Creation

Environment creation is handled via GitHub Actions pipeline:

### Workflow: `environment-configuration-update`

Input Parameters:
- **Branch Name** – Select the relevant Git branch
- **Environment Name** – Choose from: `dev`, `tst`, `stg`, `pro`
- **MSSQL Snapshot Name**
- **PostgreSQL Snapshot Name**
- **Action Type**:
  - `init+plan`: Runs `terraform plan` and shows proposed changes.
  - `init+plan+apply`: Runs plan, requests manual approval, then applies if approved.
  - `approval+destroy`: Runs `terraform destroy` after manual approval.

#### ‘init+plan+apply’ Workflow
1. Terraform plan runs and shows changes.
2. An issue is created for manual approval.
3. Enter **Approve** or **Deny** in the issue.
4. If **Approved**, the environment is created.
5. If **Denied**, the pipeline cancels.

---

## Application Parameters Setup (Manual)

> This will be automated in the future.

Steps:
1. Ensure all required config entries exist in AWS Parameter Store at `/dm/gen/config-inputs`.
2. On the Deployment Server:
   ```bash
   git clone [this repository]
   cd data-marketplace-infrastructure/app-fast/
   ./config/config.sh [env]  # e.g., ./config/config.sh dev
   ```
   This script sets up app-specific parameters in Parameter Store.

---

## Application Deployment (Manual)

> This will also be automated later.

Steps:
1. Complete **Application Parameters Setup**.
2. On the Deployment Server:
   ```bash
   cd data-marketplace-infrastructure/app-fast/
   # Create and edit .env file with deployment settings
   sh dm-deploy.sh install     # for installation
   sh dm-deploy.sh update      # for updating
   sh dm-deploy.sh uninstall   # for removal
   ```

## Application Deployment (Pipeline)

- Please create a `.env` file with deployment settings in advance via using the template provided `.env_template`  
- Please upload the newly created `.env` file to S3 Bucket  
  (the name of the bucket can be obtained from Pipeline file `data-marketplace-infrastructure/.github/workflows/application-configuration-update.yml`)  
- Then you can run GitHub Workflows pipeline of `application-configuration-update.yml` via UI or GitHub API  





---

## Post-Deployment Steps (Manual)

> These will eventually be automated.

1. **Create or update DNS** entry for the environment.
2. **Create or update WAF** associated with the ALB created by the application deployment.
3. **Always update DNS** CNAME when the ALB changes.

---

## Complete Teardown (Destroy Environment)

To completely delete an environment (e.g., `dev`):

1. **DNS Cleanup**:
   - Delete the CNAME record for the environment.
   - Wait for DNS propagation (~15–30 mins).

2. **WAF Removal**:
   - Remove the WAF linked to the ALB.

3. **Application Uninstall**:
   ```bash
   sh dm-deploy.sh uninstall
   ```

4. **Environment Destruction via Pipeline**:
   - Run `approval+destroy` option in the GitHub Actions workflow.
   - Approve the destruction in the created issue.

---

## Updating Services

1. On the Deployment Server:
   ```bash
   cd app-fast/
   cp dev.env .env   # adjust as needed
   sh dm-deploy.sh update
   ```
2. If the ALB is changed then update WAF and the CNAME accordingly.

> ⚠️ These may cause a **temporary service outage**. Application pods in the Kubernetes cluster might be restarted.
