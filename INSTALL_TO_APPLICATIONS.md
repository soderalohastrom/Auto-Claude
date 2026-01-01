# Installing Auto-Claude to macOS Applications

You have two options for running Auto-Claude:

## Option 1: Run from Project Directory (Current Setup)

**Pros:**
- Easy to update (just rebuild when you make changes)
- Keeps everything contained in your dev folder
- Your alias already works: `start-auto-claude`

**How it works:**
```bash
start-auto-claude
```

This runs the script that opens: `auto-claude-ui/dist/mac-arm64/Auto-Claude.app`

**When to rebuild:**
```bash
cd auto-claude-ui
pnpm run package:mac
```

---

## Option 2: Install to /Applications (System-Wide)

**Pros:**
- Available in Spotlight search (⌘+Space → "Auto-Claude")
- Shows up in Launchpad
- Behaves like a normal Mac app
- Can pin to Dock

**Cons:**
- Need to reinstall after code changes
- Takes up space in /Applications

### Installation Steps

**1. Copy the app to Applications:**
```bash
cp -r auto-claude-ui/dist/mac-arm64/Auto-Claude.app /Applications/
```

**2. Remove quarantine attribute (required for unsigned apps):**
```bash
xattr -cr /Applications/Auto-Claude.app
```

**3. Launch it:**
```bash
open /Applications/Auto-Claude.app
```

Or just search for "Auto-Claude" in Spotlight (⌘+Space).

**4. (Optional) Pin to Dock:**
- Open the app
- Right-click the icon in the Dock
- Options → Keep in Dock

### Updating After Code Changes

When you make changes to the code:

```bash
# 1. Rebuild the app
cd auto-claude-ui
pnpm run package:mac

# 2. Reinstall to Applications
cp -r dist/mac-arm64/Auto-Claude.app /Applications/
xattr -cr /Applications/Auto-Claude.app
```

---

## Recommendation

**For now (active development):**
- Use **Option 1** (run from project with `start-auto-claude` alias)
- Quick to rebuild, easy to test changes

**Later (stable version):**
- Use **Option 2** (install to /Applications)
- Better user experience, behaves like a native app

---

## Your Current Setup

✅ **Packaged app built:** `auto-claude-ui/dist/mac-arm64/Auto-Claude.app`  
✅ **Startup script:** `start_auto_claude.sh`  
✅ **Alias configured:** `start-auto-claude` in `~/.zshrc`

**To launch right now:**
```bash
start-auto-claude
```

This will:
1. Check if the app exists (it does now!)
2. Verify Python environment
3. Check for `.env` configuration
4. Launch the packaged Auto-Claude.app

**First-time use checklist:**
- [ ] Run `start-auto-claude` to launch
- [ ] Project Settings → General → "Use Z.ai endpoint for this project" (toggle ON)
- [ ] Enter your Z.ai API token
- [ ] New Task → Agent Profile → Auto (Optimized)
- [ ] Click "Use Z.ai GLM 4.7 for all phases" button
- [ ] Run your first autonomous task! 🎉

---

## Troubleshooting

**"Auto-Claude.app is damaged and can't be opened"**
```bash
xattr -cr /path/to/Auto-Claude.app
```

**App won't launch / crashes immediately:**
- Check `auto-claude/.env` exists with valid API keys
- Check Console.app for error logs
- Try running from terminal to see errors:
  ```bash
  /path/to/Auto-Claude.app/Contents/MacOS/Auto-Claude
  ```

**Want to uninstall:**
```bash
rm -rf /Applications/Auto-Claude.app
```
