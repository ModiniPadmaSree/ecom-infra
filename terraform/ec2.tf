# ═══════════════════════════════════════════════════════════
# EC2 INSTANCES
# ═══════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────
# Bastion Host
# Public subnet - only SSH entry point to private resources
# t2.micro - free tier, just for SSH tunneling
# ───────────────────────────────────────────────────────────
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true # needs public IP - entry point

  # IMDSv2 - prevents SSRF attacks on metadata service
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "ecom-bastion" }
}

# ───────────────────────────────────────────────────────────
# Jenkins Server
# Private subnet - NO public IP
# t3.medium - needs resources for Docker builds + Trivy
# Only reachable via bastion SSH tunnel
# ───────────────────────────────────────────────────────────
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "c7i-flex.large"
  subnet_id                   = aws_subnet.private[0].id # private subnet!
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = false # NO public IP
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_size           = 20    # enough for Docker images + Jenkins builds
    volume_type           = "gp3" # faster than gp2
    encrypted             = true  # encrypt disk at rest
    delete_on_termination = true
  }

  # IMDSv2 - prevents SSRF attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "ecom-jenkins" }
}
