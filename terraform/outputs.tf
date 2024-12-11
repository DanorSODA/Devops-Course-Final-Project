output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_public_ips" {
  value = aws_instance.k8s_workers[*].public_ip
}

output "master_private_ip" {
  value = aws_instance.k8s_master.private_ip
}

output "worker_private_ips" {
  value = aws_instance.k8s_workers[*].private_ip
} 