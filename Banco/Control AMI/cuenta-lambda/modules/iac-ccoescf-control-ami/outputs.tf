
output "ami_role_for_lambda" {
  description = "The ARN of the IAM Role"
  value       = aws_iam_role.central_lambda_function_ami_role.arn
}

output "security_group_id_for_lambda" {
  value = aws_security_group.sg_lambda.id
  description = "Security Group Image Builder"
}