import type { Dispatch, SetStateAction } from "react";
import type { Locale } from "../i18n";

export type AppState = {
  locale: Locale;
  theme: "dark";
  currentWorkspace: string;
  currentPackage: string;
  cliStatus: "ready" | "missing" | "checking";
  lastRunStatus: "empty" | "running" | "success" | "warning" | "failed";
};

export type RunState = {
  status: "empty" | "running" | "success" | "warning" | "failed";
  stdout: string;
  stderr: string;
  durationMs?: number;
  files: string[];
};

export type PageProps = {
  t: (key: string) => string;
  locale: Locale;
  appState: AppState;
  setAppState: Dispatch<SetStateAction<AppState>>;
  runState: RunState;
  setRunState: (state: RunState) => void;
};
