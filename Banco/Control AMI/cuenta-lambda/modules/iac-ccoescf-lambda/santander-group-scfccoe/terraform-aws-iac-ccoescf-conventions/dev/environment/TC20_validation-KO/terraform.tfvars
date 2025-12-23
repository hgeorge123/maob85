#---------------------------------------------------
# TEST CASE 20 - VALIDATION
#
# GIVEN:  Input with all required parameters and mandatory tags.
# WHEN:   Any of the mandatory tag values does not comply validation pattern.
# THEN:   ERROR is raised, with validation error message.
#---------------------------------------------------

#---------------------------------------------------
# AWS NAMING
#---------------------------------------------------
entity           = "cgs"
environment      = "d1"
app_name         = "iacprd"
function         = "gene"
sequence         = 99
artifact_acronym = "ec2" # (N)aming and (T)agging (C)onventions


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
  cloud_version    = ""
  artifact_name    = "ec2" # (N)aming and (T)agging (C)onventions

  #---------------------------------------------------------------
  # AWS TAGGING - SCOPE SPECIFIC VALIDATION (just for EC2 product)
  #---------------------------------------------------------------
  patch_highavailability = "N/A"   # Should be like "yes" either "no"
  patch_AZ               = "a1"    # Should be like "a" either "1"
  patch_enable           = "N/A"   # Should be like "yes" either "no"
  patch_order            = "N/A"   # Sholud be a number between 1 and 5
  os_platform            = "ARM64" # Should be like "Linux" either "Windows"
}
