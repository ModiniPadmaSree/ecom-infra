# Infrastructure Provisioning for E-Commerce Platform

This repository contains the infrastructure automation setup for provisioning and configuring the environment required for the E-Commerce application deployment.

The project demonstrates:
- Infrastructure as Code using Terraform
- Server configuration using Ansible
- AWS EC2 provisioning
- Kubernetes cluster setup
- Automated environment preparation for GitOps deployment

---

# Project Overview

Infrastructure provisioning and configuration are automated using:
- Terraform
- Ansible

The repository is responsible for:
- Provisioning AWS infrastructure
- Creating EC2 instances
- Configuring Kubernetes environment
- Preparing deployment infrastructure for CI/CD and GitOps workflows

---

# Infrastructure Workflow

```text
Terraform
      │
      ▼
AWS Infrastructure Provisioning
      │
      ▼
EC2 Instance Creation
      │
      ▼
Networking & Security Configuration
      │
      ▼
Ansible Configuration
      │
      ▼
Kubernetes Installation & Setup
      │
      ▼
Environment Ready for Deployment
```

---

# Technologies Used

- Terraform
- Ansible
- AWS EC2
- Kubernetes
- Linux
- YAML

---

# Repository Structure

```text
ecom-infra/
│
├── terraform/
│
├── ansible/
│
└── README.md
```

---

# Terraform Provisioning

Terraform is used for:
- Infrastructure provisioning
- EC2 instance creation
- Security group configuration
- Resource automation
- Environment setup

---

# Ansible Configuration

Ansible is used for:
- Server configuration
- Package installation
- Kubernetes installation
- Environment automation
- Cluster preparation

---

# Infrastructure Components

The infrastructure setup includes:
- AWS EC2 instances
- Kubernetes cluster
- Security groups
- Network configuration
- Deployment environment preparation

---

# Kubernetes Setup

The provisioned infrastructure is configured to support:
- Kubernetes deployments
- Argo CD GitOps workflows
- Monitoring stack deployment
- Container orchestration

---

# Deployment Integration

The infrastructure created by this repository is used by:

## Application Repository

```text
https://github.com/ModiniPadmaSree/ecom
```

---

## GitOps Deployment Repository

```text
https://github.com/ModiniPadmaSree/ecom-k8s
```

---

# Terraform Deployment

## Initialize Terraform

```bash
terraform init
```

---

## Validate Configuration

```bash
terraform validate
```

---

## Plan Infrastructure

```bash
terraform plan
```

---

## Apply Infrastructure

```bash
terraform apply
```

---

# Ansible Execution

## Run Ansible Playbook

```bash
ansible-playbook playbook.yml
```

---

# Repository

```text
https://github.com/ModiniPadmaSree/ecom-infra
```
