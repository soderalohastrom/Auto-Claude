import {
  RefreshCw,
  Download,
  CheckCircle2,
  AlertCircle,
  Loader2,
} from "lucide-react";
import { Button } from "../ui/button";
import { Label } from "../ui/label";
import { Switch } from "../ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import { Separator } from "../ui/separator";
import { AVAILABLE_MODELS } from "../../../shared/constants";
import type {
  Project,
  ProjectSettings as ProjectSettingsType,
  AutoBuildVersionInfo,
  ProjectEnvConfig,
} from "../../../shared/types";

interface GeneralSettingsProps {
  project: Project;
  settings: ProjectSettingsType;
  setSettings: React.Dispatch<React.SetStateAction<ProjectSettingsType>>;
  versionInfo: AutoBuildVersionInfo | null;
  isCheckingVersion: boolean;
  isUpdating: boolean;
  handleInitialize: () => Promise<void>;
  handleUpdate: () => Promise<void>;

  /**
   * Environment config for this project (.auto-claude/.env)
   * We use this (not ProjectSettings) to store per-project endpoint overrides like Z.ai.
   */
  envConfig: ProjectEnvConfig | null;
  onUpdateEnvConfig: (updates: Partial<ProjectEnvConfig>) => void;
}

export function GeneralSettings({
  project,
  settings,
  setSettings,
  versionInfo,
  isCheckingVersion,
  isUpdating,
  handleInitialize,
  handleUpdate: _handleUpdate,
  envConfig,
  onUpdateEnvConfig,
}: GeneralSettingsProps) {
  return (
    <>
      {/* Auto-Build Integration */}
      <section className="space-y-4">
        <h3 className="text-sm font-semibold text-foreground">
          Auto-Build Integration
        </h3>
        {!project.autoBuildPath ? (
          <div className="rounded-lg border border-border bg-muted/50 p-4">
            <div className="flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-warning mt-0.5 shrink-0" />
              <div className="flex-1">
                <p className="text-sm font-medium text-foreground">
                  Not Initialized
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  Initialize Auto-Build to enable task creation and agent
                  workflows.
                </p>
                <Button
                  size="sm"
                  className="mt-3"
                  onClick={handleInitialize}
                  disabled={isUpdating}
                >
                  {isUpdating ? (
                    <>
                      <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                      Initializing...
                    </>
                  ) : (
                    <>
                      <Download className="mr-2 h-4 w-4" />
                      Initialize Auto-Build
                    </>
                  )}
                </Button>
              </div>
            </div>
          </div>
        ) : (
          <div className="rounded-lg border border-border bg-muted/50 p-4 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-success" />
                <span className="text-sm font-medium text-foreground">
                  Initialized
                </span>
              </div>
              <code className="text-xs bg-background px-2 py-1 rounded">
                {project.autoBuildPath}
              </code>
            </div>
            {isCheckingVersion ? (
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Loader2 className="h-3 w-3 animate-spin" />
                Checking status...
              </div>
            ) : (
              versionInfo && (
                <div className="text-xs text-muted-foreground">
                  {versionInfo.isInitialized
                    ? "Initialized"
                    : "Not initialized"}
                </div>
              )
            )}
          </div>
        )}
      </section>

      {project.autoBuildPath && (
        <>
          <Separator />

          {/* Agent Settings */}
          <section className="space-y-4">
            <h3 className="text-sm font-semibold text-foreground">
              Agent Configuration
            </h3>

            {/* Z.ai per-project endpoint toggle (high visibility) */}
            <div className="rounded-lg border border-border bg-muted/30 p-4 space-y-3">
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <Label className="text-sm font-medium text-foreground">
                    Use Z.ai endpoint for this project
                  </Label>
                  <p className="text-xs text-muted-foreground">
                    Routes agent LLM calls through Z.ai’s Anthropic-compatible
                    endpoint for this project only. This does not affect other
                    apps or global settings.
                  </p>
                </div>
                <Switch
                  checked={Boolean(envConfig?.anthropicBaseUrl)}
                  onCheckedChange={(checked) => {
                    if (checked) {
                      onUpdateEnvConfig({
                        anthropicBaseUrl: "https://api.z.ai/api/anthropic",
                      });
                    } else {
                      onUpdateEnvConfig({
                        anthropicBaseUrl: undefined,
                        anthropicAuthToken: undefined,
                      });
                    }
                  }}
                />
              </div>

              {/* Show endpoint + token only when enabled */}
              {Boolean(envConfig?.anthropicBaseUrl) && (
                <div className="space-y-3 pt-3 border-t border-border">
                  <div className="space-y-1">
                    <Label className="text-xs text-muted-foreground">
                      ANTHROPIC_BASE_URL
                    </Label>
                    <input
                      className="h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm text-foreground"
                      value={
                        envConfig?.anthropicBaseUrl ||
                        "https://api.z.ai/api/anthropic"
                      }
                      onChange={(e) =>
                        onUpdateEnvConfig({
                          anthropicBaseUrl: e.target.value,
                        })
                      }
                      placeholder="https://api.z.ai/api/anthropic"
                    />
                  </div>

                  <div className="space-y-1">
                    <Label className="text-xs text-muted-foreground">
                      ANTHROPIC_AUTH_TOKEN (Z.ai)
                    </Label>
                    <input
                      className="h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm text-foreground"
                      value={envConfig?.anthropicAuthToken || ""}
                      onChange={(e) =>
                        onUpdateEnvConfig({
                          anthropicAuthToken: e.target.value,
                        })
                      }
                      placeholder="paste your Z.ai token here…"
                    />
                    <p className="text-xs text-muted-foreground">
                      Tip: You already validated this works via{" "}
                      <code>./test_zai_anthropic_proxy.sh</code>.
                    </p>
                  </div>
                </div>
              )}
            </div>

            <div className="space-y-2">
              <Label
                htmlFor="model"
                className="text-sm font-medium text-foreground"
              >
                Model
              </Label>
              <Select
                value={settings.model}
                onValueChange={(value) =>
                  setSettings({ ...settings, model: value })
                }
              >
                <SelectTrigger id="model">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {AVAILABLE_MODELS.map((model) => (
                    <SelectItem key={model.value} value={model.value}>
                      {model.label}
                    </SelectItem>
                  ))}

                  {/* Z.ai models (per-project)
                      Selecting these sets the model string passed to the Claude Code CLI.
                      To route traffic to Z.ai, enable the toggle above and set the token.
                  */}
                  <SelectItem value="glm-4.7">Z.ai GLM 4.7</SelectItem>
                  <SelectItem value="glm-4.5-air">Z.ai GLM 4.5 Air</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </section>

          <Separator />

          {/* Notifications */}
          <section className="space-y-4">
            <h3 className="text-sm font-semibold text-foreground">
              Notifications
            </h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="font-normal text-foreground">
                  On Task Complete
                </Label>
                <Switch
                  checked={settings.notifications.onTaskComplete}
                  onCheckedChange={(checked) =>
                    setSettings({
                      ...settings,
                      notifications: {
                        ...settings.notifications,
                        onTaskComplete: checked,
                      },
                    })
                  }
                />
              </div>
              <div className="flex items-center justify-between">
                <Label className="font-normal text-foreground">
                  On Task Failed
                </Label>
                <Switch
                  checked={settings.notifications.onTaskFailed}
                  onCheckedChange={(checked) =>
                    setSettings({
                      ...settings,
                      notifications: {
                        ...settings.notifications,
                        onTaskFailed: checked,
                      },
                    })
                  }
                />
              </div>
              <div className="flex items-center justify-between">
                <Label className="font-normal text-foreground">
                  On Review Needed
                </Label>
                <Switch
                  checked={settings.notifications.onReviewNeeded}
                  onCheckedChange={(checked) =>
                    setSettings({
                      ...settings,
                      notifications: {
                        ...settings.notifications,
                        onReviewNeeded: checked,
                      },
                    })
                  }
                />
              </div>
              <div className="flex items-center justify-between">
                <Label className="font-normal text-foreground">Sound</Label>
                <Switch
                  checked={settings.notifications.sound}
                  onCheckedChange={(checked) =>
                    setSettings({
                      ...settings,
                      notifications: {
                        ...settings.notifications,
                        sound: checked,
                      },
                    })
                  }
                />
              </div>
            </div>
          </section>
        </>
      )}
    </>
  );
}
