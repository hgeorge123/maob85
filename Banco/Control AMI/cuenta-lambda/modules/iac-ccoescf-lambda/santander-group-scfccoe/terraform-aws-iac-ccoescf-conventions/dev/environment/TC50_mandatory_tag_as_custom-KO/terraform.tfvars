#---------------------------------------------------
# TEST CASE 50 - MANDATORY TAG AS CUSTOM
#
# GIVEN:  Input with all required parameters, some mandatory tags and custom tags.
# WHEN:   A mandatory tag is passed in the `custom_tags` input map with the same either a different casing.
# THEN:   ERROR is raised with mandatory tag in `custom_tags` input error message.
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
  # Even a tag with different casing is recognized as mandatory to force tag validation.
  name = "Trying to overwrite Name without validation."
  # Even a tag out of its scope is recognized as mandatory to force tag validation.
  backup_needed = "no"
}
