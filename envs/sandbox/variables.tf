variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for all MVP resources."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
  validation {
    condition     = contains(["eastus2", "centralus", "eastus", "westus2", "westeurope", "northeurope"], var.location)
    error_message = "Location must be an approved Azure region."
  }
}

variable "environment" {
  description = "Deployment environment (FDD Table 10 enumerations)."
  type        = string
  validation {
    condition     = contains(["sandbox", "dev", "test", "stage", "qa", "uat", "sit", "prod", "nonprod", "mgt", "con", "id"], var.environment)
    error_message = "environment must be one of the FDD-defined enumerations."
  }
}

variable "vnet_address_space" {
  description = "Address space for the VNet."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "app_sku" {
  description = "App Service Plan SKU (e.g. B1, P1v3)."
  type        = string
  default     = "B1"
}

variable "mysql_sku" {
  description = "MySQL Flexible Server SKU name."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_admin_username" {
  description = "Administrator login username for MySQL."
  type        = string
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  description = "Administrator login password for MySQL. Provide via TF_VAR or HashiCorp Vault."
  type        = string
  sensitive   = true
}

variable "storage_replication" {
  description = "Storage account replication type (LRS, GRS, etc.)."
  type        = string
  default     = "LRS"
}

variable "enable_resource_lock" {
  description = "Apply CanNotDelete lock to all resources."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID for diagnostic settings. Leave empty to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Required and optional resource tags per FDD Table 12."
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
