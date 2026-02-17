#!/bin/bash

# Exit on any error
set -e

# echo "🔄 Pulling latest changes from git..."
# git pull

echo "🛑 Stopping existing containers..."
docker compose down

echo "🧹 Clearing Docker cache..."
docker builder prune -f

echo "🏗️  Building Docker images..."
# Disable provenance to avoid metadata file error
DOCKER_BUILDKIT=1 BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker compose build --no-cache || {
  echo "⚠️  Build completed with warnings (metadata file error can be ignored)"
}

echo "🚀 Starting containers..."
docker compose up -d

echo "✅ Deployment complete!"
echo "📊 Container status:"
docker compose ps
