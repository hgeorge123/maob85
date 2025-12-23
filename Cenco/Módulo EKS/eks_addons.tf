provider "aws" {
  alias      = "virginia"
  region     = "us-east-1"
  access_key = var.aws_credential_vault["access_key"]
  secret_key = var.aws_credential_vault["secret_key"]
  token      = var.aws_credential_vault["token"]

}

data "aws_iam_roles" "optional_terraform_role" {
  count      = local.enable_velero ? 1 : 0
  name_regex = "^cct-plataforma-eks-terraform-role$"
}

locals {
  is_virginia = var.region == "us-east-1"
  # Versión de Karpenter resuelta según la versión del cluster
  karpenter_chart_version = lookup(local.eks_addon_versions[var.eks["cluster_version"]], "karpenter", "1.3.3")

}
# locals {
#   # Captura el rol de ejecución de Terraform
#   is_assumed_role    = strcontains(data.aws_caller_identity.current.arn, ":assumed-role/")
#   execution_role_arn = local.is_assumed_role ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${split("/", data.aws_caller_identity.current.arn)[1]}" : data.aws_caller_identity.current.arn

#   optional_terraform_role_arn = try(tolist(data.aws_iam_roles.optional_terraform_role[0].arns)[0], null)

#   velero_policy_principals = compact(flatten([
#     local.execution_role_arn,
#     module.velero_irsa[0].iam_role_arn,
#     local.optional_terraform_role_arn,
#   ]))
# }

data "aws_ecrpublic_authorization_token" "token" {
  count = local.is_virginia ? 1 : 0
  #provider = var.region == "us-east-1" ? aws : aws.virginia
}

data "aws_ecrpublic_authorization_token" "token_other" {
  count    = local.is_virginia ? 0 : 1
  provider = aws.virginia
}

module "eks_blueprints_addons" {
  source = "./modules/terraform-aws-eks-blueprints-addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd = var.feature_flags["argocd"]["enabled"]
  argocd = {
    #chart_version = "9.1.6" #Previous version:  6.11.1
    set = [
      {
        name  = "configs.params.server\\.insecure"
        value = "true"
      },
      {
        name  = "configs.cm.url"
        value = "https://${var.feature_flags["argocd"]["ingress_argocd"]}"
      },
      {
        name  = "configs.cm.admin\\.enabled"
        value = "true"
      },
      {
        name  = "configs.rbac.policy\\.default"
        value = "role:none"
      },
      {
        name  = "configs.rbac.scopes"
        value = "[accounts\\, email\\, groups]"
      },
      {
        name  = "configs.rbac.policy\\.csv"
        value = replace(var.rbac, ",", "\\,")
      }
    ]
  }

  enable_aws_efs_csi_driver = lookup(var.feature_flags, "enable_aws_efs_csi_driver", false)

  aws_efs_csi_driver = var.dynamic_role ? {
    create_role            = true
    role_name              = "aws-efs-csi-driver"
    role_name_use_prefix   = true
    policy_name            = "aws-efs-csi-driver"
    policy_name_use_prefix = true
    } : {
    create_role            = false
    role_name              = "${module.eks.cluster_name}-aws-efs-csi-driver"
    role_name_use_prefix   = false
    policy_name            = "${module.eks.cluster_name}-aws-efs-csi-driver"
    policy_name_use_prefix = false
  }

  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  secrets_store_csi_driver = {
    set = [
      {
        name  = "syncSecret.enabled"
        value = "true"
      }
    ]
  }

  secrets_store_csi_driver_provider_aws = {
    values = [
      <<-EOT
      secrets-store-csi-driver:
        enabled: false
        install: false
      EOT
    ]    
  }

  # enable_aws_cloudwatch_metrics = true
  enable_aws_cloudwatch_metrics = try(var.feature_flags.container_insights, false)

  # aws_cloudwatch_metrics = var.dynamic_role ? {
  #   create_role          = true
  #   role_name            = "aws-cloudwatch-metrics"
  #   role_name_use_prefix = true
  #   } : {
  #   create_role          = true
  #   role_name            = "${module.eks.cluster_name}-aws-cloudwatch-metrics"
  #   role_name_use_prefix = false
  # }
  aws_cloudwatch_metrics = try(var.feature_flags.container_insights, false) ? (
    var.dynamic_role ? {
      create_role          = true
      role_name            = "${module.eks.cluster_name}-cloudwatch-metrics"
      role_name_use_prefix = true
      } : {
      create_role          = true
      role_name            = "${module.eks.cluster_name}-aws-cloudwatch-metrics"
      role_name_use_prefix = false
    }
    ) : {
    create_role          = false
    role_name            = ""
    role_name_use_prefix = false
  }

  # enable_kube_prometheus_stack   = lookup(var.feature_flags, "enable_kube_prometheus_stack", false)
  enable_kube_prometheus_stack = lookup(var.feature_flags, "enable_kube_prometheus_stack", false) || var.feature_flags["kube_prometheus_stack"]["enabled"]
  # enable_metrics_server        = try(var.feature_flags.container_insights, false)
  enable_metrics_server          = true
  enable_external_dns            = lookup(var.feature_flags, "enable_external_dns", false)
  external_dns_route53_zone_arns = lookup(var.feature_flags, "enable_external_dns", false) ? ["arn:aws:route53:::hostedzone/*"] : []

  external_dns = var.dynamic_role ? {
    create_role            = true
    role_name              = "cct-plataforma-"
    role_name_use_prefix   = true
    policy_name            = "cct-plataforma-"
    policy_name_use_prefix = true
    } : {
    create_role            = true
    role_name              = "${module.eks.cluster_name}-ext-dns"
    role_name_use_prefix   = false
    policy_name            = "${module.eks.cluster_name}-ext-dns"
    policy_name_use_prefix = false
  }

  enable_ingress_nginx = lookup(var.feature_flags, "enable_ingress_nginx", false)
  enable_cert_manager  = lookup(var.feature_flags, "enable_cert_manager", false)


  cert_manager = var.dynamic_role ? {
    create_role            = true
    role_name              = "cert-manager"
    role_name_use_prefix   = true
    policy_name            = "cert-manager"
    policy_name_use_prefix = true
    wait                   = true
    } : {
    create_role            = true
    role_name              = "${module.eks.cluster_name}-cert-manager"
    role_name_use_prefix   = false
    policy_name            = "${module.eks.cluster_name}-cert-manager"
    policy_name_use_prefix = false
    wait                   = true
  }

  # enable_aws_load_balancer_controller = lookup(var.feature_flags, "enable_aws_load_balancer_controller", false) || var.feature_flags["argocd"]["enabled"]
  enable_aws_load_balancer_controller = lookup(var.feature_flags, "enable_aws_load_balancer_controller", false) || var.feature_flags["argocd"]["enabled"] || var.feature_flags["kube_prometheus_stack"]["enabled"]
  aws_load_balancer_controller = var.dynamic_role ? {
    create_role            = true
    role_name              = "alb-controller"
    role_name_use_prefix   = true
    policy_name            = "alb-controller"
    policy_name_use_prefix = true
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
    } : {
    create_role            = true
    role_name              = "${module.eks.cluster_name}-alb-controller"
    role_name_use_prefix   = false
    policy_name            = "${module.eks.cluster_name}-alb-controller"
    policy_name_use_prefix = false
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  enable_karpenter                           = true
  karpenter_enable_instance_profile_creation = true
  karpenter_enable_spot_termination          = true

  karpenter = {
    chart_version          = local.karpenter_chart_version
    repository_username    = var.region == "us-east-1" ? data.aws_ecrpublic_authorization_token.token[0].user_name : data.aws_ecrpublic_authorization_token.token_other[0].user_name
    repository_password    = var.region == "us-east-1" ? data.aws_ecrpublic_authorization_token.token[0].password : data.aws_ecrpublic_authorization_token.token_other[0].password
    role_name              = var.dynamic_role ? "karpenter" : "${module.eks.cluster_name}-karpenter"
    role_name_use_prefix   = var.dynamic_role ? true : false
    policy_name            = var.dynamic_role ? "karpenter" : "${module.eks.cluster_name}-karpenter"
    policy_name_use_prefix = var.dynamic_role ? true : false

    namespace = "kube-system"
  }
  karpenter_node = {
    create_iam_role          = true
    iam_role_name            = var.dynamic_role ? "karpenter-${module.eks.cluster_name}" : "${module.eks.cluster_name}-karpenter-node"
    instance_profile_name    = var.dynamic_role ? "karpenter-${module.eks.cluster_name}" : "${module.eks.cluster_name}-karpenter-node"
    iam_role_use_name_prefix = false
    iam_role_additional_policies = {
      "AmazonSSMManagedInstanceCore" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  enable_aws_for_fluentbit = try(var.feature_flags.container_insights, false)
  # enable_aws_for_fluentbit = true
  # aws_for_fluentbit_cw_log_group = var.dynamic_role ? {
  #   create          = true
  #   use_name_prefix = true
  #   name_prefix     = "cct-plataforma-"
  #   retention       = 7
  #   } : {
  #   create          = true
  #   use_name_prefix = false
  #   name_prefix     = "${module.eks.cluster_name}-log-fluentbit"
  #   retention       = 7
  # }

  aws_for_fluentbit_cw_log_group = try(var.feature_flags.container_insights, false) ? (
    var.dynamic_role ? {
      create          = true
      use_name_prefix = true
      name_prefix     = "cct-plataforma-"
      retention       = 7
      } : {
      create          = true
      use_name_prefix = false
      name_prefix     = "${module.eks.cluster_name}-log-fluentbit"
      retention       = 7
    }
    ) : {
    create          = false
    use_name_prefix = false
    name_prefix     = ""
    retention       = 7
  }

  # aws_for_fluentbit = var.dynamic_role ? {
  #   enable_containerinsights = true
  #   kubelet_monitoring       = true
  #   role_name                = "cct-plataforma-"
  #   role_name_use_prefix     = true
  #   policy_name              = "cct-plataforma-aws-for-fluent-bit"
  #   policy_name_use_prefix   = true
  #   chart_version            = "0.1.35" #Previous version: 0.1.33
  #   set = [{
  #     name  = "cloudWatchLogs.autoCreateGroup"
  #     value = true
  #     },
  #     {
  #       name  = "hostNetwork"
  #       value = true
  #     },
  #     {
  #       name  = "dnsPolicy"
  #       value = "ClusterFirstWithHostNet"
  #     }
  #   ]
  #   s3_bucket_arns = [
  #     "arn:aws:s3:::${local.bucket_name}",
  #     "arn:aws:s3:::${local.bucket_name}/logs/*"
  #   ]
  #   } : {
  #   enable_containerinsights = true
  #   kubelet_monitoring       = true
  #   role_name                = "${module.eks.cluster_name}-aws-for-fluent-bit"
  #   role_name_use_prefix     = false
  #   policy_name              = "${module.eks.cluster_name}-aws-for-fluent-bit"
  #   policy_name_use_prefix   = false
  #   chart_version            = "0.1.35" #Previous version: 0.1.33
  #   set = [{
  #     name  = "cloudWatchLogs.autoCreateGroup"
  #     value = true
  #     },
  #     {
  #       name  = "hostNetwork"
  #       value = true
  #     },
  #     {
  #       name  = "dnsPolicy"
  #       value = "ClusterFirstWithHostNet"
  #     }
  #   ]
  #   s3_bucket_arns = [
  #     "arn:aws:s3:::${local.bucket_name}",
  #     "arn:aws:s3:::${local.bucket_name}/logs/*"
  #   ]
  # }
  aws_for_fluentbit = try(var.feature_flags.container_insights, false) ? (
    var.dynamic_role ? {
      enable_containerinsights = true
      kubelet_monitoring       = true
      role_name                = "${module.eks.cluster_name}-"
      role_name_use_prefix     = true
      policy_name              = "${module.eks.cluster_name}-for-fluent-bit"
      policy_name_use_prefix   = true
      #chart_version            = "0.1.35" #Previous version: 0.1.33
      set = [{
        name  = "cloudWatchLogs.autoCreateGroup"
        value = true
        },
        {
          name  = "hostNetwork"
          value = true
        },
        {
          name  = "dnsPolicy"
          value = "ClusterFirstWithHostNet"
        }
      ]
      s3_bucket_arns = local.enable_velero ? [
        "arn:aws:s3:::${local.bucket_name}",
        "arn:aws:s3:::${local.bucket_name}/logs/*"
      ] : []
      } : {
      enable_containerinsights = true
      kubelet_monitoring       = true
      role_name                = "${module.eks.cluster_name}-aws-for-fluent-bit"
      role_name_use_prefix     = false
      policy_name              = "${module.eks.cluster_name}-aws-for-fluent-bit"
      policy_name_use_prefix   = false
      #chart_version            = "0.1.35" #Previous version: 0.1.33
      set = [{
        name  = "cloudWatchLogs.autoCreateGroup"
        value = true
        },
        {
          name  = "hostNetwork"
          value = true
        },
        {
          name  = "dnsPolicy"
          value = "ClusterFirstWithHostNet"
        }
      ]
      s3_bucket_arns = local.enable_velero ? [
        "arn:aws:s3:::${local.bucket_name}",
        "arn:aws:s3:::${local.bucket_name}/logs/*"
      ] : []
    }
    ) : {
    enable_containerinsights = false
    kubelet_monitoring       = false
    role_name                = ""
    role_name_use_prefix     = false
    policy_name              = ""
    policy_name_use_prefix   = false
    #chart_version            = "0.1.35" #Previous version: 0.1.33
    set                      = []
    s3_bucket_arns           = []
  }

  # Custom helm_releases
  helm_releases = merge(local.helm_velero, local.helm_kube_green)

  tags = local.combined_tags
}

resource "aws_eks_access_entry" "karpenter_entry" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.eks_blueprints_addons.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"

  depends_on = [module.eks_blueprints_addons,
  module.eks]
}

resource "kubectl_manifest" "karpenter_crd_patch" {
  for_each = toset(local.karpenter_crds)

  yaml_body = <<YAML
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: ${each.key}
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: karpenter-crd
    meta.helm.sh/release-namespace: kube-system
YAML

  server_side_apply = true
  force_conflicts   = true

  depends_on = [module.eks_blueprints_addons, module.eks]
}

resource "helm_release" "karpenter_crd" {
  name             = "karpenter-crd"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter-crd"
  version          = local.karpenter_chart_version
  namespace        = "kube-system"
  create_namespace = true
  force_update     = true
  recreate_pods    = true
  replace          = true

  # depends_on = [
  #   kubectl_manifest.karpenter_crd_patch
  # ]
  depends_on = [
    module.eks_blueprints_addons,
    module.eks,
    kubectl_manifest.karpenter_crd_patch
  ]
}

data "aws_iam_roles" "adot_old" {
  name_regex = "^${module.eks.cluster_name}-adot$"
}

locals {
  adot_old_role_exists = length(data.aws_iam_roles.adot_old.arns) > 0
  adot_role_name       = local.adot_old_role_exists ? "${module.eks.cluster_name}-adot" : "cct-plataforma-adot"
}

module "adot_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39"

  role_name        = var.dynamic_role ? null : local.adot_role_name
  role_name_prefix = var.dynamic_role ? "cct-plataforma-adot-" : null

  role_policy_arns = {
    prometheus = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
    xray       = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["opentelemetry-operator-system:opentelemetry-operator"]
    }
  }

  tags = local.combined_tags
}

#module "adot_irsa" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "5.39"

#  role_name        = var.dynamic_role ? null : "cct-plataforma-adot"
#  role_name_prefix = var.dynamic_role ? "cct-plataforma-adot-" : null

#  role_policy_arns = {
#    prometheus = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
#    xray       = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
#    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#  }
#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["opentelemetry-operator-system:opentelemetry-operator"]
#    }
#  }

#  tags = local.combined_tags
#}

#-------------------------------------
# crea rol & service account de velero
locals {
  #bucket_name = "velero-${var.eks.cluster_name}-${data.aws_caller_identity.current.account_id}"
  bucket_name   = "velero-eks-${var.eks.cluster_name}-${data.aws_caller_identity.current.account_id}"
  enable_velero = lookup(var.feature_flags, "velero", false)
  helm_velero = local.enable_velero ? {
      velero = {
        name             = "velero"
        namespace        = "velero"
        create_namespace = true
        timeout          = var.timeout
        chart            = "${path.module}/helm-charts/helm-charts-velero-11.2.0/velero"
        values = [
          templatefile(
            "${path.module}/packages/velero/velero-values.yaml",
            {
              BUCKET = local.bucket_name,
              ROLE   = module.velero_irsa[0].iam_role_arn
              REGION = var.region
            }
          )
        ]
      }
    } : {}

  enable_kube_green = lookup(var.feature_flags, "kube-green", false)
  helm_kube_green = local.enable_kube_green ? {
      kube_green = {
        name             = "kube-green"
        namespace        = "kube-green"
        create_namespace = true
        timeout          = var.timeout
        chart            = "${path.module}/helm-charts/helm-charts-kube-green-0.7.1"
        values = [
                  templatefile(
                    "${path.module}/packages/kube-green/kube-green-values.yaml",
                    {} #TODO: SET VARIABLES
                  )
                ]
      }
    } : {}

}

resource "aws_s3_bucket" "velero_bucket" {
  count  = local.enable_velero ? 1 : 0
  bucket = local.bucket_name

  tags = merge(
    local.combined_tags,
    {
      "cfct" = "customization"
    }
  )
}

resource "aws_s3_bucket_acl" "velero_bucket_acl" {
  count      = local.enable_velero ? 1 : 0
  bucket     = aws_s3_bucket.velero_bucket[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.velero_bucket_ownership]
}

resource "aws_s3_bucket_ownership_controls" "velero_bucket_ownership" {
  count  = local.enable_velero ? 1 : 0
  bucket = aws_s3_bucket.velero_bucket[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_bucket_encryption" {
  count  = local.enable_velero ? 1 : 0
  bucket = aws_s3_bucket.velero_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# resource "aws_s3_bucket_policy" "velero_bucket_policy" {
#   count  = local.enable_velero ? 1 : 0
#   bucket = aws_s3_bucket.velero_bucket[0].id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = local.velero_policy_principals
#         }
#         Action = "s3:*"
#         Resource = [
#           "arn:aws:s3:::${local.bucket_name}",
#           "arn:aws:s3:::${local.bucket_name}/*"
#         ]
#         Condition = {
#           Bool = {
#             "aws:SecureTransport" = "false"
#           }
#         }
#       }
#     ]
#   })
# }

resource "aws_s3_bucket_policy" "velero_bucket_policy" {
  count  = local.enable_velero ? 1 : 0
  bucket = aws_s3_bucket.velero_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = compact([
          strcontains(data.aws_caller_identity.current.arn, ":assumed-role/") ?
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${split("/", data.aws_caller_identity.current.arn)[1]}" :
          data.aws_caller_identity.current.arn,
          try(module.velero_irsa[0].iam_role_arn, null),
          try(tolist(data.aws_iam_roles.optional_terraform_role[0].arns)[0], null)
        ])
      }
      Action = "s3:*"
      Resource = [
        "arn:aws:s3:::${local.bucket_name}",
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
      # Condition = {
      #   Bool = { "aws:SecureTransport" = "false" }
      # }
    }]
  })
}


################################################################
################################################################
locals {
  # velero_s3_bucket_arns = [aws_s3_bucket.velero_bucket[0].arn]
  velero_s3_bucket_arns = local.enable_velero ? [aws_s3_bucket.velero_bucket[0].arn] : []
}

data "aws_iam_policy_document" "velero" {
  count = local.enable_velero ? 1 : 0

  statement {
    sid = "Ec2ReadWrite"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3ReadWrite"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [for bucket in local.velero_s3_bucket_arns : "${bucket}/*"]
  }

  statement {
    sid = "S3List"
    actions = [
      "s3:ListBucket",
    ]
    resources = local.velero_s3_bucket_arns
  }
}

resource "aws_iam_policy" "velero" {
  count = local.enable_velero ? 1 : 0

  name        = "${module.eks.cluster_name}-velero"
  description = "Provides Velero permissions to backup and restore cluster resources"
  policy      = data.aws_iam_policy_document.velero[0].json
  tags        = local.combined_tags
}
################################################################
################################################################

module "velero_irsa" {
  count = local.enable_velero ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39"

  role_name        = var.dynamic_role ? null : "${module.eks.cluster_name}-velero"
  role_name_prefix = var.dynamic_role ? "cct-plataforma-velero-" : null

  role_policy_arns = {
    policy = aws_iam_policy.velero[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["velero:velero"]
    }
  }
  tags = local.combined_tags
}

# https://github.com/terraform-aws-modules/terraform-aws-iam/blob/v5.39.0/modules/iam-role-for-service-accounts-eks/policies.tf#L151
data "aws_iam_policy_document" "ebs_csi" {

  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:EnableFastSnapshotRestores"
    ]

    resources = ["*"]
  }

  statement {
    actions = ["ec2:CreateTags"]

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateVolume",
        "CreateSnapshot",
      ]
    }
  }

  statement {
    actions = ["ec2:DeleteTags"]

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values = [
        true
      ]
    }
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/kubernetes.io/cluster/*"
      values   = ["owned"]
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = [true]
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/cluster/*"
      values   = ["owned"]
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = [true]
    }
  }
}

resource "aws_iam_policy" "ebs_csi" {

  name        = "${module.eks.cluster_name}-ebs-csi-policy"
  description = "Provides permissions to manage EBS volumes via the container storage interface driver"
  policy      = data.aws_iam_policy_document.ebs_csi.json

  tags = local.combined_tags
}


#-------------------------------------
data "aws_iam_roles" "ebs_csi_old" {
  name_regex = "^${module.eks.cluster_name}-ebs-csi-driver$"
}

locals {
  ebs_csi_old_role_exists = length(data.aws_iam_roles.ebs_csi_old.arns) > 0
  ebs_csi_role_name       = local.ebs_csi_old_role_exists ? "${module.eks.cluster_name}-ebs-csi-driver" : "cct-plataforma-ebs-csi-driver"
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39"

  role_name        = var.dynamic_role ? null : local.ebs_csi_role_name
  role_name_prefix = var.dynamic_role ? "cct-plataforma-ebs-csi-driver-" : null

  role_policy_arns = {
    policy = aws_iam_policy.ebs_csi.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }


  tags = local.combined_tags
}

#module "ebs_csi_driver_irsa" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "5.39"

#  role_name        = var.dynamic_role ? null : "cct-plataforma-ebs-csi-driver"
#  role_name_prefix = var.dynamic_role ? "cct-plataforma-ebs-csi-driver-" : null

#  role_policy_arns = {
#    policy = aws_iam_policy.ebs_csi.arn
#  }

#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#    }
#  }


#  tags = local.combined_tags
#}

resource "kubectl_manifest" "argocd_ingress" {
  count = var.feature_flags["argocd"]["enabled"] ? 1 : 0

  yaml_body = <<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cctargocd-ingress
  namespace: argocd
  annotations:
    alb.ingress.kubernetes.io/tags: Name=${module.eks.cluster_name},nombre=${module.eks.cluster_name},propietario=${var.mandatory_tags["propietario"]},creado-por=${var.mandatory_tags["creado-por"]},aplicacion=${var.mandatory_tags["aplicacion"]},apl=${var.mandatory_tags["apl"]},proyecto=${var.mandatory_tags["proyecto"]},ambiente=${var.mandatory_tags["ambiente"]},pais=${var.mandatory_tags["pais"]},unidad-negocio=${var.mandatory_tags["unidad-negocio"]},bandera=${var.mandatory_tags["bandera"]},cuenta=${data.aws_caller_identity.current.account_id},tf-module=${var.base_tags["tf-module"]},version-so=${var.mandatory_tags["version-so"]},plataforma=${var.mandatory_tags["plataforma"]}
    alb.ingress.kubernetes.io/certificate-arn: "${var.feature_flags["argocd"]["certificate_arn"]}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: "${var.feature_flags["argocd"]["ingress_argocd"]}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argo-cd-argocd-server
                port:
                  number: 80
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}

data "aws_secretsmanager_secret" "argocd_ldap" {
  name = "cct-plataforma-ldap-argocd"
}

data "aws_secretsmanager_secret_version" "argocd_ldap_current" {
  secret_id = data.aws_secretsmanager_secret.argocd_ldap.id
}

locals {
  ldap_secrets = jsondecode(data.aws_secretsmanager_secret_version.argocd_ldap_current.secret_string)
}

data "kubernetes_config_map" "argocd_cm" {
  count = var.feature_flags["argocd"]["enabled"] ? 1 : 0

  metadata {
    name      = "argocd-cm"
    namespace = "argocd"
  }

  depends_on = [
    module.eks_blueprints_addons,
    kubectl_manifest.argocd_ingress
  ]
}

resource "kubernetes_config_map_v1_data" "argocd_cm_update" {
  count = var.feature_flags["argocd"]["enabled"] ? 1 : 0

  metadata {
    name      = "argocd-cm"
    namespace = "argocd"
  }

  data = merge(
    #data.kubernetes_config_map.argocd_cm.data,
    data.kubernetes_config_map.argocd_cm[count.index].data,
    {
      "dex.config" = <<-EOT
      connectors:
        - type: ldap
          name: ldap
          id: ldap
          config:
            host: "ldap.cencosud.net:389"
            insecureNoSSL: true
            insecureSkipVerify: true
            bindDN: "${local.ldap_secrets.user}"
            bindPW: "${local.ldap_secrets.password}"
            usernamePrompt: User Name
            userSearch:
              baseDN: dc=cencosud,dc=corp
              filter: "(objectClass=person)"
              username: sAMAccountName
              idAttr: DN
              emailAttr: userPrincipalName
              nameAttr: cn
            groupSearch:
              baseDN: dc=cencosud,dc=corp
              filter: "(objectClass=group)"
              userMatchers:
              - userAttr: DN
                groupAttr: member
              nameAttr: cn
            orgs:
            - name: cencosud
      EOT
      "url"        = "https://${var.feature_flags.argocd.ingress_argocd}"
    }
  )

  force = true

  depends_on = [
    module.eks_blueprints_addons,
    kubectl_manifest.argocd_ingress
  ]
}

##### ArgoCD Post - Config #####
##### Prometheus Post - Config #####
data "aws_secretsmanager_secret" "prometheus_ldap" {
  name = "cct-plataforma-ldap-argocd"
}

data "aws_secretsmanager_secret_version" "prometheus_ldap_current" {
  secret_id = data.aws_secretsmanager_secret.prometheus_ldap.id
}

locals {
  prometheus_ldap_secrets = jsondecode(data.aws_secretsmanager_secret_version.prometheus_ldap_current.secret_string)
}

data "kubernetes_config_map" "prometheus_grafana" {
  count = var.feature_flags["kube_prometheus_stack"]["enabled"] ? 1 : 0

  metadata {
    name      = "kube-prometheus-stack-grafana"
    namespace = "kube-prometheus-stack"

  }

  depends_on = [
    module.eks_blueprints_addons
  ]
}

resource "kubernetes_config_map_v1_data" "prometheus_grafana_ldap" {
  count = var.feature_flags["kube_prometheus_stack"]["enabled"] ? 1 : 0

  metadata {
    name      = "kube-prometheus-stack-grafana"
    namespace = "kube-prometheus-stack"
  }

  data = merge(
    data.kubernetes_config_map.prometheus_grafana[count.index].data,
    {
      "grafana.ini" = <<-EOT
${try(data.kubernetes_config_map.prometheus_grafana[count.index].data["grafana.ini"], "")}
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true
EOT

      "ldap.toml" = <<-EOT
        [[servers]]
        host = "ldap.cencosud.net"
        port = 389
        use_ssl = false
        start_tls = false
        ssl_skip_verify = false
        bind_dn = "${local.prometheus_ldap_secrets.user}"
        bind_password = "${local.prometheus_ldap_secrets.password}"
        search_filter = "(sAMAccountName=%s)"
        search_base_dns = ["dc=cencosud,dc=corp"]
        [servers.attributes]
        name = "givenName"
        surname = "sn"
        username = "sAMAccountName"
        member_of = "memberOf"
        email = "mail"
      EOT
    }
  )

  force = true

  depends_on = [
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "grafana_patch_ldap" {
  count     = var.feature_flags["kube_prometheus_stack"]["enabled"] ? 1 : 0
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-prometheus-stack-grafana
  namespace: kube-prometheus-stack
spec:
  template:
    spec:
      containers:
      - name: grafana
        volumeMounts:
        - name: config
          mountPath: /etc/grafana/ldap.toml
          subPath: ldap.toml
          readOnly: true
YAML

  server_side_apply = true
  force_conflicts   = true
  wait_for_rollout  = true

  depends_on = [
    kubernetes_config_map_v1_data.prometheus_grafana_ldap,
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "grafana_ingress" {
  count = var.feature_flags["kube_prometheus_stack"]["enabled"] ? 1 : 0

  yaml_body = <<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cctgrafana-ingress
  namespace: kube-prometheus-stack
  annotations:
    alb.ingress.kubernetes.io/tags: Name=${module.eks.cluster_name},nombre=${module.eks.cluster_name},propietario=${var.mandatory_tags["propietario"]},creado-por=${var.mandatory_tags["creado-por"]},aplicacion=${var.mandatory_tags["aplicacion"]},apl=${var.mandatory_tags["apl"]},proyecto=${var.mandatory_tags["proyecto"]},ambiente=${var.mandatory_tags["ambiente"]},pais=${var.mandatory_tags["pais"]},unidad-negocio=${var.mandatory_tags["unidad-negocio"]},bandera=${var.mandatory_tags["bandera"]},cuenta=${data.aws_caller_identity.current.account_id},tf-module=${var.base_tags["tf-module"]},version-so=${var.mandatory_tags["version-so"]},plataforma=${var.mandatory_tags["plataforma"]}
    alb.ingress.kubernetes.io/certificate-arn: "${var.feature_flags["kube_prometheus_stack"]["certificate_arn"]}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/health
spec:
  ingressClassName: alb
  rules:
    - host: "${var.feature_flags["kube_prometheus_stack"]["ingress_grafana"]}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kube-prometheus-stack-grafana
                port:
                  number: 80
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}
