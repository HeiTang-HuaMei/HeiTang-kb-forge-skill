import { CommandPreview } from "../components/CommandPreview";
import { EmptyState } from "../components/EmptyState";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function AskRuntime({ t }: PageProps) {
  const command = "heitang-kb-forge ask --package .\\output_sample --query \"...\" --top-k 5 --output .\\ask_output";
  return (
    <div className="page">
      <SectionCard title={t.askRuntime} description="Local ask runtime preview with citation and retrieval trace placeholders.">
        <div className="form-grid">
          <PathInput label="package path" value=".\\output_sample" onChange={() => undefined} />
          <PathInput label="output path" value=".\\ask_output" onChange={() => undefined} />
          <FormRow label="query"><textarea value="请先选择知识包" readOnly /></FormRow>
          <FormRow label="top_k"><input value="5" readOnly /></FormRow>
          <FormRow label={t.agentTarget}><select><option>generic_rag</option><option>mcp_server_future</option></select></FormRow>
          <FormRow label={t.connectorMode}><select><option>{t.exportOnly}</option><option>{t.localRuntimeFuture}</option><option>{t.remoteApiFuture}</option></select></FormRow>
        </div>
        <CommandPreview title={t.commandPreview} command={command} />
        <EmptyState message="没有选择知识包时显示：请先选择知识包。没有证据时显示：证据不足，无法可靠回答。" />
        <JsonViewer title="retrieval_trace.json" value={{ retrieved_chunks: [], citations: [] }} />
      </SectionCard>
    </div>
  );
}
