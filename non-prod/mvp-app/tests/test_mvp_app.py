"""
Lightweight plan-level tests for non-prod/mvp-app.

Validates naming conventions, security configuration, and resource presence
from a `terraform plan` without deploying real infrastructure.

Prerequisites:
    pip install -r tests/requirements.txt

Run:
    pytest -v tests/test_mvp_app.py
"""

import pytest
import tftest
from pathlib import Path

DIRECTORY = Path(__file__).parent.parent
TF_VARS_FILE = str(Path(__file__).parent / "fixtures" / "terraform.tfvars")
ENV = "sandbox"

VALID_VNET_NAME        = f"vnet-bdt-mvp-{ENV}-eus2-001"
VALID_NSG_APP_NAME     = f"nsg-bdt-mvp-app-{ENV}-eus2-001"
VALID_ASP_NAME         = f"asp-bdt-mvp-{ENV}-eus2-001"
VALID_APP_NAME         = f"app-bdt-mvp-{ENV}-eus2-001"
VALID_MYSQL_NAME       = f"mysql-bdt-mvp-{ENV}-eus2-001"
VALID_STORAGE_NAME     = f"stbdtmvp{ENV}eus2001"
VALID_SUBNET_APP_NAME  = f"snet-bdt-app-{ENV}-eus2-001"
VALID_SUBNET_DATA_NAME = f"snet-bdt-data-{ENV}-eus2-001"
VALID_MYSQL_DNS_ZONE   = "privatelink.mysql.database.azure.com"
VALID_MYSQL_VERSION    = "8.0.21"


@pytest.fixture(scope="module")
def plan():
    tf = tftest.TerraformTest(DIRECTORY)
    tf.setup(cleanup_on_exit=False)
    return tf.plan(output=True, tf_var_file=TF_VARS_FILE)


# ── VNet ──────────────────────────────────────────────────────────────────────

def test_vnet_name(plan):
    module = plan.modules["module.vnet"]
    vnet = module.resources["azurerm_virtual_network.this"]
    assert vnet["values"]["name"] == VALID_VNET_NAME


def test_vnet_address_space(plan):
    module = plan.modules["module.vnet"]
    vnet = module.resources["azurerm_virtual_network.this"]
    assert "10.30.0.0/16" in vnet["values"]["address_space"]


def test_app_subnet_present(plan):
    module = plan.modules["module.vnet"]
    assert any(VALID_SUBNET_APP_NAME in k for k in module.resources)


def test_data_subnet_present(plan):
    module = plan.modules["module.vnet"]
    assert any(VALID_SUBNET_DATA_NAME in k for k in module.resources)


def test_app_subnet_web_delegation(plan):
    module = plan.modules["module.vnet"]
    key = next(k for k in module.resources if VALID_SUBNET_APP_NAME in k)
    subnet = module.resources[key]
    delegations = subnet["values"].get("delegation", [])
    service_names = [d["service_delegation"][0]["name"] for d in delegations if d.get("service_delegation")]
    assert "Microsoft.Web/serverFarms" in service_names


def test_data_subnet_mysql_delegation(plan):
    module = plan.modules["module.vnet"]
    key = next(k for k in module.resources if VALID_SUBNET_DATA_NAME in k)
    subnet = module.resources[key]
    delegations = subnet["values"].get("delegation", [])
    service_names = [d["service_delegation"][0]["name"] for d in delegations if d.get("service_delegation")]
    assert "Microsoft.DBforMySQL/flexibleServers" in service_names


# ── NSG ───────────────────────────────────────────────────────────────────────

def test_nsg_app_name(plan):
    module = plan.modules["module.nsg_app"]
    nsg = module.resources["azurerm_network_security_group.this"]
    assert nsg["values"]["name"] == VALID_NSG_APP_NAME


def test_nsg_https_rule_present(plan):
    module = plan.modules["module.nsg_app"]
    nsg = module.resources["azurerm_network_security_group.this"]
    rules = nsg["values"].get("security_rule", [])
    https_rules = [r for r in rules if r.get("destination_port_range") == "443" and r.get("access") == "Allow"]
    assert len(https_rules) > 0, "Expected an inbound Allow-443 security rule"


def test_nsg_subnet_association_present(plan):
    assert "azurerm_subnet_network_security_group_association.app" in plan.resource_changes


# ── App Service Plan ──────────────────────────────────────────────────────────

def test_asp_name(plan):
    module = plan.modules["module.app_service_plan"]
    asp = module.resources["azurerm_service_plan.this"]
    assert asp["values"]["name"] == VALID_ASP_NAME


def test_asp_os_type_linux(plan):
    module = plan.modules["module.app_service_plan"]
    asp = module.resources["azurerm_service_plan.this"]
    assert asp["values"]["os_type"] == "Linux"


def test_asp_action_create(plan):
    key = next(k for k in plan.resource_changes if "azurerm_service_plan" in k and "module.app_service_plan" in k)
    assert "create" in plan.resource_changes[key]["change"]["actions"]


# ── App Service ───────────────────────────────────────────────────────────────

def test_app_name(plan):
    module = plan.modules["module.app_service"]
    app = module.resources["azurerm_linux_web_app.this"]
    assert app["values"]["name"] == VALID_APP_NAME


def test_app_action_create(plan):
    key = next(k for k in plan.resource_changes if "azurerm_linux_web_app" in k and "module.app_service" in k)
    assert "create" in plan.resource_changes[key]["change"]["actions"]


# ── MySQL Private DNS ─────────────────────────────────────────────────────────

def test_mysql_private_dns_zone_name(plan):
    dns = plan.resource_changes["azurerm_private_dns_zone.mysql"]
    assert dns["change"]["after"]["name"] == VALID_MYSQL_DNS_ZONE


def test_mysql_dns_zone_action_create(plan):
    dns = plan.resource_changes["azurerm_private_dns_zone.mysql"]
    assert "create" in dns["change"]["actions"]


def test_mysql_dns_vnet_link_present(plan):
    assert "azurerm_private_dns_zone_virtual_network_link.mysql" in plan.resource_changes


# ── MySQL Flexible Server ─────────────────────────────────────────────────────

def test_mysql_name(plan):
    module = plan.modules["module.mysql"]
    mysql = module.resources["azurerm_mysql_flexible_server.this"]
    assert mysql["values"]["name"] == VALID_MYSQL_NAME


def test_mysql_version(plan):
    module = plan.modules["module.mysql"]
    mysql = module.resources["azurerm_mysql_flexible_server.this"]
    assert mysql["values"]["version"] == VALID_MYSQL_VERSION


def test_mysql_admin_username(plan):
    module = plan.modules["module.mysql"]
    mysql = module.resources["azurerm_mysql_flexible_server.this"]
    assert mysql["values"]["administrator_login"] == "mysqladmin"


def test_mysql_action_create(plan):
    key = next(k for k in plan.resource_changes if "azurerm_mysql_flexible_server" in k and "module.mysql" in k)
    assert "create" in plan.resource_changes[key]["change"]["actions"]


# ── Storage Account ───────────────────────────────────────────────────────────

def test_storage_account_name(plan):
    key = next(k for k in plan.resource_changes if "azurerm_storage_account" in k and "module.storage" in k)
    assert plan.resource_changes[key]["change"]["after"]["name"] == VALID_STORAGE_NAME


def test_storage_tls_version(plan):
    key = next(k for k in plan.resource_changes if "azurerm_storage_account" in k and "module.storage" in k)
    assert plan.resource_changes[key]["change"]["after"]["min_tls_version"] == "TLS1_2"


def test_storage_action_create(plan):
    key = next(k for k in plan.resource_changes if "azurerm_storage_account" in k and "module.storage" in k)
    assert "create" in plan.resource_changes[key]["change"]["actions"]


def test_uploads_container_present(plan):
    containers = [k for k in plan.resource_changes if "azurerm_storage_container" in k and "uploads" in k]
    assert len(containers) > 0, "Expected 'uploads' storage container"


def test_backups_container_present(plan):
    containers = [k for k in plan.resource_changes if "azurerm_storage_container" in k and "backups" in k]
    assert len(containers) > 0, "Expected 'backups' storage container"


def test_containers_are_private(plan):
    containers = {k: v for k, v in plan.resource_changes.items() if "azurerm_storage_container" in k and "module.storage" in k}
    assert len(containers) >= 2, "Expected at least 2 containers under module.storage"
    for k, v in containers.items():
        access = v["change"]["after"].get("container_access_type", "private")
        assert access in ("private", "", None), f"Container {k} must be private, got {access!r}"


# ── Outputs ───────────────────────────────────────────────────────────────────

def test_all_outputs_declared(plan):
    expected = {
        "vnet_id",
        "app_service_hostname",
        "mysql_server_name",
        "mysql_server_fqdn",
        "storage_account_name",
        "storage_blob_endpoint",
    }
    missing = expected - set(plan.outputs.keys())
    assert not missing, f"Missing outputs: {missing}"
