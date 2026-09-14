variable "region" {
  description = "Regiao AWS onde tudo sera criado"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo usado no nome de todos os recursos"
  type        = string
  default     = "togglemaster"
}

variable "vpc_cidr" {
  description = "Bloco de enderecos da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "lab_role_name" {
  description = "Role existente do AWS Academy. O Terraform apenas le, nunca cria"
  type        = string
  default     = "LabRole"
}

variable "enable_nat_gateway" {
  description = "NAT custa por hora. Com false, os nos ficam em subnet publica e so os bancos ficam privados"
  type        = bool
  default     = false
}

variable "cluster_version" {
  description = "Versao do Kubernetes no EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "Tipo de instancia dos nos do cluster"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "services" {
  description = "Os 5 microsservicos do ToggleMaster"
  type        = list(string)
  default = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service",
  ]
}

variable "databases" {
  description = "Um RDS PostgreSQL por servico que precisa de banco"
  type = map(object({
    username = string
    db_name  = string
  }))
  default = {
    auth = {
      username = "auth_user"
      db_name  = "auth_db"
    }
    flags = {
      username = "flags_user"
      db_name  = "flags_db"
    }
    targeting = {
      username = "targeting_user"
      db_name  = "targeting_db"
    }
  }
}

variable "argocd_chart_version" {
  description = "Versao do chart do ArgoCD"
  type        = string
  default     = "7.7.11"
}
