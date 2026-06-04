import { useEffect, useMemo, useState } from "react";
import { defaultLocale, translate, type Locale } from "./i18n";
import { pages, type PageId } from "./pages";
import type { AppState, RunState } from "./pages/types";
import { Sidebar } from "./components/Sidebar";
import { TopBar } from "./components/TopBar";
import "./styles.css";

const storageKeys = {
  appState: "heitang.appState",
  page: "heitang.page"
};

const initialAppState: AppState = {
  locale: defaultLocale,
  theme: "dark",
  currentWorkspace: ".\\workspace",
  currentPackage: ".\\output_sample",
  cliStatus: "ready",
  lastRunStatus: "empty"
};

function loadAppState(): AppState {
  try {
    return { ...initialAppState, ...JSON.parse(localStorage.getItem(storageKeys.appState) || "{}") };
  } catch {
    return initialAppState;
  }
}

function App() {
  const [appState, setAppState] = useState<AppState>(loadAppState);
  const [currentPage, setCurrentPage] = useState<PageId>(() => (localStorage.getItem(storageKeys.page) as PageId) || "dashboard");
  const [runState, setRunState] = useState<RunState>({
    status: "empty",
    stdout: "",
    stderr: "",
    files: []
  });
  const t = useMemo(() => (key: string) => translate(appState.locale, key), [appState.locale]);
  const Page = useMemo(() => pages[currentPage] ?? pages.dashboard, [currentPage]);

  useEffect(() => {
    localStorage.setItem(storageKeys.appState, JSON.stringify(appState));
  }, [appState]);

  useEffect(() => {
    localStorage.setItem(storageKeys.page, currentPage);
  }, [currentPage]);

  function setLocale(locale: Locale) {
    setAppState((state) => ({ ...state, locale }));
  }

  return (
    <div className="app-shell">
      <Sidebar t={t} currentPage={currentPage} onSelect={setCurrentPage} />
      <div className="main-shell">
        <TopBar t={t} locale={appState.locale} setLocale={setLocale} />
        <Page
          t={t}
          locale={appState.locale}
          appState={appState}
          setAppState={setAppState}
          runState={runState}
          setRunState={setRunState}
        />
      </div>
    </div>
  );
}

export default App;
