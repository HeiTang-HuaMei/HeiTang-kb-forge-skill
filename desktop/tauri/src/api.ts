import { invoke } from "@tauri-apps/api/core";

export type Workflow = "build" | "batch" | "pipeline";

export type RunRequest = {
  workflow: Workflow;
  inputPath: string;
  outputPath: string;
  domain: string;
  mode: string;
};

export async function runKbForge(request: RunRequest): Promise<string> {
  return invoke<string>("run_kb_forge", request);
}
