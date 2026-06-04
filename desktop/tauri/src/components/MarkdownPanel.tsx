type MarkdownPanelProps = {
  title: string;
  content: string;
};

export function MarkdownPanel({ title, content }: MarkdownPanelProps) {
  return (
    <details className="raw-panel">
      <summary>{title}</summary>
      <pre>{content}</pre>
    </details>
  );
}
