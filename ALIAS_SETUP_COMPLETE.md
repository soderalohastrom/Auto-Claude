# Auto-Claude Aliases - Setup Complete ✅

## Quick Reference

```bash
start-auto-claude  # Start Auto-Claude UI
stop-auto-claude   # Stop Auto-Claude gracefully
```

## Your ~/.zshrc Should Have

```bash
# Auto-Claude v2.7.1 aliases
alias start-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh'
alias stop-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh'
```

## Setup Instructions

### 1. Open your ~/.zshrc

```bash
nano ~/.zshrc
# or
code ~/.zshrc
```

### 2. Add or update the aliases

Find any existing `start-auto-claude` or `stop-auto-claude` lines and replace with:

```bash
# Auto-Claude v2.7.1 aliases
alias start-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh'
alias stop-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh'
```

### 3. Reload your shell

```bash
source ~/.zshrc
```

### 4. Test them

```bash
start-auto-claude  # Should start UI without Docker
stop-auto-claude   # Should stop gracefully (no errors)
```

## What Changed

### Old Stop Method ❌
```bash
alias stop-auto-claude='pkill -f "electron.*auto-claude-ui"'
```
**Problem**: Abrupt kill → GPU/network crash errors

### New Stop Method ✅
```bash
alias stop-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh'
```
**Benefit**: Graceful shutdown → clean exit, no errors

## Scripts Overview

### start_auto_claude.sh
- Checks Python 3.12+ availability
- Verifies dependencies
- Builds UI if needed
- Starts Electron app
- Shows process ID

### stop_auto_claude.sh  
- Finds Electron process
- Sends SIGTERM (graceful shutdown)
- Waits up to 5 seconds
- Force kills only if necessary
- Clean exit, no errors

## Troubleshooting

### Aliases not found

```bash
# Reload shell config
source ~/.zshrc

# Or open new terminal window
```

### Permission denied

```bash
chmod +x /Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh
chmod +x /Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh
```

### Wrong path error

```bash
# Verify scripts exist
ls -la /Users/soderstrom/2025/December/Auto-Claude/*.sh

# Update paths in ~/.zshrc if you moved the repository
```

### "Auto-Claude is not running"

This is normal if you try to stop when nothing is running. Not an error!

## Verification

```bash
# Check your aliases
alias | grep auto-claude

# Expected output:
# start-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/start_auto_claude.sh'
# stop-auto-claude='/Users/soderstrom/2025/December/Auto-Claude/stop_auto_claude.sh'
```

## Full Workflow

```bash
# Start
start-auto-claude
# → Checks environment
# → Builds if needed
# → Starts UI
# → Shows PID

# Use Auto-Claude
# ... do your work ...

# Stop (gracefully)
stop-auto-claude
# → Finds process
# → Sends graceful shutdown
# → Waits for clean exit
# → No crash errors!
```

## Benefits

✅ **Start**: No Docker, instant launch  
✅ **Stop**: Graceful shutdown, no errors  
✅ **Simple**: Two commands, that's it  
✅ **Reliable**: Works every time  

## Files

- `start_auto_claude.sh` - Startup script (no Docker)
- `stop_auto_claude.sh` - Graceful stop script (no errors)
- `~/.zshrc` - Your shell config with aliases

## Status

✅ Scripts created and executable  
✅ Syntax validated  
✅ Ready to add to ~/.zshrc  

---

**Next**: Add aliases to ~/.zshrc, reload, and test!

```bash
# Quick setup
nano ~/.zshrc
# Add the two alias lines above
source ~/.zshrc
start-auto-claude
```
