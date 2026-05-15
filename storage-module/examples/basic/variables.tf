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
  default = {
    Application         = "bdt-msd"
    CreationDate        = "01-01-2025"
    DevOwner            = "dev@example.com"
    BusinessOwner       = "owner@example.com"
    BusinessUnit        = "BDT"
    CostCenter          = "engineering"
    DataClassification  = "Sensitive"
    BusinessCriticality = "Medium"
    IACRepository       = "https://github.com/bdt/tf-iac-storage-module"
  }
}
