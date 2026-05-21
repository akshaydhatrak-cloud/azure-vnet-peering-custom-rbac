# Azure VNet Peering & RBAC Access Control

## Business Objective

This project builds a production-like Azure network layout with two isolated virtual networks and controlled access for a limited operator role. The goal is to validate private connectivity between network segments while keeping administrative permissions restricted.

## Cloud Architecture Overview

The Bicep deployment creates two VNets, one workload subnet in each VNet, and one Linux VM in each subnet. Bidirectional VNet peering allows private communication between the two network segments. A shared network security group controls inbound SSH, HTTP, and internal ICMP traffic.

Azure AD and Azure RBAC are used to create and assign a custom `Computer Operator` role. The role can read resources and start or restart VMs, but it cannot create, delete, or modify core infrastructure.

The draw.io source is available at `docs/architecture.drawio`.

## Services Used

- Azure Virtual Network
- Azure Virtual Machines
- VNet Peering
- Network Security Groups
- Azure AD
- Azure RBAC
- Azure Storage Account for read-access validation
- Azure Bicep

## Deployment Workflow

1. Create or select an Azure resource group.
2. Deploy `infrastructure/bicep/main.bicep` using the provided PowerShell script.
3. Provision two VNets with non-overlapping address spaces.
4. Deploy one Linux web VM into each workload subnet.
5. Configure bidirectional VNet peering between the VNets.
6. Create or update the custom RBAC role from `infrastructure/rbac/`.
7. Assign the role to the selected Azure AD user at the resource group scope.
8. Validate VM-to-VM connectivity and confirm the RBAC permission boundary.

Example deployment command:

```powershell
cd infrastructure/scripts
.\deploy.ps1 `
  -ResourceGroupName rg-vnet-rbac `
  -Location uksouth `
  -AdminUsername azureuser `
  -AdminSshPublicKey "ssh-rsa AAAA..." `
  -AdminSourceAddressPrefix "203.0.113.10/32" `
  -EmployeeDisplayName "Computer Operator" `
  -EmployeeUserPrincipalName "operator@tenant.onmicrosoft.com" `
  -EmployeePassword "Temporary-Password" `
  -ProjectPrefix netops
```

## Security Considerations

- VNets use separate address spaces and connect only through explicit peering.
- SSH access is restricted by the `AdminSourceAddressPrefix` parameter.
- The custom RBAC role follows a least-privilege model for basic VM operations.
- The role does not include VM deletion, network modification, role assignment, or storage data access.
- Storage is configured with HTTPS-only access and public blob access disabled.

## Performance and Scalability Improvements

VNet peering keeps traffic on the Azure backbone and avoids public routing between workload segments. The Bicep modules allow the same structure to be reused with different prefixes, locations, or VM sizes.

## Operational Insights

- `validate-connectivity.ps1` checks private connectivity between the two VMs.
- `test-custom-role.ps1` validates allowed and blocked RBAC actions.
- Network rules should be reviewed before moving from testing to a stricter production subnet model.
- Resource naming is prefix-based so multiple environments can be deployed without mixing assets.
