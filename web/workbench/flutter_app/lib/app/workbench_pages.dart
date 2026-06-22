part of '../main.dart';

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '首页',
      'Current workspace, recent work, recent outputs, and the next real action.',
      '查看当前工作区、最近任务、最近成果和下一步真实动作。',
      memberPageIds: ['dashboard']),
  WorkbenchPage(
      'workbook',
      'Workbook',
      '工作区',
      'Create or switch the isolated workspace for materials, knowledge bases, skills, assistants, and memory.',
      '创建或切换资料、知识库、技能、助手和记忆隔离的工作区。',
      memberPageIds: ['workspace']),
  WorkbenchPage(
      'document-library',
      'Document Library',
      '文档库',
      'Add materials, organize them, and manage source documents for the current workspace.',
      '添加资料、整理资料，并管理当前工作区里的来源文档。',
      memberPageIds: [
        'import-parsing',
        'document-library',
      ]),
  WorkbenchPage(
      'knowledge-package-management',
      'Knowledge Base',
      '知识库',
      'Build, update, test, and trace knowledge bases from organized materials.',
      '从已整理资料生成、更新、测试和溯源知识库。',
      memberPageIds: [
        'knowledge-package-management',
        'vector-hub-provider-storage',
      ]),
  WorkbenchPage(
      'retrieval-verification',
      'Retrieval & Verification',
      '测试知识库',
      'Test knowledge bases with questions, citations, and saved validation records.',
      '用问题、引用和保存的测试记录检验知识库。',
      memberPageIds: ['retrieval-verification']),
  WorkbenchPage(
      'document-generation',
      'Document Generation',
      '文档生成',
      'Generate documents from a knowledge base, edit drafts, and export configured formats.',
      '从知识库生成文档、编辑草稿，并导出已配置格式。',
      memberPageIds: ['document-generation']),
  WorkbenchPage(
      'skill-factory',
      'Skill Builder',
      '技能生成',
      'Generate, check, edit, and export reusable skills from real knowledge bases.',
      '基于真实知识库生成、检查、编辑和导出可复用技能。',
      memberPageIds: ['skill-factory']),
  WorkbenchPage(
      'agent-factory-runtime',
      'Assistant Workbench',
      '我的助手',
      'Create assistants, start conversations, and let multiple assistants discuss together.',
      '创建助手、开始对话，并让多个助手一起讨论。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'artifact-center',
      'Artifact Center',
      '成果中心',
      'Browse and export generated documents, knowledge bases, skills, assistants, discussions, and usage records.',
      '查看并导出生成文档、知识库、技能、助手、讨论报告和使用记录。',
      memberPageIds: ['artifact-management']),
  WorkbenchPage(
      'reports-audit',
      'Usage Records',
      '使用记录',
      'Review generated records, failed tasks, and traceable work history.',
      '查看生成记录、失败任务和可追踪的使用历史。',
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
      'Manage workspace, model service, export settings, network authorization, storage, memory, and security.',
      '管理工作区、模型服务、导出设置、网络授权、存储、记忆和安全。',
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
