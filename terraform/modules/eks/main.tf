# No AWS Academy o Terraform nao pode criar role nem policy de IAM.
# A LabRole ja existe na conta: aqui ela e apenas lida e reaproveitada.
data "aws_iam_role" "lab" {
  name = var.lab_role_name
}

locals {
  node_subnet_ids = var.nodes_in_private_subnets ? var.private_subnet_ids : var.public_subnet_ids
  all_subnet_ids  = concat(var.public_subnet_ids, var.private_subnet_ids)
}

resource "aws_eks_cluster" "this" {
  name     = "${var.project}-cluster"
  version  = var.cluster_version
  role_arn = data.aws_iam_role.lab.arn

  vpc_config {
    subnet_ids              = local.all_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

# O launch template existe por um motivo especifico: hop limit do IMDS.
# Na Fase 2 os pods nao alcancavam o metadata service porque o limite era 1,
# e cada no novo do autoscaling nascia quebrado. Fixando 2 aqui, todo no
# criado a partir de agora ja nasce correto.
resource "aws_launch_template" "nodes" {
  name_prefix   = "${var.project}-node-"
  instance_type = var.instance_type

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project}-node" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project}-ng"
  node_role_arn   = data.aws_iam_role.lab.arn
  subnet_ids      = local.node_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.this]
}
