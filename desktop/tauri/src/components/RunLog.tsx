import type { RunState } from "../pages/types";
import { EmptyState } from "./EmptyState";

type RunLogProps = {
  runState: RunState;
  t: (key: string) => string;
};

export function RunLog({ runState, t }: RunLogProps) {
  if (runState.status === "empty") {
    return <EmptyState title={t("empty.run.title")} description={t("empty.run.description")} />;
  }

  return (
    <div className={`run-log run-log-${runState.status}`}>
      <div className="run-log-meta">
        <span>{t("status." + runState.status)}</span>
        <span>{runState.durationMs ? `${runState.durationMs}ms` : "-"}</span>
      </div>
      <h3>stdout</h3>
      <pre>{runState.stdout || "-"}</pre>
      <h3>stderr</h3>
      <pre>{runState.stderr || "-"}</pre>
    </div>
  );
}
