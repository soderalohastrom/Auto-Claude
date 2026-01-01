#!/bin/bash

# Auto-Claude Startup Script (v2.7.1)
# This script launches the Auto-Claude UI with the embedded LadybugDB memory system.
# No Docker required!

set -e

echo "======================================================================"
echo "  Starting Auto-Claude v2.7.1"
echo "======================================================================"
echo ""

# Navigate to the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Python 3.12+ is available (required for LadybugDB)
echo "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
REQUIRED_VERSION="3.12"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "⚠️  Warning: Python 3.12+ recommended for memory system (found: $PYTHON_VERSION)"
    echo "   Memory features may be limited. Continuing..."
    echo ""
fi

# Check if auto-claude Python dependencies are installed
if [ ! -d "auto-claude/.venv" ]; then
    echo "⚠️  Warning: Python virtual environment not found at auto-claude/.venv"
    echo "   Create it with: cd auto-claude && uv venv && uv pip install -r requirements.txt"
    echo ""
fi

# Check environment configuration
if [ ! -f "auto-claude/.env" ]; then
    echo "⚠️  Warning: auto-claude/.env file not found"
    echo "   Copy from: cp auto-claude/.env.example auto-claude/.env"
    echo "   Then add your API keys"
    echo ""
fi

# Navigate to the UI directory
cd auto-claude-ui

# Check if node_modules exist
if [ ! -d "node_modules" ]; then
    echo "Installing UI dependencies..."
    pnpm install
    echo ""
fi

# Build and start the UI
echo "Building and starting the Auto-Claude UI..."
echo ""

# Build the UI (only if not already built or if out of date)
if [ ! -d "out" ] || [ "src" -nt "out" ]; then
    echo "Building UI (this may take a minute)..."
    pnpm run build
    echo ""
fi

# Start the UI in the background
echo "Launching Auto-Claude UI..."
pnpm run start &

# Get the PID of the started process
UI_PID=$!

echo ""
echo "======================================================================"
echo "  Auto-Claude is starting up!"
echo "======================================================================"
echo ""
echo "✅ UI Process ID: $UI_PID"
echo "✅ Memory System: LadybugDB (embedded - no Docker needed)"
echo "✅ Configuration: auto-claude/.env"
echo ""
echo "The UI should open shortly in a new window."
echo ""
echo "To stop Auto-Claude later, run:"
echo "  kill $UI_PID"
echo ""
echo "Or use: pkill -f 'electron.*auto-claude-ui'"
echo "======================================================================"
