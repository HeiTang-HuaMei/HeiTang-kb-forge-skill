import { Badge } from "../components/Badge";
import { EmptyState } from "../components/EmptyState";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

export function Workspace({ t, appState }: PageProps) {
  const rows = [
    ["demo_product_manager_agent", ".\\examples\\demo_product_manager_agent\\output_sample", "education", "product_manager_agent", "ready", "90", "low", "-", "idle"],
    ["demo_shopping_guide_agent", ".\\examples\\demo_shopping_guide_agent\\output_sample", "commerce", "shopping_guide_agent", "warning", "78", "medium", "-", "idle"]
  ];

  return (
    <div className="page">
      <SectionCard title={t("page.workspace.title")} description={t("page.workspace.description")}>
        <div className="status-grid">
          <StatusCard label={t("field.workspacePath")} value={appState.currentWorkspace} />
          <StatusCard label="registered packages" value={rows.length} />
          <StatusCard label="last refresh" value={t("status.notChecked")} />
          <StatusCard label="registry" value={t("status.ready")} />
        </div>
        <div className="form-grid">
          <PathInput label={t("field.workspacePath")} value={appState.currentWorkspace} readonly t={t} />
          <PathInput label={t("field.packagePath")} value={appState.currentPackage} readonly t={t} />
        </div>
        <div className="button-row compact">
          <button>{t("action.initializeWorkspace")}</button>
          <button>{t("action.registerPackage")}</button>
          <button>{t("action.refreshList")}</button>
        </div>
        <table>
          <thead>
            <tr><th>name</th><th>path</th><th>domain</th><th>agent_type</th><th>readiness</th><th>quality_score</th><th>risk</th><th>updated_at</th><th>status</th></tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row[0]}>{row.map((cell, index) => <td key={cell + index} title={cell}>{index === 8 ? <Badge variant="pending" t={t} /> : cell}</td>)}</tr>
            ))}
          </tbody>
        </table>
        <EmptyState title={t("empty.workspace.title")} description={t("empty.workspace.description")} />
        <JsonViewer title={t("section.rawJson")} value={{ package_registry: rows }} />
      </SectionCard>
    </div>
  );
}
