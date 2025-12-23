output "kms_alias_prefix" {
  description = "In the AWS KMS API, the alias name is always prefixed by `alias/`. That prefix is omitted in the AWS KMS console."
  value       = local.alias_prefix
}

output "artifact_acronym" {
  description = "Acronym of the curated module product."
  value       = local.convention_inputs.artifact_acronym
}

output "kms_id" {
  description = "ID of the KMS created"
  value       = aws_kms_key.this.key_id
}
output "kms_arn" {
  description = "arn of the KMS created"
  value       = aws_kms_key.this.arn
}

output "kms_name" {
  description = "Unique name of the KMS (present in tags)"
  value       = local.product_name
}

output "kms_alias_arn" {
  description = "Alias arn of the KMS"
  value       = aws_kms_alias.this.arn
}

output "kms_alias_name" {
  description = "Alias name of the KMS. Useful to retrieve KMS data source."
  value       = aws_kms_alias.this.name
}

output "kms_policy_document" {
  description = "JSON formatted KMS policy document applied to product key."
  value       = aws_kms_key.this.policy
}
