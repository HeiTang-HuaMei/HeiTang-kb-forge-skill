import type { Messages } from "../i18n";
import type { PageId } from "../pages";
import catHead from "../assets/icons/cat-head.png";

type SidebarProps = {
  t: Messages;
  currentPage: PageId;
  onSelect: (page: PageId) => void;
};

export const navItems = [
  ["dashboard", "dashboard"],
  ["buildPackage", "buildPackage"],
  ["batchProcessing", "batchProcessing"],
  ["workspace", "workspace"],
  ["lifecycleUpdate", "lifecycleUpdate"],
  ["qualityGate", "qualityGate"],
  ["packageDetail", "packageDetail"],
  ["askRuntime", "askRuntime"],
  ["publishExport", "publishExport"],
  ["planningReadiness", "planningReadiness"],
  ["settings", "settings"]
] as const;

export function Sidebar({ t, currentPage, onSelect }: SidebarProps) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <img src={catHead} alt="cat icon" />
        <div>
          <strong>HeiTang</strong>
          <span>KB Forge</span>
        </div>
      </div>
      <nav>
        {navItems.map(([id, label]) => (
          <button key={id} className={currentPage === id ? "active" : ""} onClick={() => onSelect(id)}>
            {t[label]}
          </button>
        ))}
      </nav>
    </aside>
  );
}
