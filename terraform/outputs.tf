output "jenkins_public_ip" {
  value = aws_eip.jenkins.public_ip
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "jenkins_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.jenkins.public_ip}"
}
