import { useState } from "react";
import { Badge } from "../components/Badge";
import { CommandPreview } from "../components/CommandPreview";
import { EmptyState } from "../components/EmptyState";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function AskRuntime({ t, appState }: PageProps) {
  const [query, setQuery] = useState("");
  const command = `heitang-kb-forge ask --package ${appState.currentPackage} --query "${query || "..."}" --top-k 5 --output .\\ask_output`;
  return (
    <div className="page">
      <SectionCard title={t("page.ask.title")} description={t("page.ask.description")}>
        <div className="form-grid">
          <PathInput label={t("field.packagePath")} value={appState.currentPackage} readonly t={t} />
          <PathInput label={t("field.outputPath")} value=".\\ask_output" readonly t={t} />
          <FormRow label={t("field.query")}><textarea value={query} placeholder={t("placeholder.query")} onChange={(event) => setQuery(event.target.value)} /></FormRow>
          <FormRow label={t("field.topK")}><input value="5" readOnly /></FormRow>
          <FormRow label={t("field.agentTarget")} variant="future" t={t}><select><option>generic_rag</option><option>mcp_server_future</option></select></FormRow>
          <FormRow label={t("field.connectorMode")} variant="future" t={t}><select><option>export_only</option><option>local_runtime_future</option><option>remote_api_future</option></select></FormRow>
        </div>
        {!appState.currentPackage ? <Badge variant="warning" t={t} /> : null}
        <CommandPreview command={command} t={t} buttonLabel={t("action.ask")} />
        <EmptyState title={t("empty.ask.title")} description={t("empty.ask.description")} />
        <p className="notice">{t("notice.noEvidence")}</p>
        <JsonViewer title="retrieval_trace.json" value={{ retrieved_chunks: [], citations: [] }} />
      </SectionCard>
    </div>
  );
}
