import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'contracts/workbench_contracts.dart';

void main() {
  runApp(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
}

const brandAssets = <String>[
  'assets/brand/black_cat_head.svg',
  'assets/brand/black_tiger_head.svg',
];

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

const pages = <WorkbenchPage>[
  WorkbenchPage('dashboard', 'Dashboard', '仪表盘', 'Operating snapshot across knowledge, review, jobs, agents, and exports.', '知识、复核、任务、Agent 与导出的运营总览。'),
  WorkbenchPage('file-upload', 'File upload', '文件上传', 'Mock upload intake with parser readiness and reserved ingestion controls.', '模拟上传入口，展示解析器状态与预留导入控制。'),
  WorkbenchPage('job-progress', 'Job progress', '任务进度', 'Track mock ingestion, review, and export jobs with stage-level status.', '跟踪模拟导入、复核和导出任务的阶段状态。'),
  WorkbenchPage('knowledge-base-list', 'Knowledge base list', '知识库列表', 'Browse trusted and draft knowledge bases with bound agents and policy state.', '浏览可信与草稿知识库，以及绑定 Agent 和策略状态。'),
  WorkbenchPage('knowledge-base-detail', 'Knowledge base detail', '知识库详情', 'Inspect one knowledge base contract, chunk state, and future API fields.', '查看单个知识库契约、分片状态和未来 API 字段。'),
  WorkbenchPage('review-queue', 'Review queue', '复核队列', 'Prioritize risky chunks and route corrected text through a mock review flow.', '按风险处理分片，并通过模拟复核流转校正文稿。'),
  WorkbenchPage('corrected-text-editor', 'Corrected text editor', '校正文稿编辑器', 'Edit mock corrected text without writing to any backend runtime.', '编辑模拟校正文稿，不写入任何后端运行时。'),
  WorkbenchPage('kb-query', 'KB query', '知识库查询', 'Ask a mock grounded query and preview citation-first answer behavior.', '发起模拟证据查询，预览引用优先的回答行为。'),
  WorkbenchPage('document-generation', 'Document generation', '文档生成', 'Preview generated document drafts and citation readiness.', '预览生成文档草稿与引用就绪状态。'),
  WorkbenchPage('agent-skill-management', 'Agent / Skill management', 'Agent / Skill 管理', 'Manage mock agents, skill tools, model providers, and KB bindings.', '管理模拟 Agent、Skill 工具、模型供应商与知识库绑定。'),
  WorkbenchPage('multi-agent-workflow', 'Multi-agent workflow', '多 Agent 工作流', 'Visualize workflow steps, shared memory, and handoff trace.', '展示工作流步骤、共享记忆与交接链路。'),
  WorkbenchPage('memory-scope-viewer', 'Memory scope viewer', '记忆范围查看器', 'Inspect private agent memory and workflow-shared memory isolation.', '查看 Agent 私有记忆与工作流共享记忆隔离。'),
  WorkbenchPage('settings', 'Settings', '设置', 'Configure mock providers, parser backend, answer policy, and memory policy.', '配置模拟供应商、解析后端、回答策略与记忆策略。'),
  WorkbenchPage('export-center', 'Export center', '导出中心', 'Review mock export items reserved for future package delivery.', '查看为未来包交付预留的模拟导出项。'),
];

class WorkbenchPage {
  const WorkbenchPage(this.id, this.enTitle, this.zhTitle, this.enDescription, this.zhDescription);

  final String id;
  final String enTitle;
  final String zhTitle;
  final String enDescription;
  final String zhDescription;

  String title(String localeCode, WorkbenchContracts contracts) {
    if (localeCode == 'zh-CN') {
      return zhTitle;
    }
    return _contractView(contracts)?.label ?? enTitle;
  }

  String description(String localeCode) => localeCode == 'zh-CN' ? zhDescription : enDescription;

  ContractView? _contractView(WorkbenchContracts contracts) {
    for (final view in contracts.navigation.views) {
      if (view.id == id) {
        return view;
      }
    }
    return null;
  }
}

class HeiTangWorkbenchApp extends StatefulWidget {
  const HeiTangWorkbenchApp({super.key, this.contracts});

  final WorkbenchContracts? contracts;

  @override
  State<HeiTangWorkbenchApp> createState() => _HeiTangWorkbenchAppState();
}

class _HeiTangWorkbenchAppState extends State<HeiTangWorkbenchApp> {
  String localeCode = 'zh-CN';
  ThemeMode themeMode = ThemeMode.light;
  int selectedIndex = 0;

  bool get isDark => themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final contracts = widget.contracts ?? sampleWorkbenchContracts;

    return MaterialApp(
      title: 'HeiTang Knowledge Workbench',
      debugShowCheckedModeBanner: false,
      locale: localeCode == 'zh-CN' ? const Locale('zh', 'CN') : const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      themeMode: themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = constraints.maxWidth < 720;
          final isTablet = constraints.maxWidth >= 720 && constraints.maxWidth < 1040;

          return Scaffold(
            appBar: AppBar(
              titleSpacing: 16,
              title: _BrandHeader(localeCode: localeCode, compact: isPhone),
              actions: [
                IconButton(
                  tooltip: isDark ? 'Light mode' : 'Dark mode',
                  onPressed: () => setState(() => themeMode = isDark ? ThemeMode.light : ThemeMode.dark),
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 12),
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'zh-CN', label: Text('中')),
                      ButtonSegment(value: 'en-US', label: Text('EN')),
                    ],
                    selected: {localeCode},
                    onSelectionChanged: (value) => setState(() => localeCode = value.first),
                  ),
                ),
              ],
            ),
            body: isPhone ? _PhoneWorkbench(
              localeCode: localeCode,
              contracts: contracts,
              selectedIndex: selectedIndex,
              onPageChanged: (index) => setState(() => selectedIndex = index),
            ) : _DesktopWorkbench(
              localeCode: localeCode,
              contracts: contracts,
              selectedIndex: selectedIndex,
              isTablet: isTablet,
              onPageChanged: (index) => setState(() => selectedIndex = index),
            ),
          );
        },
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDarkTheme = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: isDarkTheme ? const Color(0xfff7f7f5) : const Color(0xff111111),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors.copyWith(
        primary: isDarkTheme ? const Color(0xfff7f7f5) : const Color(0xff111111),
        surface: isDarkTheme ? const Color(0xff181818) : const Color(0xffffffff),
      ),
      scaffoldBackgroundColor: isDarkTheme ? const Color(0xff0f0f0f) : const Color(0xfff4f4f2),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.localeCode, required this.compact});

  final String localeCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          const _MascotBadge(label: '猫'),
          const SizedBox(width: 4),
          const _MascotBadge(label: '虎'),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localeCode == 'zh-CN' ? '黑糖 HeiTang' : 'HeiTang', style: Theme.of(context).textTheme.labelLarge),
              Text('Knowledge Workbench', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MascotBadge extends StatelessWidget {
  const _MascotBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final onColor = Theme.of(context).colorScheme.onPrimary;
    return CircleAvatar(
      radius: 15,
      backgroundColor: color,
      child: Text(label, style: TextStyle(color: onColor, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _DesktopWorkbench extends StatelessWidget {
  const _DesktopWorkbench({
    required this.localeCode,
    required this.contracts,
    required this.selectedIndex,
    required this.isTablet,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final int selectedIndex;
  final bool isTablet;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isTablet ? 220.0 : 280.0;

    return Row(
      children: [
        SizedBox(
          width: sidebarWidth,
          child: _WorkbenchSidebar(
            localeCode: localeCode,
            contracts: contracts,
            selectedIndex: selectedIndex,
            onPageChanged: onPageChanged,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _PageSurface(
            page: pages[selectedIndex],
            localeCode: localeCode,
            contracts: contracts,
            columns: isTablet ? 2 : 3,
          ),
        ),
      ],
    );
  }
}

class _WorkbenchSidebar extends StatelessWidget {
  const _WorkbenchSidebar({
    required this.localeCode,
    required this.contracts,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        itemCount: pages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final page = pages[index];
          final view = _contractViewFor(page, contracts);
          final selected = index == selectedIndex;

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onPageChanged(index),
            child: ListTile(
              dense: true,
              selected: selected,
              selectedColor: colors.onPrimary,
              selectedTileColor: colors.primary,
              leading: Icon(selected ? Icons.circle : Icons.radio_button_unchecked, size: 16),
              title: Text(page.title(localeCode, contracts), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(view.assetTypes.isEmpty ? page.id : view.assetTypes.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }
}

class _PhoneWorkbench extends StatelessWidget {
  const _PhoneWorkbench({
    required this.localeCode,
    required this.contracts,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<int>(
            initialValue: selectedIndex,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: localeCode == 'zh-CN' ? '页面' : 'Page',
              border: const OutlineInputBorder(),
            ),
            items: [
              for (var index = 0; index < pages.length; index++)
                DropdownMenuItem(
                  value: index,
                  child: Text(pages[index].title(localeCode, contracts), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onPageChanged(value);
              }
            },
          ),
        ),
        Expanded(child: _PageSurface(page: pages[selectedIndex], localeCode: localeCode, contracts: contracts, columns: 1)),
      ],
    );
  }
}

class _PageSurface extends StatelessWidget {
  const _PageSurface({required this.page, required this.localeCode, required this.contracts, required this.columns});

  final WorkbenchPage page;
  final String localeCode;
  final WorkbenchContracts contracts;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final cards = _cardsFor(page.id, localeCode, contracts);

    return SingleChildScrollView(
      padding: EdgeInsets.all(columns == 1 ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(page.title(localeCode, contracts), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(page.description(localeCode), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: columns == 1 ? 156 : 168,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) => _WorkbenchCard(
              title: cards[index].title,
              body: cards[index].body,
              localeCode: localeCode,
            ),
          ),
        ],
      ),
    );
  }

  List<_CardCopy> _cardsFor(String id, String localeCode, WorkbenchContracts contracts) {
    final zh = localeCode == 'zh-CN';
    final view = _contractViewFor(page, contracts);
    final action = _actionFor(id, contracts);
    final common = view.assetTypes.isEmpty ? (zh ? '合同样例' : 'Contract sample') : view.assetTypes.join(' · ');
    final map = <String, List<_CardCopy>>{
      'dashboard': [
        _CardCopy(zh ? '合同状态' : 'Contract status', contracts.status.status),
        _CardCopy(zh ? '资产' : 'Assets', '${contracts.status.assetCount}'),
        _CardCopy(zh ? '报告' : 'Reports', '${contracts.status.reportCount}'),
      ],
      'file-upload': [
        _CardCopy(zh ? '资产类型' : 'Asset types', common),
        _CardCopy(zh ? '构建动作' : 'Build action', _commandOrFallback(action, 'build')),
      ],
      'job-progress': [
        _CardCopy(zh ? '状态徽标' : 'Status badges', contracts.errors.statusBadges.join(' · ')),
        _CardCopy(zh ? '合同文件' : 'Contract files', '${contracts.manifest.outputFiles.length}'),
      ],
      'knowledge-base-list': [
        _CardCopy(zh ? '知识包资产' : 'Knowledge package assets', _assetCount(contracts, 'knowledge_package')),
        _CardCopy(zh ? '包存储' : 'Package storage', _storageArea(contracts, 'package_storage')),
      ],
      'knowledge-base-detail': [
        _CardCopy(zh ? '包大小' : 'Package size', '${contracts.storage.sizes['package_size_bytes'] ?? 0} B'),
        _CardCopy(zh ? '索引大小' : 'Index size', '${contracts.storage.sizes['index_size_bytes'] ?? 0} B'),
      ],
      'review-queue': [
        _CardCopy(zh ? '空状态' : 'Empty states', contracts.errors.emptyStates.join(' · ')),
        _CardCopy(zh ? '错误状态' : 'Error states', contracts.errors.errorStates.join(' · ')),
      ],
      'corrected-text-editor': [
        _CardCopy(zh ? '校验状态' : 'Validation states', contracts.agent.validationStates.join(' · ')),
        _CardCopy(zh ? '错误合同' : 'Error contract', contracts.errors.errorStates.join(' · ')),
      ],
      'kb-query': [
        _CardCopy(zh ? '绑定模式' : 'Bound mode', contracts.agent.supportedModes.contains('kb_bound') ? 'kb_bound' : 'unavailable'),
        _CardCopy(zh ? '检索字段' : 'Retrieval fields', contracts.agent.kbBoundRequired.join(' · ')),
      ],
      'document-generation': [
        _CardCopy(zh ? '生成动作' : 'Generation action', _commandOrFallback(_actionById(contracts, 'generate_documents'), 'generate-documents')),
        _CardCopy(zh ? '文档报告' : 'Document report', 'generated_file_report.json'),
      ],
      'agent-skill-management': [
        _CardCopy(zh ? 'Agent 模式' : 'Agent modes', contracts.agent.supportedModes.join(' · ')),
        _CardCopy(zh ? 'Standalone 必填' : 'Standalone required', contracts.agent.standaloneRequired.join(' · ')),
        _CardCopy(zh ? 'KB-bound 必填' : 'KB-bound required', contracts.agent.kbBoundRequired.join(' · ')),
      ],
      'multi-agent-workflow': [
        _CardCopy(zh ? '母子绑定' : 'Parent-child binding', contracts.hierarchy.bindingFields.join(' · ')),
        _CardCopy(zh ? '子 Agent 模式' : 'Child agent modes', contracts.hierarchy.roles.join(' · ')),
        _CardCopy(zh ? 'Trace' : 'Trace', contracts.hierarchy.traceFiles.join(' · ')),
      ],
      'memory-scope-viewer': [
        _CardCopy(zh ? '私有记忆' : 'Private memory', '${contracts.memory.policy['child_private_memory_default']}'),
        _CardCopy(zh ? '共享记忆' : 'Shared memory', '${contracts.memory.policy['workflow_shared_memory']}'),
        _CardCopy(zh ? '写回' : 'Writeback', contracts.memory.writebackActions.join(' · ')),
      ],
      'settings': [
        _CardCopy(zh ? '存储后端' : 'Storage backend', contracts.storage.backend),
        _CardCopy(zh ? '存储区域' : 'Storage areas', contracts.storage.storageAreas.keys.join(' · ')),
        _CardCopy(zh ? '备份导出' : 'Backup/export', contracts.storage.backupExportStatus),
      ],
      'export-center': [
        _CardCopy(zh ? '导出状态' : 'Export status', contracts.status.backupExportStatus),
        _CardCopy(zh ? '清理建议' : 'Cleanup suggestions', contracts.storage.cleanupSuggestions.isEmpty ? (zh ? '无' : 'None') : contracts.storage.cleanupSuggestions.join(' · ')),
      ],
    };
    return map[id] ?? [_CardCopy(page.title(localeCode, contracts), common)];
  }
}

class _CardCopy {
  const _CardCopy(this.title, this.body);

  final String title;
  final String body;
}

ContractView _contractViewFor(WorkbenchPage page, WorkbenchContracts contracts) {
  for (final view in contracts.navigation.views) {
    if (view.id == page.id) {
      return view;
    }
  }
  return ContractView(id: page.id, label: page.enTitle, assetTypes: const []);
}

ContractAction? _actionFor(String pageId, WorkbenchContracts contracts) {
  final actionMap = <String, String>{
    'file-upload': 'build_package',
    'document-generation': 'generate_documents',
    'agent-skill-management': 'create_standalone_agent',
    'multi-agent-workflow': 'configure_agent_hierarchy',
    'memory-scope-viewer': 'queue_memory_writeback',
    'settings': 'inspect_storage_status',
  };
  final actionId = actionMap[pageId];
  return actionId == null ? null : _actionById(contracts, actionId);
}

ContractAction? _actionById(WorkbenchContracts contracts, String id) {
  for (final action in contracts.actions.actions) {
    if (action.id == id) {
      return action;
    }
  }
  return null;
}

String _commandOrFallback(ContractAction? action, String fallback) => action?.command.isNotEmpty == true ? action!.command : fallback;

String _assetCount(WorkbenchContracts contracts, String type) => '${contracts.assets.assets.where((asset) => asset.type == type).length}';

String _storageArea(WorkbenchContracts contracts, String key) {
  final area = contracts.storage.storageAreas[key];
  if (area is Map<String, dynamic>) {
    return '${area['backend'] ?? contracts.storage.backend}';
  }
  return contracts.storage.backend;
}

class _WorkbenchCard extends StatelessWidget {
  const _WorkbenchCard({required this.title, required this.body, required this.localeCode});

  final String title;
  final String body;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
            FilledButton(onPressed: () {}, child: Text(localeCode == 'zh-CN' ? '打开' : 'Open')),
          ],
        ),
      ),
    );
  }
}
