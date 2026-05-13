variable "subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure Subscription ID where the Storage Account will be deployed."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing Resource Group to deploy the Storage Account into."
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Storage Account. Must be globally unique, 3–24 lowercase alphanumeric characters."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3–24 lowercase alphanumeric characters only."
  }
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for the Storage Account."

  validation {
    condition     = contains(["eastus2", "centralus", "eastus", "westus2", "westeurope", "northeurope"], var.location)
    error_message = "location must be one of: eastus2, centralus, eastus, westus2, westeurope, northeurope."
  }
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Storage account tier. Must be 'Standard' or 'Premium'."

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication type for the Storage Account. Must be LRS, GRS, ZRS, or RAGRS."

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "RAGRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of: LRS, GRS, ZRS, RAGRS."
  }
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
  description = "Kind of Storage Account. Must be StorageV2, BlobStorage, or FileStorage."

  validation {
    condition     = contains(["StorageV2", "BlobStorage", "FileStorage"], var.account_kind)
    error_message = "account_kind must be one of: StorageV2, BlobStorage, FileStorage."
  }
}

variable "blob_containers" {
  type = map(object({
    access_type = optional(string, "private")
  }))
  default     = {}
  description = "Map of blob container configurations keyed by container name. access_type: 'private', 'blob', or 'container'."

  validation {
    condition = alltrue([
      for c in values(var.blob_containers) :
      contains(["private", "blob", "container"], c.access_type)
    ])
    error_message = "blob_containers access_type must be 'private', 'blob', or 'container'."
  }
}

variable "enable_https_traffic_only" {
  type        = bool
  default     = true
  description = "When true, only HTTPS traffic is permitted. Recommended for all environments."
}

variable "min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version for the Storage Account. Must be TLS1_0, TLS1_1, or TLS1_2."

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "min_tls_version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to all resources. Required keys: Application, Owner, Environment, CostCenter."

  validation {
    condition = alltrue([
      contains(keys(var.tags), "Application"),
      contains(keys(var.tags), "Owner"),
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "CostCenter"),
    ])
    error_message = "tags must include: Application, Owner, Environment, CostCenter."
  }
}

variable "enable_resource_lock" {
  type        = bool
  default     = false
  description = "When true, applies a CanNotDelete lock to the Storage Account. Recommended for production environments."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = ""
  description = "Resource ID of a Log Analytics Workspace for diagnostic settings. Leave empty to skip diagnostics."
}
