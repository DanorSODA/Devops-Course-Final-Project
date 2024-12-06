#!/bin/bash

echo "Cleaning up deployment..."
kubectl delete -f k8s/deployments/face-detection-ingress.yaml
kubectl delete -f k8s/deployments/face-detection-service.yaml
kubectl delete -f k8s/deployments/face-detection-deployment.yaml
kubectl delete -f k8s/deployments/face-detection-config.yaml

echo "Checking remaining resources..."
kubectl get all -l app=face-detection