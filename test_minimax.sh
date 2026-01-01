#!/bin/bash
# MiniMax smoke tests using Claude Code CLI.
#
# Goals:
#  1) Validate the Claude Code CLI can route traffic to MiniMax via ANTHROPIC_BASE_URL/AUTH_TOKEN.
#  2) Validate MiniMax accepts Claude Code's "--max-thinking-tokens" flag at multiple budgets.
#  3) Validate a "tool-ish / interleaved" scenario indirectly:
#     - We can't reliably force a real tool call in `--print` mode.
#     - Instead, we perform a multi-step instruction that typically triggers tool planning
#       and structured reasoning. If the proxy breaks tool-related schemas, you often see
#       errors here (even without executing tools).
#
# Required env vars (set these before running):
# export ANTHROPIC_BASE_URL=https://api.minimax.io/anthropic
# export ANTHROPIC_AUTH_TOKEN=your-token-here
# export CLAUDE_CODE_OAUTH_TOKEN=your-token-here
#
# Optional env vars:
# MODEL: MiniMax model name (default: minimax-m2.1-latest)
# THINKING_BUDGETS: Comma-separated list (default: 1024,4096,16384)
# OUTPUT_FORMAT: text|stream-json (default: text)
# VERBOSE: If set, shows debug info
#
# Usage examples:
#   # Basic
#   ./test_minimax.sh
#
#   # Explicit budgets
#   THINKING_BUDGETS="1024,4096" ./test_minimax.sh
#
# Notes:
# - If you see failures only at higher budgets, you may be hitting gateway limits/timeouts.
# - If you see schema/invalid_request failures, check compatibility between CLI flags and MiniMax API.
#
set -euo pipefail

BASE_URL_DEFAULT="https://api.minimax.io/anthropic"
MODEL_DEFAULT="MiniMax-M2.1"
THINKING_BUDGETS_DEFAULT="1024,4096,16384"
OUTPUT_FORMAT_DEFAULT="text"

ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-$BASE_URL_DEFAULT}"
MODEL="${MODEL:-$MODEL_DEFAULT}"
THINKING_BUDGETS="${THINKING_BUDGETS:-$THINKING_BUDGETS_DEFAULT}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-$OUTPUT_FORMAT_DEFAULT}"
VERBOSE="${VERBOSE:-}"

if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
  echo "ERROR: ANTHROPIC_AUTH_TOKEN is required (MiniMax token)." >&2
  exit 1
fi

if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "ERROR: CLAUDE_CODE_OAUTH_TOKEN is required (Claude Code OAuth token)." >&2
  echo "(Auto-Claude's SDK requires Claude Code auth even when using a proxy endpoint.)" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: claude CLI not found in PATH." >&2
  echo "Install: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi

# Pretty header
echo "== MiniMax smoke tests =="
echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
echo "MODEL=$MODEL"
echo "THINKING_BUDGETS=$THINKING_BUDGETS"
echo "OUTPUT_FORMAT=$OUTPUT_FORMAT"
echo

echo "Running: claude --version"
claude --version
echo

# Split comma-separated budgets
IFS=',' read -r -a BUDGET_LIST <<< "$THINKING_BUDGETS"

# Basic prompt that should succeed quickly and deterministically.
BASIC_SYSTEM_PROMPT="You are a concise assistant. Reply with exactly one short sentence."
BASIC_USER_PROMPT="Reply with exactly: OK from MiniMax."

# Tool-ish / interleaved prompt:
# We can't force Claude Code CLI to actually execute tools in --print mode in a stable way,
# but we can exercise the "agentic planning" style that often triggers tool invocation paths.
# If the proxy breaks tool schemas or intermediate reasoning plumbing, failures often show up here.
TOOLISH_SYSTEM_PROMPT="You are an expert software engineer. Be precise and structured."
TOOLISH_USER_PROMPT=$'Do the following in one response:\n\n1) List 3 shell commands (as plain text) you would run to check if a local HTTP service on port 9000 is reachable.\n2) Explain in 2-3 sentences why each command helps.\n3) Provide a short decision tree (bulleted) that uses the command outputs to determine likely failure causes.\n\nConstraints:\n- Do NOT actually run tools.\n- Do NOT invent outputs.\n- Keep it under 180 lines.\n'

run_one() {
  local budget="$1"
  local label="$2"
  local system_prompt="$3"
  local user_prompt="$4"

  echo "--------------------------------------------------------------------"
  echo "Test: $label"
  echo "max-thinking-tokens: $budget"
  echo "--------------------------------------------------------------------"

  # In verbose mode, show the command line (without secrets)
  if [ -n "$VERBOSE" ]; then
    echo "[debug] Running claude --print with model=$MODEL and --max-thinking-tokens=$budget"
  fi

  claude --print \
    --output-format "$OUTPUT_FORMAT" \
    --model "$MODEL" \
    --max-thinking-tokens "$budget" \
    --system-prompt "$system_prompt" \
    -- "$user_prompt"

  echo
  echo "✅ PASS: $label (budget=$budget)"
  echo
}

# Execute tests across budgets
for budget in "${BUDGET_LIST[@]}"; do
  budget="$(echo "$budget" | xargs)" # trim spaces
  if [ -z "$budget" ]; then
    continue
  fi

  # 1) Basic connectivity request
  run_one "$budget" "Basic one-turn reply" "$BASIC_SYSTEM_PROMPT" "$BASIC_USER_PROMPT"

  # 2) Tool-ish / interleaved planning request (no actual tool execution)
  run_one "$budget" "Tool-ish / interleaved planning (no tool execution)" "$TOOLISH_SYSTEM_PROMPT" "$TOOLISH_USER_PROMPT"
done

echo "===================================================================="
echo "All tests completed ✅"
echo
echo "If you saw failures at higher budgets, try reducing THINKING_BUDGETS."
echo "If you saw schema/invalid_request failures, paste the error output; it usually indicates"
echo "a compatibility gap between Claude Code CLI flags and the MiniMax API."
echo "===================================================================="
