# Changelog

## [1.0.0] - 2026-04-28

### Added
- Initial release of `tf-iac-storage-module`
- `azurerm_storage_account` with TLS 1.2 enforced (`min_tls_version = "TLS1_2"`)
- `azurerm_storage_container` — one or more blob containers via `for_each`
- Optional blob versioning via `enable_versioning`
- `storage` variable defaults to `null` — module is a no-op when omitted
- `locals.tf` with `storage_enabled` guard
- All outputs use `try(..., null)` for safe no-op behaviour; connection string marked sensitive
- `examples/basic` reference usage
- `tests/` pytest + tftest plan-level test suite
