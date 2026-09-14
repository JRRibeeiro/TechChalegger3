output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca" { value = aws_eks_cluster.this.certificate_authority[0].data }

output "node_security_group_id" {
  description = "SG que o EKS cria para os nos, usado como origem nas regras dos bancos"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
