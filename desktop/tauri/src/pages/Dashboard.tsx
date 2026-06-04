import { EmptyState } from "../components/EmptyState";
import { JsonViewer } from "../components/JsonViewer";
import { SectionCard } from "../components/SectionCard";
import { StatusCard } from "../components/StatusCard";
import type { PageProps } from "./types";

export function Dashboard({ t, runState }: PageProps) {
  const metrics = [
    [t.currentWorkspace, ".\\workspace"],
    [t.currentPackage, ".\\output_sample"],
    [t.cliStatus, "Ready"],
    [t.recentRunStatus, runState.status],
    [t.packageCount, 0],
    [t.readyCount, 0],
    [t.warningCount, 0],
    [t.highRiskCount, 0],
    [t.sourceCount, 0],
    [t.changedSources, 0],
    [t.newSources, 0],
    [t.missingSources, 0],
    [t.staleChunks, 0],
    [t.lastRefreshCheck, "Not checked"],
    [t.updateAcceptanceStatus, "Not available"]
  ];

  return (
    <div className="page">
      <SectionCard title={t.dashboard} description="Knowledge package operating snapshot.">
        <div className="status-grid">
          {metrics.map(([label, value]) => (
            <StatusCard key={String(label)} label={String(label)} value={String(value)} />
          ))}
        </div>
        <EmptyState message={t.emptyState} />
        <JsonViewer title={t.rawJson} value={{ metrics: Object.fromEntries(metrics) }} />
      </SectionCard>
    </div>
  );
}
