# 🎯 DevOps Final Project - Face Detection App Deployment

> A complete DevOps pipeline for deploying a Next.js face detection application using modern DevOps practices and tools.

## 🚀 Application Overview

This project includes a custom-built Next.js application ([next-face-detection-app](https://github.com/DanorSODA/next-face-detection-app)) as a submodule, which:

- 📸 Implements real-time face detection using webcam stream
- ⚡ Built with Next.js and TypeScript
- 🧠 Uses face-api models for detecting face landmarks, age, gender and emotion
- 🐳 Containerized using Docker
- 🔄 Automatically updated through CI/CD pipeline

### ✨ Application Features

- 🎥 Live video stream processing
- 👤 Real-time face detection
- 📱 Responsive web interface
- 🚀 Optimized Docker container

### Docker Implementation

- Multi-stage build process
- Optimized image size
- Configured for both development and production
- Automated builds via GitHub Actions

## 🛠️ Prerequisites

- ☁️ AWS Account with appropriate permissions
- 🐳 Docker installed
- ⚓ kubectl installed
- 🏗️ Terraform installed
- 🔧 AWS CLI configured

## 🔄 Project Flow

### 1. 🔄 CI/CD Pipeline

<div align="center">

```mermaid
graph LR
    A[Code Push] --> B[Update Submodule]
    B --> C[Quality Checks]
    C --> D[Build Docker Image]
    D --> E[Push to Registry]
    E --> F[Webhook Trigger]
    F --> G[Update K8s]
    G --> H[Rolling Update]
    H --> I[Health Check]

    classDef default fill:#ffffff,stroke:#e2e8f0,color:#4a5568,font-family:arial
    classDef ci fill:#5a67d8,stroke:#4c51bf,color:#fff,font-family:arial
    classDef cd fill:#48bb78,stroke:#38a169,color:#fff,font-family:arial

    class A,B,C,D,E ci
    class F,G,H,I cd
```

</div>

<details>
<summary>💡 CI/CD Details</summary>
When developers push changes, it triggers an automated pipeline that runs quality checks, builds a new Docker image, and updates the Kubernetes deployment with zero downtime.
</details>

### 2. 🏗️ Infrastructure Deployment

<div align="center">

```mermaid
graph TD
    A([terraform init]):::init --> B([terraform plan]):::plan
    B --> C([terraform apply]):::apply
    C --> D([AWS Resources]):::aws
    D --> E([K8s Cluster]):::k8s

    classDef init fill:#4299e1,stroke:#3182ce,color:#fff,font-family:arial,font-weight:bold
    classDef plan fill:#48bb78,stroke:#38a169,color:#fff,font-family:arial,font-weight:bold
    classDef apply fill:#5a67d8,stroke:#4c51bf,color:#fff,font-family:arial,font-weight:bold
    classDef aws fill:#f6ad55,stroke:#ed8936,color:#fff,font-family:arial,font-weight:bold
    classDef k8s fill:#667eea,stroke:#5a67d8,color:#fff,font-family:arial,font-weight:bold
```

</div>

<details>
<summary>💡 Infrastructure Details</summary>
The infrastructure is provisioned using Terraform, which creates all necessary AWS resources including VPC, subnets, EC2 instances for Kubernetes nodes, and security groups. Once complete, a fully functional Kubernetes cluster is ready for deployments.
</details>

### 3. ⚓ Kubernetes Implementation

<div align="center">

```mermaid
graph TD
    N([Namespace]):::namespace --> A([Ingress]):::ingress
    N --> B([Service]):::svc
    N --> C([Deployment]):::deploy
    N --> G([ConfigMap]):::config

    A --> B
    B --> C
    C --> D([Pod 1]):::pod
    C --> E([Pod 2]):::pod
    C --> F([Pod 3]):::pod

    G -.configures.-> D
    G -.configures.-> E
    G -.configures.-> F

    classDef namespace fill:#e53e3e,stroke:#c53030,color:#fff,font-family:arial,font-weight:bold
    classDef ingress fill:#f6ad55,stroke:#ed8936,color:#fff,font-family:arial,font-weight:bold
    classDef svc fill:#4299e1,stroke:#3182ce,color:#fff,font-family:arial,font-weight:bold
    classDef deploy fill:#48bb78,stroke:#38a169,color:#fff,font-family:arial,font-weight:bold
    classDef pod fill:#667eea,stroke:#5a67d8,color:#fff,font-family:arial,font-weight:bold
    classDef config fill:#9f7aea,stroke:#805ad5,color:#fff,font-family:arial,font-weight:bold
```

</div>

<details>
<summary>💡 Kubernetes Details</summary>
The application runs in a Kubernetes cluster with multiple pods for high availability. Configuration is managed through ConfigMaps and Secrets, while traffic is routed through Services and Ingress.
</details>

### 4. 🏛️ Infrastructure Overview

<div align="center">

```mermaid
graph TD
    A([AWS Infrastructure]):::aws --> B([VPC]):::vpc
    B --> SG1([Security Groups]):::sg
    B --> C([K8s Cluster]):::k8s

    SG1 -.secures.-> C
    C --> D([Production]):::prod
    C --> E([Staging]):::stage

    D --> DP([3 Pod Replicas]):::pod
    E --> SP([2 Pod Replicas]):::pod

    SG2([Load Balancer SG]):::sg -.secures.-> D
    SG3([K8s SG]):::sg -.secures.-> D
    SG2 -.secures.-> E
    SG3 -.secures.-> E

    classDef aws fill:#f6ad55,stroke:#ed8936,color:#fff,font-family:arial,font-weight:bold
    classDef vpc fill:#4299e1,stroke:#3182ce,color:#fff,font-family:arial,font-weight:bold
    classDef sg fill:#fc8181,stroke:#f56565,color:#fff,font-family:arial,font-weight:bold
    classDef k8s fill:#667eea,stroke:#5a67d8,color:#fff,font-family:arial,font-weight:bold
    classDef prod fill:#48bb78,stroke:#38a169,color:#fff,font-family:arial,font-weight:bold
    classDef stage fill:#9f7aea,stroke:#805ad5,color:#fff,font-family:arial,font-weight:bold
    classDef pod fill:#5a67d8,stroke:#4c51bf,color:#fff,font-family:arial,font-weight:bold
```

</div>

<details>
<summary>💡 Infrastructure Overview Details</summary>
The project runs on AWS with separate environments for production and staging, each with its own Kubernetes cluster. Production runs with higher availability using 3 pod replicas, while staging uses 2 replicas for cost efficiency.
</details>

## 🏗️ Technical Architecture

### 🔄 CI/CD Pipeline with GitHub Actions

1. **📦 Submodule Update Workflow**

   - Automatically detects changes in the next-face-detection-app
   - Updates the submodule in this repository
   - Triggers the quality checks pipeline

2. **✅ Quality Checks & Docker Build**

   - Runs after submodule updates
   - Performs TypeScript, ESLint, and formatting checks
   - Builds and pushes Docker image to Docker Hub

3. **🚀 Continuous Deployment**
   - Triggered by Docker Hub webhooks
   - Connects to Kubernetes cluster using GitHub Secrets
   - Updates the application deployment with zero downtime

### ⚓ Kubernetes Resources

1. **🔍 Namespace**

   - Named 'face-detection'
   - Provides logical separation of workloads

2. **🚀 Deployment**

   - Manages application pods
   - Handles rolling updates
   - Controls replica count and resource allocation

3. **🔌 Service**

   - Exposes the application within the cluster
   - Manages internal load balancing
   - Routes traffic to application pods

4. **🌐 Ingress**
   - Handles external access to the service
   - Manages SSL/TLS termination
   - Configures routing rules

### 🔐 Security

- 🛡️ AWS security groups for network isolation
- 🔑 SSH key authentication for server access
- 🔒 GitHub Secrets for sensitive data
- 🔐 HTTPS enforcement for web traffic

### 🌍 Environments

1. **🏭 Production**

   - High availability setup
   - Multiple worker nodes
   - Production-grade resources

2. **🧪 Staging**
   - Testing environment
   - Reduced resource allocation
   - Development validation

## 📚 Additional Information

- ���� [Installation Guide](install.md)
- 👥 [Contributors](CONTRIBUTORS.md)
- ✅ [Tasks](TASKS.md)
