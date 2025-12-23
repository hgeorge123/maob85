terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "cross_account_event_rule" {
  name = "RunInstancesToGlobalEventBusControlAMIRule"
  description = "Redirects RunInstances events to Global EventBus Global on central account."

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

  state = "ENABLED"
}

###EventBridge

resource "aws_cloudwatch_event_target" "cross_account_to_central_eb" {
  rule      = aws_cloudwatch_event_rule.cross_account_event_rule.name
  target_id = "CrossAccountToCentralEventBus"
  arn       = var.target_eventbus_arn
  role_arn = aws_iam_role.event_bridge_cross_account_role.arn
}

resource "aws_iam_role" "event_bridge_cross_account_role" {
  name = "CrossAccountEventBridgeControlAMI"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
           Service = [
            "events.amazonaws.com"
          ]
        }          
      }
    ]
  })

  force_detach_policies = true
  tags = var.mandatory_tags

}

resource "aws_iam_policy" "control_ami_cross_account_iam_policy" {
  name        = "ami-checker-cross-account-iam-policy"
  path        = "/"
  description = "ami-checker-cross-account-iam-policy"
  tags = var.mandatory_tags
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
          {
            Effect = "Allow"
            Action = "events:PutEvents"
            Resource = var.target_eventbus_arn
          }
    ]
  })
}

resource "aws_iam_policy_attachment" "ami-checker-cross-account-iam-policy-attach" {
  name       = "ami-checker-cross-account-iam-policy-attachment"
  roles      = [aws_iam_role.event_bridge_cross_account_role.name]
  policy_arn = aws_iam_policy.control_ami_cross_account_iam_policy.arn
}

###Lambda


resource "aws_iam_role" "lambda_cross_account_role" {
  name = "CrossAccountLambdaRole"

  assume_role_policy = jsonencode(  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": var.target_role_arn
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})



  force_detach_policies = true
  tags = var.mandatory_tags
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "ami-checker-lambda-iam-policy"
  path        = "/"
  description = "ami-checker-lambda-iam-policy"
  tags = var.mandatory_tags
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
          {
            Effect = "Allow"
            Action = [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "ec2:StopInstances",
              "ec2:TerminateInstances",
              "ec2:DescribeImages",
              "ec2:DescribeInstances",
              "ec2:CreateTags",
              "ec2:DescribeTags",
              "ec2:DescribeImageAttribute",
              "ec2:CreateNetworkInterface",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DeleteNetworkInterface"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "iam:GetInstanceProfile"
            ]
            Resource = "*"
          }
    ]
  })
}

resource "aws_iam_policy_attachment" "ami-checker-lambda-iam-policy-attach" {
  name       = "ami-checker-lambda-iam-policy-attachment"
  roles      = [aws_iam_role.lambda_cross_account_role.name]
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}