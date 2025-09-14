# DevOps Assignment: Infrastructure as Code Setup for Prefect Worker on Amazon ECS

## Overview
This project demonstrates the deployment of a Prefect worker on Amazon ECS Fargate using Terraform Infrastructure as Code. The solution includes complete AWS infrastructure provisioning, IAM configuration, and a functional Prefect orchestration system.

## Architecture
- **VPC**: Custom VPC (10.0.0.0/16) with 3 public and 3 private subnets across multiple AZs
- **ECS Cluster**: Fargate-based cluster for serverless container execution
- **IAM Roles**: Task execution role with Secrets Manager permissions
- **Networking**: NAT Gateway for private subnet outbound access
- **Orchestration**: Local Prefect server with ECS work pool integration

## Tool Choice: Terraform
**Why Terraform over CloudFormation:**
- Cross-cloud compatibility for future multi-cloud scenarios
- Superior state management and drift detection
- More readable HCL syntax compared to JSON/YAML
- Extensive provider ecosystem and community support
- Better local development and testing workflow

## Technical Challenge Overcome
**Issue**: Prefect Cloud's free tier does not support ECS work pools (requires paid Hybrid plan)

**Solution**: Implemented local Prefect server with full ECS integration, providing:
- Complete control over work pool configuration
- No vendor limitations
- Enhanced debugging capabilities
- Cost-effective development environment

## Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.2.0
- AWS CLI configured
- Python 3.8+

## Deployment Instructions

### 1. Infrastructure Setup
```bash
# Clone repository
git clone [your-repo-url]
cd devops-assignment

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

# Start local Prefect server
prefect server start

# Configure client
prefect config set PREFECT_API_URL="http://127.0.0.1:4200/api"

# Create ECS work pool
prefect work-pool create ecs-work-pool --type ecs
```

### 3. Worker Deployment
```bash
# Start ECS worker
prefect worker start --pool ecs-work-pool
```

## Verification Steps

### AWS Console Verification
1. **ECS Cluster**: Navigate to ECS → Clusters → "prefect-cluster" (Active status)
2. **VPC Resources**: EC2 → VPCs → verify VPC and subnet configuration
3. **IAM Roles**: IAM → Roles → verify "prefect-task-execution-role"

### Prefect Verification
1. Access Prefect UI at http://127.0.0.1:4200
2. Navigate to Work Pools → ecs-work-pool
3. Verify worker status shows "Online"

### End-to-End Test
```bash
# Deploy test flow
prefect deploy test_flow.py:test_ecs_flow --name test-ecs-deployment --pool ecs-work-pool

# Execute flow
python test_flow.py
```

## Outputs
- **ECS Cluster ARN**: `arn:aws:ecs:us-east-1:390700679982:cluster/prefect-cluster`
- **VPC ID**: `vpc-04b6b5e3f03eb8b96`
- **Private Subnets**: 3 subnets across different AZs
- **Task Execution Role**: Configured with Secrets Manager access

## Key Learnings
1. **IaC Best Practices**: Proper resource tagging, modular design, and state management
2. **ECS Fargate**: Serverless container orchestration benefits and networking requirements
3. **Problem-Solving**: Adapting to service limitations while maintaining functionality
4. **Integration Patterns**: Connecting cloud infrastructure with orchestration platforms

## Security Considerations
- Private subnets for worker tasks with NAT Gateway for outbound access
- IAM roles following least privilege principle
- Secrets management through AWS Secrets Manager
- No hardcoded credentials in configuration

## Cost Optimization
- Fargate launch type for pay-per-use billing
- Minimal resource allocation (256 CPU, 512 Memory)
- Single NAT Gateway to reduce costs

## Future Improvements
- Auto-scaling configuration for high-volume workloads
- CloudWatch monitoring and alerting
- Multi-region deployment for high availability
- CI/CD pipeline integration

## Cleanup
```bash
terraform destroy
```
