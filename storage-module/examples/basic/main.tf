# Reference: source = "git::https://github.com/bdtmsd/alz-modules.git//storage-module?ref=storage-module-v0.1.0"
module "storage" {
  source = "../../"

  workload            = var.workload
  env                 = var.env
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  storage = var.storage
}
