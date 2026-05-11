module "mysql" {
  source = "../../"

  server_name            = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = "mysqladmin"
  administrator_password = var.administrator_password

  sku_name        = "B_Standard_B1ms"
  mysql_version   = "8.0.21"
  storage_size_gb = 20

  databases = {
    "appdb" = { charset = "utf8mb4", collation = "utf8mb4_unicode_ci" }
    "logdb" = { charset = "utf8mb4", collation = "utf8mb4_unicode_ci" }
  }

  enable_resource_lock = false

  tags = {
    Application = "MyApplication"
    Owner       = "platform-team@bdtmsd.com"
    Environment = "dev"
    CostCenter  = "CC-1234"
  }
}
