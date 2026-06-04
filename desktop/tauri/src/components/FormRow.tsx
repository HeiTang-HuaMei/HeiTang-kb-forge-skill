import type { ReactNode } from "react";
import { Badge } from "./Badge";

type FormRowProps = {
  label: string;
  children: ReactNode;
  variant?: "editable" | "readonly" | "disabled" | "future";
  note?: string;
  t?: (key: string) => string;
};

export function FormRow({ label, children, variant = "editable", note, t }: FormRowProps) {
  return (
    <label className={`form-row form-row-${variant}`}>
      <span>
        {label}
        {variant === "future" && t ? <Badge variant="future" t={t} /> : null}
      </span>
      <div className="form-control">{children}</div>
      {note ? <small>{note}</small> : null}
    </label>
  );
}
