import { FileList } from "../components/FileList";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function PublishExport({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t("page.publish.title")} description={t("page.publish.description")}>
        <h3>{t("section.currentlyAvailable")}</h3>
        <div className="form-grid">
          <FormRow label={t("field.publishProfile")}><select><option>generic_rag</option><option>langchain</option><option>llamaindex</option><option>openai_files</option></select></FormRow>
          <PathInput label={t("field.outputPath")} value=".\\publish_output" readonly t={t} />
        </div>
        <h3>{t("section.futureReserved")}</h3>
        <div className="form-grid">
          <FormRow label={t("field.agentTarget")} variant="future" t={t}><select><option>generic_rag</option><option>openai_files</option><option>dify_import</option><option>fastgpt_import</option><option>coze_knowledge</option><option>mcp_server_future</option><option>custom_agent_api_future</option></select></FormRow>
          <FormRow label={t("field.connectorMode")} variant="future" t={t}><select><option>export_only</option><option>local_runtime_future</option><option>remote_api_future</option></select></FormRow>
        </div>
        <p className="notice">{t("notice.publishExportOnly")} OpenClaw / Claude Code / Codex / Generic Agent targets are reserved.</p>
        <FileList title={t("section.generatedFiles")} files={["publish_manifest.json", "langchain_documents.jsonl", "llamaindex_documents.jsonl", "openai_files_manifest.json"]} />
        <JsonViewer title={t("section.rawJson")} value={{ mode: "export_only" }} />
      </SectionCard>
    </div>
  );
}
