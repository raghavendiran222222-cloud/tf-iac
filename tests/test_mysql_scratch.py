"""
Plan-only tests for the mysql-scratch module using pytest + tftest.

Prerequisites:
    pip install pytest tftest==1.8.7

Required environment variables (real Azure credentials):
    ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_TENANT_ID
    (ARM_CLIENT_SECRET for SPN, or Azure CLI login)

Run:
    pytest tests/ -v
"""

import os
import pytest
import tftest

EXAMPLES_BASIC = os.path.join(os.path.dirname(__file__), "..", "examples", "basic")

APPROVED_LOCATIONS = {"eastus2", "centralus", "eastus", "westus2", "westeurope", "northeurope"}
REQUIRED_TAGS = {"Application", "Owner", "Environment", "CostCenter"}

_CRED_VARS = {"ARM_SUBSCRIPTION_ID", "ARM_CLIENT_ID", "ARM_TENANT_ID"}
_has_credentials = _CRED_VARS.issubset(os.environ)

requires_credentials = pytest.mark.skipif(
    not _has_credentials,
    reason=f"Set {_CRED_VARS} to run integration tests",
)


@pytest.fixture(scope="module")
def plan():
    if not _has_credentials:
        pytest.skip(f"Set {_CRED_VARS} to run integration tests")

    extra_vars = {"subscription_id": os.environ["ARM_SUBSCRIPTION_ID"]}

    tf = tftest.TerraformTest(EXAMPLES_BASIC)
    tf.setup(use_cache=False, extra_vars=extra_vars)
    return tf.plan(output=True)


@requires_credentials
def test_mysql_server_is_planned(plan):
    """MySQL Flexible Server must be planned."""
    server_resources = [
        k for k in plan.resource_changes
        if "mysql_flexible_server" in k.lower() and "database" not in k.lower()
    ]
    assert len(server_resources) >= 1, (
        f"Expected at least one MySQL Flexible Server resource, found: {list(plan.resource_changes.keys())}"
    )


@requires_credentials
def test_databases_are_planned(plan):
    """Basic example must plan 2 databases (appdb and logdb)."""
    db_resources = [
        k for k in plan.resource_changes
        if "mysql_flexible_database" in k.lower()
    ]
    assert len(db_resources) == 2, (
        f"Expected 2 database resources, found {len(db_resources)}: {db_resources}"
    )


@requires_credentials
def test_no_resource_lock_in_basic(plan):
    """Basic example sets enable_resource_lock=false — no lock resource should appear."""
    lock_resources = [
        k for k in plan.resource_changes
        if "management_lock" in k.lower()
    ]
    assert len(lock_resources) == 0, (
        f"Expected no resource locks in basic example, found: {lock_resources}"
    )


@requires_credentials
def test_required_tags_present(plan):
    """MySQL Flexible Server must carry all required tags."""
    server_key = next(
        (k for k in plan.resource_changes
         if "mysql_flexible_server" in k.lower() and "database" not in k.lower()),
        None,
    )
    assert server_key is not None, "No MySQL Flexible Server resource found in plan"

    change = plan.resource_changes[server_key]
    planned_tags = change.get("change", {}).get("after", {}).get("tags", {}) or {}
    missing = REQUIRED_TAGS - set(planned_tags.keys())
    assert not missing, (
        f"Missing required tags on MySQL server: {missing}. Found: {set(planned_tags.keys())}"
    )


@requires_credentials
def test_location_is_valid(plan):
    """MySQL Flexible Server must be planned in an approved region."""
    server_key = next(
        (k for k in plan.resource_changes
         if "mysql_flexible_server" in k.lower() and "database" not in k.lower()),
        None,
    )
    assert server_key is not None, "No MySQL Flexible Server resource found in plan"

    change = plan.resource_changes[server_key]
    location = change.get("change", {}).get("after", {}).get("location", "")
    assert location in APPROVED_LOCATIONS, (
        f"MySQL server location '{location}' is not in approved list: {APPROVED_LOCATIONS}"
    )


@requires_credentials
def test_no_telemetry_resources(plan):
    """No telemetry resources should be planned (scratch module, no AVM telemetry)."""
    telemetry_resources = [
        k for k in plan.resource_changes
        if "telemetry" in k.lower()
    ]
    assert len(telemetry_resources) == 0, (
        f"Unexpected telemetry resources found: {telemetry_resources}"
    )
