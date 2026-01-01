#!/bin/bash
# Z.ai (Anthropic-compatible) proxy smoke tests using Claude Code CLI.
#
# Goals:
#  1) Validate the Claude Code CLI can route traffic to Z.ai via ANTHROPIC_BASE_URL/AUTH_TOKEN.
#  2) Validate Z.ai accepts Claude Code's "--max-thinking-tokens" flag at multiple budgets.
#  3) Validate a "tool-ish / interleaved" scenario indirectly:
#     - We can't reliably force a real tool call in `--print` mode.
#     - Instead, we perform a multi-step instruction that typically triggers tool planning
#       and structured reasoning. If the proxy breaks tool-related schemas, you often see
#       errors here (even without executing tools).
#
# Why this script exists:
# Auto-Claude uses claude_agent_sdk -> Claude Code CLI. That path supports
# `--max-thinking-tokens` (Anthropic-style extended thinking) but does not expose
# arbitrary JSON request-body fields like Z.ai's native:
#   thinking: { type: "enabled", clear_thinking: false }
# Therefore we test what Auto-Claude can actually do: CLI flags + env overrides.
#
# Required env vars:
#   ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
#   ANTHROPIC_AUTH_TOKEN=... (your Z.ai token)
#   CLAUDE_CODE_OAUTH_TOKEN=... (Claude Code OAuth token; still required by SDK/CLI)
#
# Optional env vars:
#   MODEL=glm-4.7
#   THINKING_BUDGETS="1024,4096,16384"   # Comma-separated list
#   OUTPUT_FORMAT=text                   # text|stream-json (text recommended here)
#   VERBOSE=1                            # If set, shows more context
#
# Usage examples:
#   # Basic
#   ./test_zai_anthropic_proxy.sh
#
#   # Explicit budgets + model
#   MODEL=glm-4.7 THINKING_BUDGETS="1024,16384" ./test_zai_anthropic_proxy.sh
#
# Notes:
# - If you see failures only at higher budgets, you may be hitting gateway limits/timeouts.
# - If failures appear around "invalid_request" / schema, it may be incompat between CLI
#   parameters and Z.ai's Anthropic-compat layer.
#
set -euo pipefail

BASE_URL_DEFAULT="https://api.z.ai/api/anthropic"
MODEL_DEFAULT="glm-4.7"
THINKING_BUDGETS_DEFAULT="1024,4096,16384"
OUTPUT_FORMAT_DEFAULT="text"

ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-$BASE_URL_DEFAULT}"
MODEL="${MODEL:-$MODEL_DEFAULT}"
THINKING_BUDGETS="${THINKING_BUDGETS:-$THINKING_BUDGETS_DEFAULT}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-$OUTPUT_FORMAT_DEFAULT}"
VERBOSE="${VERBOSE:-}"

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

# Pretty header
echo "== Z.ai Anthropic-compatible proxy smoke tests =="
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
BASIC_USER_PROMPT="Reply with exactly: OK from Z.ai proxy."

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

  # NOTE:
  # - We deliberately use --print to keep it simple and deterministic.
  # - This uses the same --max-thinking-tokens mechanism Auto-Claude uses via the SDK.
  # - If Z.ai's Anthropic-compat layer rejects this, you'll see an error here.
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
echo "a compatibility gap between Claude Code CLI flags and the Anthropic-compatible proxy."
echo "===================================================================="
