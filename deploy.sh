#!/bin/bash

# Exit on any error
set -e

echo "🔄 Pulling latest changes from git..."
git pull

echo "🛑 Stopping existing containers..."
docker compose down

echo "🧹 Clearing Docker cache..."
docker builder prune -f

echo "🏗️  Building Docker images..."
docker compose build --no-cache

echo "🚀 Starting containers..."
docker compose up -d

echo "✅ Deployment complete!"
echo "📊 Container status:"
docker compose ps
