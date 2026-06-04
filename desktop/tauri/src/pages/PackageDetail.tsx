import { Badge } from "../components/Badge";
import { EmptyState } from "../components/EmptyState";
import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { MarkdownPanel } from "../components/MarkdownPanel";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

const categories = {
  summary: ["manifest.json", "quality_report.json", "package_validation_report.json"],
  readiness: ["package_readiness_report.md", "quality_gate_report.json", "quality_gate_summary.md", "risk_labels.jsonl"],
  runtime: ["rag_manifest.json", "embedding_manifest.json", "vector_store_manifest.json", "agent_profile.yaml", "demo_report.md"],
  lifecycle: ["source_registry.json", "incremental_update_report.md", "update_quality_gate_report.json"]
};

export function PackageDetail({ t, appState }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t("page.packageDetail.title")} description={t("page.packageDetail.description")}>
        <div className="form-grid">
          <PathInput label={t("field.packagePath")} value={appState.currentPackage} readonly t={t} />
          <button>{t("action.loadDetail")}</button>
        </div>
        <div className="status-grid">
          <StatusCard label="updated_at" value="-" />
          <StatusCard label="version" value="-" />
          <StatusCard label="domain" value="-" />
          <StatusCard label="agent_type" value="-" />
        </div>
        <EmptyState title={t("empty.package.title")} description={t("empty.package.description")} />
        {Object.entries(categories).map(([title, files]) => <FileList key={title} title={title} files={files} />)}
        <div className="module-grid">
          {["basic_summary", "quality_summary", "readiness", "risk_labels", "lifecycle_status", "rag_embedding_vector", "agent_template"].map((title) => (
            <div className="module-card" key={title}><h3>{title}</h3><Badge variant="notLoaded" t={t} /></div>
          ))}
        </div>
        <JsonViewer title={t("section.rawJson")} value={categories} />
        <MarkdownPanel title="Raw Markdown" content={t("status.notLoaded")} />
      </SectionCard>
    </div>
  );
}
