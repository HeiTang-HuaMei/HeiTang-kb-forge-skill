export const MOCK_DATA_BASE_PATH = "../../examples/ui_mock_data";

export const MOCK_DATA_FILES = {
  knowledgeBases: "knowledge_bases.json",
  agents: "agents.json",
  workflows: "workflows.json",
  memoryScopes: "memory_scopes.json",
  jobs: "jobs.json",
  reviewQueue: "review_queue.json",
  generatedDocs: "generated_docs.json",
  providerStatus: "provider_status.json",
  parserBackendStatus: "parser_backend_status.json",
  answerPolicies: "answer_policies.json",
  p1Contracts: "p1_core_contract_fixture.json",
  p1RealWorkflowV1: "p1_real_workflow_v1_evidence.json",
  p1RealWorkflowV2: "p1_real_workflow_v2_evidence.json",
  p1RealWorkflowV2Matrix: "p1_real_workflow_v2/full_ready_action_execution_matrix.json",
  p1RealWorkflowV2ActionResults: "p1_real_workflow_v2/action_execution_result_index.json",
  p1RealWorkflowV2ArtifactAssertions: "p1_real_workflow_v2/action_artifact_assertion_report.json",
  p1RealWorkflowV2ReportAssertions: "p1_real_workflow_v2/action_report_assertion_report.json",
  p1RealWorkflowV2ErrorBoundary: "p1_real_workflow_v2/action_error_boundary_report.json",
  p1RealWorkflowV2UserPaths: "p1_real_workflow_v2/full_local_user_path_closure_report.json",
  p1RealWorkflowV2GateReport: "p1_real_workflow_v2/p1_real_workflow_v2_report.json",
  p1RealWorkflowV2RemainingBlockers: "p1_real_workflow_v2/remaining_blockers.json"
};

async function loadJson(fileName) {
  const response = await fetch(`${MOCK_DATA_BASE_PATH}/${fileName}`);
  if (!response.ok) {
    throw new Error(`Unable to load mock data: ${fileName}`);
  }
  return response.json();
}

export async function loadWorkbenchData() {
  const entries = await Promise.all(
    Object.entries(MOCK_DATA_FILES).map(async ([key, fileName]) => [key, await loadJson(fileName)])
  );

  return buildWorkbenchViewModel(Object.fromEntries(entries));
}

export function buildWorkbenchViewModel(raw) {
  const knowledgeBases = raw.knowledgeBases.knowledge_bases;
  const agents = raw.agents.agents;
  const workflows = raw.workflows.workflows;
  const memoryScopes = raw.memoryScopes.memory_scopes;
  const jobs = raw.jobs.jobs;
  const reviewItems = raw.reviewQueue.review_items;
  const generatedDocs = raw.generatedDocs.generated_docs;
  const exportItems = raw.generatedDocs.export_items;
  const providers = raw.providerStatus.providers;
  const parserBackends = raw.parserBackendStatus.parser_backends;
  const answerPolicies = raw.answerPolicies.answer_policies;
  const memoryPolicies = raw.answerPolicies.memory_policies;
  const p1Contracts = raw.p1Contracts;
  const p1RealWorkflowV1 = raw.p1RealWorkflowV1;
  const p1RealWorkflowV2 = raw.p1RealWorkflowV2;
  const p1RealWorkflowV2Reports = {
    matrix: raw.p1RealWorkflowV2Matrix,
    actionResults: raw.p1RealWorkflowV2ActionResults,
    artifactAssertions: raw.p1RealWorkflowV2ArtifactAssertions,
    reportAssertions: raw.p1RealWorkflowV2ReportAssertions,
    errorBoundary: raw.p1RealWorkflowV2ErrorBoundary,
    userPaths: raw.p1RealWorkflowV2UserPaths,
    gateReport: raw.p1RealWorkflowV2GateReport,
    remainingBlockers: raw.p1RealWorkflowV2RemainingBlockers
  };

  return {
    p1Contracts,
    p1RealWorkflowV1,
    p1RealWorkflowV2,
    p1RealWorkflowV2Reports,
    knowledgeBases,
    agents,
    workflows,
    memoryScopes,
    jobs,
    reviewItems,
    generatedDocs,
    exportItems,
    providers,
    parserBackends,
    answerPolicies,
    memoryPolicies,
    metrics: {
      knowledgeBases: knowledgeBases.length,
      trustedKnowledgeBases: knowledgeBases.filter((kb) => kb.status === "trusted").length,
      draftKnowledgeBases: knowledgeBases.filter((kb) => kb.status === "draft").length,
      agents: agents.length,
      runningJobs: jobs.filter((job) => job.status === "running").length,
      reviewRisks: reviewItems.filter((item) => item.risk !== "low").length,
      exports: exportItems.length
    }
  };
}
