# tf-iac-azure-mgt-layer1

Azure Landing Zone Layer 1 — Management Groups and Azure Policy.

Deploys the default ALZ management group hierarchy and built-in policy definitions/assignments using the [Azure/avm-ptn-alz/azurerm](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest) module.

## Summary

```hcl
module "layer1" {
  source = "github.com/bdt-msd/tf-iac//layer1?ref=v1.0.0"

  root_management_group_id           = "bdt"
  root_management_group_display_name = "BDT"
  subscription_id_management         = "<uuid>"
  subscription_id_connectivity       = "<uuid>"
  subscription_id_identity           = "<uuid>"
}
```

Management group hierarchy deployed:

```
Tenant Root Group
└── bdt
    ├── bdt-platform
    │   ├── bdt-management
    │   ├── bdt-connectivity
    │   └── bdt-identity
    ├── bdt-landingzones
    │   ├── bdt-corp
    │   └── bdt-online
    ├── bdt-sandbox
    └── bdt-decommissioned
```

## Requirements

| Tool      | Version  |
|-----------|----------|
| Terraform | ~> 1.9   |
| azurerm   | ~> 4.0   |
| azapi     | ~> 2.1   |
| alz       | ~> 0.16  |

HCP Terraform: org `bdt-msd`, workspace `tf-iac-azure-mgt-layer1`

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `root_management_group_id` | Top-level MG name/prefix (e.g. `bdt`) | `string` | yes | — |
| `root_management_group_display_name` | Display name for the top-level MG | `string` | yes | — |
| `subscription_id_management` | Management platform subscription UUID | `string` | yes | — |
| `subscription_id_connectivity` | Connectivity platform subscription UUID | `string` | yes | — |
| `subscription_id_identity` | Identity platform subscription UUID | `string` | yes | — |
| `location` | Azure region for policy resources | `string` | no | `"eastus2"` |
| `parent_management_group_id` | Parent MG ID; empty = Tenant Root Group | `string` | no | `""` |
| `enable_telemetry` | Enable AVM telemetry | `bool` | no | `true` |
| `default_tags` | Tags applied to all resources | `map(string)` | no | `{}` |

## Outputs

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `management_group_resource_ids` | Map of all MG names to resource IDs | `map(string)` | `{ "bdt" = "/providers/Microsoft.Management/managementGroups/bdt" }` |
| `management_group_id_root` | Top-level MG resource ID | `string` | `/providers/Microsoft.Management/managementGroups/bdt` |
| `management_group_id_platform` | Platform MG resource ID | `string` | `/providers/Microsoft.Management/managementGroups/bdt-platform` |
| `management_group_id_landing_zones` | Landing Zones MG resource ID | `string` | `/providers/Microsoft.Management/managementGroups/bdt-landingzones` |
| `management_group_id_sandbox` | Sandbox MG resource ID | `string` | `/providers/Microsoft.Management/managementGroups/bdt-sandbox` |

## Maintained By

| Name | Role | Email | Phone |
|------|------|-------|-------|
| Raghavendiran N | Senior DevOps Engineer | raghavendirann@presidio.com | +91-904-734-6461 |
| Sakthivel Manohar | Senior DevOps Engineer | smanohar@presidio.com | 1-469-549-3826 |
