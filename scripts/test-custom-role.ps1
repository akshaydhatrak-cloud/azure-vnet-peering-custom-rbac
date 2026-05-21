param(
  [Parameter(Mandatory = $true)][string]$ResourceGroupName,
  [Parameter(Mandatory = $true)][string]$EmployeeUserPrincipalName,
  [Parameter(Mandatory = $true)][string]$TenantId,
  [string]$VmName = "rand-vm-a"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required but was not found in PATH."
}

Write-Host "Sign in as the onboarded employee when the browser prompt appears."
az login --tenant $TenantId --username $EmployeeUserPrincipalName

Write-Host "Expected to succeed: list resources in the scoped resource group."
az resource list --resource-group $ResourceGroupName --output table

Write-Host "Expected to succeed: start and restart the virtual machine."
az vm start --resource-group $ResourceGroupName --name $VmName
az vm restart --resource-group $ResourceGroupName --name $VmName

Write-Host "Expected to fail: stop/deallocate is intentionally outside the custom role."
az vm deallocate --resource-group $ResourceGroupName --name $VmName
