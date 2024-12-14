# variables.tf
# Variables configuration for the Kubernetes cluster infrastructure

# AWS Region Configuration
variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-1"
}

# Instance Type Configurations
variable "instance_type_master" {
  description = "Instance type for the Kubernetes master node"
  type        = string
  default     = "t3.medium"
}

variable "instance_type_worker" {
  description = "Instance type for the Kubernetes worker nodes"
  type        = string
  default     = "t3.small"
}

# Cluster Size Configuration
variable "worker_count" {
  description = "Number of worker nodes to be created in the cluster"
  type        = number
  default     = 2
}

# Network Configurations
variable "vpc_cidr" {
  description = "CIDR block for the Virtual Private Cloud (VPC)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet within the VPC"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone suffix for the subnet (will be combined with region, e.g., us-east-1a)"
  type        = string
  default     = "a"
}

variable "pod_network_cidr" {
  description = "CIDR block for Kubernetes pod network"
  type        = string
  default     = "10.244.0.0/16"
}

# Cluster Naming
variable "cluster_name" {
  description = "Name prefix for all cluster resources"
  type        = string
  default     = "k8s"
}

# Storage Configuration
variable "instance_root_volume_size" {
  description = "Size of the root volume for EC2 instances in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "EBS volume type for root disk (gp3, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "IOPS for root volume (only applicable for io1 or io2 volume types)"
  type        = number
  default     = 3000
}

# SSH Access Configuration
variable "ssh_key_name" {
  description = "Name of the SSH key pair for EC2 instance access"
  type        = string
  default     = "face-detection-ssh-key"
}

# Resource Tagging
variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "kubernetes-cluster"
    Terraform   = "true"
  }
}

variable "master_additional_tags" {
  description = "Additional tags specific to the master node"
  type        = map(string)
  default     = {}
}

variable "worker_additional_tags" {
  description = "Additional tags specific to worker nodes"
  type        = map(string)
  default     = {}
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Version of Kubernetes to be installed"
  type        = string
  default     = "1.29"
}

# Add-ons Configuration
variable "ingress_controller_enabled" {
  description = "Flag to enable/disable NGINX ingress controller installation"
  type        = bool
  default     = true
}

variable "cert_manager_enabled" {
  description = "Flag to enable/disable cert-manager installation"
  type        = bool
  default     = true
}

variable "cert_manager_version" {
  description = "Version of cert-manager to be installed"
  type        = string
  default     = "v1.13.3"
}

variable "enable_monitoring" {
  description = "Flag to enable/disable Prometheus and Grafana monitoring stack"
  type        = bool
  default     = false
}

# Security Groups Configuration
variable "additional_master_security_groups" {
  description = "List of additional security group IDs to attach to master node"
  type        = list(string)
  default     = []
}

variable "additional_worker_security_groups" {
  description = "List of additional security group IDs to attach to worker nodes"
  type        = list(string)
  default     = []
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Flag to enable detailed CloudWatch monitoring for EC2 instances"
  type        = bool
  default     = false
}

# Network Features
variable "enable_ipv6" {
  description = "Flag to enable IPv6 networking in the VPC"
  type        = bool
  default     = false
}

# Backup Configuration
variable "backup_retention_days" {
  description = "Number of days to retain cluster backups"
  type        = number
  default     = 7
}

# Environment Information
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Resource Ownership
variable "owner" {
  description = "Owner or team responsible for the resources"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing and resource tracking"
  type        = string
  default     = "infrastructure"
} 