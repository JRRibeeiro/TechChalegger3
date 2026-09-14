# Problema do ovo e da galinha: o state precisa morar num bucket,
# mas o bucket precisa ser criado por alguem. Esta pasta roda UMA vez,
# com state local, so para criar o bucket. Depois nunca mais e tocada.
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.70" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  description = "Precisa ser unico no mundo inteiro, nao so na sua conta"
  type        = string
}

resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# O state guarda as senhas dos bancos. Este bloco garante que o bucket
# nunca fique publico por acidente.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  description = "Copie este valor para o campo bucket em backend.tf"
  value       = aws_s3_bucket.state.id
}
