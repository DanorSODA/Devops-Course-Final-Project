variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

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

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Name prefix for the cluster resources"
  type        = string
  default     = "k8s"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "a"  # Will be combined with region like "us-east-1a"
}

variable "instance_root_volume_size" {
  description = "Root volume size for EC2 instances in GB"
  type        = number
  default     = 20
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "k8s-key"
}

variable "backend_bucket" {
  description = "S3 bucket name for terraform state"
  type        = string
  default     = "DevOps-Tech-Courseterraform-state"
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table name for terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "kubernetes-cluster"
    Terraform   = "true"
  }
}

variable "pod_network_cidr" {
  description = "CIDR block for pod network"
  type        = string
  default     = "10.244.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.29"
}

variable "ingress_controller_enabled" {
  description = "Enable NGINX ingress controller installation"
  type        = bool
  default     = true
}

variable "cert_manager_enabled" {
  description = "Enable cert-manager installation"
  type        = bool
  default     = true
}

variable "cert_manager_version" {
  description = "Version of cert-manager to install"
  type        = string
  default     = "v1.13.3"
}

variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring stack"
  type        = bool
  default     = false
}

variable "additional_master_security_groups" {
  description = "List of additional security group IDs for master node"
  type        = list(string)
  default     = []
}

variable "additional_worker_security_groups" {
  description = "List of additional security group IDs for worker nodes"
  type        = list(string)
  default     = []
}

variable "master_additional_tags" {
  description = "Additional tags for master node"
  type        = map(string)
  default     = {}
}

variable "worker_additional_tags" {
  description = "Additional tags for worker nodes"
  type        = map(string)
  default     = {}
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2 instances"
  type        = bool
  default     = false
}

variable "root_volume_type" {
  description = "Volume type for root disk"
  type        = string
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "IOPS for root volume (if using io1 or io2)"
  type        = number
  default     = 3000
}

variable "enable_ipv6" {
  description = "Enable IPv6 networking"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "infrastructure"
} 