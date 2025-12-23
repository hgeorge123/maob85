#---------------------------------------------------
# TEST CASE 11 - DEFAULT NAME FORMAT EC2 LINUX
#
# GIVEN:  Input with all required parameters and mandatory tags.
# WHEN:   `artifact_acronym` is "ec2", `mandatory_tags.os_platform` matches "Linux".
# THEN:   Non-Windows VM naming is resolved (CV-001).
#---------------------------------------------------

#---------------------------------------------------
# AWS NAMING
#---------------------------------------------------
entity           = "cgs"
environment      = "d1"
app_name         = "iacprd"
function         = "gene"
sequence         = 99
artifact_acronym = "ec2"

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

  # ARTIFACT SCOPED TAGS
  os_platform = "linux"
}
