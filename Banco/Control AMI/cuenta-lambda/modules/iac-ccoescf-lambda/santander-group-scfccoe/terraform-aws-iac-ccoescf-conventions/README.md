# terraform-aws-iac-ccoescf-conventions

Utility module to provide a normalized way to handle the [mandatory tags and naming convention](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block).

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.errors](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_region.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | (Required) App acronym of the resource. Used for Naming. (6 characters) | `string` | n/a | yes |
| <a name="input_artifact_acronym"></a> [artifact\_acronym](#input\_artifact\_acronym) | (Required) Artifact acronym of the main product/resource.<br>Used for Naming. See: <https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block><br>(3 characters) | `string` | n/a | yes |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | (Optional) Additional tags. If some key matches one of the mandatory tags, its value shall be ignored. | `map(string)` | `{}` | no |
| <a name="input_entity"></a> [entity](#input\_entity) | (Required) Santander entity code. Used for Naming. (3 characters) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | (Required) The abbreviation for the target environment. (2 characters) | `string` | n/a | yes |
| <a name="input_function"></a> [function](#input\_function) | (Optional) App function of the resource. Used for Naming. (4 characters) | `string` | `"gene"` | no |
| <a name="input_mandatory_tags"></a> [mandatory\_tags](#input\_mandatory\_tags) | (Required) Map of strings to be assigned as resource tags, complying Santander Group Tagging Standard. See: <https://confluence.alm.europe.cloudcenter.corp/x/EHMvAw> | `map(string)` | n/a | yes |
| <a name="input_parent_resource"></a> [parent\_resource](#input\_parent\_resource) | (Optional) Naming info, mainly artifact acronym and sequence number, of the parent resource that this artifact depends on or is associated to.<br>See: [CV-002](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-002VirtualMachinesassociatedresourcesnamingstandard)<br>and [CV-004](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-004Otherassociatedresourcesnamingstandard)<br>(`artifact_acronym`: 3 characters \| `sequence`: 3 digits) | <pre>object(<br>    {<br>      artifact_acronym = string<br>      sequence         = number<br>    }<br>  )</pre> | `null` | no |
| <a name="input_sequence"></a> [sequence](#input\_sequence) | (Required) Sequence number of the main product/resource.<br>According to [CV-002](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-002VirtualMachinesassociatedresourcesnamingstandard) and [CV-004](https://confluence.alm.europe.cloudcenter.corp/display/ARCHCLOUD/Naming+and+Tagging+Building+Block#NamingandTaggingBuildingBlock-CV-004Otherassociatedresourcesnamingstandard),<br>only the 2 last digits shall be considered when this sequence refers to an associated resource (when a `parent_resource` is set).<br>Used for Naming. (3 characters) | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | Name of the provider selected region. |
| <a name="output_geo_region"></a> [geo\_region](#output\_geo\_region) | Resolved geographical region acronym. |
| <a name="output_naming_convention_regex_pattern"></a> [naming\_convention\_regex\_pattern](#output\_naming\_convention\_regex\_pattern) | Regex pattern to determine whether a resource name matches SCF naming convention. |
| <a name="output_product_name"></a> [product\_name](#output\_product\_name) | Calculated name of the target resource. |
| <a name="output_tags"></a> [tags](#output\_tags) | Map of string with Tags to be declared in target resource. |
