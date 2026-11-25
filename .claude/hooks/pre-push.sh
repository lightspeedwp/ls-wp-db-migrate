#!/bin/bash

# Pre-push hook for wp-db-migrate
# Runs before pushing to remote

set -e

echo "🔍 Checking branch name..."
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ ! "$BRANCH" =~ ^wp-db- ]] && [[ "$BRANCH" != "main" ]]; then
  echo "⚠️  Warning: Branch '$BRANCH' doesn't follow naming convention (wp-db-*)"
  echo "Consider renaming to: wp-db-${BRANCH}"
fi

echo "✅ Ready to push"
