param(
  [Parameter(Mandatory = $true)][string]$ResourceGroupName,
  [string]$VmAName = "rand-vm-a",
  [string]$VmBName = "rand-vm-b"
)

$vmBPrivateIp = az vm list-ip-addresses `
  --resource-group $ResourceGroupName `
  --name $VmBName `
  --query "[0].virtualMachine.network.privateIpAddresses[0]" `
  -o tsv

az vm run-command invoke `
  --resource-group $ResourceGroupName `
  --name $VmAName `
  --command-id RunShellScript `
  --scripts "ping -c 4 $vmBPrivateIp && curl -s http://$vmBPrivateIp"
