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

const options = [
  ["--rag-export", "ragExport"],
  ["--agent-template", "agentTemplate"],
  ["--demo-report", "demoReport"],
  ["--validate-package", "packageValidation"],
  ["--downstream-export", "downstreamExport"],
  ["--quality-gate", "qualityGateOption"],
  ["--run-manifest", "runManifest"],
  ["--risk-labels", "riskLabels"],
  ["--knowledge-graph-export", "knowledgeGraph"],
  ["--retrieval-eval-export", "retrievalEval"],
  ["--embedding", "embedding"],
  ["--vector-export", "vectorExport"]
] as const;

export function BuildPackage({ t, runState, setRunState }: PageProps) {
  const [input, setInput] = useState(".\\examples\\input");
  const [output, setOutput] = useState(".\\examples\\output");
  const [domain, setDomain] = useState("education");
  const [mode, setMode] = useState("teaching");
  const [agentType, setAgentType] = useState("generic_agent");
  const [enabled, setEnabled] = useState<Record<string, boolean>>({});

  const command = useMemo(() => {
    const flags = options.filter(([flag]) => enabled[flag]).map(([flag]) => flag);
    const agent = enabled["--agent-template"] ? ` --agent-type ${agentType}` : "";
    return `heitang-kb-forge build --input ${input} --output ${output} --domain ${domain} --mode ${mode}${agent}${flags.length ? " " + flags.join(" ") : ""}`;
  }, [agentType, domain, enabled, input, mode, output]);

  async function run() {
    setRunState({ status: "empty", log: "Running build...", files: [] });
    try {
      const log = await runKbForge({ workflow: "build", inputPath: input, outputPath: output, domain, mode });
      setRunState({ status: "success", log, files: [] });
    } catch (error) {
      setRunState({ status: "error", log: String(error), files: [] });
    }
  }

  return (
    <div className="page">
      <SectionCard title={t.buildPackage} description="Create a single standardized knowledge package.">
        <div className="form-grid">
          <PathInput label={t.inputPath} value={input} onChange={setInput} />
          <PathInput label={t.outputPath} value={output} onChange={setOutput} />
          <FormRow label={t.domain}><input value={domain} onChange={(event) => setDomain(event.target.value)} /></FormRow>
          <FormRow label={t.mode}><input value={mode} onChange={(event) => setMode(event.target.value)} /></FormRow>
          <FormRow label={t.agentType}><input value={agentType} onChange={(event) => setAgentType(event.target.value)} /></FormRow>
        </div>
        <div className="toggle-grid">
          {options.map(([flag, label]) => (
            <ToggleOption key={flag} label={t[label]} checked={Boolean(enabled[flag])} onChange={(checked) => setEnabled({ ...enabled, [flag]: checked })} />
          ))}
        </div>
        <CommandPreview title={t.commandPreview} command={command} buttonLabel={t.run} onRun={run} />
      </SectionCard>
      <SectionCard title={t.result}>
        <RunLog title={t.runLog} runState={runState} />
        <FileList title={t.generatedFiles} files={runState.files} />
        <JsonViewer title={t.rawJson} value={{ status: runState.status, command }} />
      </SectionCard>
    </div>
  );
}
