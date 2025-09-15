# cleanup.ps1
# Simple cleanup script to destroy all Terraform resources

Write-Host "Starting cleanup..." -ForegroundColor Yellow

# Destroy all Terraform resources
Write-Host "Destroying infrastructure..." -ForegroundColor Red
terraform destroy -auto-approve

# Check if destroy was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Infrastructure destroyed successfully!" -ForegroundColor Green
} else {
    Write-Host "Error destroying infrastructure!" -ForegroundColor Red
    exit 1
}

# Clean up Terraform files
Write-Host "Cleaning up Terraform files..." -ForegroundColor Yellow
Remove-Item -Path "terraform.tfstate*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".terraform" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".terraform.lock.hcl" -Force -ErrorAction SilentlyContinue

# Verify everything is gone
Write-Host "Checking if resources are deleted..." -ForegroundColor Yellow
terraform state list

if ($LASTEXITCODE -eq 0) {
    $resources = terraform state list
    if ($resources) {
        Write-Host "Warning: Some resources still exist!" -ForegroundColor Red
        $resources
    } else {
        Write-Host "All resources deleted successfully!" -ForegroundColor Green
    }
} else {
    Write-Host "No state file found - cleanup complete!" -ForegroundColor Green
}

Write-Host "Cleanup finished!" -ForegroundColor Cyan



