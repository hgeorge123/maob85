resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role_test"

  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSLambdaExecute"]

  inline_policy {
    name = "lambda_iam_role_test_inline_policy"

    policy = jsonencode({
      Statement = [
        {
          Action = [
            "ec2:Describe*",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}