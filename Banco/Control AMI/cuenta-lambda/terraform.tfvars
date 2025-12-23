#COMMON
organization = ["o-3f2ugigyr0"]
vpc_id = "vpc-0734f56ef4a32d40f"
subnet_ids = ["subnet-0dfde9cbace45be94","subnet-0a04d26401b46260d"]
mandatory_tags = {
  cost_center         = "CC-XXXX"
  channel             = "TEST"
  CIA                 = "AAA"
  product             = "TEST"
  description         = "TEST"
  apm_functional      = "ORBIS_code_001"
  Name                = "Name"
  apm_technical       = "Apm_t"
  artifact_name       = "AN"
  artifact_version    = "AV"
  business_service    = "BS"
  cloud_version       = "CS"
  entity              = "CWE"
  environment         = "Env"
  map-migrated        = "MM"
  product             = "Prod"
  regions             = "reg"
  service_component   = "SC"
  shared_cost         = "yes"
  tracking_code       = "TC"
}

#LAMBDA
entity                             = "scf"
environment                        = "d1"
app_name                           = "iacprd"
function                           = "gene"
sequence                           = "001"
custom_tags = {
  "custom_tag_key" = "custom_tag_value"
}

filename = "ami_checker.zip"
runtime = "python3.10"
timeout = 300
memory_size = 256
variables = {}
create_concurrency_config = false
create_acw_event_rule = false
name_event_rule = "Name_event"
description_event_rule = "Description"
metrics_event_rule_time = "rate(5 minutes)"
target_id_event_target = "test_target_id"
triggers = []
create_lambda_function_url = true
lambda_function_url_cors = {
  allow_credentials = true
  allow_origins     = ["https://www.example.com"]
  allow_methods     = ["POST"]
  allow_headers     = ["date", "keep-alive", "x-custom-header"]
  expose_headers    = null
  max_age           = 2
}

dynamodb_items = [
  {
    allow_type   = "TAG",
    allow_value = "aws:cloud9:owner"
  },  
  {
    allow_type   = "TAG",
    allow_value = "aws:cloud9:environment"
  },  
  {
    allow_type   = "TAG",
    allow_value = "aws:elasticmapreduce:instance-group-role"
  },  
  {
    allow_type   = "TAG",
    allow_value = "aws:elasticmapreduce:job-flow-id"
  },  
  {
    allow_type   = "TAG",
    allow_value = "aws:eks:cluster-name"
  },  
  {
    allow_type   = "TAG",
    allow_value = "AWSApplicationMigrationServiceManaged"
  },  
  {
    allow_type   = "TAG",
    allow_value = "elasticbeanstalk:environment-id"
  },  
  {
    allow_type   = "TAG",
    allow_value = "aws:backup:source-resource"
  },
  {
    allow_type   = "PREFIX",
    allow_value = "amazon-eks-node-1.2"
  }
  
  /*EXAMPLES
  ALLOW EC2 INSTANCE CREATION WITH AMI ID: "AMI_ID_1" (ON ANY ACCOUNT)
  { 
    allow_type   = "AMI_ID",
    allow_value = "AMI_ID_1",
  },
  ALLOW EC2 INSTANCE CREATION WITH AMI ID: "AMI_ID_1" (ONLY ON ACCOUNTS: "AC1" AND "AC2")
  {
    allow_type   = "AMI_ID_ON_ACCOUNT",
    allow_value = "AMI_ID_3",
    account    = "AC1,AC2"
  },
  ALLOW EC2 INSTANCE CREATION IF IT CONTAINS TAG: "TAG1" ON TAGS DEFINITION (ON ANY ACCOUNT)
  {
    allow_type   = "TAG",
    allow_value = "TAG1"
  },  
  ALLOW EC2 INSTANCE CREATION IF IT CONTAINS TAG: "TAG2" ON TAGS DEFINITION (ONLY ON ACCOUNTS: "AC1" AND "AC2")
  {
    allow_type   = "TAG_ON_ACCOUNT",
    allow_value = "TAG2",
    account    = "AC1,AC2"
  },  
  ALLOW EC2 INSTANCE CREATION IF SELECTED AMI'S NAME CONTAINS: "PREFIX_1"  (ON ANY ACCOUNT)
  {
    allow_type   = "PREFIX",
    allow_value = "PREFIX_1",
  },
  ALLOW EC2 INSTANCE CREATION IF SOURCE ACCOUNT IS: "AC3"
  {
    allow_type   = "ACCOUNT_ID",
    allow_value = "AC3",
  },
  ALLOW EC2 INSTANCE CREATION IF INSTANCE PROFILE ARN IS: "ROLE1"
  {
    allow_type   = "ROLE",
    allow_value = "ROLE1",
  }*/
]