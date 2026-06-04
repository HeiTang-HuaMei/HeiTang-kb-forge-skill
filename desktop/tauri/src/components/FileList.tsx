type FileListProps = {
  title: string;
  files: string[];
};

export function FileList({ title, files }: FileListProps) {
  return (
    <div className="file-list">
      <h3>{title}</h3>
      <ul>
        {(files.length ? files : ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl", "manifest.json", "ingest_report.md", "quality_report.json"]).map((file) => (
          <li key={file}>{file}</li>
        ))}
      </ul>
    </div>
  );
}
