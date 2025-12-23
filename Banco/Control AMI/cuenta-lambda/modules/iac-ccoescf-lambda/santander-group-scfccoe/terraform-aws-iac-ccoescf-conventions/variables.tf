#---------------------------------------------------
# AWS TAGGING
#---------------------------------------------------
variable "mandatory_tags" {
  description = "(Required) Map of strings to be assigned as resource tags, complying Santander Group Tagging Standard. See: <https://confluence.alm.europe.cloudcenter.corp/x/EHMvAw>"
  type        = map(string)
}

variable "custom_tags" {
  description = "(Optional) Additional tags. If some key matches one of the mandatory tags, its value shall be ignored."
  type        = map(string)
  default     = {}
}

#---------------------------------------------------
# AWS NAMING
#---------------------------------------------------
variable "entity" {
  description = "(Required) Santander entity code. Used for Naming. (3 characters)"
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
    # condition     = length(regexall("^[[:alnum:]]{2}$", var.environment)) == 1
    condition     = length(regexall("^[dips][[:digit:]]$", var.environment)) == 1
    # error_message = "The `environment` value must be a valid environment code, with just 2 characters."
    error_message = "The `environment` value must be a valid environment code with the first character must be one of: 'd', 'i', 'p' or 's' and the other a number."
  }
}
variable "region" {
  description = "(Optional) The AWS region code."
  type        = string
  default     = "eu-west-1"
}

variable "artifact_acronym" {
  description = <<EOT
(Required) Artifact acronym of the main product/resource.
Used for Naming. See: <https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block>
(3 characters)
EOT
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{3}$", var.artifact_acronym)) == 1
    error_message = "The `artifact_acronym` value must be a valid artifact abbreviation, complying naming convention, with just 3 characters."
  }
}

variable "app_name" {
  description = "(Required) App acronym of the resource. Used for Naming. (6 characters) "
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{6}$", var.app_name)) == 1
    error_message = "The `app_name` value must be a valid Santander Group application name, with just 6 characters."
  }
}

variable "function" {
  description = "(Optional) App function of the resource. Used for Naming. (4 characters) "
  type        = string
  default     = "gene"

  validation {
    condition     = length(regexall("^[[:alnum:]]{4}$", var.function)) == 1
    error_message = "When `function` is given, its value must be a valid function code, with just 4 characters."
  }
}

variable "sequence" {
  description = <<EOT
(Required) Sequence number of the main product/resource.
According to [CV-002](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-002VirtualMachinesassociatedresourcesnamingstandard) and [CV-004](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-004Otherassociatedresourcesnamingstandard),
only the 2 last digits shall be considered when this sequence refers to an associated resource (when a `parent_resource` is set).
Used for Naming. (3 characters)
EOT
  type        = number

  validation {
    condition     = 0 <= var.sequence && var.sequence <= 999
    error_message = "The `sequence` value must be a valid positive number, between 1 and 999."
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
