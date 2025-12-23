#---------------------------------------------------
# TEST CASE 60 - MANDATORY TAG OUT OF SCOPE
#
# GIVEN:  Input with all required parameters and some mandatory tags.
# WHEN:   A mandatory tag not eligible in the current scope is passed as a `mandatory_tags` item.
# THEN:   ERROR is raised, with "out of scope" error message.
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

  #---------------------------------------------------
  # AWS TAGGING - OUT OF SCOPE (just for S3 product)
  #---------------------------------------------------
  backup_needed = "no"
}
