# tf-iac — BDT MVP Workloads Root Module

Root Terraform composition module for the BDT 2-tier MVP infrastructure. Orchestrates the vnet, nsg, app-service, mysql, and storage child modules into a deployable environment.

## Summary

```hcl
# Example — deploy dev environment
cd envs/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Architecture

**Tier 1 — Networking**
- Virtual Network (VNet) with `snet-bdt-app` and `snet-bdt-data` subnets
- Network Security Group (NSG) on `snet-bdt-app` — allows HTTPS inbound

**Tier 2 — Application + Data**
- App Service (Linux) with VNet integration to `snet-bdt-app`
- Azure Database for MySQL Flexible Server with private access via `snet-bdt-data`
- Storage Account with `uploads` and `backups` containers

## State Management

State is stored in **HCP Terraform** (Terraform Cloud) per FDD requirement. Each environment maps to its own HCP Terraform workspace:

| Environment | HCP Workspace |
|-------------|--------------|
| dev | `mvp-workload-dev` |
| prod | `mvp-workload-prod` |

Authenticate before running:
```bash
terraform login
```

Or set the `TF_TOKEN_app_terraform_io` environment variable.

## Secrets Management

MySQL admin passwords and any sensitive values must be provided via **HashiCorp Vault** or as `TF_VAR_*` environment variables. Never store plaintext secrets in `terraform.tfvars`.

```bash
export TF_VAR_mysql_admin_password="$(vault kv get -field=password secret/bdt/mysql)"
```

## Directory Structure

```
envs/
├── dev/
│   ├── main.tf           # Module wiring
│   ├── variables.tf      # Input declarations
│   ├── locals.tf         # Naming & tag composition
│   ├── outputs.tf        # Key resource outputs
│   ├── versions.tf       # Provider + HCP Terraform cloud block
│   └── terraform.tfvars  # Dev-specific values
└── prod/
    └── ...               # Same structure, prod SKUs
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `subscription_id` | Azure subscription ID | `string` | yes |
| `resource_group_name` | Target resource group | `string` | yes |
| `location` | Azure region | `string` | no (default: `eastus2`) |
| `environment` | Env enum per FDD Table 10 | `string` | yes |
| `vnet_address_space` | VNet address prefixes | `list(string)` | no |
| `app_sku` | App Service Plan SKU | `string` | no |
| `mysql_sku` | MySQL Flexible Server SKU | `string` | no |
| `mysql_admin_username` | MySQL admin login | `string` | no |
| `mysql_admin_password` | MySQL admin password (sensitive) | `string` | yes |
| `storage_replication` | Storage replication type | `string` | no |
| `enable_resource_lock` | Apply CanNotDelete lock | `bool` | no |
| `log_analytics_workspace_id` | LAW resource ID for diagnostics | `string` | no |
| `tags` | FDD Table 12 tag object | `object` | yes |

### tags object fields

| Tag | Required | Valid Values |
|-----|----------|-------------|
| `Application` | yes | Any string |
| `DevOwner` | yes | Email address |
| `BusinessOwner` | yes | Email address |
| `Environment` | yes | FDD enum (dev, prod, etc.) |
| `DataClassification` | yes | Unrestricted / Sensitive / Restricted |
| `BusinessCriticality` | yes | Low / Medium / High / Mission-critical |
| `IACRepository` | yes | GitHub repo URL |
| `CostCenter` | no | Any string |
| `Compliance` | no | CIS / HIPAA / FEDRAMP / SOX / NIST |

Auto-injected tags (not required as inputs): `ManagedBy`, `CreationDate`.

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Resource ID of the VNet |
| `app_service_hostname` | Default hostname of the App Service |
| `mysql_server_name` | Name of the MySQL Flexible Server |
| `storage_account_name` | Name of the Storage Account |
| `storage_blob_endpoint` | Primary blob service endpoint |

## Naming Convention

Resources follow the FDD naming pattern: `<type>-<deptName>-<workload>-<env>-<region>-<instance>`

Examples for `environment = "dev"`:
- VNet: `vnet-bdt-mvp-dev-eus2-001`
- NSG: `nsg-bdt-mvp-app-dev-eus2-001`
- App: `app-bdt-mvp-dev-eus2-001`
- MySQL: `mysql-bdt-mvp-dev-eus2-001`
- Storage: `stbdtmvpdeveus2001` (no hyphens — global uniqueness requirement)

## Branch Policy (FDD Table 4)

- Minimum **2 approvers** required; requestor cannot self-approve
- All reviewer votes must resolve before merge
- **Basic merge only** (no fast-forward) — retains full commit history
- Linked work items required on all PRs
- Automatic reviewers: Raghavendiran, Sakthivel Manohar (initial development)

## CI/CD Pipeline (GitHub Actions — FDD requirement)

| Trigger | Action |
|---------|--------|
| Push to feature branch | `terraform fmt` + `terraform validate` |
| Pull Request to `main` | `terraform plan` (plan posted as PR comment) |
| Merge to `main` | `terraform apply` (requires manual approval gate) |

GitHub Actions workflow files are managed separately in `.github/workflows/`.

## Maintained By

Team: team@bdtmsd.com
