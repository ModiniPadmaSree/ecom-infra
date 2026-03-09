# ── JENKINS SG ─────────────────────────────────────────────
# Industry standard — public IP but restricted ports
resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Jenkins - SSH and UI from my IP only"
  vpc_id      = aws_vpc.main.id

  # SSH — your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Jenkins UI — your IP only
  ingress {
    description = "Jenkins UI from my IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node Exporter — Prometheus scrapes from VPC
  ingress {
    description = "Node Exporter for Prometheus"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS out — GitHub, DockerHub, SonarCloud, Slack, EKS
  egress {
    description = "HTTPS out"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP out — apt packages
  egress {
    description = "HTTP out"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NO UDP — prevents DDoS reuse (your previous incident)

  tags = { Name = "jenkins-sg" }
}

# ── ALB SG ─────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB - public HTTP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# ── EKS NODES SG ───────────────────────────────────────────
resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "EKS nodes"
  vpc_id      = aws_vpc.main.id

  # Node to node
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # EKS control plane
  ingress {
    description = "EKS control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Kubelet"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS out — DockerHub pulls
  egress {
    description = "HTTPS out"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP out
  egress {
    description = "HTTP out"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node to node egress
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  tags = { Name = "eks-nodes-sg" }
}


resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "eks_from_alb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
}
