# Azure VNet Peering and Custom RBAC

## Overview

This project deploys two Azure virtual networks, places a Linux VM in each network, connects the networks with VNet peering, and assigns a limited custom RBAC role for basic VM operations. The setup is configured for a production-like environment while staying small enough to deploy and validate quickly.

## Architecture

The network path is:

```text
VM A -> VNet A -> VNet peering -> VNet B -> VM B
```

The access-control path is:

```text
Azure AD user -> Custom RBAC role -> read/start/restart VM permissions
```

Architecture files are in `architecture/`:

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

## Deployment Steps

1. Sign in with Azure CLI.
2. Deploy `infra/main.bicep` using `scripts/deploy.ps1`.
3. Confirm both VNets and both Linux VMs are created.
4. Validate private connectivity from VM A to VM B.
5. Create or update the `Computer Operator` custom role.
6. Assign the custom role to the selected Azure AD user.
7. Test that allowed actions work and blocked actions fail.

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

## Troubleshooting

- If VM-to-VM ping fails, check that both peering directions were created.
- If SSH fails, check `AdminSourceAddressPrefix` and the NSG rule.
- If the custom role assignment fails, confirm the account running the script can create role definitions and assignments.
- If the operator can deallocate a VM, review the custom role actions because deallocation should not be included.

## What I Learned

- VNet peering allows private connectivity without exposing traffic through public IPs.
- Azure RBAC can separate operational access from full infrastructure administration.
- Validation scripts are useful because network and permission issues are easier to catch right after deployment.
