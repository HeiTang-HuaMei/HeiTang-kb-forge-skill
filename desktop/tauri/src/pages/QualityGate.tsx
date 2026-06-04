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
      <SectionCard title={t.qualityGate} description="Quality report, gate status, readiness, and risk review.">
        <div className="status-grid">
          <StatusCard label="quality score" value="-" />
          <StatusCard label="quality level" value="-" />
          <StatusCard label="gate status" value="pending" tone="warning" />
          <StatusCard label="hallucination risk" value="-" />
          <StatusCard label="citation coverage" value="-" />
          <StatusCard label="source path coverage" value="-" />
          <StatusCard label="OCR/table warning count" value={0} />
          <StatusCard label="low confidence count" value={0} />
          <StatusCard label="update regression status" value="not checked" />
        </div>
        <Badge tone="neutral">quality_report.json</Badge>
        <FileList title={t.generatedFiles} files={["quality_report.json", "quality_gate_report.json", "package_acceptance_report.md", "risk_labels.jsonl", "update_quality_gate_report.json", "quality_regression_report.md"]} />
        <MarkdownPanel title="package_acceptance_report.md" content="No acceptance report loaded." />
        <JsonViewer title={t.rawJson} value={{ gate_status: "pending" }} />
      </SectionCard>
    </div>
  );
}
