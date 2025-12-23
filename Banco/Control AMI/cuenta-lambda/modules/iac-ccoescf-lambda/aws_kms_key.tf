locals {
  is_kms_key_arn_given = var.kms_key_arn != null && var.kms_key_arn != ""
  kms_key_arn          = local.is_kms_key_arn_given ? data.aws_kms_key.given_kms_key.0.key_id : module.aws_kms_key.0.kms_arn
}

data "aws_kms_key" "given_kms_key" {
  count  = local.is_kms_key_arn_given ? 1 : 0
  key_id = var.kms_key_arn
}

module "aws_kms_key" {
  #source = "github.com/santander-group-scfccoe/terraform-aws-iac-ccoescf-kms"
  source = "./santander-group-scfccoe/terraform-aws-iac-ccoescf-kms"

  count = local.is_kms_key_arn_given ? 0 : 1

  # AWS TAGGING
  mandatory_tags = merge(
    var.mandatory_tags, {
      description = "KMS Key for Lambda ${local.naming}"
    }
  )

  # AWS NAMING
  entity      = var.entity
  environment = var.environment
  app_name    = var.app_name
  function    = "lamb"
  sequence    = var.sequence
}
