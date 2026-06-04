import { Badge } from "../components/Badge";
import { FileList } from "../components/FileList";
import { JsonViewer } from "../components/JsonViewer";
import { MarkdownPanel } from "../components/MarkdownPanel";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

export function QualityGate({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t("page.quality.title")} description={t("page.quality.description")}>
        <h3>{t("section.qualityAcceptance")}</h3>
        <div className="status-grid">
          <StatusCard label="quality_score" value="-" />
          <StatusCard label="quality_level" value={t("status.notLoaded")} />
          <StatusCard label="gate_status" value={t("status.pending")} />
          <StatusCard label="hallucination_risk" value={t("status.notChecked")} />
          <StatusCard label="citation_coverage" value="-" />
          <StatusCard label="source_path_coverage" value="-" />
          <StatusCard label="ocr_table_warning_count" value={0} />
          <StatusCard label="low_confidence_count" value={0} />
          <StatusCard label="update_regression" value={t("status.notChecked")} />
        </div>
        <div className="module-grid">
          <div className="module-card"><h3>package_acceptance_report.md</h3><Badge variant="pending" t={t} /><p>{t("status.notLoaded")}</p></div>
          <div className="module-card"><h3>quality_gate_summary.md</h3><Badge variant="pending" t={t} /><p>{t("status.notLoaded")}</p></div>
        </div>
        <FileList title={t("section.generatedFiles")} files={["quality_report.json", "quality_gate_report.json", "package_acceptance_report.md", "risk_labels.jsonl", "update_quality_gate_report.json", "quality_regression_report.md"]} />
        <MarkdownPanel title="package_acceptance_report.md" content={t("status.notLoaded")} />
        <JsonViewer title={t("section.rawJson")} value={{ gate_status: "pending" }} />
      </SectionCard>
    </div>
  );
}
