#!/bin/bash

echo "Service Details:"
kubectl describe service face-detection-service

echo -e "\nEndpoints:"
kubectl get endpoints face-detection-service

echo -e "\nNode Port Access:"
kubectl get nodes -o wide 