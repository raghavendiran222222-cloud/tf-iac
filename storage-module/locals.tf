locals {
  storage_enabled = var.storage != null

  # Maps full Azure region names to the short abbreviations used in resource names.
  # Extend as additional regions are onboarded.
  _region_abbr_map = {
    eastus             = "eus"
    eastus2            = "eus2"
    centralus          = "cus"
    westus             = "wus"
    westus2            = "wus2"
    northcentralus     = "ncus"
    southcentralus     = "scus"
    westcentralus      = "wcus"
    eastasia           = "eas"
    southeastasia      = "sea"
    northeurope        = "neu"
    westeurope         = "weu"
    uksouth            = "uks"
    ukwest             = "ukw"
    australiaeast      = "aue"
    australiasoutheast = "ause"
  }

  region_abbr = lookup(local._region_abbr_map, lower(var.location), var.location)

  # Merge the env tag from var.env so it stays consistent with the naming convention.
  merged_tags = merge(var.tags, { Environment = var.env })
}
