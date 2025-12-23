# locals {
#   container_insights_enabled = try(var.feature_flags.container_insights, false)
# }

# resource "kubernetes_manifest" "cloudwatch_metrics_node_selector" {
#   count = local.container_insights_enabled ? 1 : 0

#   manifest = {
#     apiVersion = "apps/v1"
#     kind       = "DaemonSet"
#     metadata = {
#       name      = "aws-cloudwatch-metrics"
#       namespace = "amazon-cloudwatch"
#     }
#     spec = {
#       template = {
#         spec = {
#           nodeSelector = {
#             "kubernetes.io/os" = "linux"
#           }
#         }
#       }
#     }
#   }

#   field_manager {
#     name            = "terraform"
#     force_conflicts = true
#   }

#   depends_on = [module.eks_blueprints_addons]
# }

# resource "kubernetes_manifest" "fluentbit_node_selector" {
#   count = local.container_insights_enabled ? 1 : 0

#   manifest = {
#     apiVersion = "apps/v1"
#     kind       = "DaemonSet"
#     metadata = {
#       name      = "aws-for-fluent-bit"
#       namespace = "kube-system"
#     }
#     spec = {
#       template = {
#         spec = {
#           nodeSelector = {
#             "kubernetes.io/os" = "linux"
#           }
#         }
#       }
#     }
#   }

#   field_manager {
#     name            = "terraform"
#     force_conflicts = true
#   }

#   depends_on = [module.eks_blueprints_addons]
# }