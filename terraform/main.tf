data "aws_caller_identity" "current" {}

module "network" {
  source = "./modules/network"

  project            = var.project
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

module "eks" {
  source = "./modules/eks"

  project         = var.project
  cluster_version = var.cluster_version
  lab_role_name   = var.lab_role_name

  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  # Sem NAT nao ha rota de saida na subnet privada, entao os nos precisam
  # da subnet publica para puxar imagem do ECR. Ligando o NAT, eles migram.
  nodes_in_private_subnets = var.enable_nat_gateway

  instance_type = var.node_instance_type
  desired_size  = var.node_desired_size
  min_size      = var.node_min_size
  max_size      = var.node_max_size
}

module "data_stores" {
  source = "./modules/data-stores"

  project                  = var.project
  vpc_id                   = module.network.vpc_id
  private_subnet_ids       = module.network.private_subnet_ids
  client_security_group_id = module.eks.node_security_group_id
  databases                = var.databases
}

module "ecr" {
  source   = "./modules/ecr"
  services = var.services
}

# ---------------------------------------------------------------------
# Configuracao das aplicacoes dentro do cluster.
#
# Tudo que e segredo ou endereco dinamico nasce aqui, no Terraform, e e
# injetado direto no cluster. O repositorio de GitOps carrega apenas o
# workload (Deployment, Service, Ingress, HPA) e nunca uma credencial.
# ---------------------------------------------------------------------

resource "kubernetes_namespace" "app" {
  metadata {
    name = "techchallenger"
  }
}

resource "random_password" "master_key" {
  length  = 32
  special = false
}

resource "random_password" "service_api_key" {
  length  = 48
  special = false
}

locals {
  ns = kubernetes_namespace.app.metadata[0].name
}

resource "kubernetes_secret" "auth" {
  metadata {
    name      = "auth-service-secret"
    namespace = local.ns
  }

  data = {
    DATABASE_URL = module.data_stores.database_urls["auth"]
    MASTER_KEY   = random_password.master_key.result
  }
}

resource "kubernetes_secret" "flag" {
  metadata {
    name      = "flag-service-secret"
    namespace = local.ns
  }

  data = {
    DATABASE_URL = module.data_stores.database_urls["flags"]
  }
}

resource "kubernetes_secret" "targeting" {
  metadata {
    name      = "targeting-service-secret"
    namespace = local.ns
  }

  data = {
    DATABASE_URL = module.data_stores.database_urls["targeting"]
  }
}

resource "kubernetes_secret" "evaluation" {
  metadata {
    name      = "evaluation-service-secret"
    namespace = local.ns
  }

  data = {
    REDIS_URL       = "redis://${module.data_stores.redis_endpoint}:6379"
    SERVICE_API_KEY = random_password.service_api_key.result
  }
}

resource "kubernetes_config_map" "flag" {
  metadata {
    name      = "flag-service-config"
    namespace = local.ns
  }

  data = {
    PORT             = "8002"
    AUTH_SERVICE_URL = "http://auth-service:8001"
  }
}

resource "kubernetes_config_map" "targeting" {
  metadata {
    name      = "targeting-service-config"
    namespace = local.ns
  }

  data = {
    PORT             = "8003"
    AUTH_SERVICE_URL = "http://auth-service:8001"
  }
}

resource "kubernetes_config_map" "evaluation" {
  metadata {
    name      = "evaluation-service-config"
    namespace = local.ns
  }

  data = {
    PORT                  = "8004"
    AUTH_SERVICE_URL      = "http://auth-service:8001"
    FLAG_SERVICE_URL      = "http://flag-service:8002"
    TARGETING_SERVICE_URL = "http://targeting-service:8003"
    AWS_REGION            = var.region
    AWS_SQS_URL           = module.data_stores.sqs_queue_url
  }
}

resource "kubernetes_config_map" "analytics" {
  metadata {
    name      = "analytics-service-config"
    namespace = local.ns
  }

  data = {
    PORT               = "8005"
    AWS_REGION         = var.region
    AWS_SQS_URL        = module.data_stores.sqs_queue_url
    AWS_DYNAMODB_TABLE = module.data_stores.dynamodb_table_name
  }
}

# ---------------------------------------------------------------------
# ArgoCD
# ---------------------------------------------------------------------

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 900

  # Expor via LoadBalancer facilita a gravacao do video.
  # Em ambiente real isso ficaria atras do Ingress com TLS.
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
}
