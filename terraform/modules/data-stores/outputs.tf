output "database_urls" {
  description = "String de conexao pronta por banco. Consumida so pelo Secret do cluster"
  sensitive   = true
  value = {
    for k, v in aws_db_instance.this :
    k => format(
      "postgres://%s:%s@%s:%d/%s",
      v.username,
      random_password.db[k].result,
      v.address,
      v.port,
      v.db_name,
    )
  }
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "sqs_queue_url" { value = aws_sqs_queue.events.url }
output "dynamodb_table_name" { value = aws_dynamodb_table.analytics.name }
