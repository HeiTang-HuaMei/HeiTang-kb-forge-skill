import { FormRow } from "./FormRow";

type PathInputProps = {
  label: string;
  value: string;
  onChange: (value: string) => void;
};

export function PathInput({ label, value, onChange }: PathInputProps) {
  return (
    <FormRow label={label}>
      <input value={value} onChange={(event) => onChange(event.target.value)} />
    </FormRow>
  );
}
