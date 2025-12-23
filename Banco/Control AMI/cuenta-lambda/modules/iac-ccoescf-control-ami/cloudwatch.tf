data "aws_iam_policy_document" "eb_policy" {
  statement {
    sid    = "GlobalEventBusControlAMIPolicy"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]

    resources = [aws_cloudwatch_event_bus.global_event_bus_control_ami.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = var.organization
    }
  }
}

resource "aws_cloudwatch_event_bus" "global_event_bus_control_ami" {
  name = "GlobalEventBusControlAMI"
}

resource "aws_cloudwatch_event_bus_policy" "event_bus_policy" {
  event_bus_name = aws_cloudwatch_event_bus.global_event_bus_control_ami.name
  policy = data.aws_iam_policy_document.eb_policy.json
}

resource "aws_cloudwatch_event_rule" "central_event_bridge_rule_ami" {
  name = "InstanceLaunchedEventRuleAMI"
  description = "EC2 Instance Launch event rule"
  event_bus_name = aws_cloudwatch_event_bus.global_event_bus_control_ami.arn
  #role_arn = aws_iam_role.central_lambda_function_ami_role.arn
  event_pattern = jsonencode({
    source = [
      "aws.ec2"
    ]
    detail-type = [
      "AWS API Call via CloudTrail"
    ]
    detail = {
      eventSource = [
        "ec2.amazonaws.com"
      ]
      eventName = [
        "RunInstances"
      ]
    }
  })
  state = "ENABLED" # ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS 
}

resource "aws_cloudwatch_event_target" "lambda_from_custom" {
  event_bus_name = aws_cloudwatch_event_bus.global_event_bus_control_ami.name
  rule      = aws_cloudwatch_event_rule.central_event_bridge_rule_ami.name
  target_id = "CentralLambdaFunctionAMIFromCustom"
  arn       = var.lambda_arn
}

resource "aws_cloudwatch_event_rule" "default_event_bridge_rule_ami" {
  name = "InstanceLaunchedDefaultEventRuleAMI"
  description = "EC2 Instance Launch event rule for the default event bus"
  event_pattern = jsonencode({
    source = [
      "aws.ec2"
    ]
    detail-type = [
      "AWS API Call via CloudTrail"
    ]
    detail = {
      eventSource = [
        "ec2.amazonaws.com"
      ]
      eventName = [
        "RunInstances"
      ]
    }
  })
  state = "ENABLED" #ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS ?
}

resource "aws_cloudwatch_event_target" "lambda_from_default" {
  rule      = aws_cloudwatch_event_rule.default_event_bridge_rule_ami.name
  target_id = "CentralLambdaFunctionAMIFromDefault"
  arn       = var.lambda_arn
}

resource "aws_cloudwatch_log_group" "central_lambda_function_ami_log_group" {
  name = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 14
}

resource "aws_lambda_permission" "permission_for_events_to_invoke_lambda" {
  function_name = "${var.lambda_name}"
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.central_event_bridge_rule_ami.arn
}

resource "aws_lambda_permission" "permission_for_default_events_to_invoke_lambda" {
  function_name = "${var.lambda_name}"
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
}