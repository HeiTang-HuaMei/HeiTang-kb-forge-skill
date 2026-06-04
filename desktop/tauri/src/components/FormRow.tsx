import type { ReactNode } from "react";

type FormRowProps = {
  label: string;
  children: ReactNode;
};

export function FormRow({ label, children }: FormRowProps) {
  return (
    <label className="form-row">
      <span>{label}</span>
      {children}
    </label>
  );
}
