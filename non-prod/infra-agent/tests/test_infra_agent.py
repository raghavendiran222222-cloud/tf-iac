"""
Pytest / python-tftest smoke tests for non-prod/infra-agent.

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
class TestInfraAgentModule:
    """Plan-level validation for non-prod/infra-agent."""

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

    # ── Resource Group ────────────────────────────────────────────────────────

    def test_resource_group_present(self, plan):
        assert "azurerm_resource_group.main" in plan.resource_changes

    def test_resource_group_action_create(self, plan):
        rg = plan.resource_changes["azurerm_resource_group.main"]
        assert "create" in rg["change"]["actions"]

    # ── Networking ────────────────────────────────────────────────────────────

    def test_vnet_present(self, plan):
        vnet = [k for k in plan.resource_changes if "azurerm_virtual_network" in k and "module.vnet" in k]
        assert len(vnet) > 0, "Expected VNet resource under module.vnet"

    def test_nsg_container_apps_present(self, plan):
        assert "azurerm_network_security_group.container_apps" in plan.resource_changes

    def test_nsg_container_apps_action_create(self, plan):
        nsg = plan.resource_changes["azurerm_network_security_group.container_apps"]
        assert "create" in nsg["change"]["actions"]

    def test_nsg_apim_present(self, plan):
        assert "azurerm_network_security_group.apim" in plan.resource_changes

    def test_nsg_apim_action_create(self, plan):
        nsg = plan.resource_changes["azurerm_network_security_group.apim"]
        assert "create" in nsg["change"]["actions"]

    # ── Managed Identity ──────────────────────────────────────────────────────

    def test_uami_present(self, plan):
        uami = [k for k in plan.resource_changes if "azurerm_user_assigned_identity" in k and "module.uami" in k]
        assert len(uami) > 0, "Expected UAMI resource under module.uami"

    def test_uami_action_create(self, plan):
        key = next(k for k in plan.resource_changes if "azurerm_user_assigned_identity" in k and "module.uami" in k)
        assert "create" in plan.resource_changes[key]["change"]["actions"]

    # ── Key Vault ─────────────────────────────────────────────────────────────

    def test_key_vault_present(self, plan):
        kv = [k for k in plan.resource_changes if "azurerm_key_vault" in k and "module.key_vault" in k and "secret" not in k]
        assert len(kv) > 0, "Expected Key Vault resource under module.key_vault"

    def test_github_pat_secret_present(self, plan):
        assert "azurerm_key_vault_secret.github_pat" in plan.resource_changes

    def test_github_pat_secret_name(self, plan):
        secret = plan.resource_changes["azurerm_key_vault_secret.github_pat"]
        assert secret["change"]["after"]["name"] == "github-pat"

    def test_hcp_terraform_token_secret_present(self, plan):
        assert "azurerm_key_vault_secret.hcp_terraform_token" in plan.resource_changes

    def test_hcp_terraform_token_secret_name(self, plan):
        secret = plan.resource_changes["azurerm_key_vault_secret.hcp_terraform_token"]
        assert secret["change"]["after"]["name"] == "hcp-terraform-token"

    # ── Log Analytics ─────────────────────────────────────────────────────────

    def test_log_analytics_present(self, plan):
        law = [k for k in plan.resource_changes if "azurerm_log_analytics_workspace" in k and "module.log_analytics" in k]
        assert len(law) > 0, "Expected Log Analytics Workspace under module.log_analytics"

    # ── Container Apps Environment ────────────────────────────────────────────

    def test_container_apps_environment_present(self, plan):
        cae = [k for k in plan.resource_changes if "azurerm_container_app_environment" in k and "module.container_apps_environment" in k]
        assert len(cae) > 0, "Expected Container Apps Environment under module.container_apps_environment"

    # ── MCP Container Apps ────────────────────────────────────────────────────

    def test_mcp_github_container_app_present(self, plan):
        app = [k for k in plan.resource_changes if "azurerm_container_app" in k and "module.mcp_github" in k]
        assert len(app) > 0, "Expected GitHub MCP Container App under module.mcp_github"

    def test_mcp_azure_container_app_present(self, plan):
        app = [k for k in plan.resource_changes if "azurerm_container_app" in k and "module.mcp_azure" in k]
        assert len(app) > 0, "Expected Azure MCP Container App under module.mcp_azure"

    def test_mcp_terraform_container_app_present(self, plan):
        app = [k for k in plan.resource_changes if "azurerm_container_app" in k and "module.mcp_terraform" in k]
        assert len(app) > 0, "Expected Terraform MCP Container App under module.mcp_terraform"

    def test_all_three_mcp_apps_action_create(self, plan):
        mcp_apps = [
            v for k, v in plan.resource_changes.items()
            if "azurerm_container_app" in k
            and any(m in k for m in ["module.mcp_github", "module.mcp_azure", "module.mcp_terraform"])
        ]
        assert len(mcp_apps) == 3, "Expected exactly 3 MCP Container Apps"
        for app in mcp_apps:
            assert "create" in app["change"]["actions"]

    # ── Role Assignment ───────────────────────────────────────────────────────

    def test_azure_mcp_reader_role_assignment_present(self, plan):
        assert "azurerm_role_assignment.azure_mcp_reader" in plan.resource_changes

    def test_azure_mcp_reader_role_assignment_action_create(self, plan):
        ra = plan.resource_changes["azurerm_role_assignment.azure_mcp_reader"]
        assert "create" in ra["change"]["actions"]

    # ── Azure AD App Registration ─────────────────────────────────────────────

    def test_copilot_studio_app_registration_present(self, plan):
        assert "azuread_application.copilot_studio" in plan.resource_changes

    def test_copilot_studio_app_registration_action_create(self, plan):
        app = plan.resource_changes["azuread_application.copilot_studio"]
        assert "create" in app["change"]["actions"]

    def test_copilot_studio_service_principal_present(self, plan):
        assert "azuread_service_principal.copilot_studio" in plan.resource_changes

    # ── APIM ─────────────────────────────────────────────────────────────────

    def test_apim_present(self, plan):
        apim = [k for k in plan.resource_changes if "azurerm_api_management" in k and "module.apim" in k and "backend" not in k and "api" not in k and "product" not in k and "policy" not in k]
        assert len(apim) > 0, "Expected API Management resource under module.apim"

    def test_apim_global_policy_present(self, plan):
        assert "azurerm_api_management_policy.global" in plan.resource_changes

    def test_apim_global_policy_action_create(self, plan):
        policy = plan.resource_changes["azurerm_api_management_policy.global"]
        assert "create" in policy["change"]["actions"]

    def test_apim_backends_all_present(self, plan):
        for backend in ["azurerm_api_management_backend.github", "azurerm_api_management_backend.azure", "azurerm_api_management_backend.terraform"]:
            assert backend in plan.resource_changes, f"Expected APIM backend: {backend}"

    def test_apim_backends_tls_certificate_chain_validated(self, plan):
        for backend_key in ["azurerm_api_management_backend.github", "azurerm_api_management_backend.azure", "azurerm_api_management_backend.terraform"]:
            b = plan.resource_changes[backend_key]
            tls = b["change"]["after"].get("tls", [])
            assert tls and tls[0]["validate_certificate_chain"] is True, (
                f"{backend_key} must have TLS certificate chain validation enabled"
            )

    def test_apim_backends_tls_certificate_name_validated(self, plan):
        for backend_key in ["azurerm_api_management_backend.github", "azurerm_api_management_backend.azure", "azurerm_api_management_backend.terraform"]:
            b = plan.resource_changes[backend_key]
            tls = b["change"]["after"].get("tls", [])
            assert tls and tls[0]["validate_certificate_name"] is True, (
                f"{backend_key} must have TLS certificate name validation enabled"
            )

    def test_apim_apis_all_present(self, plan):
        for api_key in ['azurerm_api_management_api.mcp["github"]', 'azurerm_api_management_api.mcp["azure"]', 'azurerm_api_management_api.mcp["terraform"]']:
            assert api_key in plan.resource_changes, f"Expected APIM API: {api_key}"

    def test_apim_apis_https_only(self, plan):
        for api_key in ['azurerm_api_management_api.mcp["github"]', 'azurerm_api_management_api.mcp["azure"]', 'azurerm_api_management_api.mcp["terraform"]']:
            api = plan.resource_changes[api_key]
            protocols = api["change"]["after"].get("protocols", [])
            assert protocols == ["https"], f"{api_key} must use HTTPS only"

    def test_apim_product_present(self, plan):
        assert "azurerm_api_management_product.mcp" in plan.resource_changes

    def test_apim_product_published(self, plan):
        product = plan.resource_changes["azurerm_api_management_product.mcp"]
        assert product["change"]["after"]["published"] is True

    def test_apim_product_no_subscription_required(self, plan):
        product = plan.resource_changes["azurerm_api_management_product.mcp"]
        assert product["change"]["after"]["subscription_required"] is False

    def test_apim_diagnostics_present(self, plan):
        assert "azurerm_monitor_diagnostic_setting.apim" in plan.resource_changes

    # ── Outputs ───────────────────────────────────────────────────────────────

    def test_all_outputs_declared(self, plan):
        expected = {
            "resource_group_name",
            "apim_gateway_url",
            "apim_portal_url",
            "mcp_api_endpoints",
            "copilot_studio_app_client_id",
            "copilot_studio_oauth_token_url",
            "key_vault_uri",
            "managed_identity_client_id",
            "container_apps_environment_id",
        }
        missing = expected - set(plan.outputs.keys())
        assert not missing, f"Missing outputs: {missing}"
