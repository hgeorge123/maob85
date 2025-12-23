# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.1] - 2023-05-12

- Allow alias to have dashes for EC2 naming
- Allow alias to be shorter for EC2 naming

## [4.0.0] - 2022-12-20

### Added

- `parent_resource` input argument.

### Changed

- Key policy compose method.
  - Previously: `custom_policy` replaces default key policy.
  - Currently:  `custom_policy` can override or being merged with default key policy, according to `compose_mode` argument in custom_policy.

## [3.0.0] - 2022-05-24

### Added

- Mandatory tags input argument
- Custom tags input argument

### Removed

- cost_center input argument
- channel input argument
- cia input argument
- product input argument
- description input argument  
- tracking_code input argument
- tags input argument

## [2.0.0] - 2022-05-03

### Added

- Descriptive Outputs
- Naming inputs validation

### Changed

- sequence can be declared as a number, being formatted as a 3 digit suffix

## [1.0.0] - 2022-04-29

### Added

- First implementation

### Changed

- First implementation
