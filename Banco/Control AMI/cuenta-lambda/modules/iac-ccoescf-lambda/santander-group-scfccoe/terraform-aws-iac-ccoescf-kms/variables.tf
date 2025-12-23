#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
variable "entity" {
  description = "(Required, **Forces new resource**) Santander entity code. Used for Naming. (3 characters) "
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{3}$", var.entity)) == 1
    error_message = "The `entity` value must be a valid Santander Group entity code, with just 3 characters."
  }
}

variable "environment" {
  description = "(Required, **Forces new resource**) The abbreviation for the target environment."
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{2}$", var.environment)) == 1
    error_message = "The `environment` value must be a valid environment code, with just 2 characters."
  }
}

variable "app_name" {
  description = "(Required, **Forces new resource**) App acronym of the resource. Used for Naming. (6 characters) "
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{6}$", var.app_name)) == 1
    error_message = "The `app_name` value must be a valid Santander Group application name, with just 6 characters."
  }
}

variable "function" {
  description = "(Optional, **Forces new resource**) App function of the resource. Used for Naming. (4 characters) "
  type        = string
  default     = "gene"

  validation {
    condition     = length(regexall("^[[:alnum:]]{4}$", var.function)) == 1
    error_message = "When `function` is given, its value must be a valid function code, with just 4 characters."
  }
}

variable "sequence" {
  description = "(Required, **Forces new resource**) Sequence number of the resource. Used for Naming. (1 to 3 digits)"
  type        = number

  validation {
    condition     = 0 <= var.sequence && var.sequence <= 999
    error_message = "The `sequence` value must be a valid positive number, between 0 and 999."
  }
}

variable "parent_resource" {
  description = <<EOT
(Optional) Naming info, mainly artifact acronym and sequence number, of the parent resource that this artifact depends on or is associated to.
See: [CV-002](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-002VirtualMachinesassociatedresourcesnamingstandard)
and [CV-004](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-004Otherassociatedresourcesnamingstandard)
(`artifact_acronym`: 3 characters | `sequence`: 3 digits)
EOT
  type = object(
    {
      artifact_acronym = string
      sequence         = number
    }
  )
  default = null

  validation {
    condition = (
      can(var.parent_resource.artifact_acronym)
      ? length(regexall("^[[:alnum:]]{3}$", try(coalesce(var.parent_resource.artifact_acronym), ""))) == 1
      : true
    )
    error_message = "The `parent_resource.artifact_acronym` value must be a valid artifact abbreviation, complying naming convention, with just 3 characters."
  }

  validation {
    condition = (
      can(var.parent_resource.sequence)
      ? 0 <= var.parent_resource.sequence && var.parent_resource.sequence <= 999
      : true
    )
    error_message = "The `parent_resource.sequence` value must be a valid positive number, between 0 and 999."
  }
}

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
variable "mandatory_tags" {
  description = "(Required) Map of strings to be assigned as resource tags, complaining Santander Group Tagging Standard. See: <https://confluence.alm.europe.cloudcenter.corp/pages/viewpage.action?spaceKey=arqdevops&title=Tags>"
  type        = map(string)
}

variable "custom_tags" {
  description = "(Optional) Additional tags. If some key matches one of the mandatory tags, its value shall be ignored."
  type        = map(string)
  default     = {}
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
variable "alias_name" {
  description = "(Optional, **Forces new resource**) Name alias of the KMS."
  type        = string
  default     = null

  validation {
    condition = (
      var.alias_name == null
      || length(regexall("^[\\w|-]{22,24}(?:-[[:alpha:]]{3}[[:digit:]]{2})?$", trimprefix(try(coalesce(var.alias_name), ""), "alias/"))) == 1
    )
    error_message = "The `alias_name` value must comply SCF naming convention."
  }
}

variable "custom_policy" {
  description = <<EOF
  (Optional) A policy JSON document and the strategy to merge with the default key policy.
  Although this is a key policy, not an IAM policy, an `aws_iam_policy_document`, in the form that designates a principal, can be used.
  If you do not provide a key policy, AWS KMS attaches a default key policy to the CMK.
  Set `compose_mode` to `Merge` if both default key policy and custom_policy statements should be merged.
  Set `compose_mode` to `Override` if custom_policy statements override the default key policy.  
  EOF
  type = object(
    {
      compose_mode = string # The merge strategy with the default key policy.
      json         = string # A valid policy JSON document
    }
  )
  default = null
}

variable "is_enabled" {
  description = "(Optional) Specifies whether the key is enabled."
  type        = bool
  default     = true
}

variable "is_symmetric" {
  description = "(Optional, **Forces new resource**) If true, KMS will be symmetric, otherwise it will be (RSA_2048)"
  type        = bool
  default     = true
}

variable "key_usage" {
  description = "(Optional, **Forces new resource**) [ENCRYPT_DECRYPT or SIGN_VERIFY]"
  type        = string
  default     = "ENCRYPT_DECRYPT"

  # validation {
  #   condition     = !contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage)
  #   error_message = "The `key_usage` value must be a supported value: \"ENCRYPT_DECRYPT\" or \"SIGN_VERIFY\"."
  # }
}
