#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
entity      = "cgs"
environment = "d1"
app_name    = "iacprd"
function    = "gene"
sequence    = 99

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
mandatory_tags = {
  # REQUIRED TAGS
  cost_center       = "CC-CGS"
  CIA               = "CAA"
  apm_functional    = "orbis_code_001"
  shared_cost       = "no"
  apm_technical     = "orbis_code_001"
  business_service  = "bs"
  service_component = "sc"
  # OPTIONAL TAGS
  product       = null # Shall be set to default value (from artifact_name)
  description   = null # Shall be set to default value (from Product tag)
  channel       = "IACPRD"
  tracking_code = null # Shall be set to default value (from Channel tag)
}

custom_tags = {
  extra_tag = "custom value tag"
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
alias_name    = "cgsd1airas3geneiacprd001-kms01"
custom_policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::xxxxxxxxxx:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOT
key_usage     = "ENCRYPT_DECRYPT"
is_enabled    = true
is_symmetric  = true
