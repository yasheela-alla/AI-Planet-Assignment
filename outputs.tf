output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.prefect_cluster.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.prefect_cluster.name
}

output "Verifications" {
  description = "Instructions to verify the work pool in Prefect Cloud"
  value = <<-EOT
    To verify your work pool is active:
    1. Log in to Prefect Cloud at https://app.prefect.cloud
    2. Navigate to Work Pools
    3. Look for the work pool named: ${var.work_pool_name}
    4. Check that it shows as "Ready" status
    5. You should see the "dev-worker" worker connected
  EOT
}
