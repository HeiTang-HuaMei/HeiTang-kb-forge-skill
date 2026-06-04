import { Dashboard } from "./Dashboard";
import { BuildPackage } from "./BuildPackage";
import { BatchProcessing } from "./BatchProcessing";
import { Workspace } from "./Workspace";
import { LifecycleUpdate } from "./LifecycleUpdate";
import { QualityGate } from "./QualityGate";
import { PackageDetail } from "./PackageDetail";
import { AskRuntime } from "./AskRuntime";
import { PublishExport } from "./PublishExport";
import { PlanningReadiness } from "./PlanningReadiness";
import { Settings } from "./Settings";

export type PageId =
  | "dashboard"
  | "buildPackage"
  | "batchProcessing"
  | "workspace"
  | "lifecycleUpdate"
  | "qualityGate"
  | "packageDetail"
  | "askRuntime"
  | "publishExport"
  | "planningReadiness"
  | "settings";

export const pages = {
  dashboard: Dashboard,
  buildPackage: BuildPackage,
  batchProcessing: BatchProcessing,
  workspace: Workspace,
  lifecycleUpdate: LifecycleUpdate,
  qualityGate: QualityGate,
  packageDetail: PackageDetail,
  askRuntime: AskRuntime,
  publishExport: PublishExport,
  planningReadiness: PlanningReadiness,
  settings: Settings
};
