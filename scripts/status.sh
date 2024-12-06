#!/bin/bash

echo "Pod Status:"
kubectl get pods -l app=face-detection

echo -e "\nService Status:"
kubectl get svc face-detection-service

echo -e "\nDeployment Status:"
kubectl get deployment face-detection-app

echo -e "\nIngress Status:"
kubectl get ingress face-detection-ingress

echo -e "\nLogs from the latest pod:"
POD_NAME=$(kubectl get pods -l app=face-detection -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POD_NAME" ]; then
    kubectl logs $POD_NAME --tail=50
else
    echo "No pods found"
fi