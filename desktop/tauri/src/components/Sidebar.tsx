import type { PageId } from "../pages";
import catHead from "../assets/icons/cat-head.png";

type SidebarProps = {
  t: (key: string) => string;
  currentPage: PageId;
  onSelect: (page: PageId) => void;
};

export const navItems = [
  ["dashboard", "nav.dashboard"],
  ["buildPackage", "nav.build"],
  ["batchProcessing", "nav.batch"],
  ["workspace", "nav.workspace"],
  ["lifecycleUpdate", "nav.lifecycle"],
  ["qualityGate", "nav.quality"],
  ["packageDetail", "nav.packageDetail"],
  ["askRuntime", "nav.ask"],
  ["publishExport", "nav.publish"],
  ["planningReadiness", "nav.planning"],
  ["settings", "nav.settings"]
] as const;

export function Sidebar({ t, currentPage, onSelect }: SidebarProps) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <img src={catHead} alt="cat small icon" />
        <div>
          <strong>HeiTang</strong>
          <span>{t("brand.shell")}</span>
        </div>
      </div>
      <nav>
        {navItems.map(([id, labelKey]) => (
          <button key={id} className={currentPage === id ? "active" : ""} onClick={() => onSelect(id)}>
            {t(labelKey)}
          </button>
        ))}
      </nav>
    </aside>
  );
}
