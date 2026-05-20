# Inferred Components

The project description specified Azure VNets, test workloads, VNet peering, an onboarded Azure AD user, and a least-privilege custom RBAC role. It did not provide source code, exact IP ranges, VM operating system, or naming conventions. The following items were inferred from standard Azure implementation:

- Two VNets with non-overlapping CIDR ranges: `10.10.0.0/16` and `10.20.0.0/16`.
- One subnet and one Ubuntu test VM in each VNet.
- Nginx installed on each VM as a lightweight internet workload.
- Bidirectional VNet peering with virtual network access enabled.
- A storage account included so the custom role can demonstrate storage read access.
- Azure CLI and Bicep as the deployment tooling.
- Resource-group-level role assignment to keep the employee scoped to the lab resources.

No production application, database, VPN gateway, firewall appliance, or external identity provider was added because those are outside the prompt.
