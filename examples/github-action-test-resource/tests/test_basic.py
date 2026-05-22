"""Plan-level tests — no real Azure resources deployed."""

import json
import os
import subprocess

WORKING_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def _run(cmd, **kwargs):
    return subprocess.run(cmd, cwd=WORKING_DIR, capture_output=True, text=True, **kwargs)


def test_validate_passes():
    r = _run(["terraform", "validate", "-json"])
    data = json.loads(r.stdout)
    assert data["valid"], data.get("diagnostics", [])


def test_all_variables_have_defaults():
    r = _run(["terraform", "show", "-json"])
    r2 = _run(["terraform", "plan", "-input=false", "-no-color"])
    assert "No value for required variable" not in r2.stderr


def test_plan_targets_resource_group():
    r = _run(["terraform", "plan", "-input=false", "-no-color"])
    assert r.returncode == 0, r.stderr
    assert "azurerm_resource_group.this" in r.stdout


def test_plan_no_destructive_changes():
    r = _run(["terraform", "plan", "-input=false", "-no-color"])
    assert r.returncode == 0, r.stderr
    # Fresh plan must not plan any destroys (nothing exists yet)
    assert " 0 to destroy" in r.stdout or "No changes" in r.stdout
