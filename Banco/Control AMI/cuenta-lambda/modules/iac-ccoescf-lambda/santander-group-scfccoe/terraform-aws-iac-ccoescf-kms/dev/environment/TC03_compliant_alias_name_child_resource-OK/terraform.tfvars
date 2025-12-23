#---------------------------------------------------
# TEST CASE 03 - COMPLIANT ALIAS NAME FOR CHILDREN
#
# GIVEN:  Input with all required parameters, including mandatory tags, parent_resource and alias_name.
# WHEN:   `alias_name` input complies validation rules.
# THEN:   NO error is raised. Expected naming: "cgsd1airpaaiacprdgene111-kms99"
#---------------------------------------------------

#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
entity          = "cgs"
environment     = "d1"
app_name        = "iacprd"
function        = "gene"
sequence        = 99
parent_resource = null

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
mandatory_tags = {
  # REQUIRED TAGS
  Cost_Center    = "CC-CGS"
  CIA            = "CCC"
  APM_functional = "orbis_code_001"
  shared_costs   = "no"
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
alias_name    = "cgsd1airpaaiacprdgene111-kms99"
custom_policy = null
key_usage     = null
is_enabled    = true
is_symmetric  = true
