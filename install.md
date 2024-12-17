# 📥 Installation Guide

This guide provides detailed instructions for setting up the Face Detection App deployment environment.

## ✅ Prerequisites

Before beginning the installation, ensure you have:

- 🔑 AWS Account with appropriate permissions
- 📦 Git installed
- 💻 Terminal access
- 👑 Sudo/Administrator privileges

## 🚀 Automated Installation

### 1. 📂 Clone the Repository:

```bash
git clone --recursive https://github.com/DanorSODA/Devops-Course-Final-Project
cd Devops-Course-Final-Project
```

### 2. ⚙️ Run the Installation Script:

```bash
chmod +x install.sh
./install.sh
```

The installation script will:

- 🔍 Detect your operating system
- 📦 Install required dependencies
- ⚙️ Configure necessary tools
- ✅ Verify installations

## 🛠️ Post-Installation Setup

### 1. 🔑 Configure AWS Credentials

```bash
aws configure
```

### 2. 🏗️ Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. 🚀 Apply Terraform Configuration

```bash
terraform plan
terraform validate
terraform apply
terraform output
```

You should see outputs like:
prod_master_public_ip = "X.X.X.X"
prod_worker_public_ips = ["X.X.X.X", "X.X.X.X"]
staging_master_public_ip = "Y.Y.Y.Y"
staging_worker_public_ips = ["Y.Y.Y.Y", "Y.Y.Y.Y"]

### 4. 🔒 Set Up SSH Access

The Terraform configuration creates an SSH key pair. The private key is saved as `face-detection-ssh-key.pem` in the terraform directory.

Test the connection to the master node:

```bash
ssh -i terraform/face-detection-ssh-key.pem ubuntu@<prod/staging_master_public_ip>
```

### 5. ⚓ Deploy Kubernetes Resources

Copy deployment files to master node:

```bash
scp -i terraform/face-detection-ssh-key.pem -r k8s/deployments/*.yaml ubuntu@<prod/staging_master_public_ip>:~/k8s/deployments/
```

SSH into master node:

```bash
ssh -i terraform/face-detection-ssh-key.pem ubuntu@<prod/staging_master_public_ip>
```

Apply Kubernetes configurations:

```bash
cd ~/k8s/deployments/
# Create namespace first
kubectl apply -f face-detection-namespace.yaml

# Apply other resources in the namespace
kubectl apply -f face-detection-config.yaml
kubectl apply -f face-detection-deployment.yaml
kubectl apply -f face-detection-service.yaml
kubectl apply -f face-detection-ingress.yaml
```

### 6. ✅ Verify Deployment

```bash
kubectl get pods -n face-detection
kubectl get services -n face-detection
kubectl get ingress -n face-detection
```

Check pod status:

```bash
kubectl get pods -n face-detection -o wide
```

Check service status:

```bash
kubectl get services -n face-detection
```

Check ingress status:

```bash
kubectl get ingress -n face-detection
```

Check logs:

```bash
kubectl logs -l app=face-detection -n face-detection
```

Test the application:

```bash
curl http://<prod/staging_ingress_host>/api/v1/detect
```

### 7. 🔐 Configure GitHub Secrets

After successful deployment, you need to set up GitHub Secrets for the CD pipeline to work:

1. Get the production master node IP:

```bash
cd terraform
terraform output prod_master_public_ip
```

2. Get the SSH private key content:

```bash
cat terraform/face-detection-ssh-key.pem
```

3. Add secrets to GitHub:

   - Go to your GitHub repository
   - Navigate to `Settings` > `Secrets and variables` > `Actions`
   - Click `New repository secret`
   - Add the following secrets:

   a. Add Master IP:

   - Name: `MASTER_IP`
   - Value: [Your master node IP from step 1]

   b. Add SSH Private Key:

   - Name: `FACE_DETECTION_SSH_PRIVATE_KEY`
   - Value: [Your SSH private key content from step 2]

These secrets are required for:

- 🔄 GitHub Actions to connect to your Kubernetes cluster
- 🚀 Automated deployment updates
- ⚡ Continuous deployment pipeline

Verify the secrets are set correctly in your GitHub repository settings before running any workflows.

## 🔧 Troubleshooting

### 🚨 Common Issues

1. **AWS CLI Configuration Issues**

   - ✅ Check credentials configuration
   - 🌍 Verify region settings
   - 🔍 Test AWS CLI access

2. **Terraform Deployment Issues**

   - ⚙️ Verify AWS provider configuration
   - 🔄 Check resource dependencies
   - 📝 Review error messages

3. **Kubernetes Deployment Issues**
   - 🔍 Check pod status
   - ⚙️ Review service configurations
   - 🌐 Verify ingress setup

### 🛠️ Environment-Specific Solutions

#### AWS Configuration

```bash
aws configure list
aws sts get-caller-identity
```

#### Terraform Verification

```bash
terraform validate
terraform plan
```

#### Kubernetes Troubleshooting

```bash
kubectl describe pods
kubectl describe services
kubectl describe ingress
```

For more information, please refer to the project documentation.
