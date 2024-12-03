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

# Check if HEAD is detached
if ! git symbolic-ref -q HEAD >/dev/null; then
    echo "HEAD is detached. Checking out main branch..."
    # Save any uncommitted changes to a temporary branch
    TEMP_BRANCH="temp-$(date +%s)"
    CURRENT_COMMIT=$(git rev-parse HEAD)
    git branch "$TEMP_BRANCH" "$CURRENT_COMMIT"
    
    # Checkout main
    git checkout main || {
        echo "Error: Failed to checkout main branch"
        exit 1
    }
    
    # Try to merge the temporary branch if it contains changes
    if [ "$CURRENT_COMMIT" != "$(git rev-parse main)" ]; then
        echo "Attempting to merge changes from detached HEAD..."
        git merge "$TEMP_BRANCH" || {
            echo "Warning: Merge conflicts detected. Please resolve manually."
            git merge --abort
            exit 1
        }
    fi
fi

# Pull latest changes
echo "Pulling latest changes..."
git pull origin main || {
    echo "Error: Failed to pull changes"
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
