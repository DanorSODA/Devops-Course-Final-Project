#!/bin/bash

# Get the pod name
POD_NAME=$(kubectl get pods -l app=face-detection -o jsonpath='{.items[0].metadata.name}')

echo "Pod Details:"
kubectl describe pod $POD_NAME

echo -e "\nPod Logs:"
kubectl logs $POD_NAME 