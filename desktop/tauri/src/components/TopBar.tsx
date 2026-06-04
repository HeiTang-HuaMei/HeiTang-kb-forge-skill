import type { Locale } from "../i18n";

type TopBarProps = {
  t: (key: string) => string;
  locale: Locale;
  setLocale: (locale: Locale) => void;
};

export function TopBar({ t, locale, setLocale }: TopBarProps) {
  return (
    <header className="topbar">
      <div>
        <h1>{t("app.title")}</h1>
        <p>{t("app.subtitle")}</p>
      </div>
      <select value={locale} onChange={(event) => setLocale(event.target.value as Locale)}>
        <option value="zh-CN">中文</option>
        <option value="en-US">English</option>
      </select>
    </header>
  );
}
