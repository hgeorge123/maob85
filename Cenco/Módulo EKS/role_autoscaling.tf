locals {
  autoscaling_role_arn = var.create_autoscaling_role ? aws_iam_service_linked_role.autoscaling[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  count = var.create_autoscaling_role ? 1 : 0

  aws_service_name = "autoscaling.amazonaws.com"
  description      = "Service-linked role for Auto Scaling"
}