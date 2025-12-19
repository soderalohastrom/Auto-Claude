#!/bin/bash

# Auto-Claude Startup Script
# This script starts the Docker container for the memory layer and launches the UI in the background.

# Navigate to the project root directory (adjust if needed)
cd /Users/soderstrom/2025/December/Auto-Claude

# Start the Docker containers for FalkorDB and Graphiti MCP server
echo "Starting Docker containers for memory layer..."
docker-compose up -d falkordb graphiti-mcp

# Wait a few seconds for the container to initialize
sleep 5

# Navigate to the UI directory
cd auto-claude-ui

# Build and start the UI in the background
echo "Building and starting the Auto-Claude UI..."
pnpm run build && pnpm run start &

echo "Auto-Claude is starting up. The UI should open shortly."
