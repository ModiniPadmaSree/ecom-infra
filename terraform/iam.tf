# ═══════════════════════════════════════════════════════════
# IAM ROLES
# ═══════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────
# EKS Cluster Role
# Required for EKS control plane
# ───────────────────────────────────────────────────────────
resource "aws_iam_role" "eks_cluster" {
  name = "ecom-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# ───────────────────────────────────────────────────────────
# EKS Node Role
# Required for worker nodes to join cluster
# ───────────────────────────────────────────────────────────
resource "aws_iam_role" "eks_node" {
  name = "ecom-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Required to join EKS cluster
resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

# Required for pod networking (CNI)
resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

# Required for nodes to pull images - keep this even with DockerHub
# EKS nodes need ECR read access for AWS system images (coredns, kube-proxy)
resource "aws_iam_role_policy_attachment" "eks_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# ───────────────────────────────────────────────────────────
# Jenkins Role
# Only needs EKS access to run kubectl
# Using DockerHub not ECR - no ECR permissions needed
# ───────────────────────────────────────────────────────────
resource "aws_iam_role" "jenkins" {
  name = "ecom-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "jenkins" {
  name = "ecom-jenkins-policy"
  role = aws_iam_role.jenkins.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EKS - configure kubectl only
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "ecom-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# ───────────────────────────────────────────────────────────
# ALB Controller Role
# Required for AWS Load Balancer Controller in EKS
# Creates and manages ALB when Ingress resource is applied
# ───────────────────────────────────────────────────────────
resource "aws_iam_role" "alb_controller" {
  name = "ecom-alb-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "alb_controller" {
  name = "ecom-alb-controller-policy"
  role = aws_iam_role.alb_controller.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Load balancer management
          "elasticloadbalancing:*",
          # Security group for ALB
          "ec2:CreateSecurityGroup",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          # Certificate management
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate"
        ]
        Resource = "*"
      }
    ]
  })
}
