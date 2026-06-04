import { Badge } from "../components/Badge";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

export function Settings({ t, locale, appState, setAppState }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t("page.settings.title")} description={t("page.settings.description")}>
        <h3>{t("section.currentlyAvailable")}</h3>
        <div className="form-grid">
          <FormRow label={t("field.language")}>
            <select value={locale} onChange={(event) => setAppState((state) => ({ ...state, locale: event.target.value as typeof locale }))}>
              <option value="zh-CN">中文</option>
              <option value="en-US">English</option>
            </select>
          </FormRow>
          <FormRow label={t("field.theme")} variant="readonly"><div className="readonly-field">{appState.theme}</div></FormRow>
          <FormRow label={t("field.pythonCommand")} variant="readonly"><div className="readonly-field">heitang-kb-forge</div></FormRow>
          <FormRow label={t("field.currentWorkingDirectory")} variant="readonly"><div className="readonly-field">.\desktop\tauri</div></FormRow>
          <FormRow label={t("field.projectVersion")} variant="readonly"><div className="readonly-field">v1.2.4</div></FormRow>
          <FormRow label={t("field.tauriAppVersion")} variant="readonly"><div className="readonly-field">1.2.3</div></FormRow>
          <PathInput label={t("field.defaultInputDirectory")} value=".\\input" readonly t={t} />
          <PathInput label={t("field.defaultOutputDirectory")} value=".\\output" readonly t={t} />
        </div>
        <h3>{t("section.storageSettings")}</h3>
        <div className="form-grid">
          <FormRow label={t("field.knowledgeStoreBackend")} variant="readonly"><div className="readonly-field">file_system <Badge variant="ready" t={t} /></div></FormRow>
          <FormRow label={t("field.sqliteDbPath")} variant="future" t={t}><div className="future-field">.\workspace\knowledge_store.sqlite</div></FormRow>
          <FormRow label="Postgres DSN" variant="future" t={t}><div className="future-field">postgres_future</div></FormRow>
        </div>
        <h3>{t("section.vectorSettings")}</h3>
        <div className="form-grid">
          <FormRow label={t("field.vectorStoreBackend")} variant="readonly"><div className="readonly-field">local_json <Badge variant="ready" t={t} /></div></FormRow>
          {["faiss_future", "chroma_future", "qdrant_future", "milvus_future"].map((name) => <FormRow key={name} label={name} variant="future" t={t}><div className="future-field">{name}</div></FormRow>)}
        </div>
        <h3>{t("section.agentConnectorSettings")}</h3>
        <div className="form-grid">
          <FormRow label={t("field.agentTarget")} variant="readonly"><div className="readonly-field">generic_rag</div></FormRow>
          <FormRow label={t("field.connectorMode")} variant="readonly"><div className="readonly-field">export_only <Badge variant="ready" t={t} /></div></FormRow>
          {["mcp_server_future", "custom_agent_api_future", "local_runtime_future", "remote_api_future"].map((name) => <FormRow key={name} label={name} variant="future" t={t}><div className="future-field">{name}</div></FormRow>)}
        </div>
        <div className="status-grid">
          <StatusCard label="package_indexed" value={t("status.future")} />
          <StatusCard label="source_registry_synced" value={t("status.future")} />
          <StatusCard label="chunk_index_synced" value={t("status.future")} />
          <StatusCard label="last_sync_time" value="-" />
        </div>
        <SectionCard title={t("section.skillFirstBoundary")}>
          <p className="notice">{t("settings.skillFirst")}</p>
        </SectionCard>
        <JsonViewer title={t("section.rawJson")} value={{ locale, store: "file_system", vector: "local_json", connector: "export_only" }} />
      </SectionCard>
    </div>
  );
}
