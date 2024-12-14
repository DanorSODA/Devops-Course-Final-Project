#!/bin/bash
set -e

set -x  # Print commands as they're executed

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a installation.log
}

# Function to check last command status
check_status() {
    if [ $? -eq 0 ]; then
        log "SUCCESS: $1"
    else
        log "ERROR: $1"
        exit 1
    fi
}

# Update and install required packages
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Configure kernel modules
cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Remove existing containerd configuration if it exists
rm -f /etc/containerd/config.toml


# Install containerd
apt-get update
apt-get install -y containerd

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd
systemctl enable containerd

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Add Docker repository
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt and install Docker and Kubernetes packages
apt-get update
apt-get install -y docker-ce kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure Docker daemon with systemd driver
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Create systemd directory for docker
mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Reset any previous Kubernetes configuration
kubeadm reset -f || true
rm -rf /etc/cni/net.d/*
rm -rf $HOME/.kube

# Initialize Kubernetes with explicit configurations
IPADDR=$(hostname -i)
kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --apiserver-advertise-address=$IPADDR \
    --ignore-preflight-errors=all

# Wait for 60 seconds to allow the API server to start
sleep 60

# Set up kubeconfig with proper permissions
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# Add to bashrc for persistence
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc

# Install Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Wait for system pods to be ready
echo "Waiting for system pods to be ready..."
kubectl wait --namespace kube-system \
    --for=condition=ready pod \
    --selector=k8s-app=kube-apiserver \
    --timeout=300s

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl create namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

# Wait for NGINX Ingress Controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Create SSL certificate
echo "Creating SSL certificate..."
cat <<EOF > openssl.conf
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_ext

[dn]
C = US
ST = CA
L = SFO
O = MyOrg
OU = MyUnit
CN = kubernetes

[v3_ext]
subjectAltName = @alt_names
keyUsage = keyEncipherment,dataEncipherment
extendedKeyUsage = serverAuth

[alt_names]
IP.1 = ${IPADDR}
EOF

# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout tls.key -out tls.crt \
-config openssl.conf

# Create Kubernetes TLS secret
kubectl create secret tls face-detection-tls \
--key tls.key \
--cert tls.crt

# Create directory for deployments
mkdir -p ~/k8s/deployments

# Wait for node to be ready
until kubectl get nodes | grep -w "Ready"; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo "Kubernetes master node setup completed!"
echo "NGINX Ingress Controller and SSL certificate configured!"