#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
entity      = "scf"
environment = "d1"
app_name    = "iacprd"
sequence    = "002"

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
mandatory_tags = {
  Cost_Center    = "TEST"
  Channel        = "TEST"
  CIA            = "AAA"
  APM_functional = "orbis_code_001"
  shared_costs   = "no"
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
vpc_id             = "vpc-0f3622ff5d33055d7"      #"vpc-0657c50f0ed7e5622"
subnet_ids         = ["subnet-0da08ca886d35750b"] #["subnet-0419e935300dadccf"]
security_group_ids = ["sg-0279b19e5eed48791"]     #["sg-0282bf537d378b35d"]

filename = "lambda_function.zip"
