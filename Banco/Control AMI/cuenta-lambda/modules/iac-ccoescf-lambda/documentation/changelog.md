# Changelog

## [v3.2.6]

- Added changes for new conventions version

## [v3.2.4]

- Upgrade version (no changes - Terraform Enterprise publishing issue)

## [v3.2.3]

- Upgrade version (no changes - Terraform Enterprise publishing issue)

## [v3.2.2]

- Fix use case with no triggers

## [v3.2.1]

- added 2 variables architectures and ephemeral storage.

## [v3.2.0]

- Add resource aws_lambda_function_url
  - cors supports
- Input parameters added:
  - create_lambda_function_url
  - lambda_function_url_cors
- output parameters added:
  - lambda_function_url
  - lambda_url_id

## [v3.1.0]

- Add support for custom EventBridge triggers
- Input parameters added:
  - triggers
- Fix duplicated filename extension issue

## [v3.0.0]

- Refactor variables SCQCCOE-1383
- Version 3.0.0 for every product
- New version of conventions module (tagging)

## [v2.0.0]

- Refactor variables SCQCCOE-1383

## [v1.4.1]

- Add lambda layer.

## [v1.4.0]

- Add filename_hash variable info, Required kms_key_arn and Add EFS Config

## [v1.3.2]

- Added resource aws_lambda_provisioned_concurrency_config

## [v1.3.1]

- Add source_code_hash attribute and publish

## [v1.3.0]

- Correction module

## [v1.2.0]

- Update main.tf

## [v1.1.0]

- Bugs solved, vpcid included

## [v1.0.3]

- Deleted providers.tf

## [v1.0.2]

- Update main.tf and Delete darwin-lambda-elasticsearch.js

## [v1.0.1]

- Fix bug

## [v1.0.0]

- First version
