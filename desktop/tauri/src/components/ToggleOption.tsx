type ToggleOptionProps = {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
};

export function ToggleOption({ label, checked, onChange }: ToggleOptionProps) {
  return (
    <label className="toggle-option">
      <input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} />
      <span>{label}</span>
    </label>
  );
}
