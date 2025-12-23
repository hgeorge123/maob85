#---------------------------------------------------
# TEST CASE 00 - HAPPY PATH
#
# GIVEN:  Input with all required parameters, including mandatory tags.
# WHEN:   All required mandatory tags are set and input parameters have valid values.
# THEN:   NO error is raised. Expected naming: "cgsd1airkmsiacprdgene099"
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
alias_name    = null
custom_policy = null
key_usage     = null
is_enabled    = true
is_symmetric  = true
