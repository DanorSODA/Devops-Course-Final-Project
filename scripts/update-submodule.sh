#!/bin/bash

# Set error handling
set -e

echo "Starting submodule update process..."

# Navigate to the submodule directory
cd "$(git rev-parse --show-toplevel)/next-face-detection-app" || {
    echo "Error: Failed to navigate to submodule directory"
    exit 1
}

# Fetch all branches and tags
echo "Fetching latest changes..."
git fetch --all || {
    echo "Error: Failed to fetch from remote"
    exit 1
}

# Checkout the main branch and reset to the latest commit
echo "Checking out and resetting to the latest commit on main branch..."
git checkout main || {
    echo "Error: Failed to checkout main branch"
    exit 1
}

git reset --hard origin/main || {
    echo "Error: Failed to reset to the latest commit on main branch"
    exit 1
}

# Navigate back to the main repository
cd .. || {
    echo "Error: Failed to navigate back to main repository"
    exit 1
}

# Stage and commit the submodule update
echo "Checking for changes to commit..."
if git diff --quiet next-face-detection-app; then
    echo "No changes to commit"
    exit 0
fi

echo "Committing submodule update..."
git add next-face-detection-app || {
    echo "Error: Failed to stage changes"
    exit 1
}

git commit -m "CI: Update submodule to latest version" || {
    echo "Error: Failed to commit changes"
    exit 1
}

# Push the changes
echo "Pushing changes..."
git push origin main || {
    echo "Error: Failed to push changes"
    exit 1
}

echo "Submodule update completed successfully!"
