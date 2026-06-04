import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

export function Settings({ t }: PageProps) {
  return (
    <div className="page">
      <SectionCard title={t.settings} description="Desktop defaults and future local index backend placeholders.">
        <div className="form-grid">
          <FormRow label="当前语言"><select><option>zh-CN</option><option>en-US</option></select></FormRow>
          <FormRow label="当前主题"><input value="dark" readOnly /></FormRow>
          <FormRow label="Python 命令"><input value="heitang-kb-forge" readOnly /></FormRow>
          <FormRow label="当前工作目录"><input value=".\\desktop\\tauri" readOnly /></FormRow>
          <FormRow label="项目版本"><input value="v1.2.3" readOnly /></FormRow>
          <FormRow label="Tauri App 版本"><input value="1.2.3" readOnly /></FormRow>
          <PathInput label="默认输入目录" value=".\\input" onChange={() => undefined} />
          <PathInput label="默认输出目录" value=".\\output" onChange={() => undefined} />
          <FormRow label={t.knowledgeStoreBackend}><select><option>{t.fileSystem}</option><option>{t.sqliteFuture}</option><option>{t.postgresFuture}</option></select></FormRow>
          <PathInput label={t.sqliteDbPath} value=".\\workspace\\knowledge_store.sqlite" onChange={() => undefined} />
          <FormRow label={t.vectorStoreBackend}><select><option>{t.localJson}</option><option>{t.faissFuture}</option><option>{t.chromaFuture}</option><option>{t.qdrantFuture}</option><option>{t.milvusFuture}</option></select></FormRow>
          <FormRow label={t.agentTarget}><select><option>generic_rag</option><option>openai_files</option><option>dify_import</option><option>fastgpt_import</option><option>coze_knowledge</option><option>{t.mcpServerFuture}</option><option>{t.customAgentApiFuture}</option></select></FormRow>
          <FormRow label={t.connectorMode}><select><option>{t.exportOnly}</option><option>{t.localRuntimeFuture}</option><option>{t.remoteApiFuture}</option></select></FormRow>
        </div>
        <div className="status-grid">
          <StatusCard label="知识包索引状态" value="future" />
          <StatusCard label="源文件注册表同步状态" value="future" />
          <StatusCard label="Chunk 索引同步状态" value="future" />
          <StatusCard label="最近同步时间" value="-" />
        </div>
        <p className="notice">{t.boundary}</p>
        <JsonViewer title={t.rawJson} value={{ store: "file_system", vector: "local_json", connector: "export_only" }} />
      </SectionCard>
    </div>
  );
}
