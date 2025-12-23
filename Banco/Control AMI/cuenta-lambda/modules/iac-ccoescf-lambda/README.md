# AWS Lambda Terraform module

Terraform module, which creates an AWS Lambda uploading your code in .zip format.

## Description

> AWS Lambda is a compute service that lets you run code without provisioning or managing servers. AWS Lambda executes your code only when needed and scales automatically, from a few requests per day to thousands per second.

### Public Documentation

[AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
[AWS Lambda - Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)

## Usage

### Dependencies

The following resources must exist before the deployment can take place:

* AWS Account and permissions to create a Lambda function
* Role to assign to the Lambda function
* Generate a filename of zip-archive based on the content of the files.

### Optional Dependencies

The following dependencies will be generated if they are not provided:

* KMS key deployed in the same region where the function is created

---

### Minimum Viable Configuration

> ⚠️ **Disclaimer**
>
>The following is an example of a minimum viable configuration, with optional parameters omitted, **intended to be used only in prototype or development environments**.
>
>Note that modifying this configuration later to include more parameters or modify existing ones may cause the resource to be recreated.

<table>
<tr>
<td>

```hcl
module "iac-ccoescf-lambda-mvc" {
  source  = "github.com/santander-group-scfccoe/terraform-aws-iac-ccoescf-lambda?ref=v3.2.4-github"

  #---------------------------------------
  # GLOBAL NAMING CONVENTION
  #---------------------------------------
  entity      = var.entity
  environment = var.environment
  app_name    = var.app_name
  sequence    = var.sequence

  #---------------------------------------
  # GLOBAL TAGGING CONVENTION
  #---------------------------------------
  mandatory_tags = var.mandatory_tags

  #---------------------------------------
  # PRODUCT-SPECIFIC VARIABLES
  #---------------------------------------
  lambda_role = aws_iam_role.lambda_iam_role.arn

  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  filename      = var.filename
  filename_hash = filebase64sha256(var.filename)
}
```

</td>
<td>

**Example terraform.tfvars**

```
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
  Cost_Center = "TEST"
  Channel     = "TEST"
  CIA         = "AAA"
}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
vpc_id             = "vpc-0657c50f0ed7e5622"
subnet_ids         = ["subnet-0419e935300dadccf"]
security_group_ids = ["sg-0282bf537d378b35d"]

filename = "lambda_function.zip"
```

</td>
</tr>
</table>

---

### Configuration

<table>
<tr>
<td>

```hcl
module "iac-ccoescf-lambda" {
  source  = "github.com/santander-group-scfccoe/terraform-aws-iac-ccoescf-lambda?ref=v3.2.4-github"

  #---------------------------------------
  # GLOBAL NAMING CONVENTION
  #---------------------------------------
  entity      = var.entity
  environment = var.environment
  app_name    = var.app_name
  function    = var.function
  sequence    = var.sequence

  #---------------------------------------
  # GLOBAL TAGGING CONVENTION
  #---------------------------------------
  mandatory_tags = var.mandatory_tags

  custom_tags = var.custom_tags

  #---------------------------------------
  # PRODUCT-SPECIFIC VARIABLES
  #---------------------------------------
  lambda_role = aws_iam_role.lambda_iam_role.arn

  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  filename      = var.filename
  filename_hash = filebase64sha256(var.filename)

  runtime                   = var.runtime
  timeout                   = var.timeout
  memory_size               = var.memory_size
  variables                 = var.variables
  create_concurrency_config = var.create_concurrency_config
  # access_point_id           = var.access_point_id
  # efs_mount_path            = var.efs_mount_path

  // Eventbridge Event Triggers
  triggers = var.triggers
  // Lambda Function Url Cors
  create_lambda_function_url = var.create_lambda_function_url
  lambda_function_url_cors   = var.lambda_function_url_cors
  ephemeral_storage          = var.ephemeral_storage
  architectures              = var.architectures     
}
```

</td>
<td>

**Example terraform.tfvars**

```
#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
entity      = "scf"
environment = "d1"
app_name    = "iacprd"
function    = "gene"
sequence    = "001"

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
mandatory_tags = {
  Cost_Center   = "TEST"
  Channel       = "TEST"
  CIA           = "AAA"
  Product       = "TEST"
  Description   = "TEST"
  Tracking_Code = "TEST"
}

custom_tags = { "custom_tag_key" = "custom_tag_value" }

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
vpc_id             = "vpc-0657c50f0ed7e5622"
subnet_ids         = ["subnet-0419e935300dadccf"]
security_group_ids = ["sg-0282bf537d378b35d"]

filename = "lambda_function.zip"

runtime                   = "python3.8"
timeout                   = 5
memory_size               = 256
variables                 = {}
create_concurrency_config = false
# access_point_id           = "fsap-xxxxxxxxxxxxxxx"
# efs_mount_path            = "/mnt/efs"

// Eventbridge Event Triggers
triggers = [
  {
    name                = "my_custom_trigger"     # If null, a convention value is given
    description         = "trigger description"   # If null, a default description is set 
    schedule_expression = "rate(1 minute)"        # Mandatory
    target_id           = "lambda_test"           # If null, a convention value is given
    input_transformer = {                         # Can be null if lambda function has not input parameters
      input_paths = {                             # Can be null if no parameter need to be read from Eventbridge event
        time = "$.time"
      }
      input_template = <<EOT
{
  "first_name": "John",
  "last_name": "Smith"
  "timestamp": "last seen: <time>"
}
EOT
    }
  }
]

lambda_function_url_cors = {
    allow_credentials = true
    allow_origins     = ["https://www.example.com"]
    allow_methods     = ["POST"]
    allow_headers     = ["date", "keep-alive", "x-custom-header"]
    expose_headers    = null
    max_age           = 2
  }
  
  ephemeral_storage          = "512"
  architectures              = ["x86_64"]

```

</td>
</tr>
</table>

## Lambda Permissions for allowed triggers

Lambda Permissions should be specified to allow certain resources to invoke Lambda Function.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.12.1 |

## Inputs

| Name                                                                                                                             | Description                                                                                                                                                                                                                                                                                                                | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Default                            | Required |
|----------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name)                                                                     | (Required, Forces new resource) App acronym of the resource. Used for Naming. (6 characters)                                                                                                                                                                                                                               | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_entity"></a> [entity](#input\_entity)                                                                             | (Required, Forces new resource) Santander entity code. Used for Naming. (3 characters)                                                                                                                                                                                                                                     | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_environment"></a> [environment](#input\_environment)                                                              | (Required, Forces new resource) The abbreviation for the target environment.                                                                                                                                                                                                                                               | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_filename"></a> [filename](#input\_filename)                                                                       | (Required) The name of the file, it should be saved in Lambda\_functions folder in .zip                                                                                                                                                                                                                                    | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_filename_hash"></a> [filename\_hash](#input\_filename\_hash)                                                      | (Required) The hash of the file, it should be saved in Lambda\_functions folder in .zip                                                                                                                                                                                                                                    | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_lambda_role"></a> [lambda\_role](#input\_lambda\_role)                                                            | (Required) The name of the lambda's role                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_mandatory_tags"></a> [mandatory\_tags](#input\_mandatory\_tags)                                                   | (Required) Map of strings to be assigned as resource tags, compliant with Santander Group Tagging Standard. See: <https://confluence.alm.europe.cloudcenter.corp/pages/viewpage.action?spaceKey=arqdevops&title=Tags>                                                                                                      | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | n/a                                |   yes    |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids)                                     | (Required) Security groups that will be applied to the lambda function.                                                                                                                                                                                                                                                    | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | n/a                                |   yes    |
| <a name="input_sequence"></a> [sequence](#input\_sequence)                                                                       | (Required, Forces new resource) Sequence number of the resource. Used for Naming. (1 to 3 digits)                                                                                                                                                                                                                          | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids)                                                               | (Required, Forces new resource) Subnets where the lambda function will be deployed.                                                                                                                                                                                                                                        | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | n/a                                |   yes    |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id)                                                                           | (Required, Forces new resource) VPC where the lambda function will be deployed.                                                                                                                                                                                                                                            | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                |   yes    |
| <a name="input_access_point_id"></a> [access\_point\_id](#input\_access\_point\_id)                                              | (Optional) The Amazon EFS Access Point ID that provides access to the file system.                                                                                                                                                                                                                                         | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `null`                             |    no    |
| <a name="input_create_acw_event_rule"></a> [create\_acw\_event\_rule](#input\_create\_acw\_event\_rule)                          | (Optional, **Deprecated**, Forces new resource) Create Cloudwatch event rule                                                                                                                                                                                                                                               | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `true`                             |    no    |
| <a name="input_create_concurrency_config"></a> [create\_concurrency\_config](#input\_create\_concurrency\_config)                | (Optional) Create concurrency config                                                                                                                                                                                                                                                                                       | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `false`                            |    no    |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags)                                                            | (Optional) Additional tags. If some key matches one of the mandatory tags, its value shall be ignored.                                                                                                                                                                                                                     | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `{}`                               |    no    |
| <a name="input_description_event_rule"></a> [description\_event\_rule](#input\_description\_event\_rule)                         | (Optional, **Deprecated**) The description of the rule                                                                                                                                                                                                                                                                     | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `""`                               |    no    |
| <a name="input_efs_mount_path"></a> [efs\_mount\_path](#input\_efs\_mount\_path)                                                 | (Optional) The path where the function can access the file system, starting with /mnt/.                                                                                                                                                                                                                                    | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `null`                             |    no    |
| <a name="input_function"></a> [function](#input\_function)                                                                       | (Optional, Forces new resource) App function of the resource. Used for Naming. (4 characters)                                                                                                                                                                                                                              | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `"gene"`                           |    no    |
| <a name="input_handler"></a> [handler](#input\_handler)                                                                          | (Optional) The entry point of the lambda                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `"lambda_function.lambda_handler"` |    no    |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn)                                                          | (Optional) Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables.                                                                                                                                                                                           | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `null`                             |    no    |
| <a name="input_layers_arn"></a> [layers\_arn](#input\_layers\_arn)                                                               | (Optional) Collection of Layer ARNs with lambda requirements/dependencies.                                                                                                                                                                                                                                                 | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | `null`                             |    no    |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size)                                                            | (Optional) Amount of memory needed for the lambda function.                                                                                                                                                                                                                                                                | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `256`                              |    no    |
| <a name="input_metrics_event_rule_time"></a> [metrics\_event\_rule\_time](#input\_metrics\_event\_rule\_time)                    | (Required, **Deprecated**, if event\_pattern isn't specified) The scheduling expression. For example, cron(0 20 ** ? *) or rate(5 minutes)                                                                                                                                                                                 | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `"rate(5 minutes)"`                |    no    |
| <a name="input_name_event_rule"></a> [name\_event\_rule](#input\_name\_event\_rule)                                              | (Optional, **Deprecated**, Forces new resource) Name the lambda -cwr                                                                                                                                                                                                                                                       | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `""`                               |    no    |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | (Optional) The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency, for default 1                                                                                                                                          | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `1`                                |    no    |
| <a name="input_runtime"></a> [runtime](#input\_runtime)                                                                          | (Optional) Identifier of the function's runtime. See <https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html> for valid values.                                                                                                                                                                                 | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `"python3.9"`                      |    no    |
| <a name="input_target_id_event_target"></a> [target\_id\_event\_target](#input\_target\_id\_event\_target)                       | (Optional, **Deprecated**, Forces new resource) Target id of event target                                                                                                                                                                                                                                                  | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `"lambda"`                         |    no    |
| <a name="input_timeout"></a> [timeout](#input\_timeout)                                                                          | (Optional) The amount of time your Lambda Function has to run in seconds. Defaults to 3.                                                                                                                                                                                                                                   | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `3`                                |    no    |
| <a name="input_triggers"></a> [triggers](#input\_triggers)                                                                       | (Optional, Forces new resource) Amazon EventBridge events definition to trigger the Lambda Function.<br>See: <https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-run-lambda-schedule.html><br>See also: <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target>     | <pre>list(<br>    object({<br>      name                = string   # (Optional) The name of the trigger. If omitted, Terraform will assign a random, unique name<br>      description         = string   # (Optional) The description of the trigger.<br>      schedule_expression = string   # (Required) The scheduling expression. For example, cron(0 20 ** ? *) or rate(5 minutes). See: <https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html>.<br>      target_id           = string   # (Optional) The unique target assignment ID. If missing, will generate a random, unique id.<br>      input_transformer = object({   # (Optional) Parameters used when you are providing a custom input to a target based on certain event data.<br>        input_paths    = map(string) # (Optional) Key value pairs specified in the form of JSONPath (for example, time = $.time)<br>        input_template = string      # (Required) Template to customize data sent to the target.<br>      })<br>    })<br>  )</pre> | `[]`                               |    no    |
| <a name="input_variables"></a> [variables](#input\_variables)                                                                    | (Optional) A map that defines environment variables for the Lambda function.                                                                                                                                                                                                                                               | `map(any)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `{}`                               |    no    |
| <a name="input_create_lambda_function_url"></a> [create\_lambda\_function\_url](#input\_create\_lambda\_function\_url)           | (Optional) Create Lambda Function url                                                                                                                                                                                                                                                                                      | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `false`                            |    no    |
| <a name="input_lambda_function_url_cors"></a> [lambda\_function\_url\_cors](#input\_lambda\_function\_url\_cors)                 | (Optional) The cross-origin resource sharing (CORS) settings for the function URL. See: <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url#cors> Once CORS is defined, it is not possible to disable it. Remove Lambda Function URL completely to be recreated without CORS. | `object`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `null`                             |    no    |
| <a name="ephemeral_storage"></a> [ephemeral_storage](#input\_ephemeral_storage)                                                  | (Optional) Instruction set architecture for your Lambda function. Valid values are [x86_64] and [arm64]. Default is [x86_64]. Removing this attribute, function's architecture stay the same.                                                                                                                              | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | `["x86_64"]`                       |    no    |
| <a name="architectures"></a> [architectures](#input\_architectures)                                                              | (Optional)Lambda Function Ephemeral Storage(/tmp) allows you to configure the storage upto 10 GB. The default value set to 512 MB..                                                                                                                                                                                        | `String`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `512`                              |    no    |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_this_lambda_function_arn"></a> [this\_lambda\_function\_arn](#output\_this\_lambda\_function\_arn) | The ARN of the Lambda Function |
| <a name="output_this_lambda_function_invoke_arn"></a> [this\_lambda\_function\_invoke\_arn](#output\_this\_lambda\_function\_invoke\_arn) | The Invoke ARN of the Lambda Function |
| <a name="output_this_lambda_function_name"></a> [this\_lambda\_function\_name](#output\_this\_lambda\_function\_name) | The name of the Lambda Function |
| <a name="output_lambda_function_url"></a> [lambda\_function\_url](#output\_lambda\_function\_url) | The url of the Lambda Function |
| <a name="output_lambda_url_id"></a> [lambda\_url\_id](#output\_lambda\_url\_id) | The id of the Lambda Function url |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Security Controls for Cloud that apply always

### Foundation (**F**) Controls for Rated Workloads

|SF#|What|How it is implemented in the Product|Who|
|--|:---|:---|:--|
|SF1| IAM on all accounts|Using Identity-Based Policies (IAM Policies) for AWS Lambda.|CCoE, Entity|
|SF2|MFA on accounts| This is governed by Azure AD.|CCoE, Entity|
|SF3|Platform Activity Logs & Security Monitoring. |Platform logs and security monitoring provided by Platform. Integration with Amazon CloudWatch for monitoring AWS Lambda.AWS Lambda monitors functions on your behalf and sends metrics to Amazon CloudWatch. The metrics include total requests, duration, and error rates. The Lambda console creates graphs for these metrics and shows them on the Monitoring page for each function.|CCoE|
|SF4|Virus/Malware Protection on IaaS|No antivirus protection for AWS Lambda service. |CCoE, DevOps|
|SF5| Authenticate all connections| AWS published API calls to access Lambda through the network. Clients must support Transport Layer Security (TLS) 1.0 or later. We recommend TLS 1.2 or later. Clients must also support cipher suites with perfect forward secrecy (PFS) such as Ephemeral Diffie-Hellman (DHE) or Elliptic Curve Ephemeral Diffie-Hellman (ECDHE). Additionally, requests must be signed by using an access key ID and a secret access key that is associated with an IAM principal.|CCoE, DevOps|
|SF6| Isolated environments at network level|Provided by the platform. Integration with Amazon VPC and VPC security groups.|CCoE|
|SF7|Security Configuration & Patch Management|Provided by the platform.|CCoE|
|SF8|Privileged Access Management|Using Identity-Based Policies (IAM Policies). The role will be passed as access_policies.|CCoE, CISO|

## Medium (**M**) Controls for Rated Workloads

|SM#|What|How it is implemented in the Product|Who|
|--|:---|:---|:--|
|SM1|IAM|Roles will be passed through parameter. Specify the ARN for an IAM role.|CCoE, Entity|
|SM2| Encrypt data at rest| You can use environment variables to store secrets securely for use with Lambda functions. Lambda always encrypts environment variables at rest. Additionally, you can use the following features to customize how environment variables are encrypted.|CCoE|
|SM3| Encrypt data in transit over private interconnections| Lambda API endpoints only support secure connections over HTTPS. When you manage Lambda resources with the AWS Management Console, AWS SDK, or the Lambda API, all communication is encrypted with Transport Layer Security (TLS).|CCoE, DevOps, Entity|
|SM4|Control resource geographical location| The region is configurable as a parameter in Terraform code.|CCoE, CISO, DevOps|

-----

## Application (**P**) Controls for Rated Workloads

|SP#|What|How it is implemented in the Product|Who|
|--|:---|:---|:--|
|SP1|Resource tagging for all resources|Product includes all required tags in the deployment template. The implementation will be done in the code. |CCoE, Cybersecurity|
|SP2|Segregation of Duties| The IAM role will be passed as a parameter.|CCoE, CISO, Entity|
|SP3|Vulnerability Management|Detect is responsablefor vulnerability scanning of endpoints.|CCoE, CISO|
|SP4|Service Logs & Security Monitoring|Integration with Amazon CloudWatch for monitoring AWS Lambda.|CCoE, CISO|
|SP5|Network Security|Provided by platform. Integration with Amazon VPC and VPC security groups. Encryption of data at rest is enabling. |CCoe, DevOps|
|SP5.1|Inbound and outbound traffic CSP Private zone to Santander On-premises|Security Groups and security rules. Protection between zones provided by platform. SG passed by parameter ||
|SP5.2|Inbound and outbound traffic: between CSP Private zones of different entities|Security Groups and security rules. Protection between zones provided by platform. NSG passed by parameter|
|SP5.3| Inbound and outbound traffic: between CSP Private zones of the same entity|Security Groups and ACL. Provided by platform.| |
|SP5.4|Inbound traffic: Internet to CSP Public zone| To access private Amazon VPC resources, such as a Relational Database Service (Amazon RDS) DB instance or Amazon Elastic Compute Cloud (Amazon EC2) instance, associate your Lambda function in an Amazon VPC with one or more private subnets. To grant internet access to your function, its associated VPC must have a NAT gateway (or NAT instance) in a public subnet.||
|SP5.5| Outbound traffic: From CSP Public/Private zone to Internet|Security Groups and ACL. Provided by platform.||
|SP5.6| Control all DNS resolutions and NTP consumption in CSP Private zone|To create a CNAME for your elasticache endpoint, for the auto discovery client to recognize the CNAME as a configuration endpoint, they must include .cfg. in the CNAME.||
|SP6|Advanced Malware Protection on IaaS| N/A. AWS is responsable of malware protection.|CCoE, CISO, Entity|
|SP7|Cyber incidents management & Digital evidences gathering|Capacity provided from TLZ.|CISO, Entity|
|SP8|Encrypt data in transit over public interconnections|All data in transit using public connectivity such as Internet must be encrypted. All trafic encript with HTTPS. |CCoE, DevOps|
|SP9|Static Application Security Testing (SAST)| Evaluated by Sentinel (Terraform Enterprise) and by Dome9 (Check Point).|Entity|

-----

### Advanced (**A**) Controls for Rated Workloads

|SA#|What|How it is implemented in the Product|Who|
|--|:---|:---|:--|
|SA1| IAM|IAM permissions based on roles. Access is based on the principle of least privilege assigned to roles.|CCoE, Entity|
|SA2|Encrypt data at rest|You can use environment variables to store secrets securely for use with Lambda functions. Lambda always encrypts environment variables at rest. Additionally, you can use the following features to customize how environment variables are encrypted.|CCoE|
|SA3| Encrypt data in transit over private interconnections|Lambda API endpoints only support secure connections over HTTPS. When you manage Lambda resources with the AWS Management Console, AWS SDK, or the Lambda API, all communication is encrypted with Transport Layer Security (TLS).|CCoE, Entity|
|SA4| Santander managed keys with HSM and BYOK| Santander is responsible for key management.  The client can choose witch key use for each volume. Therefore, BYOK is available.|CCoE, Cybersecurity|
|SA5| Control resource geographical location|The region is configurable as a parameter in Terraform code.|CCoE, CISO, DevOps|
|SA6|Cardholder and auth sensitive data| Provided by the environment. |Entity|
|SA7| Access control to data with MFA| Provided by the environment.|CCoE, CISO, Entity|

### Critical (**C**) Controls for Rated Workload

|SC#|What|How it is implemented in the Product|Who|
|--|:---|:---|:--|
|SC1|Pen-testing|N/A.|CISO, Entity|
|SC2|Threat Model|N/A.|Entity|
|SC3|RedTeam|N/A.|CISO|
|SC4|Dynamic Application Security Testing (DAST)|N/A.|Entity|

# **Basic tf files description**

This section explain the structure and elements that represent the artifacts of product.

|Folder|Name|Description
|--|:-|--|
|Documentation|changelog.md|version control|
|Root|Readme.md|Product documentation file|
|Root|main.tf|Terraform file to use in pipeline to build and release a product|
|Root|outputs.tf|Terraform file to use in pipeline to check output|
|Root|variables.tf|Terraform file to define variables|

## Authors

Module written by CCoE
