# Claude to Z.ai Migration Audit

**Created**: 2025-12-30  
**Purpose**: Document all Claude API touchpoints to replace with Z.ai for cost reduction

## Executive Summary

Auto-Claude currently defaults to Claude models throughout the stack. Since Z.ai (GLM-4.7, MiniMax M2.1) costs ~1/8th of Claude, we need to audit and replace all Claude defaults with Z.ai configuration.

**Key Finding**: The "not enough tokens" error when creating tasks from Kanban is caused by the title generator using hardcoded `claude-haiku-4-5` model directly, ignoring Z.ai environment configuration.

---

## Current Z.ai Integration Status

### ✅ Already Working
- **Backend client detection**: `auto-claude/core/client.py` Line 258 detects Z.ai via `ANTHROPIC_BASE_URL`
- **Environment variable pattern**: Z.ai works through `ANTHROPIC_BASE_URL` pointing to Z.ai proxy
- **SDK compatibility**: Claude SDK client works with Z.ai when properly configured

### ❌ Blocking Issues
1. **Title Generator** (`auto-claude-ui/src/main/title-generator.ts` Line 237)
   - Hardcoded `model="claude-haiku-4-5"`
   - Creates ClaudeSDKClient without respecting `ANTHROPIC_BASE_URL`
   - **This causes the "not enough tokens" error**

2. **Model ID Constants** (UI and Backend)
   - All model IDs hardcoded to Claude variants
   - No Z.ai model options in dropdowns

---

## Detailed Touchpoint Audit

### Frontend (TypeScript/Electron)

#### 1. Model Constants
**File**: `auto-claude-ui/src/shared/constants/models.ts`

```typescript
// Lines 17-21: AVAILABLE_MODELS - UI dropdowns
export const AVAILABLE_MODELS = [
  { value: "opus", label: "Claude Opus 4.5" },
  { value: "sonnet", label: "Claude Sonnet 4.5" },
  { value: "haiku", label: "Claude Haiku 4.5" },
] as const;

// Lines 24-28: MODEL_ID_MAP - Maps to actual Claude model IDs
export const MODEL_ID_MAP: Record<string, string> = {
  opus: "claude-opus-4-5-20251101",
  sonnet: "claude-sonnet-4-5-20250929",
  haiku: "claude-haiku-4-5-20251001",
} as const;
```

**Action Required**:
- [ ] Add Z.ai model options (glm47, minimax-m21, etc.)
- [ ] Update MODEL_ID_MAP with Z.ai model IDs
- [ ] Make Z.ai the default selection

#### 2. Title Generator (CRITICAL - Causes "Not Enough Tokens" Error)
**File**: `auto-claude-ui/src/main/title-generator.ts`

```typescript
// Line 237: Hardcoded Claude model
client = ClaudeSDKClient(
    options=ClaudeAgentOptions(
        model="claude-haiku-4-5",  // ← HARDCODED
        system_prompt="...",
        max_turns=1,
    )
)
```

**Action Required**:
- [ ] Replace hardcoded model with environment-configured model
- [ ] Respect `ANTHROPIC_BASE_URL` from environment
- [ ] Use cheaper model (Z.ai equivalent or configurable default)
- [ ] Add error handling for token limits with fallback

**Fix Priority**: **CRITICAL** - This is causing user-reported errors

#### 3. Agent Profiles
**File**: `auto-claude-ui/src/shared/constants/models.ts`

```typescript
// Lines 116-153: DEFAULT_AGENT_PROFILES
export const DEFAULT_AGENT_PROFILES: AgentProfile[] = [
  {
    id: "auto",
    name: "Auto (Optimized)",
    description: "Uses Opus across all phases...",
    model: "opus",  // ← Claude default
    thinkingLevel: "high",
    // ...
  },
  // ... other profiles all use Claude models
];
```

**Action Required**:
- [ ] Create Z.ai-optimized profiles
- [ ] Update default profile to use Z.ai
- [ ] Keep Claude profiles as optional (for users with Claude credits)

---

### Backend (Python)

#### 4. Phase Configuration
**File**: `auto-claude/phase_config.py`

```python
# Lines 15-16: Model name mappings
"opus": "claude-opus-4-5-20251101",
"sonnet": "claude-sonnet-4-5-20250929",
```

**Action Required**:
- [ ] Add Z.ai model mappings (e.g., `"glm47": "glm-4-7-latest"`)
- [ ] Update defaults to Z.ai models

#### 5. Runner Defaults
Multiple runner files use hardcoded Claude models:

**Roadmap Runner** (`auto-claude/runners/roadmap_runner.py`)
```python
# Lines 58-59
default="claude-opus-4-5-20251101",
help="Model to use (default: claude-opus-4-5-20251101)",
```

**Ideation Runner** (`auto-claude/runners/ideation_runner.py`)
```python
# Lines 97-98
default="claude-opus-4-5-20251101",
help="Model to use (default: claude-opus-4-5-20251101)",
```

**Insights Runner** (`auto-claude/runners/insights_runner.py`)
```python
# Lines 135, 339-340
model: str = "claude-sonnet-4-5-20250929",
default="claude-sonnet-4-5-20250929",
help="Claude model ID (default: claude-sonnet-4-5-20250929)",
```

**AI Analyzer** (`auto-claude/runners/ai_analyzer/claude_client.py`)
```python
# Line 20
DEFAULT_MODEL = "claude-sonnet-4-5-20250929"
```

**CLI Utils** (`auto-claude/cli/utils.py`)
```python
# Line 32
DEFAULT_MODEL = "claude-opus-4-5-20251101"
```

**Spec Compaction** (`auto-claude/spec/compaction.py`)
```python
# Line 19
model: str = "claude-sonnet-4-5-20250929",
```

**Spec Pipeline** (`auto-claude/spec/pipeline/orchestrator.py`)
```python
# Lines 59, 177
model: str = "claude-sonnet-4-5-20250929",
model="claude-sonnet-4-5-20250929",  # Use Sonnet for efficiency
```

**Analysis** (`auto-claude/analysis/insight_extractor.py`)
```python
# Line 34
DEFAULT_EXTRACTION_MODEL = "claude-3-5-haiku-latest"
```

**Action Required for ALL**:
- [ ] Change all defaults to Z.ai models
- [ ] Keep Claude as optional via `--model` flag
- [ ] Update help text to mention Z.ai as default

#### 6. Graphiti Integration
**File**: `auto-claude/integrations/graphiti/config.py`

```python
# Lines 126-127, 176-177
anthropic_api_key: str = ""
anthropic_model: str = "claude-sonnet-4-5"
anthropic_model = os.environ.get("GRAPHITI_ANTHROPIC_MODEL", "claude-sonnet-4-5")
```

**Action Required**:
- [ ] Update Graphiti LLM provider to support Z.ai
- [ ] Add Z.ai as a provider option alongside Anthropic
- [ ] Update default to Z.ai when available

---

## Implementation Strategy

### Phase 1: Fix Critical "Not Enough Tokens" Error ⚠️

**Priority**: Immediate  
**Estimated Time**: 30 minutes

1. **Update Title Generator** (`auto-claude-ui/src/main/title-generator.ts`)
   ```typescript
   // Replace line 237
   // OLD: model="claude-haiku-4-5",
   // NEW: Use environment config with fallback
   
   const model = process.env.AUTO_BUILD_MODEL || "glm-4-7-latest";
   const baseUrl = process.env.ANTHROPIC_BASE_URL;
   
   client = ClaudeSDKClient(
       options=ClaudeAgentOptions(
           model=model,
           // Add base_url if using Z.ai
           ...(baseUrl && { base_url: baseUrl }),
           system_prompt="...",
           max_turns=1,
       )
   )
   ```

2. **Test**: Create task from Kanban board - should no longer error

### Phase 2: Update Model Constants

**Priority**: High  
**Estimated Time**: 1 hour

1. **UI Constants** (`auto-claude-ui/src/shared/constants/models.ts`)
   ```typescript
   export const AVAILABLE_MODELS = [
     // Z.ai models (default)
     { value: "glm47", label: "GLM-4.7 (Z.ai) - Recommended" },
     { value: "minimax-m21", label: "MiniMax M2.1 (Z.ai)" },
     // Claude models (optional)
     { value: "opus", label: "Claude Opus 4.5" },
     { value: "sonnet", label: "Claude Sonnet 4.5" },
     { value: "haiku", label: "Claude Haiku 4.5" },
   ] as const;
   
   export const MODEL_ID_MAP: Record<string, string> = {
     // Z.ai models
     glm47: "glm-4-7-latest",
     "minimax-m21": "minimax-m2.1-latest",
     // Claude models
     opus: "claude-opus-4-5-20251101",
     sonnet: "claude-sonnet-4-5-20250929",
     haiku: "claude-haiku-4-5-20251001",
   } as const;
   ```

2. **Update Default Profiles** (same file)
   ```typescript
   export const DEFAULT_AGENT_PROFILES: AgentProfile[] = [
     {
       id: "auto",
       name: "Auto (Z.ai Optimized)",
       description: "Uses GLM-4.7 across all phases for best cost/performance",
       model: "glm47",  // Changed from "opus"
       thinkingLevel: "high",
       // ...
     },
     // Add new Claude profile for users with Claude credits
     {
       id: "claude-premium",
       name: "Claude Premium",
       description: "Uses Claude Opus for maximum quality (higher cost)",
       model: "opus",
       thinkingLevel: "ultrathink",
       icon: "Brain",
     },
     // ... rest of profiles
   ];
   ```

### Phase 3: Update Backend Defaults

**Priority**: High  
**Estimated Time**: 1 hour

1. **Create Z.ai model mapping** in `phase_config.py`
   ```python
   PHASE_MODELS = {
       # Z.ai models (default)
       "glm47": "glm-4-7-latest",
       "minimax-m21": "minimax-m2.1-latest",
       # Claude models (optional)
       "opus": "claude-opus-4-5-20251101",
       "sonnet": "claude-sonnet-4-5-20250929",
       "haiku": "claude-haiku-4-5-20251001",
   }
   ```

2. **Update all runner defaults** to use Z.ai:
   - Replace all `claude-opus-4-5-20251101` → `glm-4-7-latest`
   - Replace all `claude-sonnet-4-5-20250929` → `glm-4-7-latest`
   - Replace all `claude-3-5-haiku-latest` → `glm-4-7-latest`

3. **Update help text** in argparse definitions to mention Z.ai as default

### Phase 4: Testing

1. **Test title generation** from Kanban (should work without "not enough tokens" error)
2. **Test task creation** with different profiles
3. **Test spec creation** with Z.ai models
4. **Test all runners** (roadmap, ideation, insights) with Z.ai
5. **Verify cost reduction** in Z.ai dashboard

---

## Z.ai Configuration Requirements

### Environment Variables (.env files)

**Backend** (`auto-claude/.env`):
```bash
# Z.ai Configuration (Required)
ANTHROPIC_BASE_URL=https://api.z.ai/v1  # Or your Z.ai proxy URL
ANTHROPIC_API_KEY=your-zai-api-key

# Model Override (Optional - will use glm-4-7-latest by default)
# AUTO_BUILD_MODEL=glm-4-7-latest

# Disable Claude-specific features
DISABLE_COST_WARNINGS=true  # Z.ai pricing is different
```

**Frontend** (`auto-claude-ui/.env`):
```bash
# Debug (Optional)
# DEBUG=true
```

### Verification

To verify Z.ai is being used:

1. **Check logs** for "LLM Provider: Z.ai" message (from `core/client.py` line 260)
2. **Monitor Z.ai dashboard** for API usage
3. **Watch token costs** - should be ~1/8th of Claude

---

## Cost Comparison

| Model | Provider | Input ($/1M tokens) | Output ($/1M tokens) | Use Case |
|-------|----------|---------------------|----------------------|----------|
| **GLM-4.7** | **Z.ai** | **$0.xx** | **$0.xx** | **Default** |
| **MiniMax M2.1** | **Z.ai** | **$0.xx** | **$0.xx** | **Alternative** |
| Claude Opus 4.5 | Anthropic | $15.00 | $75.00 | Premium (optional) |
| Claude Sonnet 4.5 | Anthropic | $3.00 | $15.00 | Balanced (optional) |
| Claude Haiku 4.5 | Anthropic | $0.80 | $4.00 | Fast (optional) |

**Estimated savings**: **87.5%** (using Z.ai instead of Claude)

---

## Migration Checklist

### Critical (Fix "Not Enough Tokens" Error)
- [ ] Update `title-generator.ts` to respect `ANTHROPIC_BASE_URL`
- [ ] Test task creation from Kanban board

### High Priority (Default to Z.ai)
- [ ] Add Z.ai models to `AVAILABLE_MODELS` constant
- [ ] Update `MODEL_ID_MAP` with Z.ai model IDs
- [ ] Change default agent profile to use Z.ai
- [ ] Update `phase_config.py` with Z.ai mappings
- [ ] Update all runner defaults to Z.ai models
- [ ] Test end-to-end workflow with Z.ai

### Medium Priority (Polish)
- [ ] Update UI labels to show "Z.ai" provider
- [ ] Add cost estimation with Z.ai pricing
- [ ] Update documentation to reflect Z.ai as default
- [ ] Create migration guide for existing users

### Low Priority (Optional Enhancements)
- [ ] Add Z.ai-specific optimizations
- [ ] Profile Z.ai vs Claude performance
- [ ] Add model comparison UI
- [ ] Support multiple Z.ai models in dropdowns

---

## Rollback Plan

If issues arise:

1. **Immediate**: Revert `title-generator.ts` to hardcoded model (with error handling)
2. **Environment**: Remove `ANTHROPIC_BASE_URL` to fall back to Claude
3. **Code**: Git revert model constant changes
4. **Users**: Provide clear error messages about missing Z.ai configuration

---

## Next Steps

1. **Confirm Z.ai credentials** are in `auto-claude/.env`
2. **Fix title generator** (Phase 1 - Critical)
3. **Test task creation** from Kanban
4. **Update model constants** (Phase 2)
5. **Verify cost reduction** in Z.ai dashboard

---

## Notes

- Z.ai uses Anthropic-compatible API, so existing `ClaudeSDKClient` works
- No need to change authentication flow - just point to different base URL
- Model IDs need to match what Z.ai expects (verify in Z.ai docs)
- Keep Claude models as option for users who want premium quality

---

## Questions for User

1. What are the exact Z.ai model IDs you want to use? (e.g., `glm-4-7-latest`, `minimax-m2.1-latest`)
2. Do you want to completely remove Claude options, or keep them as "premium" alternatives?
3. Should we update existing tasks to use Z.ai, or only new tasks?
4. Do you have Z.ai API credentials ready in `.env` files?
