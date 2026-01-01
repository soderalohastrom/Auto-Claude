/**
 * Model and agent profile constants
 * Claude models, Z.ai GLM models, MiniMax models, thinking levels, memory backends, and agent profiles
 */

import type {
  AgentProfile,
  PhaseModelConfig,
  FeatureModelConfig,
  FeatureThinkingConfig,
  ModelTypeShort,
} from "../types/settings";

export type LLMProvider = "zai" | "minimax";

export interface ProviderConfig {
  name: string;
  baseUrl: string;
  apiKeyEnvVar: string;
  defaultModel: string;
  fastModel: string;
}

export const PROVIDER_CONFIGS: Record<LLMProvider, ProviderConfig> = {
  zai: {
    name: "Z.ai (GLM)",
    baseUrl: "https://api.z.ai/v1",
    apiKeyEnvVar: "ZAI_API_KEY",
    defaultModel: "glm-4-7-latest",
    fastModel: "glm-4-5-air-latest",
  },
  minimax: {
    name: "MiniMax",
    baseUrl: "https://api.minimax.io/anthropic",
    apiKeyEnvVar: "MINIMAX_API_KEY",
    defaultModel: "MiniMax-M2.1",
    fastModel: "MiniMax-M2.1-lightning",
  },
};

export const DEFAULT_PROVIDER: LLMProvider = "zai";

// ============================================
// Available Models
// ============================================

export const AVAILABLE_MODELS = [
  {
    value: "opus",
    label: "Z.ai GLM-4.7 (Cost-Effective)",
    provider: "zai" as LLMProvider,
  },
  {
    value: "sonnet",
    label: "MiniMax M2.1 (Advanced Thinking)",
    provider: "minimax" as LLMProvider,
  },
  {
    value: "haiku",
    label: "Z.ai GLM-4.5-Air (Fast)",
    provider: "zai" as LLMProvider,
  },
] as const;

// Maps model shorthand to actual model IDs with provider info
export const MODEL_ID_MAP: Record<
  ModelTypeShort,
  { id: string; provider: LLMProvider }
> = {
  opus: { id: "glm-4-7-latest", provider: "zai" },
  sonnet: { id: "MiniMax-M2.1", provider: "minimax" },
  haiku: { id: "glm-4-5-air-latest", provider: "zai" },
} as const;

// ============================================
// Thinking Levels
// ============================================

// Maps thinking levels to budget tokens (null = no extended thinking)
export const THINKING_BUDGET_MAP: Record<string, number | null> = {
  none: null,
  low: 1024,
  medium: 4096,
  high: 16384,
  ultrathink: 65536,
} as const;

// Thinking levels for model (budget token allocation)
export const THINKING_LEVELS = [
  { value: "none", label: "None", description: "No extended thinking" },
  { value: "low", label: "Low", description: "Brief consideration" },
  { value: "medium", label: "Medium", description: "Moderate analysis" },
  { value: "high", label: "High", description: "Deep thinking" },
  {
    value: "ultrathink",
    label: "Ultra Think",
    description: "Maximum reasoning depth",
  },
] as const;

// ============================================
// Agent Profiles
// ============================================

// Default phase model configuration for Auto profile
// Uses Z.ai GLM-4.7 for spec/planning, GLM-4.5-Air for coding/QA (cost-effective)
export const DEFAULT_PHASE_MODELS: PhaseModelConfig = {
  spec: "opus",
  planning: "opus",
  coding: "haiku",
  qa: "haiku",
};

// Default phase thinking configuration for Auto profile
export const DEFAULT_PHASE_THINKING: import("../types/settings").PhaseThinkingConfig =
  {
    spec: "ultrathink",
    planning: "high",
    coding: "low",
    qa: "low",
  };

// ============================================
// Feature Settings (Non-Pipeline Features)
// ============================================

// Default feature model configuration (for insights, ideation, roadmap)
export const DEFAULT_FEATURE_MODELS: FeatureModelConfig = {
  insights: "haiku",
  ideation: "opus",
  roadmap: "opus",
};

// Default feature thinking configuration
export const DEFAULT_FEATURE_THINKING: FeatureThinkingConfig = {
  insights: "medium",
  ideation: "high",
  roadmap: "high",
};

// Feature labels for UI display
export const FEATURE_LABELS: Record<
  keyof FeatureModelConfig,
  { label: string; description: string }
> = {
  insights: {
    label: "Insights Chat",
    description: "Ask questions about your codebase",
  },
  ideation: {
    label: "Ideation",
    description: "Generate feature ideas and improvements",
  },
  roadmap: {
    label: "Roadmap",
    description: "Create strategic feature roadmaps",
  },
};

// ============================================
// Agent Profiles
// ============================================

export const DEFAULT_AGENT_PROFILES: AgentProfile[] = [
  {
    id: "auto",
    name: "Auto (Multi-Provider Optimized)",
    description:
      "Uses Z.ai GLM-4.7 and MiniMax M2.1 with optimized thinking levels",
    model: "opus",
    thinkingLevel: "high",
    icon: "Sparkles",
    isAutoProfile: true,
    phaseModels: DEFAULT_PHASE_MODELS,
    phaseThinking: DEFAULT_PHASE_THINKING,
  },
  {
    id: "complex",
    name: "Complex Tasks",
    description:
      "For intricate, multi-step implementations requiring deep analysis",
    model: "opus",
    thinkingLevel: "ultrathink",
    icon: "Brain",
  },
  {
    id: "balanced",
    name: "Balanced",
    description: "Good balance of speed and quality with MiniMax M2.1",
    model: "sonnet",
    thinkingLevel: "medium",
    icon: "Scale",
  },
  {
    id: "quick",
    name: "Quick Edits",
    description: "Fast iterations with Z.ai GLM-4.5-Air",
    model: "haiku",
    thinkingLevel: "low",
    icon: "Zap",
  },
];

// ============================================
// Memory Backends
// ============================================

export const MEMORY_BACKENDS = [
  { value: "file", label: "File-based (default)" },
  { value: "graphiti", label: "Graphiti (LadybugDB)" },
] as const;
