import { EmptyState } from "../components/EmptyState";
import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { MarkdownPanel } from "../components/MarkdownPanel";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

const packageFiles = [
  "manifest.json",
  "quality_report.json",
  "package_validation_report.json",
  "package_readiness_report.md",
  "quality_gate_report.json",
  "quality_gate_summary.md",
  "risk_labels.jsonl",
  "rag_manifest.json",
  "embedding_manifest.json",
  "vector_store_manifest.json",
  "agent_profile.yaml",
  "demo_report.md",
  "source_registry.json",
  "incremental_update_report.md",
  "update_quality_gate_report.json"
];

export function PackageDetail({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t.packageDetail} description="Inspect package metadata, quality, readiness, runtime, and lifecycle state.">
        <FileList title={t.generatedFiles} files={packageFiles} />
        <div className="module-grid">
          {["基础摘要", "输出文件", "质量摘要", "Readiness", "风险标签", "生命周期状态", "RAG / Embedding / Vector 状态", "Agent Template 状态", "Demo Report 状态"].map((title) => (
            <div className="module-card" key={title}><h3>{title}</h3><p>Not loaded.</p></div>
          ))}
        </div>
        <EmptyState message={t.emptyState} />
        <JsonViewer title={t.rawJson} value={{ files: packageFiles }} />
        <MarkdownPanel title="Raw Markdown" content="No markdown loaded." />
      </SectionCard>
    </div>
  );
}
