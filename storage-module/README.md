# tf-iac-storage-module

Terraform module for provisioning an Azure Storage Account with blob containers. Enforces TLS 1.2 and supports optional blob versioning.

---

## Resources

| Resource | Description |
|----------|-------------|
| `azurerm_storage_account` | Storage Account with TLS 1.2 enforced |
| `azurerm_storage_container` | One or more blob containers via `for_each` |

Set `var.storage = null` (the default) to make this module a no-op.

---

## Usage

```hcl
module "storage" {
  source = "git::https://github.com/bdtmsd/alz-modules.git//storage-module?ref=storage-module-v0.1.0"

  resource_group_name = "rg-myapp-prod-eus2-001"
  location            = "eastus2"
  tags                = { environment = "prod" }

  storage = {
    name                     = "stmyappprodeus2001"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    enable_versioning        = true
    containers = [
      { name = "uploads",  access_type = "private" },
      { name = "static",   access_type = "blob" }
    ]
  }
}
```

---

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | `string` | — | Resource group to deploy into |
| `location` | `string` | — | Azure region |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |
| `storage` | `object` | `null` | Storage Account configuration — see schema below |

### `storage` object schema

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Storage Account name (3–24 lowercase alphanumeric, globally unique) |
| `account_tier` | `string` | `"Standard"` | `"Standard"` or `"Premium"` |
| `account_replication_type` | `string` | `"LRS"` | `LRS`, `GRS`, `ZRS`, `RAGRS`, `GZRS` |
| `enable_versioning` | `bool` | `false` | Enable blob versioning for point-in-time recovery |
| `containers` | `list(object)` | `[]` | List of `{ name, access_type? }` — access type: `private`, `blob`, `container` |

---

## Outputs

| Name | Description |
|------|-------------|
| `storage_account_id` | ARM resource ID of the Storage Account (`null` if not provisioned) |
| `storage_account_name` | Name of the Storage Account (`null` if not provisioned) |
| `storage_account_primary_blob_endpoint` | Primary blob service endpoint URL (`null` if not provisioned) |
| `storage_account_primary_connection_string` | Full connection string — **sensitive** (`null` if not provisioned) |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.14.0` |
| `hashicorp/azurerm` | `>= 4.70.0` |

---

## Running the Example

```bash
cd examples/basic
terraform init
terraform plan -var-file="terraform.tfvars"
```

## Running Tests

```bash
pip install -r tests/requirements.txt
pytest tests/ -v
```

---

## Maintainers

| Name | Role | Email |
|------|------|-------|
| Raghavendiran N | Senior DevOps Engineer | raghavendirann@bdtmsd.com |
| Sakthivel Manohar | Senior DevOps Engineer | smanohar@bdtmsd.com |
