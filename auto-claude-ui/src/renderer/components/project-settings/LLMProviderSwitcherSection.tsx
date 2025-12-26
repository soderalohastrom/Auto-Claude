import { Globe, Save, RefreshCw } from "lucide-react";
import { CollapsibleSection } from "./CollapsibleSection";
import { StatusBadge } from "./StatusBadge";
import { Button } from "../ui/button";
import { Label } from "../ui/label";
import { Input } from "../ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import type { ProjectEnvConfig } from "../../../shared/types";

/**
 * LLM Provider Switcher Section
 * Lets users toggle between Anthropic and Z.ai GLM4.7 providers
 * Supports Z.ai's Anthropic-compatible endpoint and model mappings
 */
interface LLMProviderSwitcherSectionProps {
  isExpanded: boolean;
  onToggle: () => void;
  envConfig: ProjectEnvConfig | null;
  isLoadingEnv: boolean;
  envError: string | null;
  onUpdateConfig: (
    updates: Partial<ProjectEnvConfig & { llmProvider?: "anthropic" | "zai" }>,
  ) => void;
}

export function LLMProviderSwitcherSection({
  isExpanded,
  onToggle,
  envConfig,
  isLoadingEnv,
  envError,
  onUpdateConfig,
}: LLMProviderSwitcherSectionProps) {
  // Determine current provider from environment variables
  const currentProvider = envConfig?.claudeOAuthToken
    ? envConfig.anthropicBaseUrl?.includes("z.ai")
      ? "zai"
      : "anthropic"
    : "anthropic";

  // Status badge for current provider
  const providerBadge =
    currentProvider === "zai" ? (
      <StatusBadge status="info" label="Z.ai GLM4.7" />
    ) : (
      <StatusBadge status="success" label="Anthropic" />
    );

  // Handle provider selection change
  const handleProviderChange = (value: "anthropic" | "zai") => {
    if (value === "anthropic") {
      // Switch to default Anthropic configuration
      onUpdateConfig({
        anthropicBaseUrl: undefined,
        anthropicAuthToken: undefined,
        // Uncomment below to reset model mappings (Anthropic defaults)
        // anthropicDefaultOpusModel: 'claude-opus-4-5-20251101',
        // anthropicDefaultSonnetModel: 'claude-sonnet-4-5-20250929',
        // anthropicDefaultHaikuModel: 'claude-haiku-4-5-20251001',
      });
    } else {
      // Switch to Z.ai configuration (pre-filled with known values)
      onUpdateConfig({
        anthropicBaseUrl: "https://api.z.ai/api/anthropic",
        // Uncomment below to set Z.ai model mappings (GLM models)
        // anthropicDefaultOpusModel: 'GLM-4.7',
        // anthropicDefaultSonnetModel: 'GLM-4.7',
        // anthropicDefaultHaikuModel: 'GLM-4.5-Air',
      });
    }
  };

  return (
    <CollapsibleSection
      title="LLM Provider Switcher"
      icon={<Globe className="h-4 w-4" />}
      isExpanded={isExpanded}
      onToggle={onToggle}
      badge={providerBadge}
    >
      {isLoadingEnv ? (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <RefreshCw className="h-4 w-4 animate-spin" />
          Loading LLM configuration...
        </div>
      ) : envConfig ? (
        <div className="space-y-6">
          {/* Provider Selection Dropdown */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label className="text-sm font-medium text-foreground">
                Active LLM Provider
              </Label>
              <Button
                size="sm"
                variant="ghost"
                onClick={() =>
                  handleProviderChange(
                    currentProvider === "anthropic" ? "zai" : "anthropic",
                  )
                }
              >
                Switch to{" "}
                {currentProvider === "anthropic" ? "Z.ai" : "Anthropic"}
              </Button>
            </div>
            <Select
              value={currentProvider}
              onValueChange={(value) =>
                handleProviderChange(value as "anthropic" | "zai")
              }
            >
              <SelectTrigger>
                <SelectValue placeholder="Select provider" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="anthropic">Anthropic (Default)</SelectItem>
                <SelectItem value="zai">Z.ai (GLM4.7)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Z.ai Configuration (only show if selected) */}
          {currentProvider === "zai" && (
            <div className="rounded-lg border border-info/30 bg-info/5 p-4 space-y-4">
              <div className="flex items-center gap-2">
                <Globe className="h-4 w-4 text-info" />
                <h4 className="text-sm font-medium text-info">
                  Z.ai GLM4.7 Configuration
                </h4>
              </div>

              {/* Z.ai Base URL */}
              <div className="space-y-2">
                <Label className="text-sm font-medium text-foreground">
                  Z.ai Anthropic Endpoint
                </Label>
                <Input
                  value={
                    envConfig.anthropicBaseUrl ||
                    "https://api.z.ai/api/anthropic"
                  }
                  onChange={(e) =>
                    onUpdateConfig({ anthropicBaseUrl: e.target.value })
                  }
                  placeholder="https://api.z.ai/api/anthropic"
                />
              </div>

              {/* Z.ai Auth Token */}
              <div className="space-y-2">
                <Label className="text-sm font-medium text-foreground">
                  Z.ai Auth Token
                </Label>
                <Input
                  value={envConfig.anthropicAuthToken || ""}
                  onChange={(e) =>
                    onUpdateConfig({ anthropicAuthToken: e.target.value })
                  }
                  placeholder="your-zai-auth-token"
                />
              </div>

              {/* Model Mapping Configuration (Commented-out for easy switching) */}
              <div className="mt-4 pt-4 border-t border-info/20">
                <p className="text-xs text-muted-foreground mb-2">
                  Model Mapping Configuration (Uncomment in envConfig to
                  enable):
                </p>
                <pre className="text-xs text-info bg-info/10 p-2 rounded font-mono overflow-x-auto">
                  {/*
// Z.ai Model Mappings (replace Anthropic models)
anthropicDefaultOpusModel: 'GLM-4.7',
anthropicDefaultSonnetModel: 'GLM-4.7',
anthropicDefaultHaikuModel: 'GLM-4.5-Air',

// Uncomment to force specific model usage
// autoBuildModel: 'GLM-4.7',
*/}
                </pre>
                <p className="text-xs text-muted-foreground mt-2">
                  Add these to your project's envConfig to map Claude model
                  names to Z.ai GLM models
                </p>
              </div>
            </div>
          )}

          {/* Anthropic Default Configuration (Commented-out reference) */}
          {currentProvider === "anthropic" && (
            <div className="rounded-lg border border-muted/30 bg-muted/5 p-4">
              <pre className="text-xs text-muted-foreground bg-muted/10 p-2 rounded font-mono overflow-x-auto">
                {/*
// Anthropic Default Configuration (uncomment to reset)
anthropicBaseUrl: undefined,
anthropicAuthToken: undefined,
anthropicDefaultOpusModel: 'claude-opus-4-5-20251101',
anthropicDefaultSonnetModel: 'claude-sonnet-4-5-20250929',
anthropicDefaultHaikuModel: 'claude-haiku-4-5-20251001',
*/}
              </pre>
              <p className="text-xs text-muted-foreground mt-2">
                Uncomment above to reset to default Anthropic models
              </p>
            </div>
          )}

          {/* Apply Changes Button */}
          <Button size="sm" onClick={() => onUpdateConfig({})} className="mt-2">
            <Save className="h-3 w-3 mr-2" />
            Apply Provider Settings
          </Button>
        </div>
      ) : envError ? (
        <p className="text-sm text-destructive">{envError}</p>
      ) : (
        <p className="text-sm text-muted-foreground">
          Project not initialized. Complete setup to configure LLM provider.
        </p>
      )}
    </CollapsibleSection>
  );
}
