import { Badge } from "../components/Badge";
import { EmptyState } from "../components/EmptyState";
import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

const lifecycleFiles = [
  "source_registry.json",
  "source_change_report.md",
  "changed_sources.jsonl",
  "missing_sources.jsonl",
  "new_sources.jsonl",
  "stale_chunks.jsonl",
  "removed_source_impact_report.md",
  "incremental_update_report.md",
  "reused_chunks.jsonl",
  "rebuilt_chunks.jsonl",
  "removed_chunks.jsonl",
  "update_quality_gate_report.json",
  "quality_regression_report.md",
  "failed_sources.jsonl",
  "retry_manifest.json",
  "retry_report.md"
];

export function LifecycleUpdate({ t }: PageProps) {
  const modules = [t.sourceRegistry, t.changeDetection, t.incrementalUpdate, t.missingSourcePolicy, t.updateQualityGate, t.qualityRegression, t.retryRecovery];
  return (
    <div className="page">
      <SectionCard title={t.lifecycleUpdate} description="Knowledge Lifecycle backend placeholder.">
        <div className="status-grid">
          <StatusCard label={t.sourceCount} value={0} />
          <StatusCard label={t.changedSources} value={0} />
          <StatusCard label={t.newSources} value={0} />
          <StatusCard label={t.missingSources} value={0} />
          <StatusCard label={t.staleChunks} value={0} />
          <StatusCard label={t.updateAcceptanceStatus} value="pending" />
        </div>
        <div className="module-grid">
          {modules.map((module) => (
            <div className="module-card" key={module}>
              <h3>{module}</h3>
              <Badge tone="warning">future</Badge>
              <p>该能力将在 Knowledge Lifecycle 后端完成后启用。</p>
            </div>
          ))}
        </div>
        <div className="button-row">
          <button disabled>{t.fullRebuild}</button>
          <button disabled>{t.changedOnly}</button>
          <button disabled>{t.validateOnly}</button>
          <button disabled>{t.keepOldKnowledge}</button>
          <button disabled>{t.markStale}</button>
          <button disabled>{t.removeMissingKnowledge}</button>
        </div>
        <FileList title={t.generatedFiles} files={lifecycleFiles} />
        <EmptyState message={t.emptyState} />
        <JsonViewer title={t.rawJson} value={{ lifecycleFiles }} />
      </SectionCard>
    </div>
  );
}
