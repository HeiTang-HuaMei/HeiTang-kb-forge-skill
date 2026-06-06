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
  answerPolicies: "answer_policies.json"
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

  return {
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
