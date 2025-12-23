data "aws_caller_identity" "current" {}

locals {
  convention_inputs = {
    #---------------------------------------
    # GLOBAL NAMING CONVENTION
    #---------------------------------------
    entity           = var.entity
    environment      = var.environment
    artifact_acronym = "kms" # (K)ey (M)anagement (S)ervice
    app_name         = var.app_name
    function         = var.function
    sequence         = var.sequence
    parent_resource  = var.parent_resource

    #---------------------------------------
    # GLOBAL TAGGING CONVENTION
    #---------------------------------------
    mandatory_tags = merge(
      var.mandatory_tags,
      {
        # AWS TAGGING - ALM
        artifact_version = jsondecode(file("${path.module}/version.json")).version
        artifact_name    = "KMS" # (K)ey (M)anagement (S)ervice
        cloud_version    = "N/A"
      }
    )

    custom_tags = var.custom_tags
  }
}

module "conventions" {
  #source = "github.com/santander-group-scfccoe/terraform-aws-iac-ccoescf-conventions"
  source = "../terraform-aws-iac-ccoescf-conventions"


  # AWS TAGGING
  mandatory_tags = local.convention_inputs.mandatory_tags
  custom_tags    = local.convention_inputs.custom_tags

  # AWS NAMING
  entity           = local.convention_inputs.entity
  environment      = local.convention_inputs.environment
  artifact_acronym = local.convention_inputs.artifact_acronym
  app_name         = local.convention_inputs.app_name
  function         = local.convention_inputs.function
  sequence         = local.convention_inputs.sequence
  parent_resource  = local.convention_inputs.parent_resource
}


locals {
  alias_prefix = "alias/"
  product_name = trimprefix(coalesce(var.alias_name, module.conventions.product_name), local.alias_prefix)

  aws_region = module.conventions.aws_region

  tags = merge(
    module.conventions.tags,
    {
      Name = local.product_name
    }
  )

  policy_values = {
    account_id = data.aws_caller_identity.current.account_id
    region     = local.aws_region
  }

  default_policy_json = templatefile("${path.module}/resources/policy.json.tftpl", local.policy_values)
  custom_policy_json  = try(var.custom_policy.json, "")

  override_default_key_policy = try(length(regexall("^(?i:Override)$", var.custom_policy.compose_mode)) == 1, false)

  source_policy_documents = toset(
    local.override_default_key_policy
    ? [ # When overriding default key policy, it has to be the only one as source.
      local.default_policy_json
    ]
    : [ # When merging policies, both default and custom policy should be passed as source.
      local.default_policy_json,
      local.custom_policy_json
    ]
  )
  override_policy_documents = toset(
    local.override_default_key_policy
    ? [ # When overriding default key policy, custom policy should be passed as override document.
      local.custom_policy_json
    ]
    : []
  )
}

data "aws_iam_policy_document" "this" {
  source_policy_documents   = local.source_policy_documents
  override_policy_documents = local.override_policy_documents
}

#---------------------------------------------------
# AWS CREATE KMS KEY MASTER
#---------------------------------------------------
resource "aws_kms_key" "this" {
  description              = coalesce(lookup(local.tags, "Description", null), "KMS key ${local.product_name}")
  key_usage                = var.key_usage
  customer_master_key_spec = var.is_symmetric ? "SYMMETRIC_DEFAULT" : "RSA_2048"
  policy                   = data.aws_iam_policy_document.this.json # See: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
  deletion_window_in_days  = 30
  is_enabled               = var.is_enabled
  enable_key_rotation      = true

  tags = local.tags
}

#---------------------------------------------------
# AWS CREATE KMS ALIAS
#---------------------------------------------------
resource "aws_kms_alias" "this" {
  name          = "${local.alias_prefix}${local.product_name}"
  target_key_id = aws_kms_key.this.key_id
}
