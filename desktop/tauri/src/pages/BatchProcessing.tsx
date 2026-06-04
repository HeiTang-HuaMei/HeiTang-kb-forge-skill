import { useMemo, useState } from "react";
import { runKbForge } from "../api";
import { CommandPreview } from "../components/CommandPreview";
import { FileList } from "../components/FileList";
import { FormRow } from "../components/FormRow";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { RunLog } from "../components/RunLog";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import { ToggleOption } from "../components/ToggleOption";
import type { PageProps } from "./types";

export function BatchProcessing({ t, runState, setRunState, setAppState }: PageProps) {
  const [input, setInput] = useState(".\\input");
  const [output, setOutput] = useState(".\\output");
  const [domain, setDomain] = useState("education");
  const [mode, setMode] = useState("teaching");
  const [merge, setMerge] = useState(false);
  const [continueOnError, setContinueOnError] = useState(true);
  const [failFast, setFailFast] = useState(false);
  const [qualityGate, setQualityGate] = useState(false);
  const [runManifest, setRunManifest] = useState(false);
  const [maxFiles, setMaxFiles] = useState("");
  const [maxChunks, setMaxChunks] = useState("");
  const command = useMemo(() => {
    const flags = [
      continueOnError ? "--continue-on-error" : "--no-continue-on-error",
      merge ? "--merge-same-sequence" : "",
      failFast ? "--fail-fast" : "",
      qualityGate ? "--quality-gate" : "",
      runManifest ? "--run-manifest" : "",
      maxFiles ? `--max-files ${maxFiles}` : "",
      maxChunks ? `--max-chunks ${maxChunks}` : ""
    ].filter(Boolean);
    return `heitang-kb-forge batch --input ${input} --output ${output} --domain ${domain} --mode ${mode} ${flags.join(" ")}`;
  }, [continueOnError, domain, failFast, input, maxChunks, maxFiles, merge, mode, output, qualityGate, runManifest]);

  async function run() {
    const started = performance.now();
    setRunState({ status: "running", stdout: "", stderr: "", files: [] });
    try {
      const stdout = await runKbForge({ workflow: "batch", inputPath: input, outputPath: output, domain, mode });
      setAppState((state) => ({ ...state, lastRunStatus: "success" }));
      setRunState({ status: "success", stdout, stderr: "", durationMs: Math.round(performance.now() - started), files: ["batch_run_summary.json", "failed_items.jsonl", "retry_manifest.json", "batch_run_report.md"] });
    } catch (error) {
      setAppState((state) => ({ ...state, lastRunStatus: "failed" }));
      setRunState({ status: "failed", stdout: "", stderr: String(error), durationMs: Math.round(performance.now() - started), files: [] });
    }
  }

  return (
    <div className="page">
      <SectionCard title={t("page.batch.title")} description={t("page.batch.description")}>
        <h3>{t("section.basicInput")}</h3>
        <div className="form-grid">
          <PathInput label={t("field.inputPath")} value={input} onChange={setInput} t={t} />
          <PathInput label={t("field.outputPath")} value={output} onChange={setOutput} t={t} />
          <FormRow label={t("field.domain")}><input value={domain} onChange={(event) => setDomain(event.target.value)} /></FormRow>
          <FormRow label={t("field.mode")}><input value={mode} onChange={(event) => setMode(event.target.value)} /></FormRow>
        </div>
        <h3>Batch Control</h3>
        <div className="form-grid">
          <FormRow label="max-files"><input value={maxFiles} onChange={(event) => setMaxFiles(event.target.value)} /></FormRow>
          <FormRow label="max-chunks"><input value={maxChunks} onChange={(event) => setMaxChunks(event.target.value)} /></FormRow>
        </div>
        <div className="toggle-grid">
          <ToggleOption label="merge-same-sequence" checked={merge} onChange={setMerge} />
          <ToggleOption label="continue-on-error" checked={continueOnError} onChange={setContinueOnError} />
          <ToggleOption label="fail-fast" checked={failFast} onChange={setFailFast} />
          <ToggleOption label="Quality Gate" checked={qualityGate} onChange={setQualityGate} />
          <ToggleOption label="Run Manifest" checked={runManifest} onChange={setRunManifest} />
        </div>
        <CommandPreview command={command} t={t} buttonLabel={t("action.batchRun")} onRun={run} failed={runState.status === "failed"} />
      </SectionCard>
      <SectionCard title={t("section.resultSummary")}>
        <div className="status-grid">
          <StatusCard label="total_files" value="-" />
          <StatusCard label="succeeded" value="-" />
          <StatusCard label="failed" value="-" />
          <StatusCard label="warnings" value="-" />
        </div>
        <RunLog runState={runState} t={t} />
        <FileList title={t("section.generatedFiles")} files={["batch_run_summary.json", "failed_items.jsonl", "retry_manifest.json", "batch_run_report.md"]} />
        <JsonViewer title={t("section.rawJson")} value={{ retry_manifest: "pending" }} />
      </SectionCard>
    </div>
  );
}
