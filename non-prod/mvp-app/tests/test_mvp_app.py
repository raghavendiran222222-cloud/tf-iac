"""
Pytest / python-tftest smoke tests for non-prod/mvp-app.

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
class TestMvpAppModule:
    """Basic Terraform plan-level validation tests."""

    @pytest.fixture(scope="class")
    def plan(self):
        tf = tftest.TerraformTest(
            tfdir=".",
            basedir="..",
            env={
                "TF_CLI_ARGS_init": "-backend=false",
                "TF_VAR_mysql_admin_password": "TestPassword123!",
            },
        )
        tf.setup(extra_files=["tests/fixtures/terraform.tfvars"])
        yield tf.plan(output=True)
        tf.teardown()

    def test_plan_succeeds(self, plan):
        assert plan is not None

    def test_vnet_present(self, plan):
        vnet_resources = [
            k for k in plan.resource_changes if "vnet" in k.lower()
        ]
        assert len(vnet_resources) > 0, "Expected at least one VNet resource"

    def test_app_service_present(self, plan):
        app_resources = [
            k for k in plan.resource_changes if "app_service" in k.lower()
        ]
        assert len(app_resources) > 0, "Expected App Service resources"

    def test_mysql_present(self, plan):
        mysql_resources = [
            k for k in plan.resource_changes if "mysql" in k.lower()
        ]
        assert len(mysql_resources) > 0, "Expected MySQL resources"

    def test_storage_present(self, plan):
        storage_resources = [
            k for k in plan.resource_changes if "storage" in k.lower()
        ]
        assert len(storage_resources) > 0, "Expected storage resources"
