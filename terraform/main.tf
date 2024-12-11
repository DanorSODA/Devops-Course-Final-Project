terraform {
  backend "s3" {
    bucket         = "DevOps-Tech-Courseterraform-state"
    key            = "k8s-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

# Public Subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}${var.availability_zone}"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-subnet"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

# Route Table
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-rt"
  }
}

resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

# Master Node
resource "aws_instance" "k8s_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_master

  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = concat(
    [aws_security_group.k8s_sg.id],
    var.additional_master_security_groups
  )
  associate_public_ip_address = true
  key_name                   = aws_key_pair.k8s_key.key_name

  user_data = file("${path.module}/scripts/install_k8s_master.sh")

  monitoring = var.enable_detailed_monitoring

  root_block_device {
    volume_size = var.instance_root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
  }

  tags = merge(
    var.tags,
    var.master_additional_tags,
    {
      Name        = "${var.cluster_name}-master"
      Role        = "master"
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

# Worker Nodes
resource "aws_instance" "k8s_workers" {
  count         = var.worker_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_worker

  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = concat(
    [aws_security_group.k8s_sg.id],
    var.additional_worker_security_groups
  )
  associate_public_ip_address = true
  key_name                   = aws_key_pair.k8s_key.key_name

  user_data = file("${path.module}/scripts/install_k8s_worker.sh")

  monitoring = var.enable_detailed_monitoring

  root_block_device {
    volume_size = var.instance_root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
  }

  tags = merge(
    var.tags,
    var.worker_additional_tags,
    {
      Name        = "${var.cluster_name}-worker-${count.index + 1}"
      Role        = "worker"
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

# Security Group
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Security group for Kubernetes cluster"
  vpc_id      = aws_vpc.k8s_vpc.id

  # Allow inbound HTTP traffic for the application
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API server
  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all internal communication between nodes
  ingress {
    description = "Internal cluster communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # NodePort range (for services)
  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Container port for your application
  ingress {
    description = "Application container port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
} 