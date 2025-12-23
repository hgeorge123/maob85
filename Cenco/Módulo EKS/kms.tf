# Recurso para actualizar la política del KMS
resource "aws_kms_key_policy" "dynamic_kms_policy" {
  # Usar el ARN de la clave KMS del módulo
  key_id = module.eks_kms_key.key_arn

  # Política generada dinámicamente
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Default"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "KeyAdministration"
        Effect = "Allow"
        Principal = {
          # AWS = data.aws_caller_identity.current.arn
          AWS = local.terraform_role_arn
        }
        Action = [
          "kms:Update*",
          "kms:UntagResource",
          "kms:TagResource",
          "kms:ScheduleKeyDeletion",
          "kms:Revoke*",
          "kms:ReplicateKey",
          "kms:Put*",
          "kms:List*",
          "kms:ImportKeyMaterial",
          "kms:Get*",
          "kms:Enable*",
          "kms:Disable*",
          "kms:Describe*",
          "kms:Delete*",
          "kms:Create*",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "KeyServiceRolesASG"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
            module.eks.cluster_iam_role_arn,
            module.eks_blueprints_addons.karpenter_iam_role_arn
          ]
        }
        Action = [
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "KeyServiceRolesASGPersistentVol"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
            module.eks.cluster_iam_role_arn,
            module.eks_blueprints_addons.karpenter_iam_role_arn
          ]
        }
        Action   = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })

  depends_on = [
    module.eks_blueprints_addons,
    module.eks,
    module.eks_kms_key
  ]
}