#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
variable "entity" {}
variable "environment" {}
variable "app_name" {}
variable "sequence" {}

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
variable "mandatory_tags" {}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
variable "vpc_id" {}
variable "subnet_ids" {}
variable "security_group_ids" {}

variable "filename" {}
