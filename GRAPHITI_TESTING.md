# Graphiti Memory Testing Guide

This guide explains how to test and work with the Graphiti memory system in Auto-Claude.

## Overview

Auto-Claude uses **Graphiti** (powered by FalkorDB) as an optional graph-based memory backend. This allows agents to:
- Store session insights, patterns, and gotchas
- Retrieve relevant context from past sessions
- Build a knowledge graph of your codebase over time

The system has two components:
1. **Python Library Integration** (`GRAPHITI_ENABLED`) - Used by the backend to store memories
2. **MCP Server Integration** (`GRAPHITI_MCP_URL`) - Allows agents to query memories directly

## Prerequisites

### 1. Docker Containers Running

Start the required Docker containers:

```bash
# Start both FalkorDB and Graphiti MCP server
docker-compose up -d

# Verify they're running
docker ps | grep -E "falkordb|graphiti-mcp"
```

Expected output:
```
auto-claude-graphiti-mcp   0.0.0.0:9000->8000/tcp   (healthy)
auto-claude-falkordb       0.0.0.0:6380->6379/tcp   (healthy)
```

### 2. Environment Variables

Set the following in `auto-claude/.env`:

```bash
# Core Graphiti Configuration
GRAPHITI_ENABLED=true
OPENAI_API_KEY=sk-...  # Required for embeddings

# Optional: Customize providers
GRAPHITI_LLM_PROVIDER=openai
GRAPHITI_EMBEDDER_PROVIDER=openai
OPENAI_MODEL=gpt-4o-mini
OPENAI_EMBEDDING_MODEL=text-embedding-3-small

# MCP Server URL (for agent access)
GRAPHITI_MCP_URL=http://localhost:9000/sse
```

### 3. Python Dependencies

Ensure Graphiti dependencies are installed:

```bash
cd auto-claude
source .venv/bin/activate
pip install graphiti-core falkordb redis
```

## Testing Connectivity

### Quick Test

```bash
# Test Docker endpoints
curl -I http://localhost:9000/sse   # Graphiti MCP (should return 200)
redis-cli -h localhost -p 6380 ping # FalkorDB (should return PONG)
```

### Comprehensive Test

```bash
# Run the connectivity test script
python fake_memory.py --test
```

This will check:
- ✓ Configuration is loaded
- ✓ Environment variables are set correctly
- ✓ FalkorDB is accessible
- ✓ Graphiti status

## Injecting Fake Memories

Use the `fake_memory.py` script to manually inject test memories:

### 1. Session Insight

```bash
python fake_memory.py \
  --spec-dir .auto-claude/specs/001-test \
  --type insight \
  --content "Successfully implemented JWT authentication with refresh tokens"
```

### 2. Code Pattern

```bash
python fake_memory.py \
  --spec-dir .auto-claude/specs/001-test \
  --type pattern \
  --content "Always hash passwords with bcrypt before storing in database"
```

### 3. Gotcha (Pitfall)

```bash
python fake_memory.py \
  --spec-dir .auto-claude/specs/001-test \
  --type gotcha \
  --content "Remember to close Redis connections in background workers to prevent connection leaks"
```

### 4. File Discovery

```bash
python fake_memory.py \
  --spec-dir .auto-claude/specs/001-test \
  --type discovery \
  --file-path "src/api/auth.py" \
  --content "Handles JWT token generation, validation, and refresh logic"
```

## Verifying Memories in the UI

After injecting memories:

1. **Open Auto-Claude UI**
2. **Navigate to**: `Context` tab (left sidebar)
3. **Switch to**: `Memories` tab
4. **Look for**: Your injected memory in "Recent Memories"

You should see:
- Graph Memory Status: "Connected"
- Database: `auto_claude_memory`
- Host: `localhost:6380`
- Episodes: Count increases with each memory

## UI Configuration

### Project Settings

The Graphiti MCP URL is configured per-project:

1. Open `Settings` (gear icon in project sidebar)
2. Navigate to `Memory` section
3. Ensure these are set:
   - **Memory Backend**: Graphiti (toggle ON)
   - **Enable Agent Memory Access**: ON
   - **Graphiti MCP Server URL**: `http://localhost:9000/sse`

**Important**: The URL MUST end with `/sse`, not `/mcp/`. This is the Server-Sent Events endpoint used by the new Graphiti MCP version.

## Troubleshooting

### Memory Not Appearing in UI

**Problem**: Injected memories don't show up in the Context > Memories tab.

**Solutions**:
1. Check if `GRAPHITI_ENABLED=true` in `auto-claude/.env`
2. Restart the Auto-Claude UI to reload configuration
3. Verify the spec directory exists: `ls -la .auto-claude/specs/001-test`
4. Check logs: `docker logs auto-claude-graphiti-mcp`

### "Configuration validation failed"

**Problem**: Running `python fake_memory.py --test` shows validation errors.

**Solutions**:
1. Ensure `GRAPHITI_ENABLED=true` in environment
2. Check `OPENAI_API_KEY` is set: `echo $OPENAI_API_KEY`
3. Verify FalkorDB is running: `docker ps | grep falkordb`

### "Failed to initialize Graphiti"

**Problem**: Script fails to connect to FalkorDB.

**Solutions**:
1. Check Docker containers are running: `docker-compose ps`
2. Restart containers: `docker-compose restart`
3. Check port conflicts: `lsof -i :6380` (FalkorDB) and `lsof -i :9000` (MCP)
4. Review logs: `docker logs auto-claude-falkordb`

### "Credit balance is too low"

**Problem**: Anthropic API credit balance exhausted.

**Solution**:
Add credits at [console.anthropic.com](https://console.anthropic.com). Note: Claude Max subscription does NOT include API credits. They are separate pay-as-you-go.

### Wrong MCP URL Format

**Problem**: UI shows `http://localhost:9000/mcp/` in the settings.

**Solution**:
The correct endpoint is `/sse`, not `/mcp/`. Update manually in Project Settings → Memory → Graphiti MCP Server URL to:
```
http://localhost:9000/sse
```

## Architecture

### Memory Storage Flow

```
Agent Session
    ↓
Save insights/patterns/discoveries
    ↓
Python Graphiti Client
    ↓
FalkorDB (Graph Database)
    ↓
Graphiti MCP Server (port 9000)
    ↓
Agent can query via MCP tools
```

### Ports

- **6380**: FalkorDB (Redis-compatible graph database)
- **9000**: Graphiti MCP Server (mapped from container port 8000)

### File Locations

- **Spec Data**: `.auto-claude/specs/{spec-name}/`
- **Graphiti State**: `.auto-claude/specs/{spec-name}/.graphiti_state.json`
- **Memory Files**: `.auto-claude/specs/{spec-name}/memory/` (file-based backup)

## Advanced: Querying Memories Manually

### Using Python

```python
import asyncio
from pathlib import Path
from integrations.graphiti.queries_pkg.graphiti import GraphitiMemory
from integrations.graphiti.queries_pkg.schema import GroupIdMode

async def search_memories():
    memory = GraphitiMemory(
        spec_dir=Path(".auto-claude/specs/001-test"),
        project_dir=Path.cwd(),
        group_id_mode=GroupIdMode.SPEC
    )
    
    await memory.initialize()
    
    # Search for relevant context
    results = await memory.get_relevant_context(
        query="authentication JWT tokens",
        num_results=5
    )
    
    for result in results:
        print(f"Score: {result['score']:.2f}")
        print(f"Content: {result['content']}")
        print()
    
    await memory.close()

asyncio.run(search_memories())
```

### Using Redis CLI

```bash
# Connect to FalkorDB
redis-cli -h localhost -p 6380

# List all graphs
GRAPH.LIST

# Query the memory graph
GRAPH.QUERY auto_claude_memory "MATCH (n) RETURN n LIMIT 10"
```

## Next Steps

1. **Run a Real Agent Session**: Create a spec and let the agent build something. Memories will be automatically created.
2. **Search Memories**: Use the UI search box in Context > Memories to find relevant patterns.
3. **Cross-Session Learning**: Subsequent agent sessions will retrieve relevant context from past work.

## References

- [FalkorDB Documentation](https://docs.falkordb.com/)
- [Graphiti MCP Server](https://docs.falkordb.com/agentic-memory/graphiti-mcp-server.html)
- [Auto-Claude Docker Setup](guides/DOCKER-SETUP.md)