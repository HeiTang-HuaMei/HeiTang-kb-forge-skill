import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { MarkdownPanel } from "../components/MarkdownPanel";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function PlanningReadiness({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t("page.planning.title")} description={t("page.planning.description")}>
        <p className="notice">{t("notice.planningNotRuntime")}</p>
        <div className="module-grid">
          {["Planning Blueprint", "Tool Requirement Map", "Planning Eval Cases", "Planning Risk Report"].map((title) => (
            <div className="module-card" key={title}><h3>{title}</h3><p>{t("status.notLoaded")}</p></div>
          ))}
        </div>
        <FileList title={t("section.generatedFiles")} files={["agent_planning_blueprint.yaml", "tool_requirement_map.json", "planning_eval_cases.jsonl", "planning_risk_report.md"]} />
        <MarkdownPanel title="planning_risk_report.md" content={t("status.notLoaded")} />
        <JsonViewer title={t("section.rawJson")} value={{ runtime: false }} />
      </SectionCard>
    </div>
  );
}
