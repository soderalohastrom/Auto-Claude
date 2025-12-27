#!/bin/bash

# Auto-Claude Stop Script (v2.7.1)
# Gracefully stops the Auto-Claude UI

echo "Stopping Auto-Claude..."

# Find the Electron process
ELECTRON_PID=$(pgrep -f "electron.*auto-claude-ui" | head -1)

if [ -z "$ELECTRON_PID" ]; then
    echo "❌ Auto-Claude is not running"
    exit 0
fi

echo "Found Auto-Claude process: $ELECTRON_PID"

# Try graceful shutdown first (SIGTERM)
echo "Sending graceful shutdown signal..."
kill -TERM "$ELECTRON_PID" 2>/dev/null

# Wait up to 5 seconds for graceful shutdown
for i in {1..10}; do
    if ! ps -p "$ELECTRON_PID" > /dev/null 2>&1; then
        echo "✅ Auto-Claude stopped gracefully"
        exit 0
    fi
    sleep 0.5
done

# If still running, force kill
if ps -p "$ELECTRON_PID" > /dev/null 2>&1; then
    echo "Process still running, forcing shutdown..."
    kill -9 "$ELECTRON_PID" 2>/dev/null
    sleep 1
    
    if ! ps -p "$ELECTRON_PID" > /dev/null 2>&1; then
        echo "✅ Auto-Claude stopped (forced)"
    else
        echo "❌ Failed to stop Auto-Claude"
        exit 1
    fi
fi
