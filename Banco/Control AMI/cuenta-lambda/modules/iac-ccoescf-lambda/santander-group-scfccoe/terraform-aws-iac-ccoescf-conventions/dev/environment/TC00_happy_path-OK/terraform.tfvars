#---------------------------------------------------
# TEST CASE 00 - HAPPY PATH
#
# GIVEN:  Input with all required parameters, mandatory tags and custom tags.
# WHEN:   All required mandatory tags are set and input parameters have valid values.
# THEN:   NO error is raised. Expected naming: "cgsd1airntciacprdgene099"
#---------------------------------------------------

#---------------------------------------------------
# AWS NAMING
#---------------------------------------------------
entity           = "cgs"
environment      = "d1"
app_name         = "iacprd"
function         = "gene"
sequence         = 99
artifact_acronym = "ntc" # (N)aming and (T)agging (C)onventions

#---------------------------------------------------
# AWS TAGGING - CCoE
#---------------------------------------------------
mandatory_tags = {
  # REQUIRED TAGS
  cost_center    = "CC-CGSALM"
  channel        = "CGS"
  CIA            = "CAB"
  apm_functional = "from_orbis tag"
  shared_cost   = "no"
  apm_technical  = "test"
  business_service = "test" 
  service_component = "test" 
  # NON REQUIRED TAGS
  product       = null # Shall be set to default value
  description   =  "conventions"
  tracking_code = null # Shall be set to default value
  #---------------------------------------------------
  # AWS TAGGING - ALM
  #---------------------------------------------------
  artifact_version = "1.0.1"
  cloud_version    = null
  artifact_name    = "ntc" # (N)aming and (T)agging (C)onventions
}

custom_tags = {
  custom_tag1 = "custom tag value"
}
