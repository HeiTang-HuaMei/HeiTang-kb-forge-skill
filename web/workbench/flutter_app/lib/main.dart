import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core_actions/core_action_panel.dart';
import 'core_actions/page_action_mapping.dart';
import 'core_actions/workbench_actions.dart';
import 'core_bridge/local_core_bridge.dart';
import 'contracts/workbench_contracts.dart';

void main() {
  runApp(const HeiTangWorkbenchApp());
}

const brandAssets = <String>[
  'assets/brand/black_cat_head.svg',
  'assets/brand/black_tiger_head.svg',
];

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

const pages = <WorkbenchPage>[
  WorkbenchPage('dashboard', 'Dashboard', '仪表盘', 'Operating snapshot across knowledge, review, jobs, agents, and exports.', '知识、复核、任务、Agent 与导出的运营总览。'),
  WorkbenchPage('workspace', 'Workspace', '工作空间', 'Local workspace paths, health, storage, registry, backup, restore, and privacy boundary.', '本地工作区路径、健康、存储、注册表、备份恢复与隐私边界。'),
  WorkbenchPage('operation-gate', 'Operation Gate', '运行门禁', 'P1 gate status, blocked reasons, and non-v4 boundary.', 'P1 门禁状态、阻塞原因与非 v4 边界。'),
  WorkbenchPage('capability-matrix', 'Capability Matrix', '能力矩阵', 'Core P1 capability areas and action/report/artifact coverage.', 'Core P1 能力域与 action/report/artifact 覆盖。'),
  WorkbenchPage('import-parsing', 'Import & Parsing', '导入与解析', 'Multi-format import, OCR, preprocessing, and parser quality.', '多格式导入、OCR、预处理与解析质量。'),
  WorkbenchPage('knowledge-package-management', 'Knowledge Package Management', '知识包管理', 'Browse trusted and draft knowledge packages with bound agents and policy state.', '浏览可信与草稿知识包，以及绑定 Agent 和策略状态。'),
  WorkbenchPage('retrieval-verification', 'Retrieval & Verification', '检索与验证', 'Query rewriting, retrieval planning, evidence selection, and validation.', '查询改写、检索规划、证据选择与知识准确性验证。'),
  WorkbenchPage('vector-hub-provider-storage', 'Vector Hub / Provider / Storage', '向量索引 / 提供方 / 存储', 'Provider validation, vector smoke, redaction, offline fallback, and storage profiles.', '提供方验证、向量冒烟、脱敏、离线回退与存储配置。'),
  WorkbenchPage('document-generation', 'Document generation', '文档生成', 'Preview generated document drafts and citation readiness.', '预览生成文档草稿与引用就绪状态。'),
  WorkbenchPage('skill-factory', 'Skill Factory', '技能工厂', 'Book, package, and template Skill generation with validation and runtime profiles.', '书籍、知识包与模板驱动 Skill 生成、验证与运行时配置。'),
  WorkbenchPage('agent-factory-runtime', 'Agent Factory & Runtime', 'Agent 工厂与运行', 'Manage standalone agents, KB-bound agents, model providers, and runtime traces.', '管理独立 Agent、KB-bound Agent、模型提供方与运行追踪。'),
  WorkbenchPage('memory-center', 'Memory Center', '记忆中心', 'Inspect private agent memory and workflow-shared memory isolation.', '查看 Agent 私有记忆与工作流共享记忆隔离。'),
  WorkbenchPage('task-job-center', 'Task / Job Center', '任务 / 作业中心', 'Stable task states, progress fields, retry, cancel, resume, reports, and artifacts.', '稳定任务状态、进度字段、重试、取消、恢复、报告与产物。'),
  WorkbenchPage('artifact-management', 'Artifact Management', '产物管理', 'Review KB packages, chunks, indexes, generated docs, Skill/Agent packages, traces, and proofs.', '查看知识包、分片、索引、生成文档、Skill/Agent 包、追踪与证明。'),
  WorkbenchPage('error-repair-center', 'Error Repair Center', '错误修复中心', 'Stable user-visible failure taxonomy and repair actions.', '稳定的用户可见错误分类与修复动作。'),
  WorkbenchPage('reports-audit', 'Reports & Audit', '报表与审计', 'Inspect registries, hardening, gates, proofs, and blockers.', '查看注册表、加固、门禁、证明与阻塞项。'),
  WorkbenchPage('governance', 'Governance', '治理与合规', 'Document ownership, stale/conflict controls, health, permissions, and review-required flows.', '文档归属、过期/冲突控制、健康状态、权限与复核流程。'),
  WorkbenchPage('template-library', 'Template Library', '模板库', 'P1 Workbench templates for product, publishing, enterprise, education, commerce, and operations.', '产品、出版、企业、教育、电商与运营场景的 P1 模板。'),
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
  const HeiTangWorkbenchApp({
    super.key,
    this.contracts,
    this.coreBridge = const LocalCoreBridge(),
    this.coreCli = 'heitang-kb-forge',
    this.coreWorkingDirectory = '.',
    this.coreWorkspace = '.',
    this.enableLocalCoreActions = true,
    this.isWebRuntime = kIsWeb,
  });

  final WorkbenchContracts? contracts;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;

  @override
  State<HeiTangWorkbenchApp> createState() => _HeiTangWorkbenchAppState();
}

class _HeiTangWorkbenchAppState extends State<HeiTangWorkbenchApp> {
  String localeCode = 'zh-CN';
  ThemeMode themeMode = ThemeMode.light;
  int selectedIndex = 0;
  late final Future<WorkbenchContracts> _contractsFuture = widget.contracts == null
      ? const WorkbenchContractLoader().loadFromAsset('assets/contracts/p1_core_contract_fixture.json').catchError((_) => sampleWorkbenchContracts)
      : Future<WorkbenchContracts>.value(widget.contracts);

  bool get isDark => themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
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
      home: FutureBuilder<WorkbenchContracts>(
        future: _contractsFuture,
        initialData: widget.contracts ?? sampleWorkbenchContracts,
        builder: (context, snapshot) => _WorkbenchScaffold(
          contracts: snapshot.data ?? sampleWorkbenchContracts,
          localeCode: localeCode,
          themeMode: themeMode,
          selectedIndex: selectedIndex,
          isDark: isDark,
          coreBridge: widget.coreBridge,
          coreCli: widget.coreCli,
          coreWorkingDirectory: widget.coreWorkingDirectory,
          coreWorkspace: widget.coreWorkspace,
          enableLocalCoreActions: widget.enableLocalCoreActions,
          isWebRuntime: widget.isWebRuntime,
          onThemeChanged: (value) => setState(() => themeMode = value),
          onLocaleChanged: (value) => setState(() => localeCode = value),
          onPageChanged: (index) => setState(() => selectedIndex = index),
        ),
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
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final int selectedIndex;
  final bool isTablet;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
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
            coreBridge: coreBridge,
            coreCli: coreCli,
            coreWorkingDirectory: coreWorkingDirectory,
            coreWorkspace: coreWorkspace,
            enableLocalCoreActions: enableLocalCoreActions,
            isWebRuntime: isWebRuntime,
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
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final int selectedIndex;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
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
        Expanded(
          child: _PageSurface(
            page: pages[selectedIndex],
            localeCode: localeCode,
            contracts: contracts,
            columns: 1,
            coreBridge: coreBridge,
            coreCli: coreCli,
            coreWorkingDirectory: coreWorkingDirectory,
            coreWorkspace: coreWorkspace,
            enableLocalCoreActions: enableLocalCoreActions,
            isWebRuntime: isWebRuntime,
          ),
        ),
      ],
    );
  }
}

class _PageSurface extends StatelessWidget {
  const _PageSurface({
    required this.page,
    required this.localeCode,
    required this.contracts,
    required this.columns,
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
  });

  final WorkbenchPage page;
  final String localeCode;
  final WorkbenchContracts contracts;
  final int columns;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;

  @override
  Widget build(BuildContext context) {
    final cards = _cardsFor(page.id, localeCode, contracts);
    final corePanels = <Widget>[];
    for (final action in coreActionsForPage(page.id, contracts)) {
      final request = coreRequestForAction(
        action: action,
        coreCli: coreCli,
        workingDirectory: coreWorkingDirectory,
        workspace: coreWorkspace,
      );
      corePanels.add(
        CoreActionPanel(
          action: action,
          request: request,
          coreBridge: coreBridge,
          isWebRuntime: isWebRuntime,
          enabled: enableLocalCoreActions,
          localeCode: localeCode,
        ),
      );
    }

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
              mainAxisExtent: columns == 1 ? 188 : 172,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) => _WorkbenchCard(
              title: cards[index].title,
              body: cards[index].body,
              localeCode: localeCode,
            ),
          ),
          if (corePanels.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Core Bridge', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (var index = 0; index < corePanels.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              corePanels[index],
            ],
          ],
        ],
      ),
    );
  }

  List<_CardCopy> _cardsFor(String id, String localeCode, WorkbenchContracts contracts) {
    final zh = localeCode == 'zh-CN';
    final view = _contractViewFor(page, contracts);
    final actions = _actionsForView(view, contracts);
    final reports = _reportsForView(view, contracts);
    final artifacts = _artifactsForView(view, contracts);
    final common = view.assetTypes.isEmpty ? (zh ? '合同样例' : 'Contract sample') : view.assetTypes.join(' · ');
    return [
      _CardCopy(zh ? 'Core 来源' : 'Core source', contracts.source.coreCommit),
      _CardCopy(zh ? '操作契约' : 'Action contracts', actions.isEmpty ? common : actions.map((action) => action.id).take(3).join(' · ')),
      _CardCopy(zh ? '报告契约' : 'Report contracts', reports.isEmpty ? '${contracts.status.reportCount}' : reports.map((report) => report.id).take(3).join(' · ')),
      _CardCopy(zh ? '产物契约' : 'Artifact contracts', artifacts.isEmpty ? '${contracts.status.assetCount}' : artifacts.map((artifact) => artifact.id).take(3).join(' · ')),
      _CardCopy(zh ? '任务状态' : 'Task statuses', contracts.taskSchema.statuses.join(' · ')),
      _CardCopy(zh ? '门禁状态' : 'Gate status', '${contracts.gate.status} · not_v4_0_workbench_rc=${contracts.gate.notV4WorkbenchRc}'),
      if (id == 'capability-matrix') _CardCopy(zh ? '能力域' : 'Capability areas', '${contracts.capabilities.areas.length}'),
      if (id == 'agent-factory-runtime') _CardCopy(zh ? 'Agent 模式' : 'Agent modes', contracts.agent.supportedModes.join(' · ')),
      if (id == 'error-repair-center') _CardCopy(zh ? '错误码' : 'Error codes', contracts.errors.errorStates.join(' · ')),
      if (id == 'template-library') _CardCopy(zh ? '模板' : 'Templates', contracts.templates.templates.map((template) => template.id).take(3).join(' · ')),
    ];
  }
}

class _WorkbenchScaffold extends StatelessWidget {
  const _WorkbenchScaffold({
    required this.contracts,
    required this.localeCode,
    required this.themeMode,
    required this.selectedIndex,
    required this.isDark,
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onPageChanged,
  });

  final WorkbenchContracts contracts;
  final String localeCode;
  final ThemeMode themeMode;
  final int selectedIndex;
  final bool isDark;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                onPressed: () => onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark),
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
                  onSelectionChanged: (value) => onLocaleChanged(value.first),
                ),
              ),
            ],
          ),
          body: isPhone
              ? _PhoneWorkbench(
                  localeCode: localeCode,
                  contracts: contracts,
                  selectedIndex: selectedIndex,
                  coreBridge: coreBridge,
                  coreCli: coreCli,
                  coreWorkingDirectory: coreWorkingDirectory,
                  coreWorkspace: coreWorkspace,
                  enableLocalCoreActions: enableLocalCoreActions,
                  isWebRuntime: isWebRuntime,
                  onPageChanged: onPageChanged,
                )
              : _DesktopWorkbench(
                  localeCode: localeCode,
                  contracts: contracts,
                  selectedIndex: selectedIndex,
                  isTablet: isTablet,
                  coreBridge: coreBridge,
                  coreCli: coreCli,
                  coreWorkingDirectory: coreWorkingDirectory,
                  coreWorkspace: coreWorkspace,
                  enableLocalCoreActions: enableLocalCoreActions,
                  isWebRuntime: isWebRuntime,
                  onPageChanged: onPageChanged,
                ),
        );
      },
    );
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
  return ContractView(id: page.id, label: page.enTitle, assetTypes: const [], corePageId: page.id, zhLabel: page.zhTitle);
}

List<ContractAction> _actionsForView(ContractView view, WorkbenchContracts contracts) {
  return contracts.actions.actions.where((action) => action.pageId == view.corePageId).toList(growable: false);
}

List<ContractReport> _reportsForView(ContractView view, WorkbenchContracts contracts) {
  return contracts.reports.reports.where((report) => report.pageId == view.corePageId).toList(growable: false);
}

List<ContractAsset> _artifactsForView(ContractView view, WorkbenchContracts contracts) {
  return contracts.assets.assets.where((asset) => asset.pageId == view.corePageId).toList(growable: false);
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
