workload            = "tf"
env                 = "dev"
resource_group_name = "rg-bdt-terraform-dev-eus2-001"
location            = "eastus2"

tags = {
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
