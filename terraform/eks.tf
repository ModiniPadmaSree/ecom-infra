# ═══════════════════════════════════════════════════════════
# EKS CLUSTER
# ═══════════════════════════════════════════════════════════

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = [var.my_ip] # only your IP - not 0.0.0.0/0!
    security_group_ids      = [aws_security_group.eks_nodes.id]
  }

  # Enable audit logging
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]

  tags = { Name = "ecom-cluster" }
}

# ───────────────────────────────────────────────────────────
# Launch Template
# Encrypted disks + IMDSv2 for nodes
# ───────────────────────────────────────────────────────────
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "ecom-eks-nodes-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # IMDSv2 - prevents pods from accessing node metadata
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "ecom-eks-lt" }
}

# ───────────────────────────────────────────────────────────
# EKS Node Group
# Private subnets only - no public IP on nodes
# ───────────────────────────────────────────────────────────
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ecom-nodes"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id # private only!
  instance_types  = [var.node_instance_type]

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr,
  ]

  tags = { Name = "ecom-nodes" }
}
