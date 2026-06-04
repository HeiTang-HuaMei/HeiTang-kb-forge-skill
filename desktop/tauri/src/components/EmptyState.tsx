type EmptyStateProps = {
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
};

export function EmptyState({ title, description, actionLabel, onAction }: EmptyStateProps) {
  return (
    <div className="empty-state">
      <strong>{title}</strong>
      <p>{description}</p>
      {actionLabel && onAction ? <button onClick={onAction}>{actionLabel}</button> : null}
    </div>
  );
}
