locals {
  karpenter_crds = concat(
    ["ec2nodeclasses.karpenter.k8s.aws", "nodepools.karpenter.sh", "nodeclaims.karpenter.sh"],
    tonumber(split(".", var.eks.cluster_version)[1]) >= 34 ? ["nodeoverlays.karpenter.sh"] : []
  )

  eks_addon_versions = {
    "1.30" = {
      "aws-ebs-csi-driver"     = "v1.41.0-eksbuild.1"
      "coredns"                = "v1.11.4-eksbuild.2"
      "eks-pod-identity-agent" = "v1.3.5-eksbuild.2"
      "kube-proxy"             = "v1.30.9-eksbuild.3"
      "vpc-cni"                = "v1.19.3-eksbuild.1"
      "karpenter"              = "1.0.4"
    }
    "1.31" = {
      "aws-ebs-csi-driver"     = "v1.41.0-eksbuild.1"
      "coredns"                = "v1.11.4-eksbuild.2"
      "eks-pod-identity-agent" = "v1.3.5-eksbuild.2"
      "kube-proxy"             = "v1.31.3-eksbuild.2"
      "vpc-cni"                = "v1.19.3-eksbuild.1"
      "karpenter"              = "1.1.4"
    }
    "1.32" = {
      "aws-ebs-csi-driver"     = "v1.46.0-eksbuild.1"
      "coredns"                = "v1.11.4-eksbuild.14"
      "eks-pod-identity-agent" = "v1.3.8-eksbuild.2"
      "kube-proxy"             = "v1.32.6-eksbuild.2"
      "vpc-cni"                = "v1.20.0-eksbuild.1"
      "karpenter"              = "1.3.3"
    }
    "1.33" = {
      "aws-ebs-csi-driver"     = "v1.50.1-eksbuild.1"
      "coredns"                = "v1.12.4-eksbuild.1"
      "eks-pod-identity-agent" = "v1.3.8-eksbuild.2"
      "kube-proxy"             = "v1.33.3-eksbuild.10"
      "vpc-cni"                = "v1.20.3-eksbuild.1"
      "karpenter"              = "1.6.4"
    }
    "1.34" = {
      "aws-ebs-csi-driver"     = "v1.50.1-eksbuild.1"
      "coredns"                = "v1.12.4-eksbuild.1"
      "eks-pod-identity-agent" = "v1.3.8-eksbuild.2"
      "kube-proxy"             = "v1.34.0-eksbuild.4"
      "vpc-cni"                = "v1.20.3-eksbuild.1"
      "karpenter"              = "1.8.1"
    }
  }

  select_version_addon = lookup(local.eks_addon_versions, var.eks["cluster_version"], {})

  eks_version_formatted = "v${replace(var.eks["cluster_version"], ".", "-")}"
  vpc_cni_env = var.cni_delegation ? {
    ENABLE_PREFIX_DELEGATION           = "true"
    WARM_PREFIX_TARGET                 = "1"
    AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
    ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
    } : {
    AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
    ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
  }

  additional_tags = {
    "karpenter.sh/discovery" = "cct-plataforma-${var.eks["cluster_name"]}"
    Name                     = "cct-plataforma-${var.eks["cluster_name"]}"
  }

  combined_tags = merge(var.mandatory_tags, var.base_tags, local.additional_tags, var.custom_tags)

  combined_tags_yaml = yamlencode(local.combined_tags)

  # combined_tags_yaml = yamlencode(merge(
  #   var.mandatory_tags,
  #   var.base_tags,
  #   {
  #     "karpenter.sh/discovery" = "cct-plataforma-${var.eks["cluster_name"]}",
  #     "Name" = "cct-plataforma-${var.eks["cluster_name"]}"
  #   }
  # ))

  default_cluster_security_group_rules = {
    ingress_self_all = {
      description                = "Node to cluster all ports/protocols"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "ingress"
      source_node_security_group = true
    },
    ingress_cidr_runners = {
      description = "Ingress from runner"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "100.64.0.0/10"]
    },
    egress_all = {
      description      = "All traffic to all destinations"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  cluster_security_group_rules_map = { for idx, rule in var.cluster_security_group_rules : tostring(idx) => rule }
  all_cluster_security_group_rules = merge(local.default_cluster_security_group_rules, local.cluster_security_group_rules_map)

  default_nodes_security_group_rules = {
    #ingress_node_all = {
    #  description                   = "Node to node all ports/protocols"
    #  protocol                      = "-1"
    #  from_port                     = 0
    #  to_port                       = 0
    #  type                          = "ingress"
    #  source_node_security_group    = true
    #},
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    },
    egress_all = {
      description                   = "All traffic to all destinations"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "egress"
      cidr_blocks                   = ["0.0.0.0/0"]
      ipv6_cidr_blocks              = ["::/0"]
      source_cluster_security_group = false
    }
  }
  additional_security_group_rules_map = { for idx, sg_rule in var.additional_security_group_rules : tostring(idx) => sg_rule }
  all_nodes_security_group_rules      = merge(local.default_nodes_security_group_rules, local.additional_security_group_rules_map)

  account_id = data.aws_caller_identity.current.account_id

  terraform_role_arn = strcontains(data.aws_caller_identity.current.arn, ":assumed-role/") ? (
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${split("/", data.aws_caller_identity.current.arn)[1]}"
  ) : data.aws_caller_identity.current.arn

  sso_access_entries = {
    for arn in data.aws_iam_roles.sso_roles.arns : arn => {
      principal_arn = arn
      policy_associations = {
        default = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  segcorp_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ksg-segcorp"

  # Role de seguridad para administrar cluster con argocd
  segcorp_access_entry = {
    "${local.segcorp_role_arn}" = {
      principal_arn = local.segcorp_role_arn
      policy_associations = {
        default = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Convertir entradas adicionales en la estructura completa si no está vacía
  additional_access_entries = length(var.additional_access_entries) > 0 ? {
    for principal, policies in var.additional_access_entries : principal => {
      principal_arn = principal
      policy_associations = {
        for idx, policy in policies : "policy_${idx}" => {
          policy_arn = policy
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  } : {}

  # Combinar ambas entradas solo si additional_access_entries no está vacío
  combined_access_entries = length(local.additional_access_entries) > 0 ? merge(local.sso_access_entries, local.segcorp_access_entry, local.additional_access_entries) : merge(local.sso_access_entries, local.segcorp_access_entry)
}