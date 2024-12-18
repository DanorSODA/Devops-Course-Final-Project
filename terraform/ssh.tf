# ssh.tf
# SSH key configuration for Kubernetes cluster nodes

# Generate a new SSH key pair
resource "tls_private_key" "k8s_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the generated public key
resource "aws_key_pair" "k8s_key" {
  # Add timestamp to ensure unique key names
  key_name   = "${var.ssh_key_name}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  public_key = tls_private_key.k8s_ssh.public_key_openssh
}

# Save the private key locally for SSH access
resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/${var.ssh_key_name}.pem"
  content         = tls_private_key.k8s_ssh.private_key_pem
  file_permission = "0400"  # Secure file permissions for private key
}