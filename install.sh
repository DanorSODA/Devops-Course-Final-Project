#!/bin/bash

# install.sh

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
if [ -f /etc/os-release ]; then
    # Linux
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
elif [ -f /etc/debian_version ]; then
    # Debian without os-release file
    OS="Debian"
elif [ "$(uname)" == "Darwin" ]; then
    # macOS
    OS="macOS"
else
    print_error "Unsupported operating system"
    exit 1
fi

print_message "Detected OS: $OS"

# Install dependencies based on OS
case $OS in
    "Ubuntu"|"Debian GNU/Linux"|"Linux Mint")
        print_message "Installing dependencies for Debian-based system..."
        
        # Update package list
        sudo apt-get update

        # Install common dependencies
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release \
            software-properties-common \
            unzip

        # Install AWS CLI
        if ! command_exists aws; then
            print_message "Installing AWS CLI..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        fi

        # Install Terraform
        if ! command_exists terraform; then
            print_message "Installing Terraform..."
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt-get update
            sudo apt-get install -y terraform
        fi

        # Install kubectl
        if ! command_exists kubectl; then
            print_message "Installing kubectl..."
            sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
            echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
            sudo apt-get update
            sudo apt-get install -y kubectl
        fi
        ;;

    "Red Hat Enterprise Linux"|"CentOS Linux"|"Fedora")
        print_message "Installing dependencies for Red Hat-based system..."
        
        # Install EPEL repository if not already installed
        if ! rpm -qa | grep -q epel-release; then
            sudo yum install -y epel-release
        fi
        
        # Install common dependencies
        sudo yum install -y \
            curl \
            unzip \
            wget \
            yum-utils

        # Install AWS CLI
        if ! command_exists aws; then
            print_message "Installing AWS CLI..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        fi

        # Install Terraform
        if ! command_exists terraform; then
            print_message "Installing Terraform..."
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            sudo yum install -y terraform
        fi

        # Install kubectl
        if ! command_exists kubectl; then
            print_message "Installing kubectl..."
            # Add Kubernetes repository
            cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
            sudo yum install -y kubectl
        fi

        # Install additional tools that might be needed
        sudo yum install -y \
            git \
            jq \
            python3 \
            python3-pip
        ;;

    "macOS")
        print_message "Installing dependencies for macOS..."
        
        # Install Homebrew if not installed
        if ! command_exists brew; then
            print_message "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        # Install AWS CLI
        if ! command_exists aws; then
            print_message "Installing AWS CLI..."
            brew install awscli
        fi

        # Install Terraform
        if ! command_exists terraform; then
            print_message "Installing Terraform..."
            brew install terraform
        fi

        # Install kubectl
        if ! command_exists kubectl; then
            print_message "Installing kubectl..."
            brew install kubectl
        fi
        ;;

    *)
        print_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

# Verify installations
print_message "Verifying installations..."

REQUIRED_COMMANDS=("aws" "terraform" "kubectl")
ALL_INSTALLED=true

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command_exists "$cmd"; then
        version=$($cmd version 2>&1 | head -n 1)
        print_message "$cmd is installed: $version"
    else
        print_error "$cmd is not installed properly"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    print_message "All required tools are installed successfully!"
    
    # Configure AWS CLI if not already configured
    if ! aws configure list &>/dev/null; then
        print_warning "AWS CLI is not configured. Please run 'aws configure' to set up your credentials."
    fi
else
    print_error "Some tools failed to install. Please check the error messages above."
    exit 1
fi

# Additional project-specific setup
print_message "Setting up project-specific configurations..."

# Create necessary directories
mkdir -p ~/.kube

# Clone the project repository if it doesn't exist
if [ ! -d "kubernetes-face-detection" ]; then
    print_message "Cloning project repository..."
    git clone https://github.com/yourusername/kubernetes-face-detection.git
    cd kubernetes-face-detection
    git submodule update --init --recursive
fi

print_message "Installation complete! You can now proceed with the project setup."

# Print next steps
cat << EOF

${GREEN}Next steps:${NC}
1. Configure AWS credentials:
   $ aws configure

2. Initialize Terraform:
   $ cd terraform
   $ terraform init

3. Review and apply Terraform configuration:
   $ terraform plan
   $ terraform apply

4. Configure kubectl with your cluster:
   $ aws eks update-kubeconfig --region <your-region> --name <cluster-name>

For more information, please refer to the project documentation.
EOF