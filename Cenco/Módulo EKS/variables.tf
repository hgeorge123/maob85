#### GENERAL CONFIGURATION
variable "region" {
  type        = string
  description = "[REQUERIDO] Region donde se va a desplegar el cluster"
}

#### CLUSTER EKS
variable "eks" {
  type = object({
    cluster_name                    = string
    cluster_version                 = string
    cluster_endpoint_public_access  = bool
    cluster_endpoint_private_access = bool
    eks_managed_node_groups = map(object({
      name          = string
      instance_type = string
      worker_nodes  = number
      capacity_type = string
      disk_size     = number
    }))
  })

  validation {
    condition = (
      length(var.eks.cluster_name) <= 14 &&
      !can(regex("\\s", var.eks.cluster_name))
    )
    error_message = "El nombre del cluster no debe tener mas de 14 caracteres ni contener espacios en blanco"
  }

  validation {
    condition = alltrue([
      for _, ng in var.eks.eks_managed_node_groups : ng.worker_nodes <= 3
    ])
    error_message = "Ha superado el número máximo de nodos permitidos (3)."
  }

  validation {
    condition = alltrue([
      for _, ng in var.eks.eks_managed_node_groups : ng.disk_size <= 120
    ])
    error_message = "Ha superado el límite de disco permitido de 120 GB."
  }

  validation {
    condition = (
      can(regex("^1\\.\\d{2}$", var.eks.cluster_version)) &&
      tonumber(split(".", var.eks.cluster_version)[1]) >= 29
    )
    error_message = "La versión del cluster debe ser al menos 1.31 y tener el formato '1.xy' donde 'xy' son dos dígitos."
  }

  validation {
    condition = alltrue([
      for _, ng in var.eks.eks_managed_node_groups : contains([
        "t3a.large", "t3.large", "t3a.xlarge", "t3a.2xlarge", "t3.xlarge", "t3.2xlarge"
      ], ng.instance_type)
    ])
    error_message = "El tipo de instancia debe ser uno de los siguientes: t3a.large, t3.large, t3a.xlarge, t3a.2xlarge, t3.xlarge, t3.2xlarge"
  }

  validation {
    condition = alltrue([
      for _, ng in var.eks.eks_managed_node_groups : contains(["ON_DEMAND", "SPOT"], ng.capacity_type)
    ])
    error_message = "El tipo de capacidad debe ser 'ON_DEMAND' o 'SPOT'."
  }
}

#### ADDONS

variable "feature_flags" {
  type = any
  default = {
    enable_aws_efs_csi_driver           = false
    enable_kube_prometheus_stack        = false
    enable_external_dns                 = false
    enable_cert_manager                 = false
    enable_aws_load_balancer_controller = false
    enable_ingress_nginx                = false
    velero                              = false
    kube-green                          = false
    container_insights                  = false
    argocd = {
      enabled         = false
      ingress_argocd  = null
      certificate_arn = null
    }
    kube_prometheus_stack = {
      enabled         = false
      ingress_grafana = null
      certificate_arn = null
    }
  }
  description = "Feature flags para habilitar o deshabilitar componentes específicos"

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "enable_aws_efs_csi_driver", null))
    error_message = "El valor de 'enable_aws_efs_csi_driver' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "enable_external_dns", null))
    error_message = "El valor de 'enable_external_dns' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "enable_cert_manager", null))
    error_message = "El valor de 'enable_cert_manager' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "enable_aws_load_balancer_controller", null))
    error_message = "El valor de 'enable_aws_load_balancer_controller' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "enable_ingress_nginx", null))
    error_message = "El valor de 'enable_ingress_nginx' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "velero", null))
    error_message = "El valor de 'velero' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "kube-green", false))
    error_message = "El valor de 'kube-green' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags, "container_insights", false))
    error_message = "El valor de 'container_insights' debe ser 'true' o 'false'."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags["argocd"], "enabled", null))
    error_message = "El valor de 'argocd.enabled' debe ser 'true' o 'false'."
  }

  validation {
    condition     = var.feature_flags["argocd"]["enabled"] == false || can(regex("^(([a-zA-Z0-9_\\-]+)\\.)*([a-zA-Z0-9_\\-]+)\\.([a-zA-Z]{2,})$", var.feature_flags["argocd"]["ingress_argocd"]))
    error_message = "El valor de ingress_argocd debe ser un FQDN válido (por ejemplo, dominio.com, subdominio.dominio.com, subdominio.subdominio.dominio.com)."
  }

  validation {
    condition     = var.feature_flags["argocd"]["enabled"] == false || can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/[0-9a-f-]+$", var.feature_flags["argocd"]["certificate_arn"]))
    error_message = "El valor de certificate_arn debe ser un ARN válido de AWS Certificate Manager (por ejemplo, arn:aws:acm:region:account-id:certificate/certificate-id)."
  }

  validation {
    condition     = contains([true, false], lookup(var.feature_flags["kube_prometheus_stack"], "enabled", null))
    error_message = "El valor de 'kube_prometheus_stack.enabled' debe ser 'true' o 'false'."
  }

  validation {
    condition     = var.feature_flags["kube_prometheus_stack"]["enabled"] == false || can(regex("^(([a-zA-Z0-9_\\-]+)\\.)*([a-zA-Z0-9_\\-]+)\\.([a-zA-Z]{2,})$", var.feature_flags["kube_prometheus_stack"]["ingress_grafana"]))
    error_message = "El valor de ingress_grafana debe ser un FQDN válido (por ejemplo, dominio.com, subdominio.dominio.com, subdominio.subdominio.dominio.com)."
  }

  validation {
    condition     = var.feature_flags["kube_prometheus_stack"]["enabled"] == false || can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/[0-9a-f-]+$", var.feature_flags["kube_prometheus_stack"]["certificate_arn"]))
    error_message = "El valor de certificate_arn debe ser un ARN válido de AWS Certificate Manager (por ejemplo, arn:aws:acm:region:account-id:certificate/certificate-id)."
  }
}

#### NODE GROUPS

variable "ami_id" {
  description = "ID de la AMI a utilizar"
  type        = string
  #default     = "ami-0953c262131a91430"  #//"ami-05aca136585fd31d2"

  validation {
    condition     = can(regex("^ami-[a-f0-9]{17}$", var.ami_id))
    error_message = "El formato de la AMI no es válido. Debe seguir el formato 'ami-XXXXXXXXXXXXXXXXX'."
  }
}

#### NETWORKING
variable "vpc_id" {
  type        = string
  description = "[REQUERIDO] El ID de la VPC donde se deben desplegar los recursos"

  validation {
    condition = (
      can(regex("^vpc-[0-9a-f]{8}$|^vpc-[0-9a-f]{17}$", var.vpc_id))
    )
    error_message = "[ERROR] El ID de la VPC debe comenzar con el prefijo 'vpc-' y seguir con 8 o 17 caracteres alfanuméricos (formato antiguo o nuevo)."
  }
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Una lista de IDs de subnets donde se aprovisionarán los nodos/grupos de nodos. Si `control_plane_subnet_ids` no se proporciona, el plano de control del cluster EKS (ENIs) será aprovisionado en estas subnets"
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.private_subnet_ids) >= 2 && length(var.private_subnet_ids) <= 3
    )
    error_message = "La cantidad de subnet IDs debe ser mínimo 2 y máximo 3."
  }

  validation {
    condition = alltrue([
      for subnet_id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]{8}$|^subnet-[0-9a-f]{17}$", subnet_id))
    ])
    error_message = "Todos los IDs de subnets deben comenzar con 'subnet-' seguido de 8 o 17 caracteres hexadecimales (formatos antiguo o nuevo)."
  }
}

variable "container_subnet_ids" {
  description = "Una lista de IDs de subnets donde se aprovisionarán los nodos/grupos de nodos. Si `control_plane_subnet_ids` no se proporciona, el plano de control del cluster EKS (ENIs) será aprovisionado en estas subnets"
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.container_subnet_ids) >= 2 && length(var.container_subnet_ids) <= 3
    )
    error_message = "La cantidad de subnet IDs debe ser mínimo 2 y máximo 3."
  }

  validation {
    condition = alltrue([
      for subnet_id in var.container_subnet_ids : can(regex("^subnet-[0-9a-f]{8}$|^subnet-[0-9a-f]{17}$", subnet_id))
    ])
    error_message = "Todos los IDs de subnets deben comenzar con 'subnet-' seguido de 8 o 17 caracteres hexadecimales (formatos antiguo o nuevo)."
  }
}

#### LOGGING SERVICES
variable "log_group_retention_in_days" {
  description = "[REQUERIDO] El número de días para retener los eventos de log en CloudWatch"
  type        = number
  default     = 30

  validation {
    condition = (
      var.log_group_retention_in_days == 0 ||
      var.log_group_retention_in_days == 1 ||
      var.log_group_retention_in_days == 3 ||
      var.log_group_retention_in_days == 5 ||
      var.log_group_retention_in_days == 7 ||
      var.log_group_retention_in_days == 14 ||
      var.log_group_retention_in_days == 30 ||
      var.log_group_retention_in_days == 60 ||
      var.log_group_retention_in_days == 90 ||
      var.log_group_retention_in_days == 120 ||
      var.log_group_retention_in_days == 150 ||
      var.log_group_retention_in_days == 180 ||
      var.log_group_retention_in_days == 365 ||
      var.log_group_retention_in_days == 400 ||
      var.log_group_retention_in_days == 545 ||
      var.log_group_retention_in_days == 731 ||
      var.log_group_retention_in_days == 1827 ||
      var.log_group_retention_in_days == 3653
    )
    error_message = "[ERROR] El valor debe ser uno de los siguientes: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

#### SECURITY
variable "cluster_security_group_rules" {
  description = "A list of maps containing additional security group rules"
  type = list(object({
    type            = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = []
}

variable "additional_security_group_rules" {
  description = "A list of maps containing additional security group rules"
  type = list(object({
    type            = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = []
}

variable "additional_access_entries" {
  description = "Mapa de ARNs de roles o usuarios de IAM a una lista de ARNs de políticas para acceso al cluster"
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for principal, policies in var.additional_access_entries : (
        can(regex("^arn:aws:iam::\\d{12}:role(?:/[^/]+)*/[^/]+$|^arn:aws:iam::\\d{12}:user(?:/[^/]+)*/[^/]+$", principal)) && # Validar ARN del principal
        length(policies) > 0 &&                                                                                               # Asegurarse de que haya al menos una política asignada
        alltrue([for policy in policies : contains([
          "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy",
          "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
          "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
          "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        ], policy)]) # Asegurarse de que todas las políticas son válidas
      )
    ])
    error_message = "Cada clave debe ser un ARN válido de un usuario o rol de AWS con al menos una política asociada, y cada política debe ser una de las políticas permitidas de EKS.\n"
  }
}

###TAGS###
variable "base_tags" {
  type        = map(string)
  description = "Tags básicos con valores predeterminados para todos los recursos."
  default = {
    "tf-module"  = "cct-eks-blueprints-terraform"
    "EC2.8"      = "DMZ"
    "FW-Manager" = "DMZ"
    "dmz"        = "dmz"
  }
}

variable "mandatory_tags" {
  type        = map(string)
  description = "Mapa de tags para los recursos con validaciones específicas para cada tag."

  # Validación 1: Todos los tags deben estar en minúsculas y completos
  validation {
    condition = (
      length(keys(var.mandatory_tags)) == 12 &&
      alltrue([
        for k in keys(var.mandatory_tags) : k == lower(k)
      ]) &&
      alltrue([
        for v in values(var.mandatory_tags) : v == lower(v)
      ]) &&
      contains(keys(var.mandatory_tags), "propietario") &&
      contains(keys(var.mandatory_tags), "creado-por") &&
      contains(keys(var.mandatory_tags), "aplicacion") &&
      contains(keys(var.mandatory_tags), "apl") &&
      contains(keys(var.mandatory_tags), "proyecto") &&
      contains(keys(var.mandatory_tags), "ambiente") &&
      contains(keys(var.mandatory_tags), "pais") &&
      contains(keys(var.mandatory_tags), "unidad-negocio") &&
      contains(keys(var.mandatory_tags), "bandera") &&
      contains(keys(var.mandatory_tags), "cuenta") &&
      contains(keys(var.mandatory_tags), "plataforma") &&
      contains(keys(var.mandatory_tags), "version-so")
    )
    error_message = "Todos los tags y sus valores deben estar en minúsculas y completos, incluyendo propietario, creado-por, aplicacion, apl, proyecto, ambiente, pais, unidad-negocio, bandera, cuenta, plataforma, y version-so."
  }

  # Validación 2: Los correos en los tags 'propietario' y 'creado-por' deben ser válidos y de dominios autorizados
  validation {
    condition = (
      can(regex("@(blaisten\\.com\\.ar|cencosud\\.com\\.ar|disco\\.com\\.ar|discovirtual\\.com\\.ar|easy\\.com\\.ar|easyhome\\.com\\.ar|jumbo\\.com\\.ar|veadigital\\.com\\.ar|bretas\\.com\\.br|cencosud\\.com\\.br|gbarbosa\\.com\\.br|mercantilatacado\\.com\\.br|mercantilrodrigues\\.com\\.br|perini\\.com\\.br|prezunic\\.com\\.br|cencosud\\.cl|easy\\.cl|eurofashion\\.cl|johnsons\\.cl|jumbo\\.cl|jumboweb\\.cl|paris\\.cl|puntoscencosud\\.cl|santaisabel\\.cl|segurosparis\\.cl|skycostanera\\.cl|tarjetacencosud\\.cl|viajesparis\\.cl|almacenesmetro\\.co|easy\\.com\\.co|tarjetacencosud\\.co|tiendasjumbo\\.co|tiendasmetro\\.co|externos-ar\\.cencosud\\.com|externos-cl\\.cencosud\\.com|externos-br\\.cencosud\\.com|externos-pe\\.cencosud\\.com|externos-uy\\.cencosud\\.com|cencosud\\.com|cencosud\\.com\\.pe|cencosud\\.com\\.co|cencosud\\.com\\.uy|cencosud\\.uy|cencosudmedia\\.com|cencosudmedia\\.cl|gigaatacado\\.com\\.br)$", var.mandatory_tags["propietario"])) &&
      can(regex("@(blaisten\\.com\\.ar|cencosud\\.com\\.ar|disco\\.com\\.ar|discovirtual\\.com\\.ar|easy\\.com\\.ar|easyhome\\.com\\.ar|jumbo\\.com\\.ar|veadigital\\.com\\.ar|bretas\\.com\\.br|cencosud\\.com\\.br|gbarbosa\\.com\\.br|mercantilatacado\\.com\\.br|mercantilrodrigues\\.com\\.br|perini\\.com\\.br|prezunic\\.com\\.br|cencosud\\.cl|easy\\.cl|eurofashion\\.cl|johnsons\\.cl|jumbo\\.cl|jumboweb\\.cl|paris\\.cl|puntoscencosud\\.cl|santaisabel\\.cl|segurosparis\\.cl|skycostanera\\.cl|tarjetacencosud\\.cl|viajesparis\\.cl|almacenesmetro\\.co|easy\\.com\\.co|tarjetacencosud\\.co|tiendasjumbo\\.co|tiendasmetro\\.co|externos-ar\\.cencosud\\.com|externos-cl\\.cencosud\\.com|externos-br\\.cencosud\\.com|externos-pe\\.cencosud\\.com|externos-uy\\.cencosud\\.com|cencosud\\.com|cencosud\\.com\\.pe|cencosud\\.com\\.co|cencosud\\.com\\.uy|cencosud\\.uy|cencosudmedia\\.com|cencosudmedia\\.cl|gigaatacado\\.com\\.br)$", var.mandatory_tags["creado-por"]))
    )
    error_message = "Los tags 'propietario' y 'creado-por' deben ser correos válidos con dominios autorizados y estar en minúsculas."
  }

  # Validación 3: El tag 'apl' debe empezar con 'apl'
  validation {
    condition     = startswith(var.mandatory_tags["apl"], "apl")
    error_message = "El tag 'apl' debe empezar con 'apl' y estar en minúsculas."
  }

  # Validación 4: El tag 'pais' debe ser uno de los valores permitidos
  validation {
    condition     = contains(["ar", "br", "cl", "co", "pe", "uy", "regional"], var.mandatory_tags["pais"])
    error_message = "El valor para el tag 'pais' debe ser uno de los siguientes: ar, br, cl, co, pe, uy, regional y estar en minúsculas."
  }

  # Validación 5: El tag 'cuenta' debe ser un número de 12 dígitos
  validation {
    condition     = can(regex("^\\d{12}$", var.mandatory_tags["cuenta"]))
    error_message = "El tag 'cuenta' debe ser un número de 12 dígitos."
  }

  # Validación 6: Los valores de los tags no deben contener espacios al inicio o al final
  #validation {
  #  condition = alltrue([
  #    for v in values(var.mandatory_tags) : v == trimspace(v)
  #  ])
  #  error_message = "Los valores de los tags no deben contener espacios al inicio o al final."
  #}

  # Validación 7: Los valores de los tags no deben contener espacios internos
  #validation {
  #  condition = alltrue([
  #    for v in values(var.mandatory_tags) : can(regex("^[^\\s]+$", v))
  #  ])
  #  error_message = "Los valores de los tags no deben contener espacios internos."
  #}
}

variable "cni_delegation" {
  description = "Boolean to enable or disable CNI delegation"
  type        = bool
  default     = true

  validation {
    condition = (
      var.cni_delegation == true || var.cni_delegation == false
    )
    error_message = "The value must be either true or false."
  }
}

variable "timeout" {
  description = "Time in seconds to wait for any individual kubernetes operation (like Jobs for hooks). Defaults to `300` seconds"
  type        = number
  default     = 900
}

variable "create_autoscaling_role" {
  description = "Indica si se debe crear el rol de servicio vinculado de autoscaling"
  type        = bool
  default     = false

  validation {
    condition     = contains([true, false], var.create_autoscaling_role)
    error_message = "Valor inválido para create_autoscaling_role: debe ser true o false."
  }
}

variable "cct_public_eks" {
  description = "Boolean variable to indicate if the public EKS should be enabled"
  type        = bool
  default     = false

  validation {
    condition     = var.cct_public_eks == true || var.cct_public_eks == false
    error_message = "The cct_public_eks variable must be true or false."
  }
}

variable "use_bottlerocket" {
  description = "Use Bottlerocket for managed node groups"
  type        = bool
  default     = true

  validation {
    condition     = contains([true, false], var.use_bottlerocket)
    error_message = "The use_bottlerocket variable must be true or false."
  }
}

variable "rbac" {
  type        = string
  description = "User permissions and groups for the policy.csv"
}

variable "custom_tags" {
  description = "Mapa de etiquetas personalizadas opcional"
  type        = map(any)
  default     = {}
}

variable "aws_credential_vault" {
  description = "Mapa que contiene las credenciales que el vault usa en AWS"
  type        = map(string)
  default = {
    access_key = ""
    secret_key = ""
    token      = ""
  }
}

variable "dynamic_role" {
  description = "Indicates whether the role should be dynamic"
  type        = bool
  default     = false
}