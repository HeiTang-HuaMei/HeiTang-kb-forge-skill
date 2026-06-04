import { Badge } from "../components/Badge";
import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

const lifecycleModules = [
  ["section.sourceRegistry", ["source_registry.json"]],
  ["section.changeDetection", ["source_change_report.md", "changed_sources.jsonl", "missing_sources.jsonl", "new_sources.jsonl", "stale_chunks.jsonl"]],
  ["section.incrementalUpdate", ["incremental_update_report.md", "reused_chunks.jsonl", "rebuilt_chunks.jsonl", "removed_chunks.jsonl"]],
  ["section.missingSourcePolicy", ["removed_source_impact_report.md"]],
  ["section.updateQualityGate", ["update_quality_gate_report.json"]],
  ["section.qualityRegression", ["quality_regression_report.md"]],
  ["section.retryRecovery", ["failed_sources.jsonl", "retry_manifest.json", "retry_report.md"]]
] as const;

export function LifecycleUpdate({ t }: PageProps) {
  const files = lifecycleModules.flatMap(([, names]) => names);
  return (
    <div className="page">
      <SectionCard title={t("page.lifecycle.title")} description={t("page.lifecycle.description")}>
        <h3>{t("section.lifecycleOverview")}</h3>
        <div className="status-grid">
          <StatusCard label="source_count" value={0} />
          <StatusCard label="changed_sources" value={0} />
          <StatusCard label="new_sources" value={0} />
          <StatusCard label="missing_sources" value={0} />
          <StatusCard label="stale_chunks" value={0} />
          <StatusCard label="update_gate" value={t("status.pending")} />
        </div>
        <h3>{t("section.futureReserved")}</h3>
        <div className="module-grid">
          {lifecycleModules.map(([title, names]) => (
            <div className="module-card" key={title}>
              <h3>{t(title)}</h3>
              <Badge variant="reserved" t={t} />
              <p>{t("notice.futureLifecycle")}</p>
              <ul>{names.map((name) => <li key={name}>{name}</li>)}</ul>
            </div>
          ))}
        </div>
        <p className="notice">{t("notice.lifecycleBoundary")}</p>
        <FileList title={t("section.generatedFiles")} files={files} />
        <JsonViewer title={t("section.rawJson")} value={{ lifecycleModules }} />
      </SectionCard>
    </div>
  );
}
