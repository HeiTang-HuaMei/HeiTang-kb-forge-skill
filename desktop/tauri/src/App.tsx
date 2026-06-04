import { useEffect, useMemo, useState } from "react";
import { defaultLocale, messages, type Locale } from "./i18n";
import { pages, type PageId } from "./pages";
import type { RunState } from "./pages/types";
import { Sidebar } from "./components/Sidebar";
import { TopBar } from "./components/TopBar";
import "./styles.css";

const storageKeys = {
  locale: "heitang.locale",
  page: "heitang.page"
};

function App() {
  const [locale, setLocale] = useState<Locale>(() => (localStorage.getItem(storageKeys.locale) as Locale) || defaultLocale);
  const [currentPage, setCurrentPage] = useState<PageId>(() => (localStorage.getItem(storageKeys.page) as PageId) || "dashboard");
  const [runState, setRunState] = useState<RunState>({
    status: "empty",
    log: "",
    files: []
  });
  const t = messages[locale] ?? messages[defaultLocale];
  const Page = useMemo(() => pages[currentPage] ?? pages.dashboard, [currentPage]);

  useEffect(() => {
    localStorage.setItem(storageKeys.locale, locale);
  }, [locale]);

  useEffect(() => {
    localStorage.setItem(storageKeys.page, currentPage);
  }, [currentPage]);

  return (
    <div className="app-shell">
      <Sidebar t={t} currentPage={currentPage} onSelect={setCurrentPage} />
      <div className="main-shell">
        <TopBar t={t} locale={locale} onLocaleChange={setLocale} />
        <Page t={t} runState={runState} setRunState={setRunState} />
      </div>
    </div>
  );
}

export default App;
