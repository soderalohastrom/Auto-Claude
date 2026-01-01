# Changes Summary: Graphiti MCP URL Fixes

## Date
December 21, 2024

## Overview
Fixed the default Graphiti MCP Server URL to use the correct `/sse` endpoint instead of `/mcp/`. The Graphiti MCP server uses Server-Sent Events (SSE) for communication, not the older `/mcp/` path.

## Changes Made

### 1. Frontend UI Components

#### `auto-claude-ui/src/renderer/components/project-settings/MemoryBackendSection.tsx`
- **Changed**: Input placeholder and default value
- **Before**: `value={settings.graphitiMcpUrl || ""}`
- **After**: `value={settings.graphitiMcpUrl || "http://localhost:9000/sse"}`
- **Reason**: Ensures the input shows the correct default URL with `/sse` endpoint

#### `auto-claude-ui/src/renderer/components/project-settings/SecuritySettings.tsx`
- **Changed**: Input placeholder and default value
- **Before**: `value={settings.graphitiMcpUrl || ""}`
- **After**: `value={settings.graphitiMcpUrl || "http://localhost:9000/sse"}`
- **Reason**: Consistent default across all settings pages

### 2. Backend Configuration

#### `auto-claude-ui/src/shared/constants/config.ts`
- **Already Correct**: `graphitiMcpUrl: "http://localhost:9000/sse"`
- **No changes needed** - Default was already using the correct endpoint

#### `auto-claude/core/client.py`
- **Already Correct**: `return os.environ.get("GRAPHITI_MCP_URL", "http://localhost:9000/sse")`
- **No changes needed** - Backend default was already correct

#### `auto-claude-ui/src/main/agent/agent-process.ts`
- **Already Correct**: `const graphitiUrl = project.settings.graphitiMcpUrl || "http://localhost:9000/sse"`
- **No changes needed** - Process manager was already using correct default

### 3. New Testing Tools

#### `fake_memory.py` (NEW FILE)
- **Purpose**: Utility script to inject fake memories into Graphiti for testing
- **Features**:
  - Test connectivity to FalkorDB and Graphiti
  - Inject session insights, patterns, gotchas, and file discoveries
  - Comprehensive error handling and debugging output
  - Works with both Python library and Docker-based setup

**Usage Examples**:
```bash
# Test connectivity
python fake_memory.py --test

# Add a session insight
python fake_memory.py --spec-dir .auto-claude/specs/001-test \
  --type insight --content "Successfully implemented JWT auth"

# Add a code pattern
python fake_memory.py --spec-dir .auto-claude/specs/001-test \
  --type pattern --content "Always validate input before DB queries"
```

#### `GRAPHITI_TESTING.md` (NEW FILE)
- **Purpose**: Comprehensive guide for testing and troubleshooting Graphiti memory
- **Sections**:
  - Prerequisites and setup
  - Testing connectivity
  - Injecting fake memories
  - Verifying memories in UI
  - Troubleshooting common issues
  - Architecture overview
  - Advanced manual querying

## Why This Matters

### The Issue
The Graphiti MCP server listens on port 8000 inside the Docker container and uses the `/sse` endpoint for Server-Sent Events communication. The container maps this to host port 9000.

- **Correct**: `http://localhost:9000/sse`
- **Incorrect**: `http://localhost:9000/mcp/` (404 Not Found)
- **Also Incorrect**: `http://localhost:8000/sse` (won't work from host)

### Impact
- Users setting up Graphiti for the first time would see a blank input field
- Without the default, they might use the wrong endpoint format
- The UI startup logs showed the correct port (9000) but the settings UI didn't reflect this

## Configuration Checklist

For Graphiti to work properly, users need:

### 1. Docker Containers Running
```bash
docker-compose up -d
docker ps | grep -E "falkordb|graphiti-mcp"  # Both should show (healthy)
```

### 2. Environment Variables (in `auto-claude/.env`)
```bash
GRAPHITI_ENABLED=true
OPENAI_API_KEY=sk-...  # Required for embeddings
```

### 3. UI Settings (per project)
- Memory Backend: Graphiti (toggle ON)
- Enable Agent Memory Access: ON
- Graphiti MCP Server URL: `http://localhost:9000/sse`

## Testing the Fix

### Verify Correct URL is Used
1. Open Auto-Claude UI
2. Go to Settings (gear icon) → Memory
3. Check "Graphiti MCP Server URL" field
4. Should show: `http://localhost:9000/sse`

### Test Connectivity
```bash
# Test the SSE endpoint
curl -I http://localhost:9000/sse
# Should return: HTTP/1.1 200 OK

# Test FalkorDB
redis-cli -h localhost -p 6380 ping
# Should return: PONG
```

### Inject a Test Memory
```bash
python fake_memory.py --spec-dir .auto-claude/specs/001-test \
  --type insight \
  --content "This is a test memory to verify Graphiti is working"
```

### Verify in UI
1. Navigate to Context tab (left sidebar)
2. Switch to Memories tab
3. Should see "Connected" status
4. Should see your test memory in "Recent Memories"

## Backward Compatibility

- Existing projects with custom URLs are **not affected** - only the default value changed
- Users who already set a URL manually will keep their setting
- The change only affects **new projects** or projects where the URL was left blank

## Related Files

### Already Correct (No Changes Needed)
- `docker-compose.yml` - Port mapping is correct (9000:8000)
- `auto-claude/core/client.py` - Backend default was already `/sse`
- `auto-claude-ui/src/shared/constants/config.ts` - Default was already `/sse`

### Files Updated
- `auto-claude-ui/src/renderer/components/project-settings/MemoryBackendSection.tsx`
- `auto-claude-ui/src/renderer/components/project-settings/SecuritySettings.tsx`

### Files Created
- `fake_memory.py` - Testing utility
- `GRAPHITI_TESTING.md` - Comprehensive testing guide
- `CHANGES_SUMMARY.md` - This file

## Next Steps for Users

1. **Pull latest changes** from your fork
2. **Rebuild the UI** (if running from source):
   ```bash
   cd auto-claude-ui
   pnpm install
   pnpm run build
   ```
3. **Restart the app** to pick up the new defaults
4. **Test connectivity** using `fake_memory.py --test`
5. **Inject a test memory** to verify the system works end-to-end

## Known Issues Resolved

- ❌ **Before**: Settings showed empty input, users might enter wrong URL format
- ✅ **After**: Settings show correct default `http://localhost:9000/sse`

- ❌ **Before**: No easy way to test if Graphiti is working
- ✅ **After**: `fake_memory.py` provides comprehensive testing and debugging

- ❌ **Before**: Hard to troubleshoot memory issues
- ✅ **After**: `GRAPHITI_TESTING.md` provides step-by-step debugging guide

## References

- [Graphiti MCP Server Documentation](https://docs.falkordb.com/agentic-memory/graphiti-mcp-server.html)
- [Docker Setup Guide](guides/DOCKER-SETUP.md)
- [Graphiti Testing Guide](GRAPHITI_TESTING.md)