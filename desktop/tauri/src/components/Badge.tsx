import type { ReactNode } from "react";

type BadgeProps = {
  tone?: "neutral" | "success" | "warning" | "error";
  children: ReactNode;
};

export function Badge({ tone = "neutral", children }: BadgeProps) {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}
