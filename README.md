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
- **Orchestration**: Prefect Cloud work pool integration  

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

<img width="1919" height="1008" alt="Screenshot 2025-09-14 200731" src="https://github.com/user-attachments/assets/4783b432-dd6c-4f4a-aa7f-792625116a1b" />

----

**Problem:** Virtual Environment Activation

- Initially, I faced repeated errors when trying to install and run Prefect.
- I was directly installing packages into the system Python and attempting to run commands, which led to conflicts and unexpected behavior.

**Solution:** 
- At first, I didn’t realize that Prefect strongly recommends running inside a **virtual environment (venv/uv venv)**.
- When I reviewed the official Prefect documentation, I discovered that I had to create and activate a virtual environment before running any Prefect commands.

```bash
uv venv

# Create a virtual environment
python -m venv .venv

# Activate the environment (Windows PowerShell)
.venv\Scripts\Activate
```

<img width="1217" height="375" alt="image" src="https://github.com/user-attachments/assets/63169ce6-0216-4736-8ae9-39d1e57848f7" />

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
Enter your credentials when prompted:
AWS Access Key ID: <your-access-key-id>
AWS Secret Access Key: <your-secret-access-key>
Default region name: <your-region>
Default output format: json
````

### 2. Terraform Variables

Create a file named `terraform.tfvars` in the root directory of the repo and include your credentials:

```hcl
aws_region           = "<any-region>"
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
Clone repo

```bash
git clone https://github.com/yasheela-alla/AI-Planet-Assignment
cd AI-Planet-Assignment
````
Initialize Terraform

```bash
terraform init
```
Review plan

```bash
terraform plan
```
Deploy

```bash
terraform apply
```

### 2. Configuration

```bash
# Install Prefect with AWS support
pip install "prefect-aws"

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

<img width="1919" height="669" alt="Screenshot 2025-09-14 200531" src="https://github.com/user-attachments/assets/cb0244ec-37c2-4445-8f7e-e5335358c235" />


### End-to-End Test

```bash
# Deploy test flow to ECS push work pool
prefect deploy test_flow.py:test_ecs_flow --name test-ecs-deployment --pool ecs-work-pool

# Execute flow
python test_flow.py
```

<img width="1108" height="291" alt="Screenshot 2025-09-14 215056" src="https://github.com/user-attachments/assets/b22a2a52-2dde-461e-b939-d12abbbba41d" />


---

## Outputs

* **ECS Cluster ARN**: `arn:aws:ecs:us-east-1:<account-id>:cluster/prefect-cluster`
* **Instructions to verify the work pool in Prefect Cloud**

  
<img width="1092" height="311" alt="Screenshot 2025-09-14 215439" src="https://github.com/user-attachments/assets/cbe83c79-4c5a-4075-a4a3-42d0d3d05141" />

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








