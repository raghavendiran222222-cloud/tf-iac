variable "workload" {
  description = "Short workload descriptor included in resource names (e.g. \"tf\", \"data\", \"app\")."
  type        = string
}

variable "env" {
  description = "Environment enumeration used in resource names and tags."
  type        = string

  validation {
    condition     = contains(["sandbox", "dev", "test", "stage", "qa", "uat", "sit", "prod", "nonprod", "mgt", "con", "id"], var.env)
    error_message = "env must be one of: sandbox, dev, test, stage, qa, uat, sit, prod, nonprod, mgt, con, id."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. eastus2). Used to derive the region short name for naming."
  type        = string
}

variable "tags" {
  description = "Required and optional resource tags applied to every resource (Table 12 governance standard)."
  type = object({
    Application         = string
    CreationDate        = string # MM-DD-YYYY
    DevOwner            = string # email address
    BusinessOwner       = string # email address
    BusinessUnit        = string
    CostCenter          = string
    DataClassification  = string           # Unrestricted | Sensitive | Restricted
    BusinessCriticality = string           # Low | Medium | High | Mission-critical
    IACRepository       = string           # GitHub repo URL
    Compliance          = optional(string) # CIS | HIPAA | FEDRAMP | SOX | NIST
    DeleteAt            = optional(string) # MM-DD-YYYY — required for sandbox/time-bounded resources
  })

  validation {
    condition     = contains(["Unrestricted", "Sensitive", "Restricted"], var.tags.DataClassification)
    error_message = "tags.DataClassification must be one of: Unrestricted, Sensitive, Restricted."
  }

  validation {
    condition     = contains(["Low", "Medium", "High", "Mission-critical"], var.tags.BusinessCriticality)
    error_message = "tags.BusinessCriticality must be one of: Low, Medium, High, Mission-critical."
  }
}

variable "storage" {
  description = "Storage Account configuration. Set to null to skip provisioning."
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    enable_versioning        = optional(bool, false)
    containers = optional(list(object({
      name        = string
      access_type = optional(string, "private")
    })), [])
  })
  default = null
}
