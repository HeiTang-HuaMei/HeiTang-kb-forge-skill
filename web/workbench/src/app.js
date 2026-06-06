import { defaultLocale, messages, t } from "./i18n.js";
import { loadWorkbenchData } from "./mockService.js";

export const PAGES = [
  { id: "dashboard", label: "Dashboard", label_zh: "仪表盘", description: "Operating snapshot across knowledge, review, jobs, agents, and exports.", description_zh: "知识、复核、任务、Agent 与导出的运营总览。" },
  { id: "file-upload", label: "File upload", label_zh: "文件上传", description: "Mock upload intake with parser readiness and reserved ingestion controls.", description_zh: "模拟上传入口，展示解析器状态与预留导入控制。" },
  { id: "job-progress", label: "Job progress", label_zh: "任务进度", description: "Track mock ingestion, review, and export jobs with stage-level status.", description_zh: "跟踪模拟导入、复核和导出任务的阶段状态。" },
  { id: "knowledge-base-list", label: "Knowledge base list", label_zh: "知识库列表", description: "Browse trusted and draft knowledge bases with bound agents and policy state.", description_zh: "浏览可信与草稿知识库，以及绑定 Agent 和策略状态。" },
  { id: "knowledge-base-detail", label: "Knowledge base detail", label_zh: "知识库详情", description: "Inspect one knowledge base contract, chunk state, and future API fields.", description_zh: "查看单个知识库契约、分片状态和未来 API 字段。" },
  { id: "review-queue", label: "Review queue", label_zh: "复核队列", description: "Prioritize risky chunks and route corrected text through a mock review flow.", description_zh: "按风险处理分片，并通过模拟复核流转校正文稿。" },
  { id: "corrected-text-editor", label: "Corrected text editor", label_zh: "校正文稿编辑器", description: "Edit mock corrected text without writing to any backend runtime.", description_zh: "编辑模拟校正文稿，不写入任何后端运行时。" },
  { id: "kb-query", label: "KB query", label_zh: "知识库查询", description: "Ask a mock grounded query and preview citation-first answer behavior.", description_zh: "发起模拟证据查询，预览引用优先的回答行为。" },
  { id: "document-generation", label: "Document generation", label_zh: "文档生成", description: "Preview generated document drafts and citation readiness.", description_zh: "预览生成文档草稿与引用就绪状态。" },
  { id: "agent-skill-management", label: "Agent / Skill management", label_zh: "Agent / Skill 管理", description: "Manage mock agents, skill tools, model providers, and KB bindings.", description_zh: "管理模拟 Agent、Skill 工具、模型供应商与知识库绑定。" },
  { id: "multi-agent-workflow", label: "Multi-agent workflow", label_zh: "多 Agent 工作流", description: "Visualize workflow steps, shared memory, and handoff trace.", description_zh: "展示工作流步骤、共享记忆与交接链路。" },
  { id: "memory-scope-viewer", label: "Memory scope viewer", label_zh: "记忆范围查看器", description: "Inspect private agent memory and workflow-shared memory isolation.", description_zh: "查看 Agent 私有记忆与工作流共享记忆隔离。" },
  { id: "settings", label: "Settings", label_zh: "设置", description: "Configure mock providers, parser backend, answer policy, and memory policy.", description_zh: "配置模拟供应商、解析后端、回答策略与记忆策略。" },
  { id: "export-center", label: "Export center", label_zh: "导出中心", description: "Review mock export items reserved for future package delivery.", description_zh: "查看为未来包交付预留的模拟导出项。" }
];

const state = {
  locale: defaultLocale,
  theme: "light",
  activePage: "dashboard",
  data: null
};

const appRoot = document.querySelector("#app-root");
const navList = document.querySelector("#nav-list");
const mobilePageSelect = document.querySelector("#mobile-page-select");
const themeToggle = document.querySelector("#theme-toggle");

function labelFor(item) {
  return state.locale === "zh-CN" ? item.label_zh ?? item.label : item.label;
}

function descriptionFor(item) {
  return state.locale === "zh-CN" ? item.description_zh ?? item.description : item.description;
}

function byId(collection, id) {
  return collection.find((item) => item.id === id);
}

function statusPill(value) {
  return `<span class="status-pill" data-status="${value}">${value}</span>`;
}

function riskPill(value) {
  return `<span class="risk-pill" data-risk="${value}">${value}</span>`;
}

function tags(values) {
  return values.map((value) => `<span class="tag">${value}</span>`).join("");
}

function renderShellText() {
  document.documentElement.lang = state.locale;
  document.querySelectorAll("[data-i18n]").forEach((node) => {
    node.textContent = t(state.locale, node.dataset.i18n);
  });
  document.body.dataset.theme = state.theme;
  document.querySelectorAll("[data-locale]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.locale === state.locale);
  });
}

function renderNav() {
  navList.innerHTML = PAGES.map((page) => {
    const active = page.id === state.activePage ? " is-active" : "";
    return `<button class="nav-button${active}" type="button" data-page="${page.id}">${labelFor(page)}</button>`;
  }).join("");

  mobilePageSelect.innerHTML = PAGES.map((page) => {
    const selected = page.id === state.activePage ? " selected" : "";
    return `<option value="${page.id}"${selected}>${labelFor(page)}</option>`;
  }).join("");
}

function pageHeader(page) {
  return `
    <section class="page-header">
      <h2 class="page-title">${labelFor(page)}</h2>
      <p class="page-description">${descriptionFor(page)}</p>
    </section>
  `;
}

function metricCard(label, value) {
  return `
    <article class="metric-card span-3">
      <p class="metric-value">${value}</p>
      <p class="metric-label">${label}</p>
    </article>
  `;
}

function card(title, body, span = "span-4", subtitle = "") {
  return `
    <article class="card ${span}">
      <div class="card-header">
        <div>
          <h3 class="card-title">${title}</h3>
          ${subtitle ? `<p class="card-subtitle">${subtitle}</p>` : ""}
        </div>
      </div>
      ${body}
    </article>
  `;
}

function renderDashboard(data) {
  const recentJob = data.jobs[0];
  return `
    <section class="grid">
      ${metricCard(label("Knowledge bases", "知识库"), data.metrics.knowledgeBases)}
      ${metricCard(label("Trusted", "可信库"), data.metrics.trustedKnowledgeBases)}
      ${metricCard(label("Agents", "Agent"), data.metrics.agents)}
      ${metricCard(label("Review risks", "复核风险"), data.metrics.reviewRisks)}
      ${card(label("Current job", "当前任务"), `
        <p>${recentJobLabel(recentJob)}</p>
        <div class="progress-track"><div class="progress-fill" style="width: ${recentJob.progress}%"></div></div>
        <p class="muted">${recentJob.progress}% · ${recentJob.status}</p>
      `, "span-6")}
      ${card(label("Provider status", "供应商状态"), providerList(data.providers), "span-6")}
    </section>
  `;
}

function renderFileUpload(data) {
  return `
    <section class="grid">
      <div class="dropzone span-8">
        <div>
          <h3>${label("Drop files here", "拖放文件到此处")}</h3>
          <p class="muted">${label("Mock intake only. Parser and KB publish actions are reserved for Core integration.", "仅模拟入口。解析器与知识库发布动作预留给 Core 集成。")}</p>
          <button class="primary-button" type="button">${label("Select mock files", "选择模拟文件")}</button>
        </div>
      </div>
      ${card(label("Parser readiness", "解析器就绪状态"), parserList(data.parserBackends), "span-4")}
    </section>
  `;
}

function renderJobProgress(data) {
  return `<section class="grid">${data.jobs.map((job) => card(recentJobLabel(job), jobProgress(job), "span-4", `${job.type} · ${job.kb_id}`)).join("")}</section>`;
}

function renderKnowledgeBaseList(data) {
  return `<section class="grid">${data.knowledgeBases.map((kb) => kbCard(kb, data.agents)).join("")}</section>`;
}

function renderKnowledgeBaseDetail(data) {
  const kb = data.knowledgeBases[0];
  return `
    <section class="grid">
      ${card(displayName(kb), `
        <div class="status-row">${statusPill(kb.status)} ${tags([kb.answer_policy, kb.parser_backend])}</div>
        <p>${displayDescription(kb)}</p>
        <ul class="soft-list">
          <li>${label("Documents", "文档数")}: ${kb.documents}</li>
          <li>${label("Chunks", "分片数")}: ${kb.chunks}</li>
          <li>${label("Trusted chunks", "可信分片")}: ${kb.trusted_chunks}</li>
          <li>${label("Draft chunks", "草稿分片")}: ${kb.draft_chunks}</li>
        </ul>
      `, "span-8", kb.owner)}
      ${card(label("Bound agents", "绑定 Agent"), boundAgents(kb, data.agents), "span-4")}
    </section>
  `;
}

function renderReviewQueue(data) {
  return `
    <section class="grid">
      <article class="card span-12">
        <table class="table">
          <thead><tr><th>${label("Risk", "风险")}</th><th>${label("Source", "来源")}</th><th>${label("Reason", "原因")}</th><th>${label("Status", "状态")}</th></tr></thead>
          <tbody>${data.reviewItems.map((item) => `
            <tr>
              <td>${riskPill(item.risk)}</td>
              <td>${item.source}<div class="table-meta">${item.kb_id}</div></td>
              <td>${state.locale === "zh-CN" ? item.reason_zh : item.reason}</td>
              <td>${statusPill(item.status)}</td>
            </tr>
          `).join("")}</tbody>
        </table>
      </article>
    </section>
  `;
}

function renderCorrectedTextEditor(data) {
  const item = data.reviewItems[0];
  return `
    <section class="grid">
      <article class="editor-pane span-8">
        <div class="card-header">
          <div>
            <h3 class="card-title">${item.source}</h3>
            <p class="card-subtitle">${state.locale === "zh-CN" ? item.reason_zh : item.reason}</p>
          </div>
          ${riskPill(item.risk)}
        </div>
        <textarea aria-label="Corrected text">${item.corrected_text}</textarea>
        <div class="form-row">
          <button class="primary-button" type="button">${t(state.locale, "common.saveDraft")}</button>
          <button class="ghost-button" type="button">${t(state.locale, "common.review")}</button>
        </div>
      </article>
      ${card(label("Review contract", "复核契约"), `<p>${label("This editor writes to mock state only. Future Core integration should replace the service call, not the editor surface.", "此编辑器仅写入模拟状态。未来 Core 集成应替换服务调用，而不是重写编辑界面。")}</p>`, "span-4")}
    </section>
  `;
}

function renderKbQuery(data) {
  const kb = data.knowledgeBases[0];
  return `
    <section class="grid">
      <article class="card span-8">
        <div class="form-row">
          <input aria-label="KB query" value="${label("What changed in the launch process?", "发布流程有哪些变化？")}" />
          <button class="primary-button" type="button">${label("Ask", "查询")}</button>
        </div>
        <p>${label("Mock grounded answer: the launch brief must cite accepted product operations evidence and abstain when citations are missing.", "模拟证据回答：发布简报必须引用已接受的产品运营证据；缺少引用时拒答。")}</p>
        <div class="status-row">${tags(["citation: launch_notes_q2.md", "citation: ops_handbook.md"])}</div>
      </article>
      ${card(label("Selected KB", "选定知识库"), `<p>${displayName(kb)}</p>${statusPill(kb.status)}`, "span-4")}
    </section>
  `;
}

function renderDocumentGeneration(data) {
  return `<section class="grid">${data.generatedDocs.map((doc) => card(localized(doc, "title"), `
    <div class="status-row">${statusPill(doc.status)} ${tags([doc.type, doc.kb_id])}</div>
    <p class="muted">${label("Citations", "引用数")}: ${doc.citations}</p>
    <button class="ghost-button" type="button">${label("Preview", "预览")}</button>
  `, "span-6", doc.agent_id)).join("")}</section>`;
}

function renderAgentSkillManagement(data) {
  return `<section class="grid">${data.agents.map((agent) => card(localized(agent, "name"), `
    <div class="status-row">${statusPill(agent.status)} ${tags(agent.tools)}</div>
    <p class="muted">${agent.provider} · ${agent.model}</p>
    <p>${label("Bound KBs", "绑定知识库")}: ${agent.bound_kbs.join(", ")}</p>
    <p>${label("Private memory", "私有记忆")}: ${agent.private_memory_scope}</p>
  `, "span-6", agent.answer_policy)).join("")}</section>`;
}

function renderMultiAgentWorkflow(data) {
  return `<section class="grid">${data.workflows.map((workflow) => card(localized(workflow, "name"), `
    <div class="status-row">${statusPill(workflow.status)} ${tags([workflow.shared_memory_scope])}</div>
    <ul class="soft-list">
      ${workflow.steps.map((step) => `<li>${localized(step, "label")} · ${step.agent} · ${statusPill(step.status)}</li>`).join("")}
    </ul>
    <h4>${label("Handoff trace", "交接链路")}</h4>
    <ul class="soft-list">
      ${workflow.handoff_trace.map((trace) => `<li>${trace.from} → ${trace.to} · ${trace.artifact} · ${trace.status}</li>`).join("")}
    </ul>
  `, "span-6")).join("")}</section>`;
}

function renderMemoryScopeViewer(data) {
  return `<section class="grid">${data.memoryScopes.map((scope) => card(scope.id, `
    <div class="status-row">${tags([scope.type, scope.isolation])}</div>
    <p>${scope.summary}</p>
    <p class="muted">${label("Owner", "所有者")}: ${scope.owner} · ${label("Records", "记录")}: ${scope.records}</p>
  `, "span-4")).join("")}</section>`;
}

function renderSettings(data) {
  return `
    <section class="grid">
      ${card(label("Model providers", "模型供应商"), providerList(data.providers), "span-6")}
      ${card(label("Parser backends", "解析后端"), parserList(data.parserBackends), "span-6")}
      ${card(label("Answer policy", "回答策略"), policyList(data.answerPolicies), "span-6")}
      ${card(label("Memory policy", "记忆策略"), policyList(data.memoryPolicies), "span-6")}
    </section>
  `;
}

function renderExportCenter(data) {
  return `<section class="grid">${data.exportItems.map((item) => card(localized(item, "name"), `
    <div class="status-row">${statusPill(item.status)} ${tags([item.format, ...item.includes])}</div>
    <p class="muted">${item.created_at}</p>
    <button class="primary-button" type="button">${t(state.locale, "common.export")}</button>
  `, "span-6")).join("")}</section>`;
}

function renderPage() {
  const page = byId(PAGES, state.activePage) ?? PAGES[0];
  const data = state.data;
  const renderers = {
    dashboard: renderDashboard,
    "file-upload": renderFileUpload,
    "job-progress": renderJobProgress,
    "knowledge-base-list": renderKnowledgeBaseList,
    "knowledge-base-detail": renderKnowledgeBaseDetail,
    "review-queue": renderReviewQueue,
    "corrected-text-editor": renderCorrectedTextEditor,
    "kb-query": renderKbQuery,
    "document-generation": renderDocumentGeneration,
    "agent-skill-management": renderAgentSkillManagement,
    "multi-agent-workflow": renderMultiAgentWorkflow,
    "memory-scope-viewer": renderMemoryScopeViewer,
    settings: renderSettings,
    "export-center": renderExportCenter
  };

  appRoot.innerHTML = `<div class="page">${pageHeader(page)}${renderers[page.id](data)}</div>`;
  appRoot.focus({ preventScroll: true });
}

function providerList(providers) {
  return `<ul class="soft-list">${providers.map((provider) => `<li><strong>${provider.name}</strong> ${statusPill(provider.status)}<div class="muted">${provider.models.join(", ")}</div></li>`).join("")}</ul>`;
}

function parserList(backends) {
  return `<ul class="soft-list">${backends.map((backend) => `<li><strong>${backend.name}</strong> ${statusPill(backend.status)}<div class="muted">${backend.supports.join(", ")}</div></li>`).join("")}</ul>`;
}

function policyList(policies) {
  return `<ul class="soft-list">${policies.map((policy) => `<li><strong>${localized(policy, "label")}</strong><div class="muted">${policy.description}</div></li>`).join("")}</ul>`;
}

function jobProgress(job) {
  return `
    <div class="progress-track"><div class="progress-fill" style="width: ${job.progress}%"></div></div>
    <p class="muted">${job.progress}% · ${job.status}</p>
    <ul class="soft-list">${job.stages.map((stage) => `<li>${localized(stage, "name")} ${statusPill(stage.status)}</li>`).join("")}</ul>
  `;
}

function kbCard(kb, agents) {
  return card(displayName(kb), `
    <div class="status-row">${statusPill(kb.status)} ${tags([kb.answer_policy])}</div>
    <p>${displayDescription(kb)}</p>
    <p class="muted">${label("Bound agents", "绑定 Agent")}: ${kb.bound_agents.map((id) => localized(byId(agents, id), "name")).join(", ")}</p>
  `, "span-4", `${kb.documents} docs · ${kb.chunks} chunks`);
}

function boundAgents(kb, agents) {
  return `<ul class="soft-list">${kb.bound_agents.map((id) => {
    const agent = byId(agents, id);
    return `<li><strong>${localized(agent, "name")}</strong><div class="muted">${agent.provider} · ${agent.answer_policy}</div></li>`;
  }).join("")}</ul>`;
}

function displayName(item) {
  return localized(item, "name");
}

function displayDescription(item) {
  return localized(item, "description");
}

function recentJobLabel(job) {
  return localized(job, "label");
}

function localized(item, field) {
  if (!item) {
    return "";
  }
  const zhField = `${field}_zh`;
  return state.locale === "zh-CN" ? item[zhField] ?? item[field] : item[field];
}

function label(en, zh) {
  return state.locale === "zh-CN" ? zh : en;
}

function setPage(pageId) {
  state.activePage = pageId;
  renderNav();
  renderPage();
}

navList.addEventListener("click", (event) => {
  const button = event.target.closest("[data-page]");
  if (button) {
    setPage(button.dataset.page);
  }
});

mobilePageSelect.addEventListener("change", (event) => {
  setPage(event.target.value);
});

document.querySelectorAll("[data-locale]").forEach((button) => {
  button.addEventListener("click", () => {
    state.locale = button.dataset.locale;
    renderShellText();
    renderNav();
    renderPage();
  });
});

themeToggle.addEventListener("click", () => {
  state.theme = state.theme === "light" ? "dark" : "light";
  renderShellText();
});

async function bootstrap() {
  renderShellText();
  appRoot.innerHTML = `<div class="page"><p class="muted">Loading mock workbench data...</p></div>`;
  state.data = await loadWorkbenchData();
  renderNav();
  renderPage();
}

bootstrap().catch((error) => {
  appRoot.innerHTML = `<div class="page"><h2>Workbench mock data failed to load</h2><p class="muted">${error.message}</p></div>`;
});
