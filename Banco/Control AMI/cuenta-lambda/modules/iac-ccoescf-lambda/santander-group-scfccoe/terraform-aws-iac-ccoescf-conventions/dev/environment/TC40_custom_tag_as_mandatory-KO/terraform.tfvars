#---------------------------------------------------
# TEST CASE 40 - CUSTOM TAG AS MANDATORY
#
# GIVEN:  Input with all required parameters and some mandatory tags.
# WHEN:   A non-mandatory tag is passed in the `mandatory_tags` input map.
# THEN:   ERROR is raised with non-mandatory error message.
#---------------------------------------------------

#---------------------------------------------------
# AWS NAMING
#---------------------------------------------------
entity           = "cgs"
environment      = "d1"
artifact_acronym = "ntc" # (N)aming and (T)agging (C)onventions
app_name         = "iacprd"
function         = "gene"
sequence         = 99

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
  artifact_version = "0.0.1-SNAPSHOT"
  cloud_version    = null
  artifact_name    = "ntc" # (N)aming and (T)agging (C)onventions

  #---------------------------------------------------
  # AWS TAGGING - NON MANDATORY TAG
  #---------------------------------------------------
  NON-MANDATORY-TAG = "NON mandatory tag value."
}
