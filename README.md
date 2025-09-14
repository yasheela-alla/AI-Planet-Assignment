# Infrastructure as Code Setup for Prefect Worker on Amazon ECS

## Overview
This project demonstrates deploying a Prefect worker on **AWS ECS Fargate** using **Terraform**. The solution provisions all required AWS infrastructure, configures IAM roles and secrets, and connects a worker to Prefect Cloud.  

**Note:** The free Prefect Cloud plan does not support ECS pull work pools. **I overcame this by running a local Prefect server and connecting ECS workers via a push work pool**, enabling full orchestration without requiring a paid plan. 

---

## Architecture
- **VPC**: Custom VPC (10.0.0.0/16) with **3 public** and **3 private subnets** across multiple AZs  
- **ECS Cluster**: Fargate cluster for serverless container execution  
- **IAM Roles**: Task execution role with ECS and Secrets Manager permissions  
- **Networking**: NAT Gateway for outbound access from private subnets  
- **Orchestration**: Prefect Cloud push work pool integration  

---

## Tool Choice: Terraform
**Why Terraform over CloudFormation:**
- Cross-cloud compatible for future multi-cloud scenarios  
- Superior state management and drift detection  
- Cleaner, more readable HCL syntax  
- Large provider ecosystem and community support  
- Better local testing and workflow  

---

## Technical Challenge
**Problem:** Prefect Cloud's free tier does not support ECS work pools (requires paid Hybrid plan)  

**Solution:** Implemented local Prefect server with full ECS integration, providing:  
- Complete control over work pool configuration
- No vendor limitations
- Enhanced debugging capabilities
- Cost-effective development environment

---

## Prerequisites
- AWS Account with proper permissions  
- Terraform >= 1.2.0  
- AWS CLI configured  
- Python 3.8+  
- Prefect Cloud account  
- Store Prefect API key in AWS Secrets Manager as `prefect_api_key`  

---

## Configuration Steps

### 1. AWS CLI Setup
```bash
aws configure
# Enter your credentials when prompted:
# AWS Access Key ID: <your-access-key-id>
# AWS Secret Access Key: <your-secret-access-key>
# Default region name: us-east-1
# Default output format: json
````

### 2. Terraform Variables

Create a file named `terraform.tfvars` in the root directory of the repo and include your credentials:

```hcl
aws_region           = "us-east-1"
prefect_account_id   = "<your-account-id>"
prefect_workspace_id = "<your-workspace-id>"
```

### 3. Prefect Cloud Setup

1. Create a Prefect Cloud account
2. Create a **work pool** named `ecs-work-pool` (type: push)
3. Store your Prefect API key in **AWS Secrets Manager** as `prefect_api_key`

---

## Deployment Instructions

### 1. Infrastructure Setup

```bash
# Clone repo
git clone https://github.com/shaluchan/AI-PLANET-Assignment.git
cd AI-PLANET-Assignment

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Prefect Configuration

```bash
# Install Prefect with AWS support
pip install "prefect[aws]"

# Configure Prefect API URL
prefect config set PREFECT_API_URL="https://api.prefect.io"

# Create ECS push work pool if not already created
prefect work-pool create ecs-work-pool --type ecs
```

### 3. Worker Deployment

```bash
# Start ECS worker and connect it to the push work pool
prefect worker start --pool ecs-work-pool
```

---

## Verification Steps

### AWS Console Verification

1. **ECS Cluster**: ECS → Clusters → `prefect-cluster` (Active)
2. **VPC & Subnets**: EC2 → VPCs → verify public/private subnets
3. **IAM Roles**: IAM → Roles → `prefect-task-execution-role`
4. **Secrets**: Secrets Manager → `prefect_api_key` fetched by ECS

### Prefect Verification

1. Open Prefect UI → Work Pools → `ecs-work-pool`
2. Verify worker status: `Online`

### End-to-End Test

```bash
# Deploy test flow to ECS push work pool
prefect deploy test_flow.py:test_ecs_flow --name test-ecs-deployment --pool ecs-work-pool

# Execute flow
python test_flow.py
```

---

## Outputs

* **ECS Cluster ARN**: `arn:aws:ecs:us-east-1:<account-id>:cluster/prefect-cluster`
* **VPC ID**: `vpc-04b6b5e3f03eb8b96`
* **Private Subnets**: 3 subnets across AZs
* **Task Execution Role**: Configured with Secrets Manager access

---

## Key Learnings

1. **IaC Best Practices**: Resource tagging, modular design, state management
2. **ECS Fargate**: Serverless orchestration, networking, and security
3. **Problem Solving**: Handling free-tier limitations while maintaining workflow
4. **Integration Patterns**: Cloud infrastructure with orchestration platforms

---


## Cleanup

```bash
terraform destroy
```

