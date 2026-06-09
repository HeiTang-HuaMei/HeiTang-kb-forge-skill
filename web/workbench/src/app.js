import { defaultLocale, messages, t } from "./i18n.js";
import { loadWorkbenchData } from "./mockService.js";

export const PAGES = [
  { id: "dashboard", label: "Dashboard", label_zh: "仪表盘", description: "System overview and operating posture.", description_zh: "系统概览与运行态势。" },
  { id: "workspace", label: "Workspace", label_zh: "工作空间", description: "Local workspace paths, health, storage, registry, backup, restore, and privacy boundary.", description_zh: "本地工作区路径、健康、存储、注册表、备份恢复与隐私边界。" },
  { id: "operation-gate", label: "Operation Gate", label_zh: "运行门禁", description: "P1 gate status, blocked reasons, and non-v4 boundary.", description_zh: "P1 门禁状态、阻塞原因与非 v4 边界。" },
  { id: "capability-matrix", label: "Capability Matrix", label_zh: "能力矩阵", description: "Core P1 capability areas and action/report/artifact coverage.", description_zh: "Core P1 能力域与 action/report/artifact 覆盖。" },
  { id: "import-parsing", label: "Import & Parsing", label_zh: "导入与解析", description: "Multi-format import, OCR, preprocessing, and parser quality.", description_zh: "多格式导入、OCR、预处理与解析质量。" },
  { id: "knowledge-package-management", label: "Knowledge Package Management", label_zh: "知识包管理", description: "Knowledge package build, version diff, publishing, and archive.", description_zh: "知识包构建、版本差异、发布与归档。" },
  { id: "retrieval-verification", label: "Retrieval & Verification", label_zh: "检索与验证", description: "Query rewriting, retrieval planning, evidence selection, and validation.", description_zh: "查询改写、检索规划、证据选择与知识准确性验证。" },
  { id: "vector-hub-provider-storage", label: "Vector Hub / Provider / Storage", label_zh: "向量索引 / 提供方 / 存储", description: "Provider validation, vector smoke, redaction, offline fallback, and storage profiles.", description_zh: "提供方验证、向量冒烟、脱敏、离线回退与存储配置。" },
  { id: "document-generation", label: "Document Generation", label_zh: "文档生成", description: "Citation-backed document drafts, previews, and export readiness.", description_zh: "带引用的文档草稿、预览与导出就绪状态。" },
  { id: "skill-factory", label: "Skill Factory", label_zh: "技能工厂", description: "Book, package, and template Skill generation with validation and runtime profiles.", description_zh: "书籍、知识包与模板驱动 Skill 生成、验证与运行时配置。" },
  { id: "agent-factory-runtime", label: "Agent Factory & Runtime", label_zh: "Agent 工厂与运行", description: "Standalone Agent, KB-bound Agent, and multi-Agent orchestration.", description_zh: "Standalone Agent、KB-bound Agent、多 Agent 编排与运行监控。" },
  { id: "memory-center", label: "Memory Center", label_zh: "记忆中心", description: "Private agent memory and workflow-shared memory isolation.", description_zh: "Agent 私有记忆与工作流共享记忆隔离。" },
  { id: "task-job-center", label: "Task / Job Center", label_zh: "任务 / 作业中心", description: "Stable task states, progress, retry, cancel, resume, reports, and artifacts.", description_zh: "稳定任务状态、进度、重试、取消、恢复、报告与产物。" },
  { id: "artifact-management", label: "Artifact Management", label_zh: "产物管理", description: "KB packages, chunks, indexes, generated docs, Skill/Agent packages, traces, and proofs.", description_zh: "知识包、分片、索引、生成文档、Skill/Agent 包、追踪与证明。" },
  { id: "error-repair-center", label: "Error Repair Center", label_zh: "错误修复中心", description: "Stable user-visible failure taxonomy and repair actions.", description_zh: "稳定的用户可见错误分类与修复动作。" },
  { id: "reports-audit", label: "Reports & Audit", label_zh: "报表与审计", description: "System reports, provider configuration, storage, and privacy checks.", description_zh: "系统报告、提供方配置、存储与隐私安全。" },
  { id: "governance", label: "Governance", label_zh: "治理与合规", description: "Document ownership, stale/conflict controls, health, permissions, and review-required flows.", description_zh: "文档归属、过期/冲突控制、健康状态、权限与复核流程。" },
  { id: "template-library", label: "Template Library", label_zh: "模板库", description: "P1 Workbench templates for product, publishing, enterprise, education, commerce, and operations.", description_zh: "产品、出版、企业、教育、电商与运营场景的 P1 模板。" }
];

const NAV_GROUPS = [
  { label: "Overview", label_zh: "总览", pageIds: ["dashboard", "workspace", "operation-gate", "capability-matrix"] },
  { label: "Knowledge", label_zh: "知识工程", pageIds: ["import-parsing", "knowledge-package-management", "retrieval-verification", "vector-hub-provider-storage"] },
  { label: "Production", label_zh: "生产能力", pageIds: ["document-generation", "skill-factory", "agent-factory-runtime", "memory-center"] },
  { label: "Operations", label_zh: "治理与运维", pageIds: ["task-job-center", "artifact-management", "error-repair-center", "reports-audit", "governance", "template-library"] }
];

const STATUS_LABELS = {
  "zh-CN": {
    available: "可用",
    blocked: "阻塞",
    degraded: "降级",
    done: "完成",
    draft: "草稿",
    failed: "失败",
    in_review: "复核中",
    needs_correction: "需修正",
    offline: "离线",
    pass: "通过",
    queued: "排队中",
    ready: "就绪",
    review_required: "需复核",
    running: "运行中",
    trusted: "已发布"
  },
  "en-US": {
    available: "available",
    blocked: "blocked",
    degraded: "degraded",
    done: "done",
    draft: "draft",
    failed: "failed",
    in_review: "in review",
    needs_correction: "needs correction",
    offline: "offline",
    pass: "pass",
    queued: "queued",
    ready: "ready",
    review_required: "review required",
    running: "running",
    trusted: "published"
  }
};

const RISK_LABELS = {
  "zh-CN": { high: "高风险", medium: "中风险", low: "低风险" },
  "en-US": { high: "high", medium: "medium", low: "low" }
};

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
const shellTitle = document.querySelector("#shell-title");
const shellSubtitle = document.querySelector("#shell-subtitle");

function labelFor(item) {
  return state.locale === "zh-CN" ? item.label_zh ?? item.label : item.label;
}

function descriptionFor(item) {
  return state.locale === "zh-CN" ? item.description_zh ?? item.description : item.description;
}

function label(en, zh) {
  return state.locale === "zh-CN" ? zh : en;
}

function statusText(value) {
  return STATUS_LABELS[state.locale]?.[value] ?? value;
}

function riskText(value) {
  return RISK_LABELS[state.locale]?.[value] ?? value;
}

function localized(item, field) {
  if (!item) {
    return "";
  }
  const zhField = `${field}_zh`;
  return state.locale === "zh-CN" ? item[zhField] ?? item[field] : item[field];
}

function byId(collection, id) {
  return collection.find((item) => item.id === id);
}

function formatNumber(value) {
  return new Intl.NumberFormat(state.locale).format(value);
}

function renderShellText() {
  document.documentElement.lang = state.locale;
  document.querySelectorAll("[data-i18n]").forEach((node) => {
    node.textContent = t(state.locale, node.dataset.i18n);
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach((node) => {
    node.setAttribute("placeholder", t(state.locale, node.dataset.i18nPlaceholder));
  });
  document.body.dataset.theme = state.theme;
  document.querySelectorAll("[data-locale]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.locale === state.locale);
  });
}

function renderNav() {
  navList.innerHTML = NAV_GROUPS.map((group) => {
    const pages = group.pageIds.map((pageId) => byId(PAGES, pageId)).filter(Boolean);
    return `
      <section class="nav-group">
        <p class="nav-group-title">${state.locale === "zh-CN" ? group.label_zh : group.label}</p>
        ${pages.map((page) => {
          const active = page.id === state.activePage ? " is-active" : "";
          return `<button class="nav-button${active}" type="button" data-page="${page.id}">
            <span class="nav-icon" aria-hidden="true">${navIcon(page.id)}</span>
            <span><strong>${labelFor(page)}</strong><small>${state.locale === "zh-CN" ? page.label : page.label_zh}</small></span>
          </button>`;
        }).join("")}
      </section>
    `;
  }).join("");

  mobilePageSelect.innerHTML = PAGES.map((page) => {
    const selected = page.id === state.activePage ? " selected" : "";
    return `<option value="${page.id}"${selected}>${labelFor(page)}</option>`;
  }).join("");
}

function navIcon(pageId) {
  const icons = {
    dashboard: "▦",
    "file-upload": "⇧",
    "job-progress": "◴",
    "knowledge-base-list": "▣",
    "knowledge-base-detail": "◇",
    "review-queue": "□",
    "corrected-text-editor": "✎",
    "kb-query": "⌕",
    "document-generation": "▤",
    "agent-skill-management": "✣",
    "multi-agent-workflow": "⛓",
    "memory-scope-viewer": "◎",
    settings: "▥",
    "export-center": "▱"
  };
  return icons[pageId] ?? "□";
}

function statusPill(value) {
  return `<span class="status-pill" data-status="${value}">${statusText(value)}</span>`;
}

function riskPill(value) {
  return `<span class="risk-pill" data-risk="${value}">${riskText(value)}</span>`;
}

function tags(values) {
  return values.map((value) => `<span class="tag">${value}</span>`).join("");
}

function panel(title, body, className = "", subtitle = "") {
  return `
    <section class="panel ${className}">
      <div class="panel-header">
        <div>
          <h2>${title}</h2>
          ${subtitle ? `<p>${subtitle}</p>` : ""}
        </div>
      </div>
      ${body}
    </section>
  `;
}

function rightPanel(title, body, subtitle = "") {
  return `
    <section class="context-card">
      <div class="panel-header">
        <div>
          <h3>${title}</h3>
          ${subtitle ? `<p>${subtitle}</p>` : ""}
        </div>
      </div>
      ${body}
    </section>
  `;
}

function metricCard(labelText, value, note, icon = "□") {
  return `
    <article class="metric-card">
      <div class="metric-icon" aria-hidden="true">${icon}</div>
      <p class="metric-label">${labelText}</p>
      <p class="metric-value">${value}</p>
      <p class="metric-note">${note}</p>
    </article>
  `;
}

function miniMetric(labelText, value) {
  return `<div class="mini-metric"><span>${labelText}</span><strong>${value}</strong></div>`;
}

function progressBar(value) {
  return `<div class="progress-track"><div class="progress-fill" style="width: ${value}%"></div></div>`;
}

function stepper(steps, activeIndex) {
  return `
    <ol class="stepper">
      ${steps.map((step, index) => `<li class="${index === activeIndex ? "is-active" : index < activeIndex ? "is-done" : ""}">
        <span>${index + 1}</span>
        <div><strong>${step[0]}</strong><small>${step[1]}</small></div>
      </li>`).join("")}
    </ol>
  `;
}

function actionBar(actions) {
  return `<div class="action-bar">${actions.map((action, index) => `<button class="${index === 0 ? "primary-button" : "ghost-button"}" type="button">${action}</button>`).join("")}</div>`;
}

function p1Page(data, routeId) {
  return data.p1Contracts.pages.find((page) => page.route_id === routeId) ?? data.p1Contracts.pages[0];
}

function p1Actions(data, page) {
  const ids = new Set(page.action_ids);
  return data.p1Contracts.actions.filter((action) => ids.has(action.action_id));
}

function p1Reports(data, page) {
  const ids = new Set(page.report_ids);
  return data.p1Contracts.reports.filter((report) => ids.has(report.report_id));
}

function p1Artifacts(data, page) {
  const ids = new Set(page.artifact_ids);
  return data.p1Contracts.artifacts.filter((artifact) => ids.has(artifact.artifact_id));
}

function actionState(action) {
  const reason = action.web_blocked_reason || action.desktop_blocked_reason || "web_local_cli_unsupported";
  return `<button class="ghost-button is-disabled" type="button" disabled data-action-id="${action.action_id}" data-blocked-reason="${reason}">${reason}</button>`;
}

function p1ActionRows(actions, limit = 6) {
  return table([label("Action", "操作"), "Status", "blocked_reason"], actions.slice(0, limit).map((action) => [
    `<strong>${action.action_id}</strong><br><span class="muted">${action.label}</span>`,
    statusPill(action.status === "ready" ? "ready" : action.status === "dry_run" ? "review_required" : action.status === "blocked" ? "blocked" : "disabled"),
    actionState(action)
  ]));
}

function idList(items, idKey, limit = 5) {
  return `<ul class="compact-list">${items.slice(0, limit).map((item) => `<li><strong>${item[idKey]}</strong><span>${item.title || item.label || item.artifact_type || item.format || ""}</span></li>`).join("")}</ul>`;
}

function renderP1ContractPage(data, routeId, options = {}) {
  const page = p1Page(data, routeId);
  const actions = p1Actions(data, page);
  const reports = p1Reports(data, page);
  const artifacts = p1Artifacts(data, page);
  const counts = data.p1Contracts.counts;
  return pageShell(`
    <section class="panel hero-panel">
      <span class="eyebrow">${label("Core P1 contract aligned", "已对齐 Core P1 契约")}</span>
      <h2>${localized(page, "title")}</h2>
      <p>${page.capability_summary}</p>
      <div class="metric-grid compact">
        ${metricCard("actions", actions.length, `Core total ${counts.actions}`, "#")}
        ${metricCard("reports", reports.length, `Core total ${counts.reports}`, "#")}
        ${metricCard("artifacts", artifacts.length, `Core total ${counts.artifacts}`, "#")}
        ${metricCard("gate", data.p1Contracts.p1_full_operation_gate_status, "not_full_operation_yet", "#")}
      </div>
    </section>
    <section class="panel">
      <div class="section-title"><h3>${label("Action Contracts", "操作契约")}</h3><span>${label("unsupported operations are disabled with blocked_reason", "不支持操作 disabled 并显示 blocked_reason")}</span></div>
      ${p1ActionRows(actions)}
    </section>
    <div class="split-panels">
      ${panel(label("Report IDs", "报告 ID"), idList(reports, "report_id"))}
      ${panel(label("Artifact IDs", "产物 ID"), idList(artifacts, "artifact_id"))}
    </div>
  `, `
    ${rightPanel(label("Core Source", "Core 来源"), `<p>${data.p1Contracts.source.copied_from}</p><p class="muted">${data.p1Contracts.source.core_commit}</p>`)}
    ${rightPanel(label("Boundary", "边界"), `<p>${page.desktop_web_boundary || data.p1Contracts.source.fixture_policy}</p><p>${page.privacy_boundary || data.p1Contracts.source.fixture_policy}</p>`)}
    ${rightPanel(label("Gate", "门禁"), `${statusPill(data.p1Contracts.p1_full_operation_gate_status)}<p>not_v4_0_workbench_rc: ${data.p1Contracts.not_v4_0_workbench_rc}</p><p>not_full_operation_yet: ${data.p1Contracts.not_full_operation_yet}</p>`)}
    ${options.extraRail || ""}
  `);
}

function table(headers, rows) {
  return `
    <table class="data-table">
      <thead><tr>${headers.map((header) => `<th>${header}</th>`).join("")}</tr></thead>
      <tbody>${rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join("")}</tr>`).join("")}</tbody>
    </table>
  `;
}

function renderDashboard(data) {
  const runningJobs = data.jobs.filter((job) => job.status === "running").length;
  const successRate = Math.round((data.generatedDocs.filter((doc) => doc.status === "ready").length / data.generatedDocs.length) * 100);
  const counts = data.p1Contracts.counts;
  return pageShell(`
    <div class="toolbar-row">
      <div class="section-title"><h2>${label("Key Metrics", "关键指标")}</h2><span>${label("Workbench operating posture", "工作台运行态势")}</span></div>
      ${actionBar([label("Customize", "自定义"), label("Refresh", "刷新")])}
    </div>
    <section class="metric-grid">
      ${metricCard(label("P1 Pages", "P1 页面"), counts.pages, "Core contract", "▣")}
      ${metricCard(label("Actions", "操作"), counts.actions, "action_id", "✣")}
      ${metricCard(label("Reports", "报告"), counts.reports, "report_id", "▤")}
      ${metricCard(label("Artifacts", "产物"), counts.artifacts, "artifact_id", "◴")}
      ${metricCard(label("Error Codes", "错误码"), counts.errors, "error_code", "⌗")}
      ${metricCard(label("P1 Gate", "P1 门禁"), data.p1Contracts.p1_full_operation_gate_status, "not_full_operation_yet", "◇")}
    </section>
    <section class="split-grid">
      ${panel(label("Recent Tasks", "最近任务"), table(
        [label("Task", "任务"), label("Type", "类型"), label("Status", "状态"), label("Started", "发起时间"), label("Duration", "时长")],
        data.jobs.map((job) => [recentJobLabel(job), job.type, statusPill(job.status), job.started_at.slice(5, 16).replace("T", " "), job.progress === 100 ? "2m 18s" : "—"])
      ))}
      ${panel(label("System Health", "系统健康"), `
        <ul class="health-list">
          <li><span>${label("Service", "服务状态")}</span><strong>${label("All normal", "全部正常")}</strong>${statusPill("ready")}</li>
          <li><span>${label("Vector index", "向量索引")}</span><strong>${label("Normal", "正常")}</strong>${statusPill("available")}</li>
          <li><span>${label("Storage", "存储空间")}</span><strong>1.82 TB / 2.00 TB</strong>${progressBar(33)}</li>
          <li><span>${label("CPU", "CPU 使用")}</span><strong>18%</strong>${progressBar(18)}</li>
          <li><span>${label("Final gate", "最终门禁")}</span><strong>${label("Ready", "就绪")}</strong>${statusPill("ready")}</li>
        </ul>
      `)}
    </section>
    ${panel(label("Report Summary", "报表摘要"), `
      <div class="summary-grid">
        ${metricCard(label("Knowledge Growth", "知识库增长"), "+312", label("This week", "较上周"), "⌁")}
        ${metricCard(label("Retrieval Hit Rate", "检索命中率"), "87.4%", label("+2.1%", "+2.1%"), "⌕")}
        ${metricCard(label("Generation Success", "生成成功率"), `${successRate}%`, label("+1.3%", "+1.3%"), "▤")}
        ${metricCard(label("Human Review Rate", "人工复核率"), "7.1%", label("-0.6%", "-0.6%"), "□")}
      </div>
    `)}
  `, dashboardRail(data));
}

function dashboardRail(data) {
  return `
    ${rightPanel(label("Local First", "本地优先 · 隐私安全"), `<p>${label("All data is processed and stored locally. No upload, no sharing, no remote dependency by default.", "所有数据仅在本地处理与存储，不上传、不共享、不默认联网。")}</p><button class="ghost-button" type="button">${label("Privacy Settings", "隐私与安全设置")}</button>`)}
    ${rightPanel(label("Runtime Overview", "运行概览"), `
      ${miniMetric(label("Running agents", "运行中的 Agent"), "7")}
      ${miniMetric(label("Queued tasks", "排队中的任务"), "2")}
      ${miniMetric(label("Documents today", "今日处理文档"), "1,248")}
      ${miniMetric(label("Generated today", "今日生成内容"), "86")}
    `)}
    ${rightPanel(label("Activity", "活动时间线"), timeline([
      ["10:42", label("Document parse completed", "文档解析完成"), "产品手册 v2.3.pdf"],
      ["10:15", label("Knowledge package built", "知识包构建完成"), "合同范本 2024Q1"],
      ["09:58", label("Agent started", "Agent 启动"), "财报问答 Agent"],
      ["08:57", label("Agent running", "Agent 执行中"), "客户服务助手"]
    ]))}
  `;
}

function renderOperationGate(data) {
  const gate = data.p1Contracts.gate_report;
  return renderP1ContractPage(data, "operation-gate", {
    extraRail: rightPanel(label("Blocked Reasons", "阻塞原因"), idList(gate.blocker_ids.map((id) => ({ id, title: id })), "id"))
  });
}

function renderCapabilityMatrix(data) {
  const rows = data.p1Contracts.capability_matrix.map((area) => [
    `<strong>${area.page_id}</strong><br><span class="muted">${area.title}</span>`,
    area.action_ids.length,
    area.report_ids.length,
    area.artifact_ids.length,
    area.desktop_web_boundary
  ]);
  return pageShell(`
    <section class="panel hero-panel">
      <span class="eyebrow">${label("Core P1 capability matrix", "Core P1 能力矩阵")}</span>
      <h2>${label("Capability Matrix", "能力矩阵")}</h2>
      <p>${label("Every Core P1 capability area keeps action/report/artifact cross references stable for UI consumption.", "每个 Core P1 能力域都保留稳定 action/report/artifact 交叉引用供 UI 消费。")}</p>
    </section>
    <section class="panel">
      ${table([label("Capability", "能力域"), "actions", "reports", "artifacts", label("Boundary", "边界")], rows)}
    </section>
  `, `
    ${rightPanel(label("Contract Counts", "契约计数"), `${miniMetric("pages", data.p1Contracts.counts.pages)}${miniMetric("actions", data.p1Contracts.counts.actions)}${miniMetric("reports", data.p1Contracts.counts.reports)}${miniMetric("artifacts", data.p1Contracts.counts.artifacts)}`)}
    ${rightPanel(label("Source Commit", "来源提交"), `<p>${data.p1Contracts.source.core_commit}</p>`)}
  `);
}

function renderFileUpload(data) {
  return pageShell(`
    ${stepper([
      [label("Select Source", "选择来源"), label("Source files", "来源文件")],
      [label("Parser Config", "解析配置"), label("Backend strategy", "解析策略")],
      [label("OCR Config", "OCR 配置"), label("Language and images", "语言与图像")],
      [label("Execute Job", "执行任务"), label("Progress", "执行进度")],
      [label("Validate Result", "结果校验"), label("Quality gate", "质量门禁")]
    ], 3)}
    <section class="split-grid">
      ${panel(label("1. Select Source", "1. 选择来源"), `
        <div class="dropzone">
          <div class="upload-glyph">⇧</div>
          <h3>${label("Drag files or folders here, or choose files", "拖拽文件或文件夹到此处，或点击选择")}</h3>
          <p>${label("Supports PDFs, Office files, Markdown, HTML, EPUB, images, and archives.", "支持 PDF、Office、Markdown、HTML、EPUB、图片与压缩件。")}</p>
          <div class="file-types">${["PDF", "DOCX", "PPTX", "XLSX", "MD", "HTML", "EPUB", "MOBI", label("Image", "图片")].map((type) => `<span>${type}</span>`).join("")}</div>
        </div>
        ${actionBar([label("Select files", "选择文件"), label("Select folder", "选择文件夹"), label("Import from link", "从链接导入")])}
      `)}
      ${panel(label("2. Parser Configuration", "2. 解析配置"), `
        <div class="option-grid">
          ${optionCard("HeiTang Parser", label("Recommended", "推荐"), true)}
          ${optionCard("Unstructured", label("General documents", "通用文档"), false)}
          ${optionCard("LlamaParse", label("Long technical docs", "长技术文档"), false)}
          ${optionCard(label("Custom rules", "自定义规则"), label("Enterprise rules", "企业规则"), false)}
        </div>
        <div class="check-grid">
          ${check(label("Clean text", "清洗文本"), true)}
          ${check(label("Recognize tables", "表格结构识别"), true)}
          ${check(label("Formula OCR", "公式识别"), false)}
          ${check(label("Keep images", "保留图片与图表"), true)}
          ${check(label("Merge paragraphs", "段落合并分句"), true)}
        </div>
      `)}
    </section>
    <section class="three-grid">
      ${panel(label("3. OCR Configuration", "3. OCR 配置"), formRows([
        [label("Enable OCR", "启用 OCR"), toggle(true)],
        [label("OCR Engine", "OCR 引擎"), selectBox("PaddleOCR (PP-OCRv4)")],
        [label("Language", "语言"), selectBox(label("Chinese + English", "中英混合"))],
        [label("Keep scans", "图像质量增强"), selectBox(label("Standard", "标准"))]
      ]))}
      ${panel(label("4. Scope", "4. 执行范围"), formRows([
        [label("Page Range", "页码范围"), radioText(label("All pages", "全部页面"), true)],
        [label("Selected pages", "指定范围"), "<input placeholder=\"1-10, 12, 15-20\" />"],
        [label("Sampling", "随机抽样"), "<input value=\"10%\" />"]
      ]))}
      ${panel(label("Advanced", "高级选项"), formRows([
        [label("Text strategy", "文本切分策略"), selectBox(label("Semantic chunking", "语义切分"))],
        [label("Target chunk", "目标 Chunk 大小"), "<input value=\"800 tokens\" />"],
        [label("Chunk overlap", "Chunk 重叠"), "<input value=\"120 tokens\" />"]
      ]))}
    </section>
    ${panel(label("5. Execution Progress", "5. 执行任务"), `
      <div class="execution-head"><strong>${label("Current job", "当前任务")}: ${recentJobLabel(data.jobs[0])}</strong><span>${statusPill(data.jobs[0].status)} ${data.jobs[0].progress}%</span></div>
      ${progressBar(data.jobs[0].progress)}
      ${table(
        [label("File", "文件名"), label("Size", "大小"), label("Type", "类型"), label("Pages", "页数"), label("Status", "状态"), label("Progress", "进度")],
        [
          ["劳动合同模板（2024版）.pdf", "2.4 MB", "PDF", "12", statusPill("done"), progressBar(100)],
          ["员工手册（完整版）.docx", "5.7 MB", "DOCX", "68", statusPill("running"), progressBar(72)],
          ["保密协议（标准版）.pdf", "1.1 MB", "PDF", "8", statusPill("queued"), progressBar(0)]
        ]
      )}
    `)}
  `, `
    ${rightPanel(label("Queue Status", "队列状态"), `${miniMetric(label("Queued", "排队中"), "3")}${miniMetric(label("Running", "运行中"), "1")}${miniMetric(label("Done", "已完成"), "12")}`)}
    ${rightPanel(label("Failed Files", "失败文件"), `<ul class="compact-list"><li>年度财务报告_2023.pdf ${statusPill("failed")}</li><li>扫描件_合同补充页_03.jpg ${statusPill("failed")}</li></ul>`)}
    ${rightPanel(label("Quick Repair", "快速修复"), `<ul class="compact-list"><li>${label("Retry OCR for failed files", "重新 OCR 失败文件")}</li><li>${label("Switch parser and retry", "更换解析后端并重试")}</li><li>${label("Skip and import parseable content", "跳过并导入可解析内容")}</li></ul>`)}
  `);
}

function renderJobProgress(data) {
  return pageShell(`
    <section class="metric-grid narrow">
      ${metricCard(label("Queued", "排队中"), data.jobs.filter((job) => job.status === "queued").length, label("waiting", "等待中"), "◴")}
      ${metricCard(label("Running", "运行中"), data.jobs.filter((job) => job.status === "running").length, label("active", "执行中"), "▶")}
      ${metricCard(label("Blocked", "阻塞"), data.jobs.filter((job) => job.status === "blocked").length, label("needs action", "需要处理"), "□")}
      ${metricCard(label("Done", "完成"), data.jobs.filter((job) => job.status === "done").length, label("completed", "已完成"), "✓")}
    </section>
    ${panel(label("Job Queue", "任务队列"), table(
      [label("Job", "任务"), label("Type", "类型"), label("KB", "知识库"), label("Status", "状态"), label("Progress", "进度"), label("Stages", "阶段")],
      data.jobs.map((job) => [recentJobLabel(job), job.type, job.kb_id, statusPill(job.status), progressBar(job.progress), job.stages.map((stage) => statusPill(stage.status)).join("")])
    ))}
    <section class="split-grid">
      ${data.jobs.map((job) => panel(recentJobLabel(job), `
        <div class="execution-head"><span>${job.started_at}</span><strong>${job.progress}%</strong></div>
        ${progressBar(job.progress)}
        <ul class="compact-list">${job.stages.map((stage) => `<li>${localized(stage, "name")} ${statusPill(stage.status)}</li>`).join("")}</ul>
      `, "compact-panel", `${job.type} · ${job.kb_id}`)).join("")}
    </section>
  `, defaultOperationsRail(data));
}

function renderKnowledgeBaseList(data) {
  const selected = data.knowledgeBases[0];
  return pageShell(`
    <div class="toolbar-row">
      <div class="filter-row">
        ${selectBox(label("All spaces", "全部空间"))}
        ${selectBox(label("All statuses", "全部状态"))}
        ${selectBox(label("All tags", "全部标签"))}
      </div>
      ${actionBar([label("New package", "新建知识包"), label("Incremental update", "增量更新"), label("Publish", "发布"), label("Export", "导出")])}
    </div>
    ${panel(label("Knowledge Packages", "知识包列表"), table(
      [label("Name", "名称"), label("Version", "版本"), label("Sources", "来源数量"), "chunks", label("Quality", "质量分"), label("Status", "状态"), label("Updated", "更新时间")],
      data.knowledgeBases.map((kb) => [displayName(kb), "v2.3.0", kb.documents, formatNumber(kb.chunks), `<span class="score">${kb.trusted_chunks ? Math.round((kb.trusted_chunks / kb.chunks) * 1000) / 10 : "—"}</span>`, statusPill(kb.status), kb.last_updated.slice(5, 16).replace("T", " ")])
    ))}
    ${panel(displayName(selected), `
      <div class="detail-head">
        <p>${displayDescription(selected)}</p>
        <div class="status-row">${statusPill(selected.status)} ${tags([selected.answer_policy, selected.parser_backend])}</div>
      </div>
      <div class="summary-grid">
        ${miniMetric(label("Latest version", "最新版本"), "v2.3.0")}
        ${miniMetric("Trust Gate", "92.4 / 100")}
        ${miniMetric(label("Version diff", "版本差异"), "+2,104 chunks")}
        ${miniMetric(label("Vector status", "重建状态"), label("Success", "成功"))}
      </div>
    `)}
    ${panel(label("Export Targets", "导出目标"), `<div class="export-strip">${["本地索引库", "向量库 (Milvus)", "对象存储 (S3 兼容)", "备份归档"].map((item) => `<span>${item}</span>`).join("")}</div>`)}
  `, knowledgeRail(data));
}

function renderKnowledgeBaseDetail(data) {
  const kb = data.knowledgeBases[0];
  return pageShell(`
    ${panel(displayName(kb), `
      <div class="detail-head">
        <p>${displayDescription(kb)}</p>
        ${actionBar([label("Edit info", "编辑信息"), label("Rebuild index", "重建索引"), label("Export", "导出")])}
      </div>
      <div class="summary-grid">
        ${miniMetric(label("Documents", "文档数"), kb.documents)}
        ${miniMetric(label("Chunks", "分片数"), formatNumber(kb.chunks))}
        ${miniMetric(label("Trusted chunks", "可信分片"), formatNumber(kb.trusted_chunks))}
        ${miniMetric(label("Draft chunks", "草稿分片"), formatNumber(kb.draft_chunks))}
        ${miniMetric(label("Risk count", "风险数"), kb.risk_count)}
      </div>
    `)}
    <section class="split-grid">
      ${panel("Trust Gate", `<ul class="health-list"><li><span>${label("Parse success", "解析成功率")}</span><strong>99.2%</strong>${statusPill("pass")}</li><li><span>${label("Deduplication", "去重率")}</span><strong>93.1%</strong>${statusPill("pass")}</li><li><span>${label("Structure integrity", "结构完整性")}</span><strong>${statusText("pass")}</strong>${statusPill("pass")}</li></ul>`)}
      ${panel(label("Bound agents", "绑定 Agent"), boundAgents(kb, data.agents))}
    </section>
  `, knowledgeRail(data));
}

function renderReviewQueue(data) {
  return pageShell(`
    <div class="toolbar-row">
      <div class="filter-row">${selectBox(label("All risks", "全部风险"))}${selectBox(label("All assignees", "全部负责人"))}${selectBox(label("All statuses", "全部状态"))}</div>
      ${actionBar([label("Assign", "分配"), label("Mark reviewed", "标记已复核")])}
    </div>
    ${panel(label("Review Items", "复核项"), table(
      [label("Risk", "风险"), label("Source", "来源"), label("Reason", "原因"), label("Status", "状态"), label("Assignee", "负责人")],
      data.reviewItems.map((item) => [riskPill(item.risk), `<strong>${item.source}</strong><div class="table-meta">${item.kb_id}</div>`, localized(item, "reason"), statusPill(item.status), item.assignee])
    ))}
    ${panel(label("Blocked Reasons", "阻塞原因"), `<ul class="compact-list">${data.reviewItems.filter((item) => item.risk !== "low").map((item) => `<li><strong>${item.source}</strong><span>${localized(item, "reason")}</span></li>`).join("")}</ul>`)}
  `, reviewRail(data));
}

function renderCorrectedTextEditor(data) {
  const item = data.reviewItems[0];
  return pageShell(`
    ${panel(label("Correction Workspace", "校正文稿工作区"), `
      <div class="editor-toolbar">
        <span>${riskPill(item.risk)}</span>
        <span>${statusPill(item.status)}</span>
        <strong>${item.source}</strong>
      </div>
      <textarea aria-label="Corrected text">${item.corrected_text}</textarea>
      ${actionBar([t(state.locale, "common.saveDraft"), t(state.locale, "common.review"), label("Send to trust gate", "送入可信门禁")])}
    `)}
    ${panel(label("Review Contract", "复核契约"), `<p>${label("This editor writes to mock state only. Future Core integration should replace the service call, not the editor surface.", "此编辑器仅写入模拟状态。未来 Core 集成应替换服务调用，而不是重写编辑界面。")}</p>`)}
  `, reviewRail(data));
}

function renderKbQuery(data) {
  return pageShell(`
    ${panel(label("Query Console", "查询控制台"), `
      <textarea class="query-box" aria-label="KB query">${label("What changed in the launch process?", "2024年中国新能源汽车补贴政策有哪些变化？各地是否有额外补贴？")}</textarea>
      <div class="query-actions"><span>${label("Original language", "原始语言")}: ${state.locale === "zh-CN" ? "中文" : "English"}</span>${actionBar([label("Search & Verify", "检索与验证")])}</div>
    `)}
    ${stepper([
      [label("Query Rewrite", "查询改写"), label("Rewrite", "查询改写")],
      [label("Retrieval Planning", "检索规划"), label("Plan", "检索规划")],
      [label("Hybrid Retrieval", "混合检索"), label("Search", "混合检索")],
      [label("Rerank", "重排序"), label("Rank", "重排序")],
      [label("Claim Verification", "证据验证"), label("Verify", "证据验证")]
    ], 2)}
    <section class="split-grid wide-left">
      ${panel(label("Retrieved Evidence", "检索证据"), table(
        ["#", label("Evidence", "证据"), label("Score", "分数"), label("State", "状态")],
        [
          ["1", "关于进一步完善新能源汽车推广应用财政补贴政策的通知（2024版）", "0.95", statusPill("ready")],
          ["2", "北京市促进新能源汽车消费实施方案（2024年）", "0.89", statusPill("ready")],
          ["3", "上海市鼓励购买和使用新能源汽车实施办法", "0.83", statusPill("ready")],
          ["4", "2024年新能源汽车补贴将全面取消？官方回应", "0.62", statusPill("review_required")]
        ]
      ))}
      ${panel(label("Evidence Selection & Reasoning", "证据选择与推理"), `
        <h3>${label("Selected evidence", "已选证据")} (3)</h3>
        <ul class="compact-list"><li>政策通知（2024版）</li><li>北京市消费实施方案</li><li>上海市实施办法</li></ul>
        <h3>${label("Reasoning", "推理说明")}</h3>
        <p>${label("The selected official policy files directly answer the national and local subsidy changes. Media-only sources are kept out of final evidence.", "以上官方政策文件直接回答了国家层面补贴政策以及北京、上海两地的额外补贴问题，媒体来源不进入最终证据。")}</p>
      `)}
    </section>
  `, `
    ${rightPanel(label("Knowledge Accuracy", "知识准确性"), `<div class="accuracy-ring">92.7%</div>${miniMetric(label("Confidence", "可信度"), label("High", "高"))}`)}
    ${rightPanel(label("Contradictions", "矛盾与冲突"), `<p>${label("One potential contradiction detected. Check source timeliness.", "检测到 1 条潜在冲突，请注意时效性。")}</p>${statusPill("review_required")}`)}
    ${rightPanel(label("Quality Metrics", "质量指标"), `${miniMetric(label("Context recall", "上下文召回率"), "0.88")}${miniMetric(label("Faithfulness", "忠实度"), "0.93")}${miniMetric(label("Hit rate", "命中率"), "0.91")}${miniMetric(label("Review required", "需人工复核"), "8.3%")}`)}
  `);
}

function renderDocumentGeneration(data) {
  return pageShell(`
    <div class="toolbar-row">
      <div class="filter-row">${selectBox(label("Brief", "简报"))}${selectBox(label("Grounded only", "仅基于证据"))}${selectBox(label("Markdown + DOCX", "Markdown + DOCX"))}</div>
      ${actionBar([label("Generate", "生成文档"), label("Preview", "预览"), label("Export", "导出")])}
    </div>
    ${panel(label("Generated Documents", "生成文档"), table(
      [label("Title", "标题"), label("Type", "类型"), label("Status", "状态"), label("KB", "知识库"), label("Agent", "Agent"), label("Citations", "引用数")],
      data.generatedDocs.map((doc) => [localized(doc, "title"), doc.type, statusPill(doc.status), doc.kb_id, doc.agent_id, doc.citations])
    ))}
    <section class="split-grid">
      ${data.generatedDocs.map((doc) => panel(localized(doc, "title"), `<div class="status-row">${statusPill(doc.status)} ${tags([doc.type, doc.kb_id])}</div><p>${label("Citation-backed draft is ready for preview and export validation.", "带引用草稿可预览并进入导出校验。")}</p>`, "compact-panel", doc.agent_id)).join("")}
    </section>
  `, defaultOperationsRail(data));
}

function renderAgentSkillManagement(data) {
  const agent = data.agents[0];
  return pageShell(`
    ${panel(label("1. Agent Mode", "1. Agent 模式选择"), `
      <div class="option-grid three">
        ${optionCard(label("Standalone Agent", "独立 Agent"), label("Independent configuration and runtime", "独立配置与运行"), true)}
        ${optionCard(label("KB-bound Agent", "KB 绑定 Agent"), label("Answers with bound knowledge bases", "绑定知识库并提供精准回答"), false)}
        ${optionCard(label("Multi-agent orchestration", "多 Agent 编排"), label("Parent-child workflow execution", "母代调度子代理执行任务"), false)}
      </div>
    `)}
    ${panel(label("2. Agent Configuration", "2. Agent 配置"), `
      <div class="tab-strip">${["Prompt", "Soul", "Policy", "KB", "Tools", "Memory", "Providers"].map((tab, index) => `<span class="${index === 0 ? "is-active" : ""}">${tab}</span>`).join("")}</div>
      <section class="split-grid">
        <div>
          <label class="form-label">${label("System Prompt", "系统提示词")}</label>
          <textarea>${label("You are a HeiTang enterprise knowledge assistant. Answer with citations and abstain when evidence is missing.", "你是 HeiTang 企业知识助手。请基于证据回答，缺少证据时拒答。")}</textarea>
        </div>
        <div class="form-stack">
          ${formRows([
            [label("Model", "模型选择"), selectBox(agent.model)],
            [label("Temperature", "温度"), "<input value=\"0.2\" />"],
            [label("Max output tokens", "最大输出"), "<input value=\"2048\" />"],
            [label("Top P", "Top P"), "<input value=\"0.9\" />"]
          ])}
        </div>
        <div class="form-stack">
          ${formRows([
            [label("Bound KBs", "知识库绑定"), tags(agent.bound_kbs)],
            [label("Default retrieval", "默认检索策略"), selectBox(label("Hybrid retrieval", "混合检索"))],
            [label("Top K", "检索数量"), "<input value=\"8\" />"],
            [label("Enforce citation", "强制引用"), toggle(true)]
          ])}
        </div>
      </section>
    `)}
    ${panel(label("3. Runtime & Trace", "3. 运行与追踪"), `
      <div class="tab-strip">${["Session Trace", "Checkpoints", "Tool Calls", "Task Queue"].map((tab, index) => `<span class="${index === 0 ? "is-active" : ""}">${tab}</span>`).join("")}</div>
      <section class="split-grid wide-left">
        ${panel(label("Session", "会话"), `<ul class="compact-list"><li>${label("User asked about product permission management.", "用户询问产品权限管理知识。")}</li><li>KB-Product-Assistant ${statusPill("running")}</li><li>Tool: search_docs ${statusPill("done")}</li></ul>`, "inner-panel")}
        ${panel(label("Task Queue", "任务队列"), `<ul class="compact-list"><li>${label("Analyze permission model", "分析用户权限模型")} ${statusPill("running")}</li><li>${label("Retrieve policy docs", "查询权限相关设计文档")} ${statusPill("running")}</li><li>${label("Generate advice", "生成权限管理建议")} ${statusPill("queued")}</li></ul>`, "inner-panel")}
      </section>
    `)}
  `, `
    ${rightPanel(label("Runtime & Resources", "运行与资源"), `<ul class="compact-list">${data.agents.map((item) => `<li><strong>${localized(item, "name")}</strong>${statusPill(item.status)}</li>`).join("")}</ul>`)}
    ${rightPanel(label("Child Agent Access", "子代理访问控制"), `<ul class="compact-list"><li>Orchestrator-Main</li><li>KB-Product-Assistant ${statusPill("ready")}</li><li>Data-Analyzer ${statusPill("ready")}</li></ul>`)}
    ${rightPanel(label("Memory Isolation", "记忆隔离策略"), `${formRows([[label("Isolation", "隔离级别"), selectBox(label("Session isolated", "会话级隔离"))], [label("Shared memory", "共享记忆"), selectBox(label("No sharing", "无共享"))]])}`)}
    ${rightPanel(label("Last Failure", "最近失败"), `KB-Product-Assistant ${statusPill("failed")}<p>Tool: search_docs timeout (30s)</p>`)}
  `);
}

function renderMultiAgentWorkflow(data) {
  return pageShell(`
    <section class="split-grid">
      ${data.workflows.map((workflow) => panel(localized(workflow, "name"), `
        <div class="status-row">${statusPill(workflow.status)} ${tags([workflow.shared_memory_scope])}</div>
        <ul class="compact-list">${workflow.steps.map((step) => `<li>${localized(step, "label")} · ${step.agent} ${statusPill(step.status)}</li>`).join("")}</ul>
      `)).join("")}
    </section>
    ${panel(label("Handoff Trace", "交接链路"), `<ul class="compact-list">${data.workflows.flatMap((workflow) => workflow.handoff_trace).map((trace) => `<li>${trace.from} → ${trace.to} · ${trace.artifact} ${statusPill(trace.status)}</li>`).join("")}</ul>`)}
  `, defaultOperationsRail(data));
}

function renderMemoryScopeViewer(data) {
  return pageShell(`
    <section class="split-grid">
      ${data.memoryScopes.map((scope) => panel(scope.id, `
        <div class="status-row">${tags([scope.type, scope.isolation])}</div>
        <p>${scope.summary}</p>
        ${miniMetric(label("Owner", "所有者"), scope.owner)}
        ${miniMetric(label("Records", "记录"), scope.records)}
      `)).join("")}
    </section>
    ${panel(label("Memory Policy", "记忆策略"), `<ul class="health-list"><li><span>${label("Private memory", "私有记忆")}</span><strong>${label("Isolated by default", "默认隔离")}</strong>${statusPill("ready")}</li><li><span>${label("Workflow shared memory", "工作流共享记忆")}</span><strong>${label("Explicit only", "仅显式授权")}</strong>${statusPill("ready")}</li></ul>`)}
  `, defaultOperationsRail(data));
}

function renderSettings(data) {
  return pageShell(`
    <section class="split-grid">
      ${panel(label("Report Center", "报告中心"), table(
        [label("Report", "报告项"), label("Status", "状态"), label("Last run", "最近运行"), label("Trend", "趋势"), label("Actions", "操作")],
        [
          ["Product Hardening", statusPill("pass"), "2024-05-17 10:42", "⌁⌁⌁", "↧"],
          ["Final Gate", statusPill("review_required"), "2024-05-17 09:21", "⌁⌁", "↧"],
          ["OCR Proof", statusPill("pass"), "2024-05-17 10:15", "⌁⌁⌁", "↧"],
          ["UI Gate", statusPill("blocked"), "2024-05-17 07:02", "⌁", "↧"]
        ]
      ))}
      ${panel(label("Providers & Storage", "提供方与存储配置"), `
        ${providerList(data.providers)}
        ${parserList(data.parserBackends)}
      `)}
    </section>
  `, `
    ${rightPanel(label("Issues & Quick Fix", "问题与修复建议"), `<ul class="compact-list"><li>UI Gate ${statusPill("blocked")}<button class="primary-button" type="button">${label("Quick fix", "一键修复")}</button></li><li>Final Gate ${statusPill("review_required")}</li></ul>`)}
    ${rightPanel(label("Answer Policies", "回答策略"), policyList(data.answerPolicies))}
  `);
}

function renderExportCenter(data) {
  return pageShell(`
    ${panel(label("Export Packages", "导出包"), table(
      [label("Name", "名称"), label("Format", "格式"), label("Status", "状态"), label("Includes", "包含内容"), label("Created", "创建时间")],
      data.exportItems.map((item) => [localized(item, "name"), item.format, statusPill(item.status), item.includes.join(", "), item.created_at.slice(5, 16).replace("T", " ")])
    ))}
    ${panel(label("Generated Document Exports", "生成文档导出"), table(
      [label("Document", "文档"), label("Type", "类型"), label("Status", "状态"), label("Citations", "引用数")],
      data.generatedDocs.map((doc) => [localized(doc, "title"), doc.type, statusPill(doc.status), doc.citations])
    ))}
  `, `
    ${rightPanel(label("Storage Targets", "存储目标"), `<ul class="compact-list"><li>${label("Local index", "本地索引库")}</li><li>${label("Vector DB", "向量库")}</li><li>${label("Archive", "备份归档")}</li></ul>`)}
    ${rightPanel(label("Delivery Boundary", "交付边界"), `<p>${label("Current Workbench remains local and mock-backed for page workflows; it is not the v4.0 release.", "当前工作台页面流程仍为本地模拟与桥接契约，不是 v4.0 release。")}</p>`)}
  `);
}

function pageShell(mainContent, railContent) {
  return `
    <div class="workbench-page">
      <section class="page-main">${mainContent}</section>
      <aside class="right-context">${railContent}</aside>
    </div>
  `;
}

function defaultOperationsRail(data) {
  return `
    ${rightPanel(label("Operations", "运行概览"), `${miniMetric(label("Running jobs", "运行任务"), data.metrics.runningJobs)}${miniMetric(label("Review risks", "复核风险"), data.metrics.reviewRisks)}${miniMetric(label("Exports", "导出项"), data.metrics.exports)}`)}
    ${rightPanel(label("Provider Status", "供应商状态"), providerList(data.providers))}
    ${rightPanel(label("Local First", "本地优先"), `<p>${label("Desktop Workbench keeps the Core boundary local and file-first.", "Desktop Workbench 保持 Core 边界本地优先、文件优先。")}</p>`)}
  `;
}

function knowledgeRail(data) {
  return `
    ${rightPanel(label("Package Overview", "知识包概览"), `${miniMetric(label("Total", "总数"), data.metrics.knowledgeBases)}${miniMetric(label("Trusted", "已发布"), data.metrics.trustedKnowledgeBases)}${miniMetric(label("Draft", "草稿"), data.metrics.draftKnowledgeBases)}${miniMetric(label("Avg quality", "平均质量分"), "88.6")}`)}
    ${rightPanel(label("Recent Changes", "最近变更"), timeline(data.knowledgeBases.map((kb) => [kb.last_updated.slice(11, 16), displayName(kb), statusText(kb.status)])))}
    ${rightPanel(label("Package Actions", "知识包操作"), `<ul class="compact-list"><li>${label("Compare versions", "对比版本")}</li><li>${label("Rollback version", "回滚版本")}</li><li>${label("Trigger rebuild", "触发重建")}</li><li>${label("Archive package", "归档知识包")}</li></ul>`)}
  `;
}

function reviewRail(data) {
  const high = data.reviewItems.filter((item) => item.risk === "high").length;
  return `
    ${rightPanel(label("Review Status", "复核状态"), `${miniMetric(label("High risk", "高风险"), high)}${miniMetric(label("Open items", "待处理"), data.reviewItems.length)}${miniMetric(label("Blocked", "阻塞"), data.reviewItems.filter((item) => item.status === "needs_correction").length)}`)}
    ${rightPanel(label("Quick Actions", "快捷操作"), `<ul class="compact-list"><li>${label("Assign to reviewer", "分配复核人")}</li><li>${label("Export CSV", "导出 CSV")}</li><li>${label("Send to trust gate", "送入可信门禁")}</li></ul>`)}
  `;
}

function providerList(providers) {
  return `<ul class="compact-list">${providers.map((provider) => `<li><strong>${provider.name}</strong>${statusPill(provider.status)}<span>${provider.models.join(", ")}</span></li>`).join("")}</ul>`;
}

function parserList(backends) {
  return `<ul class="compact-list">${backends.map((backend) => `<li><strong>${backend.name}</strong>${statusPill(backend.status)}<span>${backend.supports.join(", ")}</span></li>`).join("")}</ul>`;
}

function policyList(policies) {
  return `<ul class="compact-list">${policies.map((policy) => `<li><strong>${localized(policy, "label")}</strong><span>${localized(policy, "description")}</span></li>`).join("")}</ul>`;
}

function boundAgents(kb, agents) {
  return `<ul class="compact-list">${kb.bound_agents.map((id) => {
    const agent = byId(agents, id);
    return `<li><strong>${localized(agent, "name")}</strong><span>${agent.provider} · ${agent.answer_policy}</span></li>`;
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

function formRows(rows) {
  return `<div class="form-grid">${rows.map(([name, control]) => `<label><span>${name}</span>${control}</label>`).join("")}</div>`;
}

function selectBox(value) {
  return `<select><option>${value}</option></select>`;
}

function toggle(checked) {
  return `<span class="switch ${checked ? "is-on" : ""}" role="switch" aria-checked="${checked}"><span></span></span>`;
}

function check(text, checked) {
  return `<label class="check-row"><input type="checkbox" ${checked ? "checked" : ""} /> ${text}</label>`;
}

function radioText(text, checked) {
  return `<label class="check-row"><input type="radio" ${checked ? "checked" : ""} /> ${text}</label>`;
}

function optionCard(title, subtitle, selected) {
  return `<article class="option-card ${selected ? "is-selected" : ""}"><strong>${title}</strong><span>${subtitle}</span><i></i></article>`;
}

function timeline(items) {
  return `<ol class="timeline">${items.map(([time, title, subtitle]) => `<li><time>${time}</time><div><strong>${title}</strong><span>${subtitle}</span></div></li>`).join("")}</ol>`;
}

function renderPage() {
  const page = byId(PAGES, state.activePage) ?? PAGES[0];
  const data = state.data;
  const renderers = {
    dashboard: renderDashboard,
    workspace: (viewData) => renderP1ContractPage(viewData, "workspace"),
    "operation-gate": renderOperationGate,
    "capability-matrix": renderCapabilityMatrix,
    "import-parsing": renderFileUpload,
    "knowledge-package-management": renderKnowledgeBaseList,
    "retrieval-verification": renderKbQuery,
    "vector-hub-provider-storage": (viewData) => renderP1ContractPage(viewData, "vector-hub-provider-storage"),
    "document-generation": renderDocumentGeneration,
    "skill-factory": (viewData) => renderP1ContractPage(viewData, "skill-factory"),
    "agent-factory-runtime": renderAgentSkillManagement,
    "memory-center": renderMemoryScopeViewer,
    "task-job-center": renderJobProgress,
    "artifact-management": (viewData) => renderP1ContractPage(viewData, "artifact-management"),
    "error-repair-center": (viewData) => renderP1ContractPage(viewData, "error-repair-center"),
    "reports-audit": renderSettings,
    governance: (viewData) => renderP1ContractPage(viewData, "governance"),
    "template-library": (viewData) => renderP1ContractPage(viewData, "template-library")
  };

  shellTitle.textContent = labelFor(page);
  shellSubtitle.textContent = descriptionFor(page);
  appRoot.innerHTML = (renderers[page.id] || ((viewData) => renderP1ContractPage(viewData, page.id)))(data);
  appRoot.focus({ preventScroll: true });
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
  appRoot.innerHTML = `<div class="workbench-page"><section class="page-main"><p class="muted">Loading mock workbench data...</p></section></div>`;
  state.data = await loadWorkbenchData();
  renderNav();
  renderPage();
}

bootstrap().catch((error) => {
  appRoot.innerHTML = `<div class="workbench-page"><section class="page-main"><h2>Workbench mock data failed to load</h2><p class="muted">${error.message}</p></section></div>`;
});
