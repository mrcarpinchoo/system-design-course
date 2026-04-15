#!/bin/bash
# setup-docker.sh — Lab 08 initial infrastructure deployment (Docker version)
#
# This script automates the first phase of the lab using Docker containers:
#   1. Validates that Docker is installed and .env file exists
#   2. Starts the aws-cli and terraform containers
#   3. Verifies that AWS credentials are active (sts get-caller-identity)
#   4. Deploys the CloudFormation stack (VPC, subnets, IGW, route tables)
#   5. Initializes Terraform (downloads the AWS provider)
#
# After running this script, students must manually:
#   - Create a key pair (Task 3)
#   - Create a security group (Task 4)
#   - Run terraform plan and terraform apply (Task 5)
#
# Usage: ./setup-docker.sh

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
cd "$SCRIPT_DIR"

STACK_NAME="vpc-lab-network"
AWS_CONTAINER="docker compose exec aws-cli"
TF_CONTAINER="docker compose exec terraform"

echo "========================================="
echo "Lab 08 — Cloud Networking VPC Setup"
echo "========================================="
echo ""

# --- Prerequisite checks ---
echo "Checking prerequisites..."

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker not found. Install it first."
  exit 1
fi
echo "  Docker: $(docker --version)"

if [ ! -f .env ]; then
  echo "ERROR: .env file not found. Create it with your AWS credentials:"
  echo "  AWS_ACCESS_KEY_ID=..."
  echo "  AWS_SECRET_ACCESS_KEY=..."
  echo "  AWS_SESSION_TOKEN=..."
  echo "  AWS_DEFAULT_REGION=us-east-1"
  exit 1
fi
echo "  .env file found"

# --- Start containers ---
echo ""
echo "Starting containers..."
docker compose up -d
echo ""

# --- Verify credentials ---
echo "Verifying AWS credentials..."
if ! $AWS_CONTAINER aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not configured. Update your .env file."
  exit 1
fi
$AWS_CONTAINER aws sts get-caller-identity --output table
echo ""

# --- Deploy CloudFormation stack ---
echo "Deploying CloudFormation stack: $STACK_NAME ..."
echo "This creates: VPC, 2 public subnets, Internet Gateway, route tables."
echo ""

$AWS_CONTAINER aws cloudformation deploy \
  --template-file cloudformation/vpc-network.yaml \
  --stack-name "$STACK_NAME" \
  --no-fail-on-empty-changeset

echo ""
echo "Waiting for stack to complete..."
$AWS_CONTAINER aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" 2>/dev/null || true

# --- Show outputs ---
echo ""
echo "CloudFormation stack outputs:"
$AWS_CONTAINER aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

# --- Initialize Terraform ---
echo ""
echo "Initializing Terraform..."
$TF_CONTAINER terraform init -input=false

echo ""
echo "========================================="
echo "Network infrastructure deployed!"
echo "========================================="
echo ""
echo "Next steps (see README for full instructions):"
echo ""
echo "  1. Create a key pair:"
echo "     docker compose exec aws-cli aws ec2 create-key-pair --key-name vpc-lab-key \\"
echo "       --query 'KeyMaterial' --output text > vpc-lab-key.pem"
echo "     chmod 400 vpc-lab-key.pem"
echo ""
echo "  2. Create a security group (see README Task 4)"
echo ""
echo "  3. Deploy EC2 instances:"
echo "     cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
echo "     docker compose exec terraform terraform plan"
echo "     docker compose exec terraform terraform apply"
echo ""
