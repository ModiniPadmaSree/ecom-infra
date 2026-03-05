# ═══════════════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════════════

output "bastion_public_ip" {
  description = "SSH to bastion using this IP"
  value       = aws_instance.bastion.public_ip
}

output "jenkins_private_ip" {
  description = "Jenkins private IP - access via bastion only"
  value       = aws_instance.jenkins.private_ip
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

# ───────────────────────────────────────────────────────────
# Useful commands - copy paste after terraform apply
# ───────────────────────────────────────────────────────────
output "cmd_ssh_bastion" {
  description = "SSH to bastion"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "cmd_ssh_jenkins" {
  description = "SSH to Jenkins via bastion in one command"
  value       = "ssh -i ${var.key_name}.pem -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.jenkins.private_ip}"
}

output "cmd_jenkins_ui" {
  description = "SSH tunnel to access Jenkins UI - then open http://localhost:8080"
  value       = "ssh -i ${var.key_name}.pem -L 8080:${aws_instance.jenkins.private_ip}:8080 ubuntu@${aws_instance.bastion.public_ip}"
}

output "cmd_kubectl_config" {
  description = "Configure kubectl to connect to EKS"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}
