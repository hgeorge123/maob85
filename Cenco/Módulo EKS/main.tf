data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_iam_roles" "sso_roles" {
  name_regex  = "^AWSReservedSSO_CencoAdm*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni"])

  addon_name         = each.value
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_ssm_parameter" "bottlerocket_ami_id" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.eks["cluster_version"]}/x86_64/latest/image_id"
}

locals {
  bottlerocket_config = {
    #ami_id   = data.aws_ami.bottlerocket[0].id
    ami_id = try(data.aws_ssm_parameter.bottlerocket_ami_id.value, "")

    use_latest_ami_release_version = true

    bootstrap_extra_args = <<-EOT
      [settings.kubernetes]
      "shutdown-grace-period" = "30s"
      "shutdown-grace-period-for-critical-pods" = "30s"
      max-pods = 110

      [settings.host-containers.admin]
      enabled = false

      [settings.host-containers.control]
      enabled = true

      [settings.kernel]
      lockdown = "integrity"
    EOT

    cloudinit_pre_nodeadm    = []
    post_bootstrap_user_data = ""
  }

  al2023_config = {
    ami_id = data.aws_ssm_parameter.al2023_ami_id.value

    use_latest_ami_release_version = false

    bootstrap_extra_args = "--use-max-pods false"

    cloudinit_pre_nodeadm = [
      {
        content_type = "application/node.eks.aws"
        content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  kind: KubeletConfiguration
                  apiVersion: kubelet.config.k8s.io/v1beta1
                  maxPods: 110
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
          EOT
      }
    ]

    post_bootstrap_user_data = <<-EOT
      yum install -y amazon-ssm-agent
      systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
    EOT
  }

  eks_node_group_config = var.use_bottlerocket ? local.bottlerocket_config : local.al2023_config

  #ami_id = var.use_bottlerocket ? data.aws_ami.bottlerocket[0].id : data.aws_ssm_parameter.al2023_ami_id.value
  ami_id                 = var.use_bottlerocket ? try(data.aws_ssm_parameter.bottlerocket_ami_id.value, "") : data.aws_ssm_parameter.al2023_ami_id.value
  user_data_bottlerocket = <<-EOT
    [settings.kubernetes]
    "kube-api-qps" = 30
    "shutdown-grace-period" = "30s"
    "shutdown-grace-period-for-critical-pods" = "30s"
    max-pods = 110

    [settings.kubernetes.eviction-hard]
    "memory.available" = "20%"

    [settings.host-containers.admin]
    enabled = false

    [settings.host-containers.control]
    enabled = true

    [settings.kernel]
    lockdown = "integrity"
  EOT

  user_data_al2023 = <<-EOT
    #!/bin/bash
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
    apiVersion: node.eks.aws/v1alpha1
    kind: NodeConfig
    spec:
      kubelet:
        maxPods: 110
        config:
          kind: KubeletConfiguration
          apiVersion: kubelet.config.k8s.io/v1beta1
          maxPods: 110
          shutdownGracePeriod: 5m
          featureGates:
            DisableKubeletCloudCredentialProviders: true
  EOT

  user_data = var.use_bottlerocket ? local.user_data_bottlerocket : local.user_data_al2023

}

################################################################################
# EKS Module
################################################################################

data "aws_ssm_parameter" "al2023_ami_id" {
  name = "/aws/service/eks/optimized-ami/${var.eks["cluster_version"]}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

output "ami_id" {
  value = nonsensitive(data.aws_ssm_parameter.al2023_ami_id.value)
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  # version = "20.33.1"
  version = "20.37.2"

  cluster_name                    = "cct-plataforma-${var.eks["cluster_name"]}"
  cluster_version                 = var.eks["cluster_version"]
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = var.eks["cluster_endpoint_private_access"]

  cluster_ip_family                      = "ipv4"
  create_cni_ipv6_iam_policy             = false
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.log_group_retention_in_days


  enable_cluster_creator_admin_permissions = true

  iam_role_name            = var.dynamic_role ? null : "cct-plataforma-${var.eks["cluster_name"]}"
  iam_role_use_name_prefix = var.dynamic_role ? true : false

  enable_efa_support = true
  create_kms_key     = false

  cluster_addons = {
    aws-ebs-csi-driver = {
      #most_recent              = true
      addon_version            = local.select_version_addon["aws-ebs-csi-driver"] #"v1.40.0-eksbuild.1"
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    coredns = {
      #most_recent = true
      addon_version = local.select_version_addon["coredns"] #"v1.11.4-eksbuild.2"
      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    eks-pod-identity-agent = {
      #most_recent = true
      addon_version = local.select_version_addon["eks-pod-identity-agent"] #"v1.3.5-eksbuild.2"
    }
    kube-proxy = {
      #most_recent = true
      addon_version = local.select_version_addon["kube-proxy"] #"v1.32.0-eksbuild.2"
    }
    vpc-cni = {
      #most_recent    = true
      addon_version  = local.select_version_addon["vpc-cni"] #"v1.19.3-eksbuild.1"
      before_compute = true
      configuration_values = jsonencode({
        env = local.vpc_cni_env
      })
    }
  }

  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.eks_kms_key.key_arn
  }

  cluster_encryption_policy_name            = "cct-plataforma-${var.eks["cluster_name"]}-cluster-encryption"
  cluster_encryption_policy_use_name_prefix = var.dynamic_role ? true : false

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    for name, ng in var.eks.eks_managed_node_groups : name => {
      name     = "cct-plataforma-${ng.name}"
      ami_type = var.use_bottlerocket ? "BOTTLEROCKET_x86_64" : "AL2023_x86_64_STANDARD"
      platform = var.use_bottlerocket ? "bottlerocket" : "al2023"
      ami_id   = var.use_bottlerocket ? "" : data.aws_ssm_parameter.al2023_ami_id.value

      use_latest_ami_release_version = local.eks_node_group_config.use_latest_ami_release_version

      bootstrap_extra_args = local.eks_node_group_config.bootstrap_extra_args

      cloudinit_pre_nodeadm    = local.eks_node_group_config.cloudinit_pre_nodeadm
      post_bootstrap_user_data = local.eks_node_group_config.post_bootstrap_user_data

      enable_bootstrap_user_data = var.use_bottlerocket ? false : true
      create_launch_template     = var.use_bottlerocket ? true : true
      launch_template_tags       = local.combined_tags
      use_custom_launch_template = true
      iam_role_name              = var.dynamic_role ? null : "cct-plataforma-${var.eks["cluster_name"]}-${ng.name}"
      iam_role_use_name_prefix   = var.dynamic_role ? true : false
      iam_role_attach_cni_policy = true
      iam_role_additional_policies = {
        AmazonEC2SSM                       = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
        SecretsManagerReadWrite            = "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
        AmazonEBSCSIDriver                 = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
        AmazonEFS                          = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy",
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        AmazonEKSClusterPolicy             = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        additional                         = aws_iam_policy.node_additional.arn
      }

      min_size       = 3           #ng.worker_nodes
      max_size       = 3           #ng.worker_nodes
      desired_size   = 3           #ng.worker_nodes
      capacity_type  = "ON_DEMAND" #ng.capacity_type
      instance_types = [ng.instance_type]

      ebs_optimized        = true
      enable_monitoring    = true
      force_update_version = true

      block_device_mappings = var.use_bottlerocket ? [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = ng.disk_size
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = module.eks_kms_key.key_arn
            iops                  = 3000
            throughput            = 125
          }
        },
        {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = ng.disk_size
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = module.eks_kms_key.key_arn
            iops                  = 3000
            throughput            = 125
          }
        }
        ] : [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = ng.disk_size
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = module.eks_kms_key.key_arn
            iops                  = 3000
            throughput            = 125
          }
        }
      ]
    }
  }

  node_security_group_additional_rules    = local.all_nodes_security_group_rules
  cluster_security_group_additional_rules = local.all_cluster_security_group_rules

  access_entries = local.combined_access_entries

  tags = local.combined_tags
}

resource "kubectl_manifest" "eni_config" {
  for_each = zipmap(var.azs, var.container_subnet_ids)

  yaml_body = yamlencode({
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = each.key
    }
    spec = {
      securityGroups = [
        module.eks.node_security_group_id
      ]
      subnet = each.value
    }
  })
}



################################################################################
# Supporting Resources
################################################################################
module "eks_kms_key" {
  # source  = "terraform-aws-modules/kms/aws"
  # version = "3.1.1"
  source = "./modules/terraform-aws-kms"

  deletion_window_in_days = 7
  enable_key_rotation     = true

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  # key_administrators = [
  #   data.aws_caller_identity.current.arn
  # ]
  key_administrators = [
    local.terraform_role_arn
  ]

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn
  ]

  # key_users = [
  #   "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cct-plataforma-eks-*",
  #   module.velero_irsa[0].iam_role_arn
  # ]

  # key_service_users = [
  #   "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  # ]

  # Aliases
  aliases = ["eks/${"cct-plataforma-${var.eks["cluster_name"]}"}/ebs"]

  tags = local.combined_tags
}

resource "aws_iam_policy" "node_additional" {
  name        = "${"cct-plataforma-${var.eks["cluster_name"]}"}-additional"
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.combined_tags
}

resource "kubectl_manifest" "karpenter_node_class_Bottlerocket" {
  count     = var.use_bottlerocket ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: "Bottlerocket"
      role:  ${module.eks_blueprints_addons.karpenter.node_iam_role_name}
      subnetSelectorTerms:
%{for subnet_id in var.private_subnet_ids~}
        - id: ${subnet_id}
%{endfor~}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      userData: |
        [settings.kubernetes]
        "kube-api-qps" = 30
        "shutdown-grace-period" = "60s"
        "shutdown-grace-period-for-critical-pods" = "60s"

        [settings.host-containers.admin]
        enabled = false

        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      tags:
        karpenter.sh/discovery: "${module.eks.cluster_name}"
        "Name": "karpenter-${module.eks.cluster_name}"
        "EC2.8": "${var.base_tags["EC2.8"]}"
        "FW-Manager": "${var.base_tags["FW-Manager"]}"
        "ambiente": "${var.mandatory_tags["ambiente"]}"
        "apl": "${var.mandatory_tags["apl"]}"
        "aplicacion": "${var.mandatory_tags["aplicacion"]}"
        "bandera": "${var.mandatory_tags["bandera"]}"
        "creado-por": "${var.mandatory_tags["creado-por"]}"
        "cuenta": "${data.aws_caller_identity.current.account_id}"
        "pais": "${var.mandatory_tags["pais"]}"
        "plataforma": "${var.mandatory_tags["plataforma"]}"
        "propietario": "${var.mandatory_tags["propietario"]}"
        "proyecto": "${var.mandatory_tags["proyecto"]}"
        "tf-module": "${var.base_tags["tf-module"]}"
        "unidad-negocio": "${var.mandatory_tags["unidad-negocio"]}"
        "version-so": "${var.mandatory_tags["version-so"]}"
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: disabled
        httpPutResponseHopLimit: 2
        httpTokens: required
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: "${lookup(values(var.eks.eks_managed_node_groups)[0], "disk_size", 50)}Gi"
            volumeType: gp3
            encrypted: true
            kmsKeyID: "${module.eks_kms_key.key_id}"
            iops: 3000
            troughput: 125
            deleteOnTermination: true
        - deviceName: /dev/xvdb
          ebs:
            volumeSize: "${lookup(values(var.eks.eks_managed_node_groups)[0], "disk_size", 50)}Gi"
            volumeType: gp3
            encrypted: true
            kmsKeyID: "${module.eks_kms_key.key_id}"
            iops: 3000
            troughput: 125
            deleteOnTermination: true
      amiSelectorTerms:
          - id: ${local.ami_id}
  YAML

  depends_on = [
    # helm_release.karpenter
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_class_AL2023" {
  count     = var.use_bottlerocket ? 0 : 1
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role:  ${module.eks_blueprints_addons.karpenter.node_iam_role_name}
      subnetSelectorTerms:
%{for subnet_id in var.private_subnet_ids~}
        - id: ${subnet_id}
%{endfor~}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      userData: |
        #!/bin/bash
        yum install -y amazon-ssm-agent
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
        apiVersion: node.eks.aws/v1alpha1
        kind: NodeConfig
        spec:
          kubelet:
            maxPods: 110
            config:
              kind: KubeletConfiguration
              apiVersion: kubelet.config.k8s.io/v1beta1
              maxPods: 110
              shutdownGracePeriod: 5m
              featureGates:
                DisableKubeletCloudCredentialProviders: true
      tags:
        "karpenter.sh/discovery": "${module.eks.cluster_name}"
        "Name": "karpenter-${module.eks.cluster_name}"
        "EC2.8": "${var.base_tags["EC2.8"]}"
        "FW-Manager": "${var.base_tags["FW-Manager"]}"
        "ambiente": "${var.mandatory_tags["ambiente"]}"
        "apl": "${var.mandatory_tags["apl"]}"
        "aplicacion": "${var.mandatory_tags["aplicacion"]}"
        "bandera": "${var.mandatory_tags["bandera"]}"
        "creado-por": "${var.mandatory_tags["creado-por"]}"
        "cuenta": "${data.aws_caller_identity.current.account_id}"
        "pais": "${var.mandatory_tags["pais"]}"
        "plataforma": "${var.mandatory_tags["plataforma"]}"
        "propietario": "${var.mandatory_tags["propietario"]}"
        "proyecto": "${var.mandatory_tags["proyecto"]}"
        "tf-module": "${var.base_tags["tf-module"]}"
        "unidad-negocio": "${var.mandatory_tags["unidad-negocio"]}"
        "version-so": "${var.mandatory_tags["version-so"]}"
        "instance-karpenter": "true"
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: disabled
        httpPutResponseHopLimit: 2
        httpTokens: required
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: "${lookup(values(var.eks.eks_managed_node_groups)[0], "disk_size", 50)}Gi"
            volumeType: gp3
            encrypted: true
            kmsKeyID: "${module.eks_kms_key.key_id}"
            iops: 3000
            throughput: 125
            deleteOnTermination: true
      amiSelectorTerms:
          - id: ${data.aws_ssm_parameter.al2023_ami_id.value}
  YAML

  depends_on = [
    # helm_release.karpenter
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_Bottlerocket" {
  count     = var.use_bottlerocket ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t", "c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["2", "4", "8"]
            - key: "node.kubernetes.io/instance-type"
              operator: Exists
              minValues: 4
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
      limits:
        cpu: "2000"
        memory: 1536Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 5m
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class_Bottlerocket
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_AL2023" {
  count     = var.use_bottlerocket ? 0 : 1
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t", "c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["2", "4", "8"]
            - key: "node.kubernetes.io/instance-type"
              operator: Exists
              minValues: 4
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
      limits:
        cpu: "2000"
        memory: 1536Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 5m
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class_AL2023
  ]
}

resource "kubectl_manifest" "karpenter_example_deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: inflate
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: inflate
      template:
        metadata:
          labels:
            app: inflate
        spec:
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
              resources:
                requests:
                  cpu: 1
  YAML

  depends_on = [
    # helm_release.karpenter
    module.eks_blueprints_addons
  ]
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  allow_volume_expansion = true
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    type                = "gp3"
    encrypted           = "true"
    tagSpecification_1  = "creado-por=cpe-plataforma"
    tagSpecification_2  = "propietario=cpe-plataforma"
    tagSpecification_3  = "cuenta=${var.mandatory_tags["cuenta"]}"
    tagSpecification_4  = "aplicacion=${var.mandatory_tags["aplicacion"]}"
    tagSpecification_5  = "apl=${var.mandatory_tags["apl"]}"
    tagSpecification_6  = "ambiente=${var.mandatory_tags["ambiente"]}"
    tagSpecification_7  = "pais=${var.mandatory_tags["pais"]}"
    tagSpecification_8  = "unidad-negocio=${var.mandatory_tags["unidad-negocio"]}"
    tagSpecification_9  = "bandera=${var.mandatory_tags["bandera"]}"
    tagSpecification_10 = "proyecto=${var.mandatory_tags["proyecto"]}"
  }

  depends_on = [
    module.eks_blueprints_addons,
    module.eks
  ]
}