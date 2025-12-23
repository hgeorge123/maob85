resource "aws_kms_key" "image-builder" {
  description             = "KMS key for image builder"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for Auto Scaling service role from all accounts in the organization"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID": data.aws_organizations_organization.org.id,
            "aws:PrincipalArn": "arn:aws:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          }
        }
      },
      {
        Sid    = "Allow use of the key for EC2ImageBuilderDistributionCrossAccountRole service role from all accounts in the organization"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID": data.aws_organizations_organization.org.id,
            "aws:PrincipalArn": "arn:aws:iam::*:role/EC2ImageBuilderDistributionCrossAccountRole"
          }
        }
      },      
      {
        Sid    = "Allow use of the key for all accounts in the organization"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID": data.aws_organizations_organization.org.id
          }
        }
      }
    ]
  })

  tags = merge(var.mandatory_tags, var.custom_tags)
}

#TODO: Enable Alias
#resource "aws_kms_alias" "image-builder_alias" {
#  name          = "alias/cgsp2aiimagebuilder-kms001"
#  target_key_id = aws_kms_key.image-builder.key_id
#
#}

#TODO: Create as many kms_replicas as ami_regions_kms_key
resource "aws_kms_replica_key" "kms_replica" {

  provider = aws.us-east-2
  description         = "Replica KMS key for image builder (us-east-2)" 
  primary_key_arn     = aws_kms_key.image-builder.arn
}