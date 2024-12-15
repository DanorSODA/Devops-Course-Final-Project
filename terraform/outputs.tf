# outputs.tf
# Output definitions for the Kubernetes cluster infrastructure

# Public IP address of the Kubernetes master node
output "prod_master_public_ip" {
  value = aws_instance.k8s_master_prod.public_ip
}

# List of public IP addresses for all worker nodes
output "prod_worker_public_ips" {
  value = aws_instance.k8s_workers_prod[*].public_ip
}

# Private IP address of the Kubernetes master node (for internal communication)
output "prod_master_private_ip" {
  value = aws_instance.k8s_master_prod.private_ip
}

# List of private IP addresses for all worker nodes (for internal communication)
output "prod_worker_private_ips" {
  value = aws_instance.k8s_workers_prod[*].private_ip
}

# Public IP address of the Kubernetes master node
output "staging_master_public_ip" {
  value = aws_instance.k8s_master_staging.public_ip
}

# List of public IP addresses for all worker nodes
output "staging_worker_public_ips" {
  value = aws_instance.k8s_workers_staging[*].public_ip
}

# Private IP address of the Kubernetes master node (for internal communication)
output "staging_master_private_ip" {
  value = aws_instance.k8s_master_staging.private_ip
}

# List of private IP addresses for all worker nodes (for internal communication)
output "staging_worker_private_ips" {
  value = aws_instance.k8s_workers_staging[*].private_ip
}