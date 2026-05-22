"""End-to-end tests — deploys real Azure infrastructure and destroys it after."""

import json
import os
import subprocess

import pytest

WORKING_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def _run(cmd, check=True):
    return subprocess.run(cmd, cwd=WORKING_DIR, capture_output=True, text=True, check=check)


@pytest.fixture(scope="module", autouse=True)
def deployed():
    _run(["terraform", "init", "-input=false"])
    _run(["terraform", "apply", "-input=false", "-auto-approve"])
    yield
    _run(["terraform", "destroy", "-input=false", "-auto-approve"])


def _outputs() -> dict:
    r = _run(["terraform", "output", "-json"])
    return json.loads(r.stdout)


def test_resource_group_output_exists():
    outputs = _outputs()
    assert "resource_group_name" in outputs
    assert outputs["resource_group_name"]["value"] != ""


def test_resource_group_id_output_exists():
    outputs = _outputs()
    assert "resource_group_id" in outputs
    assert outputs["resource_group_id"]["value"].startswith("/subscriptions/")


def test_resource_group_exists_in_azure():
    rg_name = _outputs()["resource_group_name"]["value"]
    r = subprocess.run(
        ["az", "group", "show", "--name", rg_name, "--output", "json"],
        capture_output=True,
        text=True,
    )
    assert r.returncode == 0, f"Resource group '{rg_name}' not found in Azure:\n{r.stderr}"
    data = json.loads(r.stdout)
    assert data["properties"]["provisioningState"] == "Succeeded"


def test_resource_group_tags():
    rg_name = _outputs()["resource_group_name"]["value"]
    r = subprocess.run(
        ["az", "group", "show", "--name", rg_name, "--output", "json"],
        capture_output=True,
        text=True,
        check=True,
    )
    tags = json.loads(r.stdout).get("tags", {})
    assert tags.get("managed-by") == "terraform"
    assert tags.get("purpose") == "github-actions-testing"
