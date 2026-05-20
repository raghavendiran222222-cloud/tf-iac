"""
Pytest / python-tftest smoke tests for non-prod/mvp-app.

Prerequisites:
    pip install pytest python-tftest

Run:
    pytest -v tests/
"""

import os
from pathlib import Path

import pytest

try:
    import tftest

    TFTEST_AVAILABLE = True
except ImportError:
    TFTEST_AVAILABLE = False

_ROOT = Path(__file__).parent.parent
_TFVARS = str(_ROOT / "tests" / "fixtures" / "terraform.tfvars")


@pytest.mark.skipif(not TFTEST_AVAILABLE, reason="python-tftest not installed")
class TestMvpAppModule:
    """Plan-level validation for non-prod/mvp-app."""

    @pytest.fixture(scope="class")
    def plan(self):
        tf = tftest.TerraformTest(
            tfdir=str(_ROOT),
            env={
                **os.environ,
                "TF_CLI_ARGS_init": "-backend=false",
                "TF_CLI_ARGS_plan": "-lock=false",
            },
        )
        tf.setup(extra_files=[_TFVARS])
        yield tf.plan(output=True)
        tf.teardown()

    # ── Plan health ───────────────────────────────────────────────────────────

    def test_plan_succeeds(self, plan):
        assert plan is not None

    # ── Networking ────────────────────────────────────────────────────────────

    def test_vnet_present(self, plan):
        vnet = [k for k in plan.resource_changes if "azurerm_virtual_network" in k and "module.vnet" in k]
        assert len(vnet) > 0, "Expected VNet resource under module.vnet"

    def test_vnet_action_create(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_virtual_network" in k and "module.vnet" in k)
        assert "create" in plan.resource_changes[key]["change"]["actions"]

    def test_nsg_app_present(self, plan):
        nsg = [k for k in plan.resource_changes if "azurerm_network_security_group" in k and "module.nsg_app" in k]
        assert len(nsg) > 0, "Expected NSG resource under module.nsg_app"

    def test_nsg_subnet_association_present(self, plan):
        assert "azurerm_subnet_network_security_group_association.app" in plan.resource_changes

    def test_nsg_subnet_association_action_create(self, plan):
        assoc = plan.resource_changes["azurerm_subnet_network_security_group_association.app"]
        assert "create" in assoc["change"]["actions"]

    # ── MySQL Private DNS ─────────────────────────────────────────────────────

    def test_mysql_private_dns_zone_present(self, plan):
        assert "azurerm_private_dns_zone.mysql" in plan.resource_changes

    def test_mysql_private_dns_zone_action_create(self, plan):
        dns = plan.resource_changes["azurerm_private_dns_zone.mysql"]
        assert "create" in dns["change"]["actions"]

    def test_mysql_private_dns_zone_name(self, plan):
        dns = plan.resource_changes["azurerm_private_dns_zone.mysql"]
        assert dns["change"]["after"]["name"] == "privatelink.mysql.database.azure.com"

    def test_mysql_private_dns_vnet_link_present(self, plan):
        assert "azurerm_private_dns_zone_virtual_network_link.mysql" in plan.resource_changes

    def test_mysql_private_dns_vnet_link_action_create(self, plan):
        link = plan.resource_changes["azurerm_private_dns_zone_virtual_network_link.mysql"]
        assert "create" in link["change"]["actions"]

    # ── App Service ───────────────────────────────────────────────────────────

    def test_app_service_plan_present(self, plan):
        asp = [k for k in plan.resource_changes if "azurerm_service_plan" in k and "module.app_service_plan" in k]
        assert len(asp) > 0, "Expected App Service Plan under module.app_service_plan"

    def test_app_service_plan_action_create(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_service_plan" in k and "module.app_service_plan" in k)
        assert "create" in plan.resource_changes[key]["change"]["actions"]

    def test_linux_web_app_present(self, plan):
        apps = [k for k in plan.resource_changes if "azurerm_linux_web_app" in k and "module.app_service" in k]
        assert len(apps) > 0, "Expected Linux Web App under module.app_service"

    def test_linux_web_app_action_create(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_linux_web_app" in k and "module.app_service" in k)
        assert "create" in plan.resource_changes[key]["change"]["actions"]

    # ── MySQL Flexible Server ─────────────────────────────────────────────────

    def test_mysql_flexible_server_present(self, plan):
        mysql = [k for k in plan.resource_changes if "azurerm_mysql_flexible_server" in k and "module.mysql" in k]
        assert len(mysql) > 0, "Expected MySQL Flexible Server under module.mysql"

    def test_mysql_flexible_server_action_create(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_mysql_flexible_server" in k and "module.mysql" in k)
        assert "create" in plan.resource_changes[key]["change"]["actions"]

    # ── Storage Account (module.storage) ──────────────────────────────────────

    def test_storage_account_present(self, plan):
        sa = [k for k in plan.resource_changes if "azurerm_storage_account" in k and "module.storage" in k]
        assert len(sa) > 0, "Expected storage account under module.storage"

    def test_storage_account_action_create(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_storage_account" in k and "module.storage" in k)
        assert "create" in plan.resource_changes[key]["change"]["actions"]

    def test_storage_tls_enforced(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_storage_account" in k and "module.storage" in k)
        sa = plan.resource_changes[key]
        assert sa["change"]["after"]["min_tls_version"] == "TLS1_2"

    def test_uploads_container_present(self, plan):
        containers = [k for k in plan.resource_changes if "azurerm_storage_container" in k and "uploads" in k]
        assert len(containers) > 0, "Expected 'uploads' storage container under module.storage"

    def test_backups_container_present(self, plan):
        containers = [k for k in plan.resource_changes if "azurerm_storage_container" in k and "backups" in k]
        assert len(containers) > 0, "Expected 'backups' storage container under module.storage"

    def test_both_containers_action_create(self, plan):
        containers = [
            v for k, v in plan.resource_changes.items()
            if "azurerm_storage_container" in k and "module.storage" in k
        ]
        assert len(containers) >= 2, "Expected at least 2 storage containers under module.storage"
        for c in containers:
            assert "create" in c["change"]["actions"]

    # ── Outputs ───────────────────────────────────────────────────────────────

    def test_all_outputs_declared(self, plan):
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
