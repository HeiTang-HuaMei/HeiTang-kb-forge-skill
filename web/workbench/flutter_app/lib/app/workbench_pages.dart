part of '../main.dart';

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '首页',
      'Workbench overview, recent work, health, artifacts, and work entrypoints.',
      '工作台概览、最近任务、健康状态、产物与工作入口。',
      memberPageIds: ['dashboard']),
  WorkbenchPage(
      'workbook',
      'Workbook',
      '工作本管理',
      'Review the current workbook, persistence state, recent assets, and handoff entries.',
      '查看当前工作本、持久化状态、最近资产和承接入口。',
      memberPageIds: ['workspace']),
  WorkbenchPage(
      'document-library',
      'Document Library',
      '文档库',
      'Manage source documents, metadata, parsing records, versions, references, and artifacts.',
      '管理来源文档、元数据、解析记录、版本、引用和产物。',
      memberPageIds: [
        'import-parsing',
        'document-library',
      ]),
  WorkbenchPage(
      'knowledge-package-management',
      'Knowledge Base',
      '知识库',
      'Manage knowledge bases, vector indexes, quality, versions, builds, and validation records.',
      '管理知识库、向量索引、质量、版本、构建与验证记录。',
      memberPageIds: [
        'knowledge-package-management',
        'vector-hub-provider-storage',
      ]),
  WorkbenchPage(
      'retrieval-verification',
      'Retrieval & Verification',
      '检索与验证',
      'Rewrite queries, plan retrieval, select evidence, rerank, and verify against local evidence.',
      '执行查询改写、检索规划、证据选择、重排，以及基于本地证据的验证。',
      memberPageIds: ['retrieval-verification']),
  WorkbenchPage(
      'document-generation',
      'Document Generation',
      '文档生成',
      'Choose a knowledge base, template, and output type, then generate, validate, and export documents inside this module.',
      '选择知识库、文档模板和输出类型，在本模块完成生成、验证与导出。',
      memberPageIds: ['document-generation']),
  WorkbenchPage(
      'skill-factory',
      'Skill Factory',
      'Skill 工厂',
      'Create, validate, and export governed Skill drafts from real knowledge bases.',
      '基于真实知识库创建、验证和导出经过治理的 Skill 草稿。',
      memberPageIds: ['skill-factory']),
  WorkbenchPage(
      'agent-factory-runtime',
      'Agent Workbench',
      'Agent 工作台',
      'Create Agents, run single-agent dialogue, and coordinate governed multi-agent discussion.',
      '创建 Agent、运行单 Agent 对话，并协调受治理的多 Agent 讨论。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'artifact-center',
      'Artifact Center',
      '产物中心',
      'Browse generated documents, knowledge artifacts, Skills, Agents, dialogue records, and A2A outputs from real workspace state.',
      '从真实工作区状态浏览生成文档、知识库产物、Skill、Agent、对话记录和 A2A 输出。',
      memberPageIds: ['artifact-management']),
  WorkbenchPage(
      'reports-audit',
      'Governance & Audit',
      '治理与审计',
      'Review quality, retrieval, OCR, safety, governance reports, issues, and repair suggestions.',
      '查看质量、检索、OCR、安全和治理报告、问题与修复建议。',
      memberPageIds: [
        'reports-audit',
        'error-repair-center',
        'governance',
        'memory-center',
      ]),
  WorkbenchPage(
      'workspace',
      'Settings',
      '设置',
      'Manage workspace, models, providers, Redis, vector database, storage, and security authorization.',
      '管理工作区、模型、Provider、Redis、向量库、存储和安全授权。',
      memberPageIds: [
        'workspace',
        'vector-hub-provider-storage',
      ]),
];

// Legacy web/P1 routes remain covered by the Flutter source contract, but they
// are not mounted into the user-facing dashboard product flow.
const productFlowHiddenContractRouteIds = <String>[
  'operation-gate',
  'capability-matrix',
  'task-job-center',
];

class WorkbenchPage {
  const WorkbenchPage(this.id, this.enTitle, this.zhTitle, this.enDescription,
      this.zhDescription,
      {this.memberPageIds = const <String>[]});

  final String id;
  final String enTitle;
  final String zhTitle;
  final String enDescription;
  final String zhDescription;
  final List<String> memberPageIds;

  List<String> get pageIds => memberPageIds.isEmpty ? [id] : memberPageIds;

  String title(String localeCode, WorkbenchContracts _) {
    if (localeCode == 'zh-CN') {
      return zhTitle;
    }
    return enTitle;
  }

  String description(String localeCode) =>
      localeCode == 'zh-CN' ? zhDescription : enDescription;
}
