# Update Your zshrc Alias for Auto-Claude v2.7.1

## What Changed

Your startup script has been updated to work with the new embedded LadybugDB memory system (no Docker required). You need to update your zsh alias to point to the new script.

## Current Alias (Old)

Your current `~/.zshrc` probably has:

```bash
alias start-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh'
```

## Good News

**The alias still works!** The script path hasn't changed, only the script's contents have been updated to:
- ✅ Remove Docker commands (no longer needed)
- ✅ Check Python version (3.12+ for memory)
- ✅ Verify dependencies
- ✅ Build and start UI

## Verify Your Alias

```bash
# Check your current alias
grep "start-auto-claude" ~/.zshrc

# Test it
start-auto-claude
```

## Optional: Add Stop Alias

Since Docker is gone, add a graceful stop script:

```bash
# Add to ~/.zshrc
alias stop-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh'
```

**Important**: Use the script path, not `pkill`, to avoid GPU/network crash errors.

## Full Setup (If Starting Fresh)

If you need to set up the alias from scratch:

### 1. Open your zshrc

```bash
nano ~/.zshrc
# or
vim ~/.zshrc
# or
code ~/.zshrc
```

### 2. Add the aliases

```bash
# Auto-Claude aliases
alias start-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh'
alias stop-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh'
```

### 3. Reload your shell

```bash
source ~/.zshrc
```

### 4. Test it

```bash
start-auto-claude
```

## What the Updated Script Does

The new `start_auto_claude.sh` script:

1. ✅ Checks Python 3.12+ availability (for LadybugDB)
2. ✅ Verifies Python virtual environment exists
3. ✅ Checks for `.env` configuration file
4. ✅ Installs UI dependencies if needed
5. ✅ Builds the UI (only if changed)
6. ✅ Starts the Electron app
7. ✅ Shows process ID for easy stopping

**No Docker commands** - Everything is embedded!

## Output You'll See

When you run `start-auto-claude`:

```
======================================================================
  Starting Auto-Claude v2.7.1
======================================================================

Checking Python version...
Building and starting the Auto-Claude UI...

Launching Auto-Claude UI...

======================================================================
  Auto-Claude is starting up!
======================================================================

✅ UI Process ID: 12345
✅ Memory System: LadybugDB (embedded - no Docker needed)
✅ Configuration: auto-claude/.env

The UI should open shortly in a new window.

To stop Auto-Claude later, run:
  kill 12345

Or use: pkill -f 'electron.*auto-claude-ui'
======================================================================
```

## Stopping Auto-Claude

### Option 1: Use the Process ID

```bash
# The script shows the PID when it starts
kill 12345  # Use the actual PID shown
```

### Option 2: Use the alias (Recommended)

```bash
stop-auto-claude  # Graceful shutdown, no errors
```

### Option 3: Close the app normally

Just close the Auto-Claude window like any other app.

## Troubleshooting

### Alias not found

```bash
# Reload your shell config
source ~/.zshrc

# Or open a new terminal window
```

### Permission denied

```bash
# Make the script executable
chmod +x /Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh
```

### Script not found

```bash
# Verify the path
ls -la /Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh

# Update the path in your alias if needed
which start-auto-claude
```

### Python version warning

If you see a Python version warning:

```bash
# Check your Python version
python3 --version

# If < 3.12, memory features will be limited
# Consider upgrading Python or disabling memory:
# In auto-claude/.env: GRAPHITI_ENABLED=false
```

## Migration from Docker Version

### Old workflow (v2.6.5):
```bash
start-auto-claude
# → Started Docker containers
# → Waited for containers to be ready
# → Started UI

docker ps  # To check containers
docker-compose down  # To stop
```

### New workflow (v2.7.1):
```bash
start-auto-claude
# → Checks environment
# → Starts UI with embedded database

# No Docker to check!
stop-auto-claude  # To stop
```

## Benefits of the New Script

✅ **Faster startup** - No Docker container initialization  
✅ **Simpler** - One command, no dependencies  
✅ **Reliable** - Fewer moving parts  
✅ **Portable** - Works anywhere Python 3.12+ is installed  
✅ **Better errors** - Helpful warnings if something is missing  

## Quick Reference

```bash
# Start Auto-Claude
start-auto-claude

# Stop Auto-Claude (gracefully)
stop-auto-claude

# Check if running
ps aux | grep "electron.*auto-claude"

# View scripts
cat /Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh
cat /Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh

# Edit scripts
nano /Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh
nano /Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh
```

## Summary

✅ Your `start-auto-claude` alias still works!  
✅ Script updated automatically (no Docker commands)  
✅ Add `stop-auto-claude` alias for graceful shutdown  
✅ Much simpler workflow now  

Just run `start-auto-claude` as before and enjoy the faster, simpler v2.7.1!

**Note**: Use the `stop_auto_claude.sh` script for stopping (not `pkill`) to avoid GPU/network crash errors.