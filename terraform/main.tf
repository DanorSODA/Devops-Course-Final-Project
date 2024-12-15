# main.tf
# Main infrastructure configuration for Kubernetes cluster

# Ubuntu AMI data source
# Fetches the latest Ubuntu 22.04 LTS AMI for the current region
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
  owners = ["099720109477"] # Canonical's AWS account ID
}

# VPC Configuration
# Creates a Virtual Private Cloud for the Kubernetes cluster
resource "aws_vpc" "k8s_vpc_prod" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Enable DNS hostnames for EC2 instances
  enable_dns_support   = true # Enable DNS support

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc-prod"
  })
}

resource "aws_vpc" "k8s_vpc_staging" {
  cidr_block           = "10.1.0.0/16"  # Different CIDR for staging
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k8s-staging-vpc"
    Environment = "staging"
  }
}

# Public Subnet Configuration
# Creates a public subnet within the VPC for the Kubernetes nodes
resource "aws_subnet" "k8s_subnet_prod" {
  vpc_id                  = aws_vpc.k8s_vpc_prod.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true # Automatically assign public IPs to instances
  availability_zone       = "${var.aws_region}${var.availability_zone}"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-subnet-prod"
  })
}

resource "aws_subnet" "k8s_subnet_staging" {
  vpc_id                  = aws_vpc.k8s_vpc_staging.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}${var.availability_zone}"

  tags = {
    Name = "k8s-staging-subnet"
    Environment = "staging"
  }
}

# Internet Gateway
# Enables internet access for resources in the VPC
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc_prod.id

  tags = {
    Name = "k8s-igw"
  }
}

# Route Table
# Defines routing rules for the VPC
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-rt"
  }
}

# Route Table Association
# Associates the route table with the subnet
resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet_prod.id
  route_table_id = aws_route_table.k8s_rt.id
}

# Master Node Configuration
# Creates the Kubernetes master node EC2 instance
resource "aws_instance" "k8s_master_prod" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_master

  subnet_id                   = aws_subnet.k8s_subnet_prod.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id, aws_security_group.lb_sg.id]
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
      Name        = "${var.cluster_name}-master-prod"
      Role        = "master"
      Environment = "production"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

resource "aws_instance" "k8s_master_staging" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.k8s_subnet_staging.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg_staging.id, aws_security_group.lb_sg_staging.id]
  associate_public_ip_address = true
  key_name                   = aws_key_pair.k8s_key.key_name

  user_data = file("${path.module}/scripts/install_k8s_master.sh")

  monitoring = var.enable_detailed_monitoring

  root_block_device {
    volume_size = var.instance_root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
  }

  tags = {
    Name = "k8s-staging-master"
    Environment = "staging"
  }
}

# Worker Nodes Configuration
# Creates the Kubernetes worker node EC2 instances
resource "aws_instance" "k8s_workers_prod" {
  count         = var.worker_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_worker

  subnet_id                   = aws_subnet.k8s_subnet_prod.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id, aws_security_group.lb_sg.id]
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
      Name        = "${var.cluster_name}-worker-prod-${count.index + 1}"
      Role        = "worker"
      Environment = "production"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

resource "aws_instance" "k8s_workers_staging" {
  count         = 2  # Fixed number for staging
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id     = aws_subnet.k8s_subnet_staging.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg_staging.id, aws_security_group.lb_sg_staging.id]
  associate_public_ip_address = true
  key_name                   = aws_key_pair.k8s_key.key_name

  user_data = file("${path.module}/scripts/install_k8s_worker.sh")

  monitoring = var.enable_detailed_monitoring

  root_block_device {
    volume_size = var.instance_root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
  }

  tags = {
    Name = "k8s-staging-worker-${count.index + 1}"
    Environment = "staging"
  }
}

# Security Group Configurations

# Main Kubernetes Security Group
# Defines security rules for Kubernetes cluster nodes
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-face-detection-sg"
  description = "Security group for face detection Kubernetes cluster"
  vpc_id      = aws_vpc.k8s_vpc_prod.id

  tags = {
    Name = "k8s-sg"
  }
}

# SSH Access Rule
# Allows SSH access to the nodes for management
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "SSH"
  from_port        = 22
  to_port          = 22
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# Internal Communication Rule
# Allows all internal communication between cluster nodes
resource "aws_vpc_security_group_ingress_rule" "internal" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Internal cluster communication"
  from_port        = 0
  to_port          = 0
  ip_protocol      = "-1"
  referenced_security_group_id = aws_security_group.k8s_sg.id
}

# Outbound Traffic Rule
# Allows all outbound traffic from the cluster
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Allow all outbound traffic"
  ip_protocol      = "-1"
  from_port        = 0
  to_port          = 0
  cidr_ipv4        = "0.0.0.0/0"
}

# Load Balancer Security Group
# Defines security rules for the Kubernetes load balancer
resource "aws_security_group" "lb_sg" {
  name        = "k8s-lb-sg"
  description = "Security group for Kubernetes load balancer"
  vpc_id      = aws_vpc.k8s_vpc_prod.id

  tags = {
    Name = "k8s-lb-sg"
  }
}

# Load Balancer HTTP Rule
# Allows HTTP traffic to the load balancer
resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.lb_sg.id
  description      = "HTTP from internet"
  from_port        = 80
  to_port          = 80
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# Container Port Access Rule
# Allows traffic from load balancer to container ports
resource "aws_vpc_security_group_ingress_rule" "container_port" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Allow traffic from Load Balancer to container port"
  from_port        = 3000
  to_port          = 3000
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.lb_sg.id
}

# Load Balancer Outbound Rule
# Allows all outbound traffic from the load balancer
resource "aws_vpc_security_group_egress_rule" "lb_outbound" {
  security_group_id = aws_security_group.lb_sg.id
  description      = "Allow all outbound traffic"
  ip_protocol      = "-1"
  from_port        = 0
  to_port          = 0
  cidr_ipv4        = "0.0.0.0/0"
}

# Kubernetes API Server Rule
# Allows access to the Kubernetes API server
resource "aws_vpc_security_group_ingress_rule" "kubernetes_api" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Kubernetes API server"
  from_port        = 6443
  to_port          = 6443
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# NGINX Ingress HTTP Rule
# Allows HTTP traffic to NGINX Ingress controller
resource "aws_vpc_security_group_ingress_rule" "ingress_nodeport" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Ingress NodePort access"
  from_port        = 31652
  to_port          = 31652
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# NGINX Ingress HTTPS Rule
# Allows HTTPS traffic to NGINX Ingress controller
resource "aws_vpc_security_group_ingress_rule" "ingress_https_nodeport" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Ingress HTTPS NodePort access"
  from_port        = 31935
  to_port          = 31935
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# Security Groups for Staging
resource "aws_security_group" "k8s_sg_staging" {
  name        = "k8s-face-detection-sg-staging"
  description = "Security group for face detection Kubernetes cluster staging"
  vpc_id      = aws_vpc.k8s_vpc_staging.id

  tags = {
    Name = "k8s-sg-staging"
    Environment = "staging"
  }
}

# Load Balancer Security Group for Staging
resource "aws_security_group" "lb_sg_staging" {
  name        = "k8s-lb-sg-staging"
  description = "Security group for Kubernetes load balancer staging"
  vpc_id      = aws_vpc.k8s_vpc_staging.id

  tags = {
    Name = "k8s-lb-sg-staging"
    Environment = "staging"
  }
}

# Copy all the security group rules for staging
resource "aws_vpc_security_group_ingress_rule" "ssh_staging" {
  security_group_id = aws_security_group.k8s_sg_staging.id
  description      = "SSH"
  from_port        = 22
  to_port          = 22
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}