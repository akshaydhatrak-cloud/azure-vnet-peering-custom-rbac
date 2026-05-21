param(
  [Parameter(Mandatory = $true)][string]$ResourceGroupName,
  [Parameter(Mandatory = $true)][string]$Location,
  [Parameter(Mandatory = $true)][string]$AdminUsername,
  [Parameter(Mandatory = $true)][string]$AdminSshPublicKey,
  [Parameter(Mandatory = $true)][string]$AdminSourceAddressPrefix,
  [Parameter(Mandatory = $true)][string]$EmployeeDisplayName,
  [Parameter(Mandatory = $true)][string]$EmployeeUserPrincipalName,
  [Parameter(Mandatory = $true)][string]$EmployeePassword,
  [string]$ProjectPrefix = "rand"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required but was not found in PATH."
}

$subscriptionId = az account show --query id -o tsv
$resourceGroupId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName"
$templatePath = Join-Path $PSScriptRoot "../infra/main.bicep"
$roleTemplatePath = Join-Path $PSScriptRoot "../rbac/computer-operator-role.template.json"

az group create `
  --name $ResourceGroupName `
  --location $Location

az deployment group create `
  --resource-group $ResourceGroupName `
  --template-file $templatePath `
  --parameters `
    location=$Location `
    projectPrefix=$ProjectPrefix `
    adminUsername=$AdminUsername `
    adminSshPublicKey="$AdminSshPublicKey" `
    adminSourceAddressPrefix=$AdminSourceAddressPrefix

$existingUserId = az ad user show `
  --id $EmployeeUserPrincipalName `
  --query id `
  -o tsv 2>$null

if (-not $existingUserId) {
  $existingUserId = az ad user create `
    --display-name $EmployeeDisplayName `
    --user-principal-name $EmployeeUserPrincipalName `
    --password $EmployeePassword `
    --force-change-password-next-sign-in true `
    --query id `
    -o tsv
}

$roleDefinitionPath = Join-Path $env:TEMP "computer-operator-role-$subscriptionId.json"
$roleDefinition = Get-Content $roleTemplatePath -Raw | ConvertFrom-Json
$roleDefinition.AssignableScopes = @("/subscriptions/$subscriptionId")
$roleDefinition | ConvertTo-Json -Depth 10 | Set-Content -Path $roleDefinitionPath -Encoding utf8

$roleExists = az role definition list `
  --name "Computer Operator" `
  --query "[0].name" `
  -o tsv

if ($roleExists) {
  az role definition update --role-definition $roleDefinitionPath
}
else {
  az role definition create --role-definition $roleDefinitionPath
}

az role assignment create `
  --assignee $existingUserId `
  --role "Computer Operator" `
  --scope $resourceGroupId

az deployment group show `
  --resource-group $ResourceGroupName `
  --name main `
  --query properties.outputs
