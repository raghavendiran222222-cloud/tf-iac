output "management_group_resource_ids" {
  description = "Map of all management group names to their Azure resource IDs."
  value       = module.alz.management_group_resource_ids
}

output "management_group_id_root" {
  description = "Resource ID of the top-level ALZ management group (e.g. /providers/Microsoft.Management/managementGroups/bdt)."
  value       = module.alz.management_group_resource_ids[var.root_management_group_id]
}

output "management_group_id_platform" {
  description = "Resource ID of the Platform management group."
  value       = module.alz.management_group_resource_ids["${var.root_management_group_id}-platform"]
}

output "management_group_id_landing_zones" {
  description = "Resource ID of the Landing Zones management group."
  value       = module.alz.management_group_resource_ids["${var.root_management_group_id}-landingzones"]
}

output "management_group_id_sandbox" {
  description = "Resource ID of the Sandbox management group."
  value       = module.alz.management_group_resource_ids["${var.root_management_group_id}-sandbox"]
}
