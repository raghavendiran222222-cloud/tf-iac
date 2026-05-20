# Terraform IaC Agent — Knowledge Base

## 1. Repository Layout

There are **two separate GitHub repositories**. Always target the correct repo when creating branches, committing files, and opening PRs.

---

### Repo A — Application Stacks

**GitHub:** `https://github.com/bdtmsd/alz-landingzones-infra`
**Working branch:** `alz-landingzones-infra`
**Purpose:** Application-level Terraform root modules (non-prod and prod environments)

```
alz-landingzones-infra (branch)
├── non-prod/
│   ├── mvp-app/                   # Reference: VNet + App Service + MySQL + Storage
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   ├── versions.tf
│   │   ├── backend.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfvars.example
│   │   ├── README.md
│   │   ├── CHANGELOG.md
│   │   ├── examples/
│   │   │   └── main.tf
│   │   └── tests/
│   └── infra-agent/               # MCP Server: Container Apps + APIM + Key Vault
│       └── (same 10-file structure as mvp-app)
├── prod/                          # Production workloads (same file structure)
├── policies/                      # OPA/Rego governance policies
└── scripts/                       # CI/CD helper scripts
```

**New apps go to:** `non-prod/{app-name}/` or `prod/{app-name}/`
**New app branch:** `{app-name}-{env}` off `alz-landingzones-infra`
**PR target:** `alz-landingzones-infra` branch in `github.com/bdtmsd/alz-landingzones-infra`

---

### Repo B — Reusable Modules

**GitHub:** `https://github.com/bdtmsd/alz-modules`
**Working branch:** `alz-modules`
**Purpose:** Reusable Terraform child modules consumed by application stacks via `git::` source

```
alz-modules (branch)
├── storage-module/                # Reference module: Storage Account + Blob Containers
│   ├── main.tf                    # azurerm_storage_account, azurerm_storage_container
│   ├── variables.tf               # workload, env, resource_group_name, location, tags, storage
│   ├── outputs.tf                 # storage_account_id, name, primary_blob_endpoint (sensitive: connection string)
│   ├── locals.tf                  # _region_abbr_map, region_abbr, merged_tags, storage_enabled guard
│   ├── versions.tf                # required_version >= 1.14.0, azurerm >= 4.70.0
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── examples/
│   │   └── basic/
│   │       ├── main.tf            # Minimal call of the module
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── versions.tf
│   └── tests/
│       ├── test_storage.py        # Plan-level tests via tftest (no real Azure)
│       ├── test_e2e_basic_ex.py   # E2E apply/destroy tests via Azure SDK
│       └── requirements.txt       # pytest, tftest, azure-identity, azure-mgmt-storage
│
└── {new-module}/                  # Every new module follows the same structure above
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── locals.tf
    ├── versions.tf
    ├── CHANGELOG.md
    ├── README.md
    ├── examples/basic/
    └── tests/
```

**New modules go to:** `{module-name}/` folder
**New module branch:** `{module-name}` off `alz-modules`
**PR target:** `alz-modules` branch in `github.com/bdtmsd/alz-modules`

---

### How Apps Consume Modules

Application stacks in `alz-landingzones-infra` reference modules from `alz-modules` using the git source syntax:

```hcl
module "storage" {
  source = "git::https://github.com/bdtmsd/alz-modules.git//storage-module?ref=storage-module-v0.1.0"
  # variables...
}
```

Pattern: `git::https://github.com/bdtmsd/alz-modules.git//{module-name}?ref={module-name}-v{x.y.z}`

---

## 2. Environment Enumerations

Valid values for `environment` / `env` variable:

| Value | Tier |
|---|---|
| sandbox | non-prod |
| dev | non-prod |
| test | non-prod |
| stage | non-prod |
| qa | non-prod |
| uat | non-prod |
| sit | non-prod |
| nonprod | non-prod |
| prod | prod |
| mgt | prod |
| con | prod |
| id | prod |

---

## 3. Region Abbreviation Map

```hcl
_region_abbr_map = {
  eastus             = "eus"
  eastus2            = "eus2"
  centralus          = "cus"
  westus             = "wus"
  westus2            = "wus2"
  northcentralus     = "ncus"
  southcentralus     = "scus"
  westcentralus      = "wcus"
  eastasia           = "eas"
  southeastasia      = "sea"
  northeurope        = "neu"
  westeurope         = "weu"
  uksouth            = "uks"
  ukwest             = "ukw"
  australiaeast      = "aue"
  australiasoutheast = "ause"
}
```

Default region: `eastus2` (abbreviation: `eus2`)

---

## 4. Tag Governance (FDD Table 12)

### Required Tags
| Tag | Type | Allowed Values |
|---|---|---|
| Application | string | workload name |
| DevOwner | string | email address |
| BusinessOwner | string | email address |
| Environment | string | see Section 2 |
| DataClassification | string | `Unrestricted` \| `Sensitive` \| `Restricted` |
| BusinessCriticality | string | `Low` \| `Medium` \| `High` \| `Mission-critical` |
| IACRepository | string | full GitHub URL |

### Optional Tags
| Tag | Notes |
|---|---|
| CostCenter | cost allocation code |
| Compliance | `CIS` \| `HIPAA` \| `FEDRAMP` \| `SOX` \| `NIST` |
| DeleteAt | `MM-DD-YYYY` — required for sandbox/time-bounded resources |

### Auto-added in `locals.tf`
```hcl
common_tags = merge(var.tags, {
  ManagedBy    = "Terraform"
  CreationDate = formatdate("MMDDYYYY", timestamp())
})
```

---

## 5. Naming Convention

Format: `{prefix}-bdt-{app}-{env}-{region-abbr}-{instance}`

| Resource | Prefix | Example |
|---|---|---|
| Resource Group | `rg` | `rg-bdt-mvp-dev-eus2-001` |
| Virtual Network | `vnet` | `vnet-bdt-mvp-dev-eus2-001` |
| Subnet | `snet` | `snet-bdt-app-dev-eus2-001` |
| NSG | `nsg` | `nsg-bdt-mvp-app-dev-eus2-001` |
| App Service Plan | `asp` | `asp-bdt-mvp-dev-eus2-001` |
| App Service | `app` | `app-bdt-mvp-dev-eus2-001` |
| MySQL Flexible | `mysql` | `mysql-bdt-mvp-dev-eus2-001` |
| Storage Account | `st` | `stbdtmvpdeveus2001` (no hyphens, lowercase, ≤24 chars) |
| Key Vault | `kv` | `kv-bdt-mvp-dev-eus2-001` |
| Container App | `ca` | `ca-bdt-mvp-dev-eus2-001` |
| Log Analytics WS | `log` | `log-bdt-mvp-dev-eus2-001` |
| Private DNS Zone | N/A | `privatelink.{service}.azure.com` |

---

## 6. Module File Template (alz-modules pattern)

Based on `storage-module`. Every module MUST have these files:

### `main.tf`
```hcl
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
  suffix  = [var.workload, var.env, local.region_abbr]
}

# Resource definitions here using azurerm provider
# Use count = local.{feature}_enabled ? 1 : 0 for optional resources
```

### `variables.tf`
```hcl
variable "workload" {
  description = "Short workload descriptor (e.g. \"tf\", \"data\", \"app\")."
  type        = string
}

variable "env" {
  description = "Environment enumeration."
  type        = string
  validation {
    condition     = contains(["sandbox","dev","test","stage","qa","uat","sit","prod","nonprod","mgt","con","id"], var.env)
    error_message = "env must be a valid FDD environment."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. eastus2)."
  type        = string
}

variable "tags" {
  description = "Required resource tags per FDD Table 12."
  type = object({
    Application         = string
    CreationDate        = string
    DevOwner            = string
    BusinessOwner       = string
    BusinessUnit        = string
    CostCenter          = string
    DataClassification  = string
    BusinessCriticality = string
    IACRepository       = string
    Compliance          = optional(string)
    DeleteAt            = optional(string)
  })
  validation {
    condition     = contains(["Unrestricted","Sensitive","Restricted"], var.tags.DataClassification)
    error_message = "tags.DataClassification must be Unrestricted, Sensitive, or Restricted."
  }
  validation {
    condition     = contains(["Low","Medium","High","Mission-critical"], var.tags.BusinessCriticality)
    error_message = "tags.BusinessCriticality must be Low, Medium, High, or Mission-critical."
  }
}

# Add resource-specific variables below with optional() defaults where applicable
```

### `outputs.tf`
```hcl
# Use try(..., null) for conditional resources
output "resource_id" {
  description = "ARM resource ID."
  value       = try(azurerm_RESOURCE.this[0].id, null)
}
# Mark connection strings and keys as sensitive = true
```

### `locals.tf`
```hcl
locals {
  feature_enabled = var.feature_config != null   # guard for optional blocks

  _region_abbr_map = {
    eastus = "eus"  eastus2 = "eus2"  centralus = "cus"
    westus = "wus"  westus2 = "wus2"  northeurope = "neu"
    westeurope = "weu"  uksouth = "uks"  australiaeast = "aue"
  }
  region_abbr = lookup(local._region_abbr_map, lower(var.location), var.location)
  merged_tags = merge(var.tags, { Environment = var.env })
}
```

### `versions.tf`
```hcl
terraform {
  required_version = ">= 1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.70.0"
    }
  }
}
```

---

## 7. Application File Templates (alz-landingzones-infra pattern)

Based on `non-prod/mvp-app`. Every application MUST have these files:

### `versions.tf`
```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm" version = "~> 4.71" }
    azapi   = { source = "Azure/azapi"       version = "~> 2.9"  }
  }
}
```

### `backend.tf`
```hcl
terraform {
  cloud {
    organization = "bdtmsd"
    workspaces {
      name = "alz-landingzones-{app-name}"
      tags = ["{tier}"]    # "non-prod" or "prod"
    }
  }
}
```

### `provider.tf`
```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

### `variables.tf` (always include these base variables)
```hcl
variable "subscription_id" { type = string }
variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "eastus2"
  validation {
    condition     = contains(["eastus2","centralus","eastus","westus2","westeurope","northeurope"], var.location)
    error_message = "Location must be an approved Azure region."
  }
}
variable "environment" {
  type = string
  validation {
    condition     = contains(["sandbox","dev","test","stage","qa","uat","sit","prod","nonprod","mgt","con","id"], var.environment)
    error_message = "environment must be a valid FDD enumeration."
  }
}
variable "tags" {
  type = object({
    Application         = string
    DevOwner            = string
    BusinessOwner       = string
    Environment         = string
    DataClassification  = string
    BusinessCriticality = string
    IACRepository       = string
    CostCenter          = optional(string, "")
    Compliance          = optional(string, "")
  })
}
```

### `locals.tf`
```hcl
locals {
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  common_tags = merge(var.tags, {
    ManagedBy    = "Terraform"
    CreationDate = formatdate("MMDDYYYY", timestamp())
  })
  # Naming — replace {app} with actual app short name
  vnet_name = "vnet-bdt-{app}-${var.environment}-eus2-001"
  # ... add all resource name locals
}
```

---

## 8. AVM Module Catalog (validated versions)

| Module | Source | Version |
|---|---|---|
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` | `0.17.1` |
| NSG | `Azure/avm-res-network-networksecuritygroup/azurerm` | `0.5.1` |
| App Service Plan | `Azure/avm-res-web-serverfarm/azurerm` | `2.0.4` |
| App Service | `Azure/avm-res-web-site/azurerm` | `0.22.0` |
| MySQL Flexible | `Azure/avm-res-dbformysql-flexibleserver/azurerm` | `0.1.6` |
| Log Analytics | `Azure/avm-res-operationalinsights-workspace/azurerm` | `0.4.2` |
| Key Vault | `Azure/avm-res-keyvault-vault/azurerm` | `0.10.2` |
| Container Apps Env | `Azure/avm-res-app-managedenvironment/azurerm` | `0.3.0` |
| Container App | `Azure/avm-res-app-containerapp/azurerm` | `0.8.0` |
| API Management | `Azure/avm-res-apimanagement-service/azurerm` | `0.0.8` |
| Azure Naming | `Azure/naming/azurerm` | `0.4.2` |

**Custom modules from alz-modules:**
```
git::https://github.com/bdtmsd/alz-modules.git//{module-name}?ref={module-name}-v{x.y.z}
```
Example: `git::https://github.com/bdtmsd/alz-modules.git//storage-module?ref=storage-module-v0.1.0`

All AVM modules: always set `enable_telemetry = false`

---

## 9. Secret Management Rules

- **Never hardcode** passwords, tokens, or connection strings in `.tf` files
- Passwords: use `sensitive = true` variable + inject via `TF_VAR_*` env var or HCP Vault Secrets
- MySQL password example: `TF_VAR_mysql_admin_password`
- `terraform.tfvars.example`: comment out sensitive values with `# provide via TF_VAR_... or Vault`
- Production secrets: store in Azure Key Vault, reference via Key Vault secret data source

---

## 10. GitHub PR Template

**Repo and branch routing — always use the correct repo:**

| Operation | GitHub Repo | Base Branch | Feature Branch |
|---|---|---|---|
| New module | `github.com/bdtmsd/alz-modules` | `alz-modules` | `{module-name}-agent` |
| Update module | `github.com/bdtmsd/alz-modules` | `alz-modules` | `update-{module-name}-{desc}-agent` |
| Tests for module | `github.com/bdtmsd/alz-modules` | `alz-modules` | `tests-{module-name}-agent` |
| New app | `github.com/bdtmsd/alz-landingzones-infra` | `alz-landingzones-infra` | `{app-name}-{env}-agent` |
| Update app | `github.com/bdtmsd/alz-landingzones-infra` | `alz-landingzones-infra` | `update-{app-name}-{desc}-agent` |
| Tests for app | `github.com/bdtmsd/alz-landingzones-infra` | `alz-landingzones-infra` | `tests-{app-name}-agent` |

**PR title format** (all PR titles end with `(agent)`)
- New: `feat({name}): add {description} (agent)`
- Update/fix: `fix({name}): {description} (agent)`
- Tests: `test({name}): add plan and e2e tests (agent)`

**PR body:**
```markdown
## Summary
- Created/Updated: {list resources}
- Repo: github.com/bdtmsd/{alz-modules | alz-landingzones-infra}
- Branch target: {alz-modules | alz-landingzones-infra}

## Checklist
- [ ] terraform validate
- [ ] tflint --enable-plugin=azurerm
- [ ] checkov -d .
- [ ] Cost estimate reviewed
- [ ] Tags validated against FDD Table 12

## Environment
{environment} | {tier (non-prod/prod)}
```

---

## 11. Reference: mvp-app Pattern Summary

The `non-prod/mvp-app` application deploys:
- **VNet** with 2 subnets: `snet-bdt-app-{env}-eus2-001` (App Service delegation) and `snet-bdt-data-{env}-eus2-001` (MySQL delegation)
- **NSG** attached to app subnet with HTTPS inbound allow
- **App Service Plan** (Linux) + **App Service** (webapp, VNet-integrated)
- **Private DNS Zone** (`privatelink.mysql.database.azure.com`) + VNet link
- **MySQL Flexible Server** with private subnet delegation
- **Storage Account** via custom `storage-module` from alz-modules

Use this as the canonical pattern for new 3-tier web applications.

---

## 12. Reference: storage-module Pattern Summary

The `storage-module` on `alz-modules` provides:
- Optional `azurerm_storage_account` (null = skip provisioning)
- `azurerm_storage_container` for multiple containers via `for_each`
- TLS 1.2 enforcement, blob versioning toggle
- Uses `Azure/naming/azurerm` for deterministic storage account names
- All outputs use `try(..., null)` for safe null handling
- Primary connection string output marked `sensitive = true`

Tag object in storage-module includes `BusinessUnit` and `CreationDate` (required). This differs slightly from the app-level `tags` object — always check module variable definitions before passing tags.
