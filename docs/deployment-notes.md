# Deployment Notes

The deployment uses Bicep for the Azure resources and a PowerShell script for orchestration.

Main checks after deployment:

- both VNets exist with non-overlapping address ranges
- both VM private IPs are available
- peering exists in both directions
- the custom RBAC role is assigned only at the required resource group scope
- the operator can start and restart VMs but cannot deallocate or delete them
