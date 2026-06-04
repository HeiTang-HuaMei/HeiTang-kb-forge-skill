import { Badge } from "../components/Badge";
import { EmptyState } from "../components/EmptyState";
import { JsonViewer } from "../components/JsonViewer";
import { PathInput } from "../components/PathInput";
import { SectionCard } from "../components/SectionCard";
import type { PageProps } from "./types";

export function Workspace({ t }: PageProps) {
  const rows = [
    ["demo_product_manager_agent", ".\\examples\\demo_product_manager_agent\\output_sample", "education", "product_manager_agent", "ready", "90", "low", "-"],
    ["demo_shopping_guide_agent", ".\\examples\\demo_shopping_guide_agent\\output_sample", "commerce", "shopping_guide_agent", "warning", "78", "medium", "-"]
  ];

  return (
    <div className="page">
      <SectionCard title={t.workspace} description="Manage local workspace registry and package status.">
        <div className="form-grid">
          <PathInput label="workspace path" value=".\\workspace" onChange={() => undefined} />
          <PathInput label="package path" value=".\\output_sample" onChange={() => undefined} />
        </div>
        <div className="button-row">
          <button>初始化工作区</button>
          <button>注册知识包</button>
          <button>刷新列表</button>
        </div>
        <table>
          <thead>
            <tr><th>知识包名称</th><th>路径</th><th>领域</th><th>Agent 类型</th><th>Readiness</th><th>Quality Score</th><th>Risk</th><th>更新时间</th><th>状态</th></tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row[0]}>{row.map((cell, index) => <td key={cell + index}>{index === 8 ? <Badge tone="neutral">idle</Badge> : cell}</td>)}</tr>
            ))}
          </tbody>
        </table>
        <EmptyState message={t.emptyState} />
        <JsonViewer title={t.rawJson} value={{ package_registry: rows }} />
      </SectionCard>
    </div>
  );
}
