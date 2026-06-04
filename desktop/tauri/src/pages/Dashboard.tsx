import { Badge } from "../components/Badge";
import { EmptyState } from "../components/EmptyState";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageId } from ".";
import type { PageProps } from "./types";

type DashboardProps = PageProps & {
  onNavigate?: (page: PageId) => void;
};

export function Dashboard({ t, appState, onNavigate }: DashboardProps) {
  const overview = [
    [t("field.workspacePath"), appState.currentWorkspace],
    [t("field.packagePath"), appState.currentPackage],
    ["CLI", t(`status.${appState.cliStatus}`)],
    [t("status.running"), t(`status.${appState.lastRunStatus}`)]
  ];
  const metrics = [
    [t("nav.packageDetail"), 0],
    [t("field.inputPath"), 0],
    [t("section.changeDetection"), 0],
    ["High Risk", 0],
    [t("section.updateQualityGate"), t("status.notChecked")],
    [t("section.qualityAcceptance"), t("status.pending")]
  ];

  return (
    <div className="page">
      <SectionCard title={t("page.dashboard.title")} description={t("page.dashboard.description")}>
        <div className="status-grid">
          {overview.map(([label, value]) => <StatusCard key={label} label={String(label)} value={String(value)} />)}
        </div>
        <div className="flow-line">Documents -&gt; Skill / CLI -&gt; Knowledge Package -&gt; Quality Gate -&gt; Lifecycle -&gt; Export -&gt; Agent</div>
      </SectionCard>
      <SectionCard title={t("section.lifecycleOverview")}>
        <div className="status-grid">
          {metrics.map(([label, value]) => <StatusCard key={label} label={String(label)} value={String(value)} />)}
        </div>
      </SectionCard>
      <SectionCard title={t("section.currentlyAvailable")}>
        <div className="button-row">
          <button onClick={() => onNavigate?.("buildPackage")}>{t("nav.build")}</button>
          <button onClick={() => onNavigate?.("batchProcessing")}>{t("nav.batch")}</button>
          <button onClick={() => onNavigate?.("workspace")}>{t("action.initializeWorkspace")}</button>
          <button onClick={() => onNavigate?.("askRuntime")}>{t("nav.ask")}</button>
          <button onClick={() => onNavigate?.("publishExport")}>{t("nav.publish")}</button>
        </div>
        <EmptyState title={t("empty.workspace.title")} description={t("empty.workspace.description")} />
        <Badge variant="ready" t={t} />
      </SectionCard>
    </div>
  );
}
