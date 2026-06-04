export type BadgeVariant =
  | "ready"
  | "success"
  | "warning"
  | "failed"
  | "pending"
  | "future"
  | "notChecked"
  | "notLoaded"
  | "notAvailable"
  | "reserved";

type BadgeProps = {
  variant?: BadgeVariant;
  t: (key: string) => string;
};

const statusKeys: Record<BadgeVariant, string> = {
  ready: "status.ready",
  success: "status.success",
  warning: "status.warning",
  failed: "status.failed",
  pending: "status.pending",
  future: "status.future",
  notChecked: "status.notChecked",
  notLoaded: "status.notLoaded",
  notAvailable: "status.notAvailable",
  reserved: "status.reserved"
};

export function Badge({ variant = "pending", t }: BadgeProps) {
  return <span className={`badge badge-${variant}`}>{t(statusKeys[variant])}</span>;
}
