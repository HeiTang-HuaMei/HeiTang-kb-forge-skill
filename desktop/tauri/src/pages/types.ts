import type { Messages } from "../i18n";

export type RunState = {
  status: "empty" | "success" | "error";
  log: string;
  files: string[];
};

export type PageProps = {
  t: Messages;
  runState: RunState;
  setRunState: (state: RunState) => void;
};
