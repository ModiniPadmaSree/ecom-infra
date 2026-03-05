variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "ecom-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs - for Bastion and ALB"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs - for Jenkins and EKS nodes"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "key_name" {
  description = "Your EC2 key pair name"
  type        = string
}

variable "my_ip" {
  description = "Your public IP with /32"
  type        = string

}

variable "node_instance_type" {
  description = "EKS node instance type"
  default     = "c7i-flex.large"
}

variable "desired_capacity" {
  description = "Desired EKS nodes"
  default     = 2
}

variable "max_size" {
  description = "Maximum EKS nodes"
  default     = 3
}

variable "min_size" {
  description = "Minimum EKS nodes"
  default     = 1
}
