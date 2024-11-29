# DevOps Final Project

This README provides an overview and the step-by-step tasks required to complete the deployment of the `next-face-detection-app`  Next.js project using a DevOps pipeline. The project will utilize GitHub Actions for CI/CD, and the infrastructure will be deployed on AWS with tools like Docker, Terraform, Ansible, K3s, and Jenkins. The implementation will follow best practices for infrastructure as code (IaC), containerization, and CI/CD pipelines.

---

## Project Repository
- **Details-App Source Repository**: [next-face-detection-app](https://github.com/DanorSODA/next-face-detection-app)
- **Final Project Repository**: [DevOps-Course-Final-Project](https://github.com/DanorSODA/Devops-Course-Final-Project)

---

## Tech Stack
The following technologies will be used for this project:
- **CI/CD**: GitHub Actions
- **Containerization**: Docker
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **Container Orchestration**: K3s (Lightweight Kubernetes)
- **Cloud Provider**: AWS

---

## Tasks Overview
### **Phase 1: Repository Setup**
1. Fork the `next-face-detection-app` repository into your GitHub account.
2. Clone the forked repository locally and add it as a submodule to your final project repository:
   ```bash
   git submodule add https://github.com/DanorSODA/next-face-detection-app
   ```
3. Set up the project repository with the following folder structure:
   ```
   Devops-Course-Final-Project/
   |-- next-face-detection-app/         # Submodule for the application source code
   |-- terraform/           # Terraform configuration files
   |-- ansible/             # Ansible playbooks for configuration management
   |-- k8s/                 # K3s deployment YAML files
   |-- .github/workflows/   # GitHub Actions workflows for CI/CD
   ```

---

### **Phase 2: Cloud Infrastructure with Terraform**
1. Write Terraform scripts to provision the following AWS infrastructure:
   - **VPC**: Create a Virtual Private Cloud with public and private subnets.
   - **EC2 Instances**: Launch instances to serve as K3s nodes.
   - **RDS Database**: Create an RDS instance for application persistence.
   - **Security Groups**: Define security groups to allow only necessary traffic.

2. Test Terraform configuration locally:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
3. Push Terraform scripts to the `terraform/` folder in the repository.

---

### **Phase 3: Configuration Management with Ansible**
1. Write Ansible playbooks to:
   - Install Docker and K3s on EC2 instances.
   - Deploy Jenkins as a containerized application on the K3s cluster.
   - Configure security settings for K3s and Docker.
2. Test the Ansible playbooks locally and push them to the `ansible/` folder.

---

### **Phase 4: Deploy the Application on K3s**
1. Write Kubernetes YAML files to:
   - Define a Deployment for the `details-app` application.
   - Expose the application using a Service (LoadBalancer type).
   - Configure environment variables for database access.
2. Push the Kubernetes YAML files to the `k8s/` folder.
3. Use `kubectl` commands to apply the YAML files and validate the deployment:
   ```bash
   kubectl apply -f k8s/
   kubectl get pods,svc
   ```

---

### **Phase 5: CI/CD Pipeline with GitHub Actions**
1. Set up a GitHub Actions workflow for:
   - **CI Tasks**:
     - Run static code analysis (e.g., Flake8) on the `next-face-detection-app` source code.
     - Build and push a Docker image of the application to DockerHub.
   - **CD Tasks**:
     - Deploy the application to the K3s cluster using `kubectl`.

2. Create a workflow file in `.github/workflows/ci-cd.yml`:
   ```yaml
   name: CI/CD Pipeline

   on:
     push:
       branches:
         - main

   jobs:
     build:
       runs-on: ubuntu-latest

       steps:
         - name: Checkout Code
           uses: actions/checkout@v3

         - name: Set Up Docker
           uses: docker/setup-buildx-action@v2

         - name: Build and Push Docker Image
           run: |
             docker build -t <your-dockerhub-username>/details-app:latest .
             docker push <your-dockerhub-username>/details-app:latest

     deploy:
       needs: build
       runs-on: ubuntu-latest

       steps:
         - name: Configure kubectl
           uses: azure/setup-kubectl@v3
           with:
             version: 'v1.24.0'

         - name: Deploy to K3s Cluster
           run: |
             kubectl apply -f k8s/
   ```

3. Push the workflow to the `.github/workflows/` directory.

---

### **Phase 6: Monitoring and Scaling**
1. Set up monitoring for the K3s cluster using Prometheus and Grafana.
2. Configure auto-scaling for the application deployment based on CPU/memory usage.
3. Test the application for scaling scenarios and log performance metrics.

---

### **Phase 7: Final Steps**
1. Document all configurations and processes in the `README.md` file.
2. Test the CI/CD pipeline end-to-end.
3. Clean up unused resources in AWS to avoid additional costs.

---

## Deliverables
- Fully functional AWS infrastructure with Terraform.
- CI/CD pipeline implemented using GitHub Actions.
- Application deployed on K3s cluster.
- Documentation and source code in the final project repository.

---

## Additional Notes
- Use best practices for security, including encrypting sensitive data using AWS KMS or GitHub Secrets.
- Regularly monitor AWS costs and optimize infrastructure for cost-efficiency.
- Reference official documentation for Terraform, Ansible, Kubernetes, and GitHub Actions for advanced configurations.

