# Lab 08 — Docker Environment

This guide explains how to run the lab using Docker instead of installing the
AWS CLI and Terraform locally. The `docker-compose.yml` provides two
containers — `aws-cli` and `terraform` — that are used by the setup and
cleanup scripts.

## Prerequisites

- Docker and Docker Compose installed
- AWS Academy Learner Lab credentials (or personal AWS account)

## Setup

### 1. Configure credentials

Copy `.env.example` to `.env` and fill in your AWS credentials:

```bash
cp .env.example .env
```

```ini
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_SESSION_TOKEN=your_session_token
AWS_DEFAULT_REGION=us-east-1
```

> `.env` is read by both containers via the `env_file` directive in
> `docker-compose.yml`. Never commit this file to version control.

### 2. Run the setup script

```bash
./setup-docker.sh
```

This will:
1. Verify Docker is available and `.env` exists
2. Start the `aws-cli` and `terraform` containers (`docker compose up -d`)
3. Validate your AWS credentials
4. Deploy the CloudFormation stack (VPC, subnets, Internet Gateway, route tables)
5. Initialize Terraform

### 3. Continue with the lab tasks

After setup completes, run AWS CLI and Terraform commands through the
containers:

```bash
# AWS CLI commands
docker compose exec aws-cli aws ec2 describe-vpcs

# Terraform commands
docker compose exec terraform terraform plan
docker compose exec terraform terraform apply
```

## Cleanup

When you are done with the lab, run:

```bash
./cleanup-docker.sh
```

This will:
1. Destroy Terraform-managed EC2 instances
2. Delete the security group
3. Delete the key pair and local `.pem` file
4. Delete the CloudFormation stack
5. Stop and remove the Docker containers (`docker compose down`)

## Container Details

| Service | Image | Mounts |
| --- | --- | --- |
| `aws-cli` | `amazon/aws-cli:latest` | `./cloudformation` → `/workspace/cloudformation` |
| `terraform` | `hashicorp/terraform:latest` | `./terraform` → `/workspace` |

Both containers use `sh -i` as the entrypoint so they stay running in the
background, allowing `docker compose exec` to work without spinning up a new
container for each command.
