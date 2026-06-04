type CommandPreviewProps = {
  command: string;
  t: (key: string) => string;
  buttonLabel?: string;
  onRun?: () => void;
  failed?: boolean;
};

export function CommandPreview({ command, t, buttonLabel, onRun, failed = false }: CommandPreviewProps) {
  return (
    <details className={`command-preview ${failed ? "command-preview-failed" : ""}`} open>
      <summary>{t("section.rawLog")} · {t("action.copyCommand")}</summary>
      <code>{command}</code>
      <div className="button-row compact">
        <button type="button" onClick={() => navigator.clipboard?.writeText(command)}>{t("action.copyCommand")}</button>
        {onRun && buttonLabel ? <button onClick={onRun}>{buttonLabel}</button> : null}
      </div>
    </details>
  );
}
