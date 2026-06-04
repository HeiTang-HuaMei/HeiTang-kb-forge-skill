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

export function BatchProcessing({ t, runState, setRunState }: PageProps) {
  const [input, setInput] = useState(".\\input");
  const [output, setOutput] = useState(".\\output");
  const [domain, setDomain] = useState("education");
  const [mode, setMode] = useState("teaching");
  const [merge, setMerge] = useState(false);
  const [failFast, setFailFast] = useState(false);
  const [qualityGate, setQualityGate] = useState(false);
  const [runManifest, setRunManifest] = useState(false);
  const [maxFiles, setMaxFiles] = useState("");
  const [maxChunks, setMaxChunks] = useState("");
  const command = useMemo(() => {
    const flags = [
      merge ? "--merge-same-sequence" : "",
      failFast ? "--fail-fast" : "",
      qualityGate ? "--quality-gate" : "",
      runManifest ? "--run-manifest" : "",
      maxFiles ? `--max-files ${maxFiles}` : "",
      maxChunks ? `--max-chunks ${maxChunks}` : ""
    ].filter(Boolean);
    return `heitang-kb-forge batch --input ${input} --output ${output} --domain ${domain} --mode ${mode} --continue-on-error${flags.length ? " " + flags.join(" ") : ""}`;
  }, [domain, failFast, input, maxChunks, maxFiles, merge, mode, output, qualityGate, runManifest]);

  async function run() {
    setRunState({ status: "empty", log: "Running batch...", files: [] });
    try {
      const log = await runKbForge({ workflow: "batch", inputPath: input, outputPath: output, domain, mode });
      setRunState({ status: "success", log, files: ["batch_run_summary.json", "failed_items.jsonl", "retry_manifest.json"] });
    } catch (error) {
      setRunState({ status: "error", log: String(error), files: [] });
    }
  }

  return (
    <div className="page">
      <SectionCard title={t.batchProcessing} description="Run numbered source files with isolated item failure handling.">
        <div className="form-grid">
          <PathInput label={t.inputPath} value={input} onChange={setInput} />
          <PathInput label={t.outputPath} value={output} onChange={setOutput} />
          <FormRow label={t.domain}><input value={domain} onChange={(event) => setDomain(event.target.value)} /></FormRow>
          <FormRow label={t.mode}><input value={mode} onChange={(event) => setMode(event.target.value)} /></FormRow>
          <FormRow label={t.maxFiles}><input value={maxFiles} onChange={(event) => setMaxFiles(event.target.value)} /></FormRow>
          <FormRow label={t.maxChunks}><input value={maxChunks} onChange={(event) => setMaxChunks(event.target.value)} /></FormRow>
        </div>
        <div className="toggle-grid">
          <ToggleOption label={t.mergeSameSequence} checked={merge} onChange={setMerge} />
          <ToggleOption label={t.failFast} checked={failFast} onChange={setFailFast} />
          <ToggleOption label={t.qualityGateOption} checked={qualityGate} onChange={setQualityGate} />
          <ToggleOption label={t.runManifest} checked={runManifest} onChange={setRunManifest} />
        </div>
        <CommandPreview title={t.commandPreview} command={command} buttonLabel={t.run} onRun={run} />
      </SectionCard>
      <SectionCard title={t.result}>
        <RunLog title={t.runLog} runState={runState} />
        <FileList title={t.generatedFiles} files={runState.files} />
        <JsonViewer title={t.rawJson} value={{ batch_run_summary: true, failed_items: true, retry_manifest: true }} />
      </SectionCard>
    </div>
  );
}
