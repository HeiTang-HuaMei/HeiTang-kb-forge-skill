import { FormRow } from "./FormRow";

type PathInputProps = {
  label: string;
  value: string;
  onChange?: (value: string) => void;
  placeholder?: string;
  readonly?: boolean;
  validationMessage?: string;
  t: (key: string) => string;
};

export function PathInput({ label, value, onChange, placeholder, readonly = false, validationMessage, t }: PathInputProps) {
  return (
    <FormRow label={label} variant={readonly ? "readonly" : "editable"} note={validationMessage}>
      <div className="path-input">
        <input
          value={value}
          placeholder={placeholder}
          readOnly={readonly}
          onChange={(event) => onChange?.(event.target.value)}
        />
        <button disabled title={t("path.browseDisabled")}>{t("action.browse")}</button>
        <button type="button" onClick={() => navigator.clipboard?.writeText(value)}>{t("action.copy")}</button>
        {!readonly ? <button type="button" onClick={() => onChange?.("")}>{t("action.clear")}</button> : null}
      </div>
    </FormRow>
  );
}
