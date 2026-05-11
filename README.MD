# tf-iac (mysql-scratch)

Plain Terraform module for provisioning Azure MySQL Flexible Server. Uses raw `azurerm_mysql_flexible_server` resources — no AVM wrapper — enabling access to the native `fqdn` output removed from AVM MySQL v0.1.6.

## Features

- Raw `azurerm_mysql_flexible_server` with no AVM dependency
- Multiple database provisioning via a `databases` map
- Optional VNet integration (delegated subnet + private DNS zone)
- Zone-redundancy drift protection via `lifecycle.ignore_changes`
- Optional CanNotDelete resource lock
- Native `fqdn` output for downstream DNS configuration

## Usage

```hcl
module "mysql" {
  source = "git::https://github.com/bdtmsd/tf-iac.git?ref=v1.0.0"

  server_name            = "mysql-myapp-prod-eus2-001"
  resource_group_name    = "rg-myapp-prod-eus2-001"
  location               = "eastus2"
  administrator_login    = "mysqladmin"
  administrator_password = var.mysql_admin_password

  sku_name        = "B_Standard_B1ms"
  mysql_version   = "8.0.21"
  storage_size_gb = 20

  delegated_subnet_id = module.vnet.subnets["snet-data"].resource_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  databases = {
    "appdb" = { charset = "utf8mb4", collation = "utf8mb4_unicode_ci" }
  }

  enable_resource_lock = true

  tags = {
    Application = "MyApp"
    Owner       = "team@bdtmsd.com"
    Environment = "prod"
    CostCenter  = "CC-1234"
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `server_name` | string | Yes | — | MySQL Flexible Server name |
| `resource_group_name` | string | Yes | — | Pre-existing Resource Group name |
| `location` | string | Yes | — | Azure region |
| `administrator_login` | string | No | `mysqladmin` | Admin username |
| `administrator_password` | string | Yes | — | Admin password (sensitive) |
| `sku_name` | string | No | `B_Standard_B1ms` | Server SKU |
| `mysql_version` | string | No | `8.0.21` | MySQL engine version |
| `storage_size_gb` | number | No | `20` | Storage size in GB |
| `backup_retention_days` | number | No | `7` | Backup retention period |
| `delegated_subnet_id` | string | No | `""` | Subnet ID for VNet integration |
| `private_dns_zone_id` | string | No | `""` | Private DNS Zone ID |
| `databases` | map(object) | No | `{}` | Databases to provision (charset + collation) |
| `enable_resource_lock` | bool | No | `false` | Apply CanNotDelete lock |
| `tags` | map(string) | No | `{}` | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `server_id` | Resource ID of the MySQL Flexible Server |
| `server_name` | Name of the MySQL Flexible Server |
| `server_fqdn` | Fully qualified domain name of the server |
| `database_names` | List of provisioned database names |

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.9.0, < 2.0.0 |
| azurerm provider | ~> 4.71 |

## Running Tests

```bash
pip install pytest tftest==1.8.7
export ARM_SUBSCRIPTION_ID="..."
export ARM_CLIENT_ID="..."
export ARM_TENANT_ID="..."
pytest tests/ -v
```
