#!/usr/bin/env bash
set -euo pipefail

# Detects changed directories and outputs a JSON array for a GitHub Actions matrix.
#
# Required env vars:
#   PATTERN       grep regex applied to changed file paths   (e.g. '^[^/]+-module/')
#   FIELD         awk field to extract as the directory name (e.g. 1 for root, 2 for non-prod/<app>)
#
# Optional env vars:
#   PREFIX        directory prefix for existence check        (e.g. 'non-prod' → checks non-prod/<dir>)
#   REQUIRE_TESTS set to 'true' to skip dirs without tests/  (default: false)

: "${PATTERN:?PATTERN env var is required}"
: "${FIELD:?FIELD env var is required}"
PREFIX="${PREFIX:-}"
REQUIRE_TESTS="${REQUIRE_TESTS:-false}"

base="${GITHUB_BASE_REF:-}"

if [[ -n "$base" ]]; then
  # PR: diff only the commits introduced by this PR.
  git fetch origin "$base" --depth=50
  merge_base=$(git merge-base "origin/$base" HEAD)
  changed_files=$(git diff --name-only "$merge_base"...HEAD) || true

elif git rev-parse HEAD^ >/dev/null 2>&1; then
  # Push to main: only files in this commit.
  changed_files=$(git diff --name-only HEAD^ HEAD) || true

else
  # Initial commit: discover all matching top-level dirs.
  if [[ -n "$PREFIX" ]]; then
    changed_files=$(find "$PREFIX" -maxdepth 2 -mindepth 2 -type f | head -200) || true
  else
    changed_files=$(find . -maxdepth 2 -mindepth 2 -type f \
      | sed 's|^\./||' | grep -E "${PATTERN}" | head -200) || true
  fi
fi

# Extract unique directory names from the changed file list.
raw_dirs=$(printf '%s\n' "${changed_files:-}" \
  | grep -E "${PATTERN}" \
  | awk -F/ "{print \$$FIELD}" \
  | sort -u) || true

# Apply existence and optional tests/ filter.
filtered=()
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue

  full_path="${PREFIX:+$PREFIX/}$dir"
  [[ -d "$full_path" ]] || continue

  if [[ "$REQUIRE_TESTS" == "true" ]] && [[ ! -d "$full_path/tests" ]]; then
    continue
  fi

  filtered+=("$dir")
done <<< "$raw_dirs"

if [[ ${#filtered[@]} -eq 0 ]]; then
  echo "changed=[]"
else
  json=$(printf '%s\n' "${filtered[@]}" | jq -R . | jq -s -c .)
  echo "changed=${json}"
fi
