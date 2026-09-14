variable "project" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "client_security_group_id" {
  description = "SG dos nos do EKS. Unica origem autorizada a falar com banco e cache"
  type        = string
}
variable "databases" {
  type = map(object({
    username = string
    db_name  = string
  }))
}
