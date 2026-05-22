"""
End-to-end tests for non-prod/mvp-app.

Applies real infrastructure, validates it via Azure management SDK, then
destroys everything in the fixture teardown.

Prerequisites:
    pip install -r tests/requirements.txt

    The following environment variables must be set before running:
        AZURE_CLIENT_ID      — service-principal app ID
        AZURE_CLIENT_SECRET  — service-principal secret
        AZURE_TENANT_ID      — Azure AD tenant ID
        TF_VAR_mysql_admin_password — MySQL admin password

Run:
    pytest -v tests/test_mvp_app_e2e.py
"""

from pathlib import Path

import pytest
import tftest
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.rdbms.mysql_flexibleservers import MySQLManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.web import WebSiteManagementClient

DIRECTORY = Path(__file__).parent.parent
TF_VARS_FILE = str(Path(__file__).parent / "fixtures" / "terraform.tfvars")


def _subscription_id(vnet_id: str) -> str:
    return vnet_id.split("/")[2]


def _resource_group(vnet_id: str) -> str:
    return vnet_id.split("/")[4]


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def output():
    tf = tftest.TerraformTest(DIRECTORY)
    tf.setup(cleanup_on_exit=False)
    try:
        tf.apply(output=True, tf_var_file=TF_VARS_FILE)
        yield tf.output()
    finally:
        tf.destroy(auto_approve=True, tf_var_file=TF_VARS_FILE)


@pytest.fixture(scope="module")
def credential():
    return DefaultAzureCredential()


@pytest.fixture(scope="module")
def sub_id(output):
    return _subscription_id(output["vnet_id"])


@pytest.fixture(scope="module")
def rg(output):
    return _resource_group(output["vnet_id"])


# ── VNet ──────────────────────────────────────────────────────────────────────

def test_vnet_exists(output, credential, sub_id, rg):
    nmc = NetworkManagementClient(credential, sub_id)
    vnet_name = output["vnet_id"].split("/")[-1]
    vnet = nmc.virtual_networks.get(rg, vnet_name)
    assert vnet is not None


def test_vnet_has_app_and_data_subnets(output, credential, sub_id, rg):
    nmc = NetworkManagementClient(credential, sub_id)
    vnet_name = output["vnet_id"].split("/")[-1]
    vnet = nmc.virtual_networks.get(rg, vnet_name, expand="subnets")
    subnet_names = [s.name for s in vnet.subnets]
    assert any("app" in n for n in subnet_names), f"No app subnet found in {subnet_names}"
    assert any("data" in n for n in subnet_names), f"No data subnet found in {subnet_names}"


def test_app_subnet_has_web_delegation(output, credential, sub_id, rg):
    nmc = NetworkManagementClient(credential, sub_id)
    vnet_name = output["vnet_id"].split("/")[-1]
    vnet = nmc.virtual_networks.get(rg, vnet_name, expand="subnets")
    app_subnet = next(s for s in vnet.subnets if "app" in s.name)
    delegation_services = [d.service_name for d in (app_subnet.delegations or [])]
    assert "Microsoft.Web/serverFarms" in delegation_services


def test_data_subnet_has_mysql_delegation(output, credential, sub_id, rg):
    nmc = NetworkManagementClient(credential, sub_id)
    vnet_name = output["vnet_id"].split("/")[-1]
    vnet = nmc.virtual_networks.get(rg, vnet_name, expand="subnets")
    data_subnet = next(s for s in vnet.subnets if "data" in s.name)
    delegation_services = [d.service_name for d in (data_subnet.delegations or [])]
    assert "Microsoft.DBforMySQL/flexibleServers" in delegation_services


# ── App Service ───────────────────────────────────────────────────────────────

def test_app_service_exists(output, credential, sub_id, rg):
    wmc = WebSiteManagementClient(credential, sub_id)
    app_name = output["app_service_hostname"].split(".")[0]
    app = wmc.web_apps.get(rg, app_name)
    assert app is not None


def test_app_service_running(output, credential, sub_id, rg):
    wmc = WebSiteManagementClient(credential, sub_id)
    app_name = output["app_service_hostname"].split(".")[0]
    app = wmc.web_apps.get(rg, app_name)
    assert app.state == "Running"


def test_app_service_is_linux(output, credential, sub_id, rg):
    wmc = WebSiteManagementClient(credential, sub_id)
    app_name = output["app_service_hostname"].split(".")[0]
    app = wmc.web_apps.get(rg, app_name)
    assert app.kind and "linux" in app.kind.lower()


def test_app_service_vnet_integrated(output, credential, sub_id, rg):
    wmc = WebSiteManagementClient(credential, sub_id)
    app_name = output["app_service_hostname"].split(".")[0]
    connections = list(wmc.web_apps.list_virtual_network_connections(rg, app_name))
    assert len(connections) > 0, "App Service must be VNet-integrated"


# ── MySQL Flexible Server ─────────────────────────────────────────────────────

def test_mysql_server_exists(output, credential, sub_id, rg):
    mysql_client = MySQLManagementClient(credential, sub_id)
    server = mysql_client.servers.get(rg, output["mysql_server_name"])
    assert server is not None


def test_mysql_server_ready(output, credential, sub_id, rg):
    mysql_client = MySQLManagementClient(credential, sub_id)
    server = mysql_client.servers.get(rg, output["mysql_server_name"])
    assert server.state == "Ready"


def test_mysql_fqdn(output, credential, sub_id, rg):
    mysql_client = MySQLManagementClient(credential, sub_id)
    server = mysql_client.servers.get(rg, output["mysql_server_name"])
    assert server.fully_qualified_domain_name == output["mysql_server_fqdn"]


def test_mysql_appdb_database_exists(output, credential, sub_id, rg):
    mysql_client = MySQLManagementClient(credential, sub_id)
    db = mysql_client.databases.get(rg, output["mysql_server_name"], "appdb")
    assert db is not None


def test_mysql_appdb_charset(output, credential, sub_id, rg):
    mysql_client = MySQLManagementClient(credential, sub_id)
    db = mysql_client.databases.get(rg, output["mysql_server_name"], "appdb")
    assert db.charset == "utf8mb4"


# ── Storage Account ───────────────────────────────────────────────────────────

def test_storage_account_exists(output, credential, sub_id, rg):
    smc = StorageManagementClient(credential, sub_id)
    sa = smc.storage_accounts.get_properties(rg, output["storage_account_name"])
    assert sa is not None


def test_storage_blob_endpoint_matches_output(output, credential, sub_id, rg):
    smc = StorageManagementClient(credential, sub_id)
    sa = smc.storage_accounts.get_properties(rg, output["storage_account_name"])
    assert sa.primary_endpoints.blob.rstrip("/") == output["storage_blob_endpoint"].rstrip("/")


def test_uploads_container_exists(output, credential, sub_id, rg):
    smc = StorageManagementClient(credential, sub_id)
    container = smc.blob_containers.get(rg, output["storage_account_name"], "uploads")
    assert container is not None


def test_backups_container_exists(output, credential, sub_id, rg):
    smc = StorageManagementClient(credential, sub_id)
    container = smc.blob_containers.get(rg, output["storage_account_name"], "backups")
    assert container is not None


def test_containers_are_private(output, credential, sub_id, rg):
    smc = StorageManagementClient(credential, sub_id)
    for name in ("uploads", "backups"):
        container = smc.blob_containers.get(rg, output["storage_account_name"], name)
        assert container.public_access in (None, "None"), f"Container '{name}' must be private"
