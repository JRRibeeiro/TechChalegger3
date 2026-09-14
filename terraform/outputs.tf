output "cluster_name" { value = module.eks.cluster_name }

output "kubeconfig_command" {
  description = "Rode isto depois do apply para apontar o kubectl no cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_registry" {
  description = "Valor do secret ECR_REGISTRY no GitHub Actions"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "ecr_repository_urls" { value = module.ecr.repository_urls }
output "redis_endpoint" { value = module.data_stores.redis_endpoint }
output "sqs_queue_url" { value = module.data_stores.sqs_queue_url }
output "vpc_id" { value = module.network.vpc_id }

output "argocd_senha_inicial" {
  description = "Comando que revela a senha do usuario admin do ArgoCD"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "service_api_key" {
  description = "Chave que o evaluation usa para falar com o auth"
  sensitive   = true
  value       = random_password.service_api_key.result
}
