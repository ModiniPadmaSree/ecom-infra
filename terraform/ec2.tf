data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "c7i-flex.large"
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_size = 20          
    volume_type = "gp3"       
    encrypted   = true        
  }
  # IMDSv2 — prevents metadata attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "jenkins-server" }
}
resource "aws_eip" "jenkins" {
  instance   = aws_instance.jenkins.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "jenkins-eip" }
}
