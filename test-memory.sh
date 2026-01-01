#!/bin/bash
# test-memory.sh
# Convenient wrapper for fake_memory.py that uses the correct Python interpreter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="$SCRIPT_DIR/auto-claude/.venv/bin/python"

# Check if virtual environment exists
if [ ! -f "$PYTHON_BIN" ]; then
    echo "Error: Python virtual environment not found at auto-claude/.venv/"
    echo ""
    echo "Create it with:"
    echo "  cd auto-claude"
    echo "  uv venv && uv pip install -r requirements.txt"
    exit 1
fi

# Run fake_memory.py with the correct Python interpreter
exec "$PYTHON_BIN" "$SCRIPT_DIR/fake_memory.py" "$@"
