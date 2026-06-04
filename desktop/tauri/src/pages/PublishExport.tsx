import { FileList } from "../components/FileList";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function PublishExport({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t.publishExport} description="Generate import packages without calling external platform APIs.">
        <div className="form-grid">
          <FormRow label="publish profile"><select><option>generic_rag</option><option>langchain</option><option>llamaindex</option><option>openai_files</option><option>dify_import</option><option>fastgpt_import</option><option>coze_knowledge</option></select></FormRow>
          <FormRow label={t.agentTarget}><select><option>generic_rag</option><option>openai_files</option><option>dify_import</option><option>fastgpt_import</option><option>coze_knowledge</option><option>{t.mcpServerFuture}</option><option>{t.customAgentApiFuture}</option></select></FormRow>
          <FormRow label={t.connectorMode}><select><option>{t.exportOnly}</option><option>{t.localRuntimeFuture}</option><option>{t.remoteApiFuture}</option></select></FormRow>
        </div>
        <p className="notice">这只是生成导入包，不调用外部平台 API。</p>
        <FileList title="publish_package" files={["publish_manifest.json", "langchain_documents.jsonl", "llamaindex_documents.jsonl", "openai_files_manifest.json"]} />
        <JsonViewer title={t.rawJson} value={{ limitations: ["export_only", "no_external_api"] }} />
      </SectionCard>
    </div>
  );
}
