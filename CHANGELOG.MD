# Changelog

## [1.0.0] - 2026-05-08

### Added
- Initial release of MySQL scratch module using raw `azurerm_mysql_flexible_server`
- MySQL Flexible Server resource with configurable SKU, version, and storage
- Multiple database provisioning via `databases` map variable
- Optional VNet integration via `delegated_subnet_id` and `private_dns_zone_id`
- Optional CanNotDelete resource lock
- Zone-redundancy drift protection via lifecycle `ignore_changes`
- Basic usage example with 2 databases
- 6 plan-only pytest tests
- Complete documentation
