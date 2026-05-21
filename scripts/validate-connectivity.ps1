param(
  [Parameter(Mandatory = $true)][string]$ResourceGroupName,
  [string]$VmAName = "rand-vm-a",
  [string]$VmBName = "rand-vm-b"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required but was not found in PATH."
}

$vmBPrivateIp = az vm list-ip-addresses `
  --resource-group $ResourceGroupName `
  --name $VmBName `
  --query "[0].virtualMachine.network.privateIpAddresses[0]" `
  -o tsv

if (-not $vmBPrivateIp) {
  throw "Could not resolve the private IP address for $VmBName."
}

az vm run-command invoke `
  --resource-group $ResourceGroupName `
  --name $VmAName `
  --command-id RunShellScript `
  --scripts "ping -c 4 $vmBPrivateIp && curl -s http://$vmBPrivateIp"
