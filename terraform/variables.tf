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