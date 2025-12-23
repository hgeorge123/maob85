#---------------------------------------------------
# TEST CASE 12 - MERGE EMPTY CUSTOM POLICY
#
# GIVEN:  Input with all required parameters, including mandatory tags and a custom policy.
# WHEN:   `custom_policy.compose_mode` is `merge` and `custom_policy.json` is an empty JSON object.
# THEN:   Default policy document is set as key policy.
#---------------------------------------------------

#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
entity          = "cgs"
environment     = "d1"
app_name        = "iacprd"
function        = "gene"
sequence        = 099
parent_resource = null

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
mandatory_tags = {
  # REQUIRED TAGS
  Cost_Center    = "CC-CGS"
  CIA            = "CAA"
  APM_functional = "orbis_code_001"
  shared_costs   = "no"
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
alias_name = null
key_usage  = null
custom_policy = {
  compose_mode = "merge"
  # Same Sid as default key policy
  json = <<EOT
{}
EOT
}
is_enabled   = true
is_symmetric = true
