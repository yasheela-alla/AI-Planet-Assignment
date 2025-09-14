terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# VPC with CIDR 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "prefect-ecs"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "prefect-ecs"
  }
}

# Public Subnets (3 across different AZs)
resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "prefect-ecs-public-${count.index + 1}"
  }
}

# Private Subnets (3 across different AZs)
resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "prefect-ecs-private-${count.index + 1}"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "prefect-ecs"
  }

  depends_on = [aws_internet_gateway.main]
}

# Single NAT Gateway for private subnet outbound traffic
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "prefect-ecs"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "prefect-ecs-public"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "prefect-ecs-private"
  }
}

# Public Route Table
resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ECS Cluster named prefect-cluster
resource "aws_ecs_cluster" "prefect_cluster" {
  name = "prefect-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "prefect-ecs"
  }
}

# Service Discovery 
resource "aws_service_discovery_private_dns_namespace" "prefect" {
  name        = "default.prefect.local"
  description = "Private DNS namespace for Prefect services"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "prefect-ecs"
  }
}

# IAM Role 
resource "aws_iam_role" "ecs_execution_role" {
  name = "prefect-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "prefect_worker" {
  name              = "/ecs/prefect-worker"
  retention_in_days = 7

  tags = {
    Name = "prefect-ecs"
  }
}

# Security Group
resource "aws_security_group" "prefect_worker" {
  name_prefix = "prefect-worker-"
  vpc_id      = aws_vpc.main.id

  # Outbound HTTPS traffic
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  # Outbound HTTP traffic
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  # Outbound traffic for Prefect Server API
  egress {
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prefect Server API"
  }

  tags = {
    Name = "prefect-ecs"
  }
}

# ECS Task Definition 
resource "aws_ecs_task_definition" "prefect_worker" {
  family                   = "prefect-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "prefect-worker"
      image = "prefecthq/prefect:2-latest"
      
      environment = [
        {
          name  = "PREFECT_API_URL"
          value = var.prefect_server_url
        }
      ]
      
      command = [
        "/bin/bash", "-c", 
        "prefect worker start --pool ${var.work_pool_name}"
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prefect_worker.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      essential = true
    }
  ])

  tags = {
    Name = "prefect-ecs"
  }
}

# ECS Service 
resource "aws_ecs_service" "prefect_worker" {
  name            = "dev-worker"
  cluster         = aws_ecs_cluster.prefect_cluster.id
  task_definition = aws_ecs_task_definition.prefect_worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.prefect_worker.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_nat_gateway.main,
    aws_iam_role_policy_attachment.ecs_execution_role_policy
  ]

  tags = {
    Name = "prefect-ecs"
  }
}
