#!/bin/bash

# Add AWS authentication
aws eks update-kubeconfig --region your-region --name your-cluster-name

# Default to local environment if not specified
ENVIRONMENT=${1:-local}
VALUES_FILE="k8s/values/${ENVIRONMENT}.yaml"

if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: Values file not found: $VALUES_FILE"
    exit 1
fi

# Read values using yq
REPLICAS=$(yq eval '.deployment.replicas' "$VALUES_FILE")
MEMORY_REQUEST=$(yq eval '.deployment.resources.requests.memory' "$VALUES_FILE")
CPU_REQUEST=$(yq eval '.deployment.resources.requests.cpu' "$VALUES_FILE")
MEMORY_LIMIT=$(yq eval '.deployment.resources.limits.memory' "$VALUES_FILE")
CPU_LIMIT=$(yq eval '.deployment.resources.limits.cpu' "$VALUES_FILE")
IMAGE_REPOSITORY=$(yq eval '.image.repository' "$VALUES_FILE")
IMAGE_TAG=$(yq eval '.image.tag' "$VALUES_FILE")
IMAGE_PULL_POLICY=$(yq eval '.image.pullPolicy' "$VALUES_FILE")

# Update the deployment YAML with the correct values
yq eval "
  .spec.replicas = $REPLICAS |
  .spec.template.spec.containers[0].image = \"$IMAGE_REPOSITORY:$IMAGE_TAG\" |
  .spec.template.spec.containers[0].imagePullPolicy = \"$IMAGE_PULL_POLICY\" |
  .spec.template.spec.containers[0].resources.requests.memory = \"$MEMORY_REQUEST\" |
  .spec.template.spec.containers[0].resources.requests.cpu = \"$CPU_REQUEST\" |
  .spec.template.spec.containers[0].resources.limits.memory = \"$MEMORY_LIMIT\" |
  .spec.template.spec.containers[0].resources.limits.cpu = \"$CPU_LIMIT\"
" k8s/deployments/face-detection-deployment.yaml -i

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests for environment: $ENVIRONMENT"
kubectl apply -f k8s/deployments/face-detection-config.yaml
kubectl apply -f k8s/deployments/face-detection-deployment.yaml
kubectl apply -f k8s/deployments/face-detection-service.yaml
kubectl apply -f k8s/deployments/face-detection-ingress.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/face-detection-app

# Get service information
echo "Service Details:"
kubectl get service face-detection-service

# Show pods status
echo "Pod Status:"
kubectl get pods -l app=face-detection

# Show how to access the application
if [ "$ENVIRONMENT" = "local" ]; then
    NODE_PORT=$(kubectl get svc face-detection-service -o jsonpath='{.spec.ports[0].nodePort}')
    echo -e "\nAccess your application at: http://localhost:${NODE_PORT}"
fi