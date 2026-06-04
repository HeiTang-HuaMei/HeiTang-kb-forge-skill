import type { RunState } from "../pages/types";

type RunLogProps = {
  title: string;
  runState: RunState;
};

export function RunLog({ title, runState }: RunLogProps) {
  return (
    <div className={`run-log run-log-${runState.status}`}>
      <h3>{title}</h3>
      <pre>{runState.log || "No log yet."}</pre>
    </div>
  );
}
