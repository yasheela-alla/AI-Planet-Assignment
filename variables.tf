variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "prefect_api_url" {
  description = "Prefect Cloud API URL"
  type        = string
  default     = "https://api.prefect.cloud/api/accounts"
}

variable "prefect_account_id" {
  description = "Prefect Cloud Account ID"
  type        = string
}

variable "prefect_workspace_id" {
  description = "Prefect Cloud Workspace ID"
  type        = string
}

variable "work_pool_name" {
  description = "Name of the Prefect work pool"
  type        = string
  default     = "ecs-work-pool"
}
