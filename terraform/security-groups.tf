# ═══════════════════════════════════════════════════════════
# SECURITY GROUPS - FINAL CORRECT VERSION
#
# Project uses:
#   - GitHub       (clone code, push values.yaml)
#   - DockerHub    (push/pull images)
#   - SonarCloud   (code quality scan)
#   - Slack        (notifications)
#   - AWS EKS      (kubectl)
#   - apt          (package installs)
#
# DNS: AWS VPC has built-in DNS at 169.254.169.253
#      No egress rule needed for DNS!
#
# No UDP egress = No DOS attack possible!
# ═══════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────
# Bastion Security Group
#
# Purpose: SSH jump host + run kubectl + aws cli
# Inbound:  SSH from your IP only
# Outbound: HTTPS + HTTP for apt/kubectl/awscli
#           SSH to reach Jenkins in private subnet
# ───────────────────────────────────────────────────────────
resource "aws_security_group" "bastion" {
  name        = "ecom-bastion-sg"
  description = "Bastion: SSH jump host, kubectl, awscli"
  vpc_id      = aws_vpc.main.id

  # ── INBOUND ──────────────────────────────────────────────

  ingress {
    description = "SSH from your IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # ── OUTBOUND ─────────────────────────────────────────────

  # HTTPS - kubectl, awscli, apt updates
  egress {
    description = "HTTPS: kubectl, awscli, apt updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - apt package downloads
  egress {
    description = "HTTP: apt package downloads"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH to Jenkins in private subnet
  egress {
    description = "SSH: reach Jenkins in private subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "ecom-bastion-sg" }
}

# ───────────────────────────────────────────────────────────
# Jenkins Security Group
#
# Purpose: CI pipeline - build, test, scan, push images
# Inbound:  SSH + 8080 from bastion only
#           9100 from VPC for Prometheus scraping
# Outbound: HTTPS for GitHub, DockerHub, SonarCloud, Slack
#           HTTP for apt installs
#           VPC for EKS communication
#
# No UDP = No DOS attack possible!
# ───────────────────────────────────────────────────────────
resource "aws_security_group" "jenkins" {
  name        = "ecom-jenkins-sg"
  description = "Jenkins: private EC2, bastion access only, no UDP"
  vpc_id      = aws_vpc.main.id

  # ── INBOUND ──────────────────────────────────────────────

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "Jenkins UI via SSH tunnel from bastion"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "Prometheus: scrape Jenkins node exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ── OUTBOUND ─────────────────────────────────────────────

  # HTTPS covers ALL Jenkins needs:
  #   GitHub     → clone ecom repo, push to ecom-k8s values.yaml
  #   DockerHub  → push built images (ecom-frontend, ecom-backend)
  #   SonarCloud → send scan results
  #   Slack      → send pipeline notifications to #jenkins-ci
  #   AWS EKS    → kubectl commands
  #   Trivy      → download vulnerability database
  egress {
    description = "HTTPS: GitHub, DockerHub, SonarCloud, Slack, EKS, Trivy"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - apt installs (Java, Docker, Jenkins, yq, git)
  egress {
    description = "HTTP: apt installs - Java, Docker, Jenkins, yq"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VPC - talk to EKS control plane
  egress {
    description = "VPC: EKS API server communication"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "ecom-jenkins-sg" }
}

# ───────────────────────────────────────────────────────────
# ALB Security Group
#
# Purpose: Receive user traffic, forward to pods
# Inbound:  HTTP from internet (NexMart users)
# Outbound: TCP to EKS nodes only - nothing else!
# No UDP needed at all!
# ───────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "ecom-alb-sg"
  description = "ALB: HTTP in from internet, TCP out to EKS nodes only"
  vpc_id      = aws_vpc.main.id

  # ── INBOUND ──────────────────────────────────────────────

  ingress {
    description = "HTTP: NexMart app users"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── OUTBOUND ─────────────────────────────────────────────

  # TCP only to EKS nodes - ALB never needs UDP!
  egress {
    description     = "TCP to EKS nodes only: forward user traffic to pods"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  tags = { Name = "ecom-alb-sg" }
}

# ───────────────────────────────────────────────────────────
# EKS Nodes Security Group
#
# Purpose: Run frontend + backend + monitoring pods
# Inbound:  ALB traffic + node-to-node + EKS control plane
# Outbound: HTTPS to pull Docker images from DockerHub
#           HTTP for package installs
#           VPC for node-to-node + EKS control plane
#
# CRITICAL: No UDP to internet = No DOS attack!
# Previous attack happened because of egress all = UDP flood
# ───────────────────────────────────────────────────────────
resource "aws_security_group" "eks_nodes" {
  name        = "ecom-eks-nodes-sg"
  description = "EKS nodes: no UDP to internet, prevents DOS attack"
  vpc_id      = aws_vpc.main.id

  # ── INBOUND ──────────────────────────────────────────────

  # Node to node - required for Kubernetes networking
  ingress {
    description = "Node to node: Kubernetes pod communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # ALB forwards user traffic to frontend/backend pods
  ingress {
    description     = "ALB: user traffic to frontend and backend pods"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # EKS control plane manages nodes
  ingress {
    description = "EKS control plane: API server to nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "EKS control plane: kubelet port"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Prometheus scrapes metrics from pods
  ingress {
    description = "Prometheus: scrape frontend, backend, node metrics"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ── OUTBOUND ─────────────────────────────────────────────
  # ONLY TCP - No UDP to internet!
  # AWS VPC DNS handles name resolution internally
  # No DNS egress rule needed!

  # HTTPS - pull Docker images from DockerHub
  egress {
    description = "HTTPS: pull ecom-frontend, ecom-backend images from DockerHub"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - occasional package installs
  egress {
    description = "HTTP: package installs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node to node within VPC only
  egress {
    description = "Node to node: Kubernetes pod communication within VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # EKS control plane
  egress {
    description = "EKS control plane: nodes report back to API server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "ecom-eks-nodes-sg" }
}
