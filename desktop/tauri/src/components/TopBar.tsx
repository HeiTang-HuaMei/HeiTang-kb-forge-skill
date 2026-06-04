import type { Locale, Messages } from "../i18n";

type TopBarProps = {
  t: Messages;
  locale: Locale;
  onLocaleChange: (locale: Locale) => void;
};

export function TopBar({ t, locale, onLocaleChange }: TopBarProps) {
  return (
    <header className="topbar">
      <div>
        <h1>{t.appTitle}</h1>
        <p>{t.appSubtitle}</p>
      </div>
      <select value={locale} onChange={(event) => onLocaleChange(event.target.value as Locale)}>
        <option value="zh-CN">中文</option>
        <option value="en-US">English</option>
      </select>
    </header>
  );
}
