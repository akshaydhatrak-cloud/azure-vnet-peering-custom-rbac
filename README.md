# Internship Experience: Azure VNet Peering and Custom RBAC

## Overview

During my internship work, I deployed two Azure virtual networks, placed a Linux VM in each network, connected the networks with VNet peering, and assigned a limited custom RBAC role for basic VM operations. The setup was configured like a production-style environment while staying small enough to validate quickly.

## Architecture

The network path I implemented was:

```text
VM A -> VNet A -> VNet peering -> VNet B -> VM B
```

The access-control path was:

```text
Azure AD user -> Custom RBAC role -> read/start/restart VM permissions
```

Architecture notes are in `architecture/`:

- `architecture.mmd`
- `architecture.svg`

## Services Used

- Azure Virtual Network
- Azure Virtual Machines
- VNet Peering
- Network Security Groups
- Azure AD
- Azure RBAC
- Azure Storage Account for read-access validation
- Azure Bicep

## Implementation Steps

1. Signed in with Azure CLI.
2. Deployed `infra/main.bicep` using `scripts/deploy.ps1`.
3. Confirmed both VNets and both Linux VMs were created.
4. Validated private connectivity from VM A to VM B.
5. Created or updated the `Computer Operator` custom role.
6. Assigned the custom role to the selected Azure AD user.
7. Tested that allowed actions worked and blocked actions failed.

Deploy the environment:

```powershell
cd scripts
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

Validate connectivity:

```powershell
.\validate-connectivity.ps1 `
  -ResourceGroupName rg-vnet-rbac `
  -VmAName netops-vm-a `
  -VmBName netops-vm-b
```

## Troubleshooting Notes

- If VM-to-VM ping fails, check that both peering directions were created.
- If SSH fails, check `AdminSourceAddressPrefix` and the NSG rule.
- If the custom role assignment fails, confirm the account running the script can create role definitions and assignments.
- If the operator can deallocate a VM, review the custom role actions because deallocation should not be included.

## Key Takeaways

- VNet peering allows private connectivity without exposing traffic through public IPs.
- Azure RBAC can separate operational access from full infrastructure administration.
- Validation scripts are useful because network and permission issues are easier to catch right after deployment.
