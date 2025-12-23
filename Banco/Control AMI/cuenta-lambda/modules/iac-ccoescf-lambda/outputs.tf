output "this_lambda_function_arn" {
  description = "The ARN of the Lambda Function"
  value       = element(concat(aws_lambda_function.this.*.arn, [""]), 0)
}

output "this_lambda_function_invoke_arn" {
  description = "The Invoke ARN of the Lambda Function"
  value       = element(concat(aws_lambda_function.this.*.invoke_arn, [""]), 0)
}

output "this_lambda_function_name" {
  description = "The name of the Lambda Function"
  value       = element(concat(aws_lambda_function.this.*.function_name, [""]), 0)
}

output "lambda_function_url" {
  description = "The url of the Lambda Function"
  value       = element(concat(aws_lambda_function_url.this.*.function_url, [""]), 0)
}

output "lambda_url_id" {
  description = "The id of the Lambda Function url"
  value       = element(concat(aws_lambda_function_url.this.*.url_id, [""]), 0)
}