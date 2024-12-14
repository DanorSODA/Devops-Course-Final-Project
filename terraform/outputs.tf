# outputs.tf
# Output definitions for the Kubernetes cluster infrastructure

# Public IP address of the Kubernetes master node
output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

# List of public IP addresses for all worker nodes
output "worker_public_ips" {
  value = aws_instance.k8s_workers[*].public_ip
}

# Private IP address of the Kubernetes master node (for internal communication)
output "master_private_ip" {
  value = aws_instance.k8s_master.private_ip
}

# List of private IP addresses for all worker nodes (for internal communication)
output "worker_private_ips" {
  value = aws_instance.k8s_workers[*].private_ip
}