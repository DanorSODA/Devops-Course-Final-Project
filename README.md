# DevOps Final Project - Face Detection App Deployment

This project demonstrates a complete DevOps pipeline for deploying a Next.js face detection application using modern DevOps practices and tools. The project uses a microservices architecture, infrastructure as code, and automated CI/CD pipelines.

## Application Overview

This project includes a custom-built Next.js application ([next-face-detection-app](https://github.com/DanorSODA/next-face-detection-app)) as a submodule, which:

- Implements real-time face detection using webcam stream
- Built with Next.js and TypeScript
- use a face-api models for detecting the face landmarks, age, gender and emotion
- Containerized using Docker
- Automatically updated through CI/CD pipeline

### Application Features

- Live video stream processing
- Real-time face detection
- Responsive web interface
- Optimized Docker container

### Docker Implementation

- Multi-stage build process
- Optimized image size
- Configured for both development and production
- Automated builds via GitHub Actions

## Project Overview

The project deploys the [next-face-detection-app](https://github.com/DanorSODA/next-face-detection-app) (included as a submodule) using a comprehensive DevOps pipeline that includes:

- Infrastructure provisioning with Terraform
- Kubernetes deployment configuration
- Automated CI/CD pipelines with GitHub Actions
- Multi-environment support (Production and Staging)

### Architecture

- **Application**: Next.js face detection application
- **Infrastructure**: AWS-based Kubernetes cluster
- **CI/CD**: GitHub Actions pipelines
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **IaC**: Terraform

### Project Structure

```tree
.
├── .github/workflows/           # GitHub Actions workflow definitions
│   ├── quality-checks.yml      # Code quality and Docker build pipeline
│   ├── update-deployment.yml   # K8s deployment update pipeline
│   └── update-submodule.yml    # Submodule update automation
├── k8s/                        # Kubernetes configuration files
│   └── deployments/            # K8s deployment yaml manifests
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Variable definitions
│   └── outputs.tf             # Output definitions
├── next-face-detection-app/    # Application submodule
├── CONTRIBUTORS.md            # Project contributors
├── INSTALL.md                 # Installation guide
├── LICENSE                    # Project license
├── README.md                  # Project documentation
├── TASKS.md                   # Project tasks
└── install.sh                 # Installation script
```

## Prerequisites

- AWS Account with appropriate permissions
- Docker installed
- kubectl installed
- Terraform installed
- AWS CLI configured

## Technical Architecture

### CI/CD Pipeline with GitHub Actions

The project implements three main workflows:

1. **Submodule Update Workflow**

   - Automatically detects changes in the next-face-detection-app
   - Updates the submodule in this repository
   - Triggers the quality checks pipeline

2. **Quality Checks & Docker Build**

   - Runs after submodule updates
   - Performs TypeScript, ESLint, and formatting checks
   - Builds and pushes Docker image to Docker Hub

3. **Continuous Deployment**
   - Triggered by Docker Hub webhooks
   - Connects to Kubernetes cluster using GitHub Secrets
   - Updates the application deployment with zero downtime

### Kubernetes Resources

The application runs on Kubernetes with the following components:

1. **Deployment**

   - Manages application pods
   - Handles rolling updates
   - Controls replica count and resource allocation

2. **Service**

   - Exposes the application within the cluster
   - Manages internal load balancing
   - Routes traffic to application pods

3. **Ingress**

   - Handles external access to the service
   - Manages SSL/TLS termination
   - Configures routing rules

4. **ConfigMap**
   - Stores application configuration
   - Manages environment variables
   - Enables environment-specific settings

### Infrastructure (Terraform)

Terraform manages AWS infrastructure for both production and staging:

1. **Network Resources**

   - VPC for each environment
   - Public and private subnets
   - Internet Gateway
   - Route tables
   - Security Groups

2. **Compute Resources**
   - Kubernetes master nodes
   - Worker nodes
   - SSH key pairs
   - Instance configurations

### Deployment Flow

1. Code changes pushed to next-face-detection-app
2. Submodule update triggered automatically
3. Quality checks and Docker build initiated
4. New image pushed to Docker Hub
5. Webhook triggers deployment update
6. Application updated on Kubernetes cluster

### Environments

1. **Production**

   - High availability setup
   - Multiple worker nodes
   - Production-grade resources

2. **Staging**
   - Testing environment
   - Reduced resource allocation
   - Development validation

### Security

- AWS security groups for network isolation
- SSH key authentication for server access
- GitHub Secrets for sensitive data
- HTTPS enforcement for web traffic

### Setup and Installation

- [Installation Guide](INSTALL.md) - Detailed setup instructions
- [Installation Script](install.sh) - Automated setup script

### Project Information

- [Contributors](CONTRIBUTORS.md) - Project team and contributions
- [Tasks](TASKS.md) - Completed and future tasks
- [License](LICENSE) - Project license
