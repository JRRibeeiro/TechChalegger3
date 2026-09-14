resource "aws_ecr_repository" "this" {
  for_each = toset(var.services)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  # Varredura no proprio registry, em cima do Trivy que ja roda no pipeline.
  # Uma imagem que passou no CI mas cujo CVE foi publicado depois aparece aqui.
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Manter apenas as 10 imagens mais recentes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
