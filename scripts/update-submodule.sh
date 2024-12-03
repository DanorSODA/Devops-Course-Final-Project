#!/bin/bash

# Set error handling
set -e

echo "Starting submodule update process..."

# Navigate to the submodule directory
cd "$(git rev-parse --show-toplevel)/next-face-detection-app"

# Fetch and pull the latest changes
echo "Fetching latest changes..."
git fetch origin
git checkout main
git pull origin main

# Navigate back to the main repository
cd ..

# Stage and commit the submodule update
echo "Committing submodule update..."
git add next-face-detection-app
git commit -m "CI: Update submodule to latest version"

# Push the changes
echo "Pushing changes..."
git push origin main

echo "Submodule update completed successfully!"
