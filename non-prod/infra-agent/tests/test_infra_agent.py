"""
Pytest / python-tftest smoke tests for non-prod/infra-agent.

Prerequisites:
    pip install pytest python-tftest

Run:
    pytest -v tests/
"""

import pytest

try:
    import tftest
    TFTEST_AVAILABLE = True
except ImportError:
    TFTEST_AVAILABLE = False


@pytest.mark.skipif(not TFTEST_AVAILABLE, reason="python-tftest not installed")
class TestInfraAgentModule:
    """Basic Terraform plan-level validation tests."""

    @pytest.fixture(scope="class")
    def plan(self):
        tf = tftest.TerraformTest(
            tfdir=".",
            basedir="..",
            env={
                "TF_CLI_ARGS_init": "-backend=false",
            },
        )
        tf.setup(extra_files=["tests/fixtures/terraform.tfvars"])
        yield tf.plan(output=True)
        tf.teardown()

    def test_plan_succeeds(self, plan):
        assert plan is not None

    def test_resource_group_present(self, plan):
        assert "azurerm_resource_group.main" in plan.resource_changes

    def test_apim_present(self, plan):
        apim_resources = [
            k for k in plan.resource_changes if "apim" in k.lower()
        ]
        assert len(apim_resources) > 0, "Expected at least one APIM resource"

    def test_container_apps_present(self, plan):
        ca_resources = [
            k for k in plan.resource_changes if "container_app" in k.lower()
        ]
        assert len(ca_resources) >= 3, "Expected at least 3 Container App resources"
