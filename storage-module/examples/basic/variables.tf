variable "workload" {
  type    = string
  default = "tf"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "resource_group_name" {
  type    = string
  default = "rg-bdt-terraform-dev-eus2-001"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "storage" {
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    enable_versioning        = optional(bool, false)
    containers = optional(list(object({
      name        = string
      access_type = optional(string, "private")
    })), [])
  })
  default = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    enable_versioning        = false
    containers = [
      { name = "uploads", access_type = "private" }
    ]
  }
}

variable "tags" {
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
}
