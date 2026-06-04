type CommandPreviewProps = {
  title: string;
  command: string;
  buttonLabel?: string;
  onRun?: () => void;
};

export function CommandPreview({ title, command, buttonLabel, onRun }: CommandPreviewProps) {
  return (
    <div className="command-preview">
      <h3>{title}</h3>
      <code>{command}</code>
      {onRun && buttonLabel ? <button onClick={onRun}>{buttonLabel}</button> : null}
    </div>
  );
}
