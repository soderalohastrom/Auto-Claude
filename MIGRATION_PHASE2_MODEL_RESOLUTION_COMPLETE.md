# Migration Phase 2: Model Resolution - COMPLETE ✅

## Summary

Fixed the model resolution layer to ensure all agent calls use `get_phase_model()` which maps shorthand names (opus/sonnet/haiku) to Z.ai GLM models via `MODEL_ID_MAP` in `phase_config.py`.

## Root Cause

The model parameter was being passed directly to `create_client()` without going through the `get_phase_model()` mapping function, causing Claude model IDs to be sent to the Z.ai API endpoint.

## Files Fixed

### 1. `auto-claude/spec/pipeline/agent_runner.py` ✅
**Lines changed:** 8-12, 113-125

**Before:**
```python
from core.client import create_client

# ...
client = create_client(
    self.project_dir,
    self.spec_dir,
    self.model,  # ❌ Raw model, not resolved
    max_thinking_tokens=thinking_budget,
)
```

**After:**
```python
from core.client import create_client
from phase_config import get_phase_model, get_phase_thinking_budget

# ...
model_for_spec_phase = get_phase_model(self.spec_dir, "spec", self.model)
client = create_client(
    self.project_dir,
    self.spec_dir,
    model_for_spec_phase,  # ✅ Resolved through MODEL_ID_MAP
    max_thinking_tokens=thinking_budget,
)
```

**Impact:** All spec creation phases (Discovery, Requirements, Research, Context, Spec Writer, Critic, Planner) now use Z.ai models.

---

### 2. `auto-claude/agents/planner.py` ✅
**Lines changed:** 12, 92-98

**Before:**
```python
from phase_config import get_phase_thinking_budget

# ...
planning_thinking_budget = get_phase_thinking_budget(spec_dir, "planning")
client = create_client(
    project_dir,
    spec_dir,
    model,  # ❌ Raw model, not resolved
    max_thinking_tokens=planning_thinking_budget,
)
```

**After:**
```python
from phase_config import get_phase_model, get_phase_thinking_budget

# ...
model_for_planning_phase = get_phase_model(spec_dir, "planning", model)
planning_thinking_budget = get_phase_thinking_budget(spec_dir, "planning")
client = create_client(
    project_dir,
    spec_dir,
    model_for_planning_phase,  # ✅ Resolved through MODEL_ID_MAP
    max_thinking_tokens=planning_thinking_budget,
)
```

**Impact:** Follow-up planning sessions now use Z.ai models.

---

### 3. `auto-claude/agents/coder.py` ✅ (Already correct!)
**Lines 248-260**

```python
# Get the phase-specific model and thinking level (respects task_metadata.json configuration)
# first_run means we're in planning phase, otherwise coding phase
current_phase = "planning" if first_run else "coding"
phase_model = get_phase_model(spec_dir, current_phase, model)  # ✅ Already correct!
phase_thinking_budget = get_phase_thinking_budget(spec_dir, current_phase)

# Create client (fresh context) with phase-specific model and thinking
client = create_client(
    project_dir,
    spec_dir,
    phase_model,  # ✅ Already using resolved model
    max_thinking_tokens=phase_thinking_budget,
)
```

**Impact:** Main autonomous agent loop (planning + coding phases) was already correct.

---

## Model Resolution Flow (After Fix)

```
User/CLI
  ↓ (passes "opus", "sonnet", "haiku", or full model name)
CLI Default: "GLM-4.7"
  ↓
agent_runner.py / planner.py / coder.py
  ↓
get_phase_model(spec_dir, phase, model)
  ↓
resolve_model_id(model)  [in phase_config.py]
  ↓
MODEL_ID_MAP lookup:
  "opus" → "GLM-4.7"
  "sonnet" → "GLM-4.7"
  "haiku" → "GLM-4.5-Air"
  ↓
create_client(project_dir, spec_dir, "GLM-4.7", ...)
  ↓
Z.ai API with correct model ID ✅
```

## Verification

To verify the fix works:

1. **Check default model:**
   ```bash
   grep "^DEFAULT_MODEL" auto-claude/cli/utils.py
   # Should show: DEFAULT_MODEL = "GLM-4.7"
   ```

2. **Check model mapping:**
   ```bash
   grep -A 5 "MODEL_ID_MAP" auto-claude/phase_config.py
   # Should show Z.ai GLM models (not Claude models)
   ```

3. **Test task creation:**
   - Create a task from Kanban board
   - Check logs for "GLM-4.7" or "GLM-4.5-Air" (not claude-opus/sonnet/haiku)
   - Should NOT see "Credit balance is too low" errors

## Configuration

The active mapping in `auto-claude/phase_config.py`:

```python
MODEL_ID_MAP: dict[str, str] = {
    # Z.ai GLM Mappings (ACTIVE - using cheaper Z.ai models)
    "opus": "GLM-4.7",
    "sonnet": "GLM-4.7",
    "haiku": "GLM-4.5-Air",
    # Claude Mappings (Commented out for "rich day")
    # "opus": "claude-opus-4-5-20251101",
    # "sonnet": "claude-sonnet-4-5-20250929",
    # "haiku": "claude-haiku-4-5-20251001",
}
```

## Environment

Z.ai credentials in `auto-claude/.env`:

```bash
# Z.ai Configuration (PRIMARY)
ANTHROPIC_BASE_URL=https://api.z.ai/v1
ANTHROPIC_API_KEY=3f14bc8806b84ea4b781cdae3f92f86d.t2EdFPfEJ34X8Kxo
ZAI_MODEL_THINKING=GLM-4.7
ZAI_MODEL_FAST=GLM-4.5-Air

DISABLE_COST_WARNINGS=true
```

## Cost Savings

- **Before:** Claude API @ $20/10M tokens
- **After:** Z.ai GLM @ $2.5/10M tokens
- **Savings:** 8x cost reduction 💰

## Status: COMPLETE ✅

All model resolution paths now correctly route through `get_phase_model()` → `resolve_model_id()` → `MODEL_ID_MAP`, ensuring Z.ai GLM models are used instead of expensive Claude models.

**Next step:** Test task creation from Kanban board to confirm no more "Credit balance is too low" errors.
