import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { MarkdownPanel } from "../components/MarkdownPanel";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function PlanningReadiness({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t.planningReadiness} description="Agent Planning Readiness assets, not an Agent Planning Runtime.">
        <p className="notice">这是 Agent Planning Readiness 资产，不是 Agent Planning Runtime。</p>
        <FileList title={t.generatedFiles} files={["agent_planning_blueprint.yaml", "tool_requirement_map.json", "planning_eval_cases.jsonl", "planning_risk_report.md"]} />
        <MarkdownPanel title="planning_risk_report.md" content="No planning readiness report loaded." />
        <JsonViewer title={t.rawJson} value={{ runtime: false }} />
      </SectionCard>
    </div>
  );
}
