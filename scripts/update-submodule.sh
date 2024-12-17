#!/bin/bash

# Set error handling
set -e

echo "Starting submodule update process..."

# Configure git to use HTTPS with token
git config --global url."https://${TOKEN}@github.com/".insteadOf "https://github.com/"

# Navigate to the submodule directory
cd "$(git rev-parse --show-toplevel)/next-face-detection-app" || {
    echo "Error: Failed to navigate to submodule directory"
    exit 1
}

# Configure git for the submodule
git config user.name "GitHub Actions"
git config user.email "github-actions@github.com"

# Fetch and pull the latest changes
echo "Fetching latest changes..."
git fetch origin || {
    echo "Error: Failed to fetch from remote"
    exit 1
}

# Check if HEAD is detached
if ! git symbolic-ref -q HEAD >/dev/null; then
    echo "HEAD is detached. Checking out main branch..."
    git checkout main || {
        echo "Error: Failed to checkout main branch"
        exit 1
    }
fi

# Check if we're already up to date
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "Submodule is already up to date. No changes needed."
    exit 0
fi

# Try to pull changes
git pull origin main || {
    echo "Error: Failed to pull changes"
    exit 1
}

# Navigate back to the main repository
cd .. || {
    echo "Error: Failed to navigate back to main repository"
    exit 1
}

# Configure git for the main repository
git config user.name "GitHub Actions"
git config user.email "github-actions@github.com"

# Stage and commit the submodule update
echo "Committing submodule update..."
# Check if there are actually changes to commit
if git diff --quiet next-face-detection-app; then
    echo "No changes to commit"
    exit 0
fi

git add next-face-detection-app || {
    echo "Error: Failed to stage changes"
    exit 1
}

git commit -m "CI: Update submodule to latest version" || {
    echo "Error: Failed to commit changes"
    exit 1
}

# Push the changes using token
echo "Pushing changes..."
git push "https://${TOKEN}@github.com/DanorSODA/Devops-Course-Final-Project.git" main || {
    echo "Error: Failed to push changes"
    exit 1
}

echo "Submodule update completed successfully!"