terraform {
  # backend "s3" {
  #   bucket         = "devops-tech-course-terraform-state"
  #   key            = "k8s-cluster/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
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
      Name        = "${var.cluster_name}-worker-${count.index + 1}"
      Role        = "worker"
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

# Security Group for K8s nodes (master and workers)
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-face-detection-sg"
  description = "Security group for face detection Kubernetes cluster"
  vpc_id      = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-sg"
  }
}

# Allow SSH access for management
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "SSH"
  from_port        = 22
  to_port          = 22
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# Allow internal communication between nodes
resource "aws_vpc_security_group_ingress_rule" "internal" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Internal cluster communication"
  from_port        = 0
  to_port          = 0
  ip_protocol      = "-1"
  referenced_security_group_id = aws_security_group.k8s_sg.id
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Allow all outbound traffic"
  ip_protocol      = "-1"
  from_port        = 0
  to_port          = 0
  cidr_ipv4        = "0.0.0.0/0"
}

# Load Balancer Security Group
resource "aws_security_group" "lb_sg" {
  name        = "k8s-lb-sg"
  description = "Security group for Kubernetes load balancer"
  vpc_id      = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-lb-sg"
  }
}

# Allow HTTP traffic to Load Balancer
resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.lb_sg.id
  description      = "HTTP from internet"
  from_port        = 80
  to_port          = 80
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

# Allow Load Balancer to reach container port on nodes
resource "aws_vpc_security_group_ingress_rule" "container_port" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Allow traffic from Load Balancer to container port"
  from_port        = 3000
  to_port          = 3000
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.lb_sg.id
}

# Allow Load Balancer outbound traffic
resource "aws_vpc_security_group_egress_rule" "lb_outbound" {
  security_group_id = aws_security_group.lb_sg.id
  description      = "Allow all outbound traffic"
  ip_protocol      = "-1"
  from_port        = 0
  to_port          = 0
  cidr_ipv4        = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "kubernetes_api" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Kubernetes API server"
  from_port        = 6443
  to_port          = 6443
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "etcd" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "etcd server client API"
  from_port        = 2379
  to_port          = 2380
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "kubelet" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "Kubelet API"
  from_port        = 10250
  to_port          = 10250
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "kube_scheduler" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "kube-scheduler"
  from_port        = 10259
  to_port          = 10259
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "kube_controller_manager" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "kube-controller-manager"
  from_port        = 10257
  to_port          = 10257
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "nodeport" {
  security_group_id = aws_security_group.k8s_sg.id
  description      = "NodePort access"
  from_port        = 30080
  to_port          = 30080
  ip_protocol      = "tcp"
  cidr_ipv4        = "0.0.0.0/0"
} 