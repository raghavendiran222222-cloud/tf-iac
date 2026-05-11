# tf-iac — BDT MVP Workloads (Direct AVM)

Root Terraform composition module for the BDT 2-tier MVP infrastructure. Calls Azure Verified Modules (AVM) **directly** from the Terraform Registry — no intermediate wrapper modules. MySQL uses a scratch module (`mysql-scratch` branch, tagged `v1.0.0`) with raw `azurerm` resources.

## Summary

```hcl
# Deploy dev environment
cd envs/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Architecture

**Tier 1 — Networking**
- VNet (`Azure/avm-res-network-virtualnetwork/azurerm` v0.17.1)
- NSG on App Subnet (`Azure/avm-res-network-networksecuritygroup/azurerm` v0.5.1)

**Tier 2 — Application + Data**
- App Service Plan + App Service (`Azure/avm-res-web-serverfarm/azurerm` v2.0.4 + `Azure/avm-res-web-site/azurerm` v0.22.0)
- MySQL Flexible Server — scratch module at `git::https://github.com/bdtmsd/tf-iac.git?ref=v1.0.0` (raw `azurerm_mysql_flexible_server`)
- Storage Account (`Azure/avm-res-storage-storageaccount/azurerm` v0.6.8)

## Module Sources

| Resource | Source | Note |
|---|---|---|
| VNet | `Azure/avm-res-network-virtualnetwork/azurerm` | AVM Registry |
| NSG | `Azure/avm-res-network-networksecuritygroup/azurerm` | AVM Registry |
| App Service Plan | `Azure/avm-res-web-serverfarm/azurerm` | AVM Registry |
| App Service | `Azure/avm-res-web-site/azurerm` | AVM Registry |
| Storage | `Azure/avm-res-storage-storageaccount/azurerm` | AVM Registry |
| MySQL | `git::https://github.com/bdtmsd/tf-iac.git?ref=v1.0.0` | Scratch module (no AVM) — exposes `fqdn` output |

## vs `workloads` branch

| Aspect | `workloads` | `workloads-avm` (this branch) |
|---|---|---|
| Module source | Wrapped child module repos (`tf-iac-*-module`) | AVM Registry directly |
| Subnet output | `module.vnet.subnet_ids[name]` | `module.vnet.subnets[name].resource_id` |
| MySQL | AVM v0.1.6 (no fqdn) | Scratch azurerm (exposes fqdn) |
| Abstraction layers | 2 | 1 |

## State Management

HCP Terraform workspaces:

| Environment | Workspace |
|---|---|
| dev | `mvp-workload-dev` |
| prod | `mvp-workload-prod` |

```bash
terraform login
# or: export TF_TOKEN_app_terraform_io=<token>
```

## Secrets

MySQL password via HashiCorp Vault or environment variable:
```bash
export TF_VAR_mysql_admin_password="$(vault kv get -field=password secret/bdt/mysql)"
```

## Outputs

| Output | Description |
|---|---|
| `vnet_id` | VNet resource ID |
| `app_service_hostname` | App Service default hostname |
| `mysql_server_name` | MySQL server name |
| `mysql_server_fqdn` | MySQL server FQDN (available from scratch module) |
| `storage_account_name` | Storage account name |
| `storage_blob_endpoint` | Primary blob endpoint |

## Maintained By

Team: team@bdtmsd.com
