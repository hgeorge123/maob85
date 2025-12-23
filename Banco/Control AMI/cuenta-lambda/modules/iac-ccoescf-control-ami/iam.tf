resource "aws_iam_role" "central_lambda_function_ami_role" {
  name = "ControlAMI"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
           Service = [
            "lambda.amazonaws.com",
            "events.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }          
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
            Effect: "Allow",
              Action: [
                  "sts:AssumeRole"
              ],
              Resource: "arn:aws:iam::*:role/CrossAccountLambdaRole"
          },      
         {
            Effect = "Allow"
            Action = [
              "dynamodb:GetItem",
              "dynamodb:Query",
              "dynamodb:Scan"
            ]
            Resource = aws_dynamodb_table.centralized_dynamo_db_table.arn
          },
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
  roles      = [aws_iam_role.central_lambda_function_ami_role.name]
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}