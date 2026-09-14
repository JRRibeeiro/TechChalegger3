# As senhas nascem aqui e nunca passam por arquivo versionado.
# Ficam apenas no state remoto (S3, fora do git) e sao injetadas no cluster
# como Secret do Kubernetes pela raiz do projeto.
resource "random_password" "db" {
  for_each = var.databases

  length  = 24
  special = false
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project}-db-subnets" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds"
  description = "PostgreSQL acessivel somente de dentro do cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL vindo dos nos do EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.client_security_group_id]
  }

  tags = { Name = "${var.project}-rds" }
}

resource "aws_db_instance" "this" {
  for_each = var.databases

  identifier     = "${var.project}-${each.key}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = true

  db_name  = each.value.db_name
  username = each.value.username
  password = random_password.db[each.key].result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # A Fase 2 subiu com publicly_accessible ligado. Aqui fica desligado:
  # o banco so existe dentro da VPC, em subnet privada.
  publicly_accessible = false
  multi_az            = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = { Name = "${var.project}-${each.key}-db" }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-cache-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-redis"
  description = "Redis acessivel somente de dentro do cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis vindo dos nos do EKS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.client_security_group_id]
  }

  tags = { Name = "${var.project}-redis" }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${var.project}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]
}

resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = { Name = "ToggleMasterAnalytics" }
}

resource "aws_sqs_queue" "events" {
  name                       = "${var.project}-evaluation-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
}
