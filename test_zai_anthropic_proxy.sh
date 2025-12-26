#!/bin/bash
# Quick Z.ai (Anthropic-compatible) connectivity test using Claude Code CLI.
#
# This validates that the Claude Code CLI + SDK path works against the Z.ai endpoint
# WITHOUT needing any app/UI changes.
#
# Required env vars:
#   ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
#   ANTHROPIC_AUTH_TOKEN=... (your Z.ai token)
#   CLAUDE_CODE_OAUTH_TOKEN=... (still required by Auto-Claude/SDK)
#
# Optional:
#   MODEL=glm-4.7
#   MAX_THINKING_TOKENS=1024
#
# Usage:
#   ANTHROPIC_AUTH_TOKEN=... CLAUDE_CODE_OAUTH_TOKEN=... ./test_zai_anthropic_proxy.sh

set -euo pipefail

BASE_URL_DEFAULT="https://api.z.ai/api/anthropic"
MODEL_DEFAULT="glm-4.7"
MAX_THINKING_DEFAULT="1024"

ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-$BASE_URL_DEFAULT}"
MODEL="${MODEL:-$MODEL_DEFAULT}"
MAX_THINKING_TOKENS="${MAX_THINKING_TOKENS:-$MAX_THINKING_DEFAULT}"

if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
  echo "ERROR: ANTHROPIC_AUTH_TOKEN is required (Z.ai token)." >&2
  exit 1
fi

if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "ERROR: CLAUDE_CODE_OAUTH_TOKEN is required (Claude Code OAuth token)." >&2
  echo "(Auto-Claude’s SDK requires Claude Code auth even when using a proxy endpoint.)" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: claude CLI not found in PATH." >&2
  echo "Install: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi

echo "== Z.ai Anthropic-compatible proxy smoke test =="
echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
echo "MODEL=$MODEL"
echo "MAX_THINKING_TOKENS=$MAX_THINKING_TOKENS"
echo

echo "Running: claude --version"
claude --version

echo

echo "Running a 1-turn print request…"
# Note: this exercises the same flag that the SDK uses (max thinking tokens)
# If Z.ai rejects it, you’ll see an error here.
claude --print \
  --output-format text \
  --model "$MODEL" \
  --max-thinking-tokens "$MAX_THINKING_TOKENS" \
  --system-prompt "You are a concise assistant. Reply with exactly one short sentence." \
  -- "Reply with: OK from Z.ai proxy." 

echo
echo "✅ Success: CLI request completed"
