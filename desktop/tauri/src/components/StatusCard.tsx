type StatusCardProps = {
  label: string;
  value: string | number;
  tone?: "neutral" | "success" | "warning" | "error";
};

export function StatusCard({ label, value, tone = "neutral" }: StatusCardProps) {
  return (
    <div className={`status-card status-${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
