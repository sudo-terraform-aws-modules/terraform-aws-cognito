# Changelog

All notable changes to this module are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the module uses [Semantic Versioning](https://semver.org/).

## [1.0.1] - 2026-10-15

### Fixed

- `username_case_sensitive = null` now leaves `username_configuration` out, so a pool created without it can be adopted without being replaced.
- README badges sit on one line on the Terraform Registry instead of stacking.

## [1.0.0] - 2026-10-15

### Added

- Cognito user pool with secure defaults: admin-only sign-up, required MFA, 14-character passwords, deletion protection and attribute verification before update.
- User pool domain with managed login or the classic hosted UI, including hosted UI customisation and per-client managed login branding.
- App clients, OAuth resource servers, user groups, federated identity providers and bootstrap users.
- Threat protection settings and risk configuration for the PLUS tier.
- Log delivery to CloudWatch Logs, S3 or Firehose.
- Optional identity pool with role attachment and role mappings.
- Minimal and complete examples, and unit tests against a mock provider.

[1.0.1]: https://github.com/sudo-terraform-aws-modules/terraform-aws-cognito/releases/tag/v1.0.1
[1.0.0]: https://github.com/sudo-terraform-aws-modules/terraform-aws-cognito/releases/tag/v1.0.0
