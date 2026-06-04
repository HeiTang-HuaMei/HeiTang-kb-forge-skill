import { useMemo, useState } from "react";
import { runKbForge } from "../api";
import { CommandPreview } from "../components/CommandPreview";
import { FileList } from "../components/FileList";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { RunLog } from "../components/RunLog";
import { SectionCard } from "../components/SectionCard";
import { ToggleOption } from "../components/ToggleOption";
import type { PageProps } from "./types";

const groups = [
  ["section.buildEnhancement", [["--rag-export", "RAG"], ["--agent-template", "Agent Template"], ["--downstream-export", "Downstream Export"], ["--knowledge-graph-export", "Knowledge Graph"]]],
  ["section.qualityAcceptance", [["--validate-package", "Package Validation"], ["--quality-gate", "Quality Gate"], ["--risk-labels", "Risk Labels"], ["--demo-report", "Demo Report"]]],
  ["section.runTrace", [["--run-manifest", "Run Manifest"], ["--retrieval-eval-export", "Retrieval Eval"], ["--embedding", "Embedding"], ["--vector-export", "Vector Export"]]]
] as const;

export function BuildPackage({ t, setRunState, runState, setAppState }: PageProps) {
  const [input, setInput] = useState(".\\examples\\input");
  const [output, setOutput] = useState(".\\examples\\output");
  const [domain, setDomain] = useState("education");
  const [mode, setMode] = useState("teaching");
  const [agentType, setAgentType] = useState("generic_agent");
  const [enabled, setEnabled] = useState<Record<string, boolean>>({});
  const command = useMemo(() => {
    const flags = Object.keys(enabled).filter((flag) => enabled[flag]);
    const agent = enabled["--agent-template"] ? ` --agent-type ${agentType}` : "";
    return `heitang-kb-forge build --input ${input} --output ${output} --domain ${domain} --mode ${mode}${agent}${flags.length ? " " + flags.join(" ") : ""}`;
  }, [agentType, domain, enabled, input, mode, output]);

  async function run() {
    const started = performance.now();
    setRunState({ status: "running", stdout: "", stderr: "", files: [] });
    try {
      const stdout = await runKbForge({ workflow: "build", inputPath: input, outputPath: output, domain, mode });
      setAppState((state) => ({ ...state, currentPackage: output, lastRunStatus: "success" }));
      setRunState({ status: "success", stdout, stderr: "", durationMs: Math.round(performance.now() - started), files: [] });
    } catch (error) {
      setAppState((state) => ({ ...state, lastRunStatus: "failed" }));
      setRunState({ status: "failed", stdout: "", stderr: String(error), durationMs: Math.round(performance.now() - started), files: [] });
    }
  }

  return (
    <div className="page">
      <SectionCard title={t("page.build.title")} description={t("page.build.description")}>
        <h3>{t("section.basicInput")}</h3>
        <div className="form-grid">
          <PathInput label={t("field.inputPath")} value={input} onChange={setInput} t={t} />
          <PathInput label={t("field.outputPath")} value={output} onChange={setOutput} t={t} />
          <FormRow label={t("field.domain")}><input value={domain} onChange={(event) => setDomain(event.target.value)} /></FormRow>
          <FormRow label={t("field.mode")}><input value={mode} onChange={(event) => setMode(event.target.value)} /></FormRow>
          <FormRow label={t("field.agentType")}><input value={agentType} onChange={(event) => setAgentType(event.target.value)} /></FormRow>
        </div>
        {groups.map(([title, options]) => (
          <div key={title}>
            <h3>{t(title)}</h3>
            <div className="toggle-grid">
              {options.map(([flag, label]) => (
                <ToggleOption key={flag} label={label} checked={Boolean(enabled[flag])} onChange={(checked) => setEnabled({ ...enabled, [flag]: checked })} />
              ))}
            </div>
          </div>
        ))}
        <CommandPreview command={command} t={t} buttonLabel={t("action.build")} onRun={run} failed={runState.status === "failed"} />
      </SectionCard>
      <SectionCard title={t("section.resultSummary")}>
        <RunLog runState={runState} t={t} />
        <FileList title={t("section.generatedFiles")} files={runState.files} />
        <JsonViewer title={t("section.rawJson")} value={{ status: runState.status, command }} />
      </SectionCard>
    </div>
  );
}
