# Generate SSH key pair
resource "tls_private_key" "k8s_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair with timestamp to ensure uniqueness
resource "aws_key_pair" "k8s_key" {
  # Add timestamp to make the key name unique
  key_name   = "${var.ssh_key_name}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  public_key = tls_private_key.k8s_ssh.public_key_openssh
}

# Save private key locally
resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/${var.ssh_key_name}.pem"
  content         = tls_private_key.k8s_ssh.private_key_pem
  file_permission = "0400"
} 