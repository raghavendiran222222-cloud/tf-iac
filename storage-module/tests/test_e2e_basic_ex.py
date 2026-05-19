"""
End-to-end tests for tf-iac-storage-module using examples/basic.

Applies real infrastructure, validates it via the Azure SDK, then destroys it.

Prerequisites:
    pip install -r tests/requirements.txt
    az login  (or set ARM_* env vars for service principal auth)
    export ARM_SUBSCRIPTION_ID=<your-subscription-id>

Run:
    pytest tests/test_e2e_basic_ex.py -v -s
"""

import os
import pytest
import tftest
from pathlib import Path
from azure.identity import DefaultAzureCredential
from azure.mgmt.storage import StorageManagementClient

_DIRECTORY = Path(__file__).parent.parent / "examples" / "basic"
_TF_VARS_FILE = "terraform.tfvars"
_RESOURCE_GROUP = "rg-bdt-terraform-dev-eus2-001"


def _storage_client():
    subscription_id = os.environ.get("ARM_SUBSCRIPTION_ID")
    if not subscription_id:
        pytest.skip("ARM_SUBSCRIPTION_ID env var not set")
    return StorageManagementClient(DefaultAzureCredential(), subscription_id)


@pytest.fixture(scope="module")
def output():
    tf = tftest.TerraformTest(str(_DIRECTORY))
    tf.setup()
    try:
        tf.apply(output=True, tf_var_file=_TF_VARS_FILE)
        yield tf.output()
    finally:
        tf.destroy(auto_approve=True, tf_var_file=_TF_VARS_FILE)


# ── Storage Account ───────────────────────────────────────────────────────────

def test_storage_account_exists(output):
    account = _storage_client().storage_accounts.get_properties(_RESOURCE_GROUP, output["storage_account_name"])
    assert account is not None


def test_storage_account_tls_enforced(output):
    account = _storage_client().storage_accounts.get_properties(_RESOURCE_GROUP, output["storage_account_name"])
    assert account.minimum_tls_version == "TLS1_2"


def test_storage_account_tier_standard(output):
    account = _storage_client().storage_accounts.get_properties(_RESOURCE_GROUP, output["storage_account_name"])
    assert account.sku.tier == "Standard"


def test_storage_account_replication_lrs(output):
    account = _storage_client().storage_accounts.get_properties(_RESOURCE_GROUP, output["storage_account_name"])
    assert "LRS" in account.sku.name


def test_storage_account_versioning_disabled(output):
    props = _storage_client().blob_services.get_service_properties(_RESOURCE_GROUP, output["storage_account_name"])
    assert props.is_versioning_enabled is False


# ── Blob Container ────────────────────────────────────────────────────────────

def test_uploads_container_exists(output):
    container = _storage_client().blob_containers.get(_RESOURCE_GROUP, output["storage_account_name"], "uploads")
    assert container is not None


def test_uploads_container_access_private(output):
    container = _storage_client().blob_containers.get(_RESOURCE_GROUP, output["storage_account_name"], "uploads")
    assert container.public_access in (None, "None")
