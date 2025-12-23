
#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
variable "entity" {}

variable "environment" {}

variable "app_name" {}

variable "function" {}

variable "sequence" {}

variable "parent_resource" {
  type = object(
    {
      artifact_acronym = string
      sequence         = number
    }
  )
}

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
variable "mandatory_tags" {
}

variable "custom_tags" {
  default = {}
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
variable "alias_name" {}

variable "custom_policy" {
  type = object(
    {
      compose_mode = string
      json         = string
    }
  )
}

variable "is_enabled" {}

variable "is_symmetric" {}

variable "key_usage" {}
