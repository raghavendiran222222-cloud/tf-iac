variable "server_name" {
  description = "Name of the MySQL Flexible Server."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the MySQL server."
  type        = string
}

variable "administrator_login" {
  description = "Administrator login username for MySQL."
  type        = string
  default     = "mysqladmin"
}

variable "administrator_password" {
  description = "Administrator login password for MySQL. Provide via TF_VAR or HashiCorp Vault."
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name for the MySQL Flexible Server (e.g. B_Standard_B1ms, GP_Standard_D2ds_v4)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_version" {
  description = "MySQL server version."
  type        = string
  default     = "8.0.21"
}

variable "storage_size_gb" {
  description = "Storage size in GB."
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Backup retention period in days."
  type        = number
  default     = 7
}

variable "delegated_subnet_id" {
  description = "Resource ID of the delegated subnet for private access. Leave empty for public access."
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone for MySQL. Required when delegated_subnet_id is set."
  type        = string
  default     = ""
}

variable "databases" {
  description = "Map of databases to create on the server."
  type = map(object({
    charset   = string
    collation = string
  }))
  default = {}
}

variable "enable_resource_lock" {
  description = "Apply a CanNotDelete management lock to the server."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
