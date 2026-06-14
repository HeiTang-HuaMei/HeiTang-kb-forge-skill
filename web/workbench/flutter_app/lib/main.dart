import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core_actions/core_action_panel.dart';
import 'core_actions/page_action_mapping.dart';
import 'core_actions/workbench_actions.dart';
import 'core_bridge/local_core_bridge.dart';
import 'contracts/workbench_contracts.dart';
import 'backend_evidence/parser_backend_dashboard.dart';
import 'skill_factory/skill_factory_workflow.dart';
import 'workbench/task_workbench.dart';

void main() {
  runApp(const HeiTangWorkbenchApp());
}

const brandAssets = <String>[
  'assets/brand/black_cat_head.svg',
  'assets/brand/black_tiger_head.svg',
];

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Workbench',
      '工作台',
      'Task-card workflow across local input, progress, outputs, evidence, and recovery.',
      '以任务卡组织本地输入、进度、输出、证据与恢复动作。',
      memberPageIds: [
        'dashboard',
        'operation-gate',
        'capability-matrix',
        'task-job-center',
      ]),
  WorkbenchPage(
      'import-parsing',
      'Import & Parsing',
      '导入与解析',
      'Local file import, parser boundaries, preprocessing, and quality evidence.',
      '本地文件导入、解析边界、预处理与质量证据。',
      memberPageIds: ['import-parsing']),
  WorkbenchPage(
      'knowledge-package-management',
      'Knowledge Build',
      '知识构建',
      'Knowledge splitting, package drafts, retrieval evidence, and local validation boundaries.',
      '知识切分、知识包草稿、检索证据与本地验证边界。',
      memberPageIds: [
        'knowledge-package-management',
        'retrieval-verification',
        'vector-hub-provider-storage',
        'document-generation',
      ]),
  WorkbenchPage(
      'skill-factory',
      'Skill Generation',
      'Skill 生成',
      'Inspect the Knowledge Package to Methodology to Skill Suite evidence, governance reports, and export boundary.',
      '查看知识包到方法论再到 Skill Suite 的证据、治理报告与导出边界。',
      memberPageIds: ['skill-factory']),
  WorkbenchPage(
      'agent-factory-runtime',
      'Agent Package',
      'Agent 包生成',
      'Generate Agent package drafts without claiming executable Agent or Memory Runtime.',
      '生成 Agent 包草稿，不宣称可执行 Agent Runtime 或 Memory Runtime。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'reports-audit',
      'Validation & Reports',
      '验证与报告',
      'Inspect manifests, reports, failure evidence, and Campaign 4/5 boundaries.',
      '查看 manifest、报告、失败证据与 Campaign 4/5 边界。',
      memberPageIds: [
        'reports-audit',
        'artifact-management',
        'error-repair-center',
        'governance',
        'memory-center',
      ]),
  WorkbenchPage(
      'workspace',
      'Settings & Boundaries',
      '设置与边界',
      'Local workspace paths, Core availability, optional dependencies, and blocked runtime boundaries.',
      '本地工作区路径、Core 可用性、可选依赖与被阻塞的运行时边界。',
      memberPageIds: ['workspace', 'template-library']),
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

class HeiTangWorkbenchApp extends StatefulWidget {
  const HeiTangWorkbenchApp({
    super.key,
    this.contracts,
    this.workflowEvidence,
    this.workflowV2Evidence,
    this.externalCapabilities,
    this.parserBackends,
    this.skillGovernanceReport,
    this.methodologyMap,
    this.skillSuiteWorkflow,
    this.coreBridge = const LocalCoreBridge(),
    this.coreCli = 'heitang-kb-forge',
    this.coreWorkingDirectory = '.',
    this.coreWorkspace = '.',
    this.enableLocalCoreActions = true,
    this.isWebRuntime = kIsWeb,
    this.initialSelectedIndex = 0,
  });

  final WorkbenchContracts? contracts;
  final P1WorkflowEvidence? workflowEvidence;
  final P1WorkflowEvidence? workflowV2Evidence;
  final ExternalCapabilityRegistry? externalCapabilities;
  final ParserBackendMatrix? parserBackends;
  final Map<String, dynamic>? skillGovernanceReport;
  final Map<String, dynamic>? methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final int initialSelectedIndex;

  @override
  State<HeiTangWorkbenchApp> createState() => _HeiTangWorkbenchAppState();
}

class _HeiTangWorkbenchAppState extends State<HeiTangWorkbenchApp> {
  String localeCode = 'zh-CN';
  ThemeMode themeMode = ThemeMode.light;
  late int selectedIndex = widget.initialSelectedIndex;
  late final Future<WorkbenchContracts> _contractsFuture =
      widget.contracts == null
          ? const WorkbenchContractLoader()
              .loadFromAsset('assets/contracts/p1_core_contract_fixture.json')
              .catchError((_) => sampleWorkbenchContracts)
          : Future<WorkbenchContracts>.value(widget.contracts);
  late final Future<P1WorkflowEvidence> _workflowEvidenceFuture = widget
              .workflowEvidence ==
          null
      ? const P1WorkflowEvidenceLoader()
          .loadFromAsset('assets/workflows/p1_real_workflow_v1_evidence.json')
          .catchError((_) => sampleP1WorkflowEvidence)
      : Future<P1WorkflowEvidence>.value(widget.workflowEvidence);
  late final Future<P1WorkflowEvidence> _workflowV2EvidenceFuture = widget
              .workflowV2Evidence ==
          null
      ? const P1WorkflowEvidenceLoader()
          .loadFromAsset('assets/workflows/p1_real_workflow_v2_evidence.json')
          .catchError((_) => sampleP1WorkflowV2Evidence)
      : Future<P1WorkflowEvidence>.value(widget.workflowV2Evidence);
  late final Future<ExternalCapabilityRegistry> _externalCapabilitiesFuture =
      widget.externalCapabilities == null
          ? const ExternalCapabilityLoader()
              .loadFromAsset(
                  'assets/external/external_capability_registry.json')
              .catchError((_) => sampleExternalCapabilityRegistry)
          : Future<ExternalCapabilityRegistry>.value(
              widget.externalCapabilities);
  late final Future<ParserBackendMatrix> _parserBackendsFuture = widget
              .parserBackends ==
          null
      ? const ParserBackendMatrixLoader()
          .loadFromAsset('assets/parser_backends/parser_backend_matrix.json')
          .catchError((_) => sampleParserBackendMatrix)
      : Future<ParserBackendMatrix>.value(widget.parserBackends);
  late final Future<Map<String, dynamic>> _skillGovernanceReportFuture =
      Future<Map<String, dynamic>>.value(
          widget.skillGovernanceReport ?? sampleSkillGovernanceReport);

  bool get isDark => themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeiTang Knowledge Workbench',
      debugShowCheckedModeBanner: false,
      locale: localeCode == 'zh-CN'
          ? const Locale('zh', 'CN')
          : const Locale('en', 'US'),
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
        builder: (context, contractsSnapshot) =>
            FutureBuilder<P1WorkflowEvidence>(
          future: _workflowEvidenceFuture,
          initialData: widget.workflowEvidence ?? sampleP1WorkflowEvidence,
          builder: (context, evidenceSnapshot) =>
              FutureBuilder<P1WorkflowEvidence>(
            future: _workflowV2EvidenceFuture,
            initialData:
                widget.workflowV2Evidence ?? sampleP1WorkflowV2Evidence,
            builder: (context, v2Snapshot) =>
                FutureBuilder<ExternalCapabilityRegistry>(
              future: _externalCapabilitiesFuture,
              initialData: widget.externalCapabilities ??
                  sampleExternalCapabilityRegistry,
              builder: (context, externalSnapshot) =>
                  FutureBuilder<ParserBackendMatrix>(
                future: _parserBackendsFuture,
                initialData: widget.parserBackends ?? sampleParserBackendMatrix,
                builder: (context, parserSnapshot) =>
                    FutureBuilder<Map<String, dynamic>>(
                  future: _skillGovernanceReportFuture,
                  initialData: widget.skillGovernanceReport ??
                      sampleSkillGovernanceReport,
                  builder: (context, skillGovernanceSnapshot) =>
                      _WorkbenchScaffold(
                    contracts:
                        contractsSnapshot.data ?? sampleWorkbenchContracts,
                    workflowEvidence:
                        evidenceSnapshot.data ?? sampleP1WorkflowEvidence,
                    workflowV2Evidence:
                        v2Snapshot.data ?? sampleP1WorkflowV2Evidence,
                    externalCapabilities: externalSnapshot.data ??
                        sampleExternalCapabilityRegistry,
                    parserBackends:
                        parserSnapshot.data ?? sampleParserBackendMatrix,
                    skillGovernanceReport: skillGovernanceSnapshot.data ??
                        sampleSkillGovernanceReport,
                    methodologyMap:
                        widget.methodologyMap ?? sampleMethodologyMap,
                    skillSuiteWorkflow: widget.skillSuiteWorkflow,
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
                    onThemeChanged: (value) =>
                        setState(() => themeMode = value),
                    onLocaleChanged: (value) =>
                        setState(() => localeCode = value),
                    onPageChanged: (index) =>
                        setState(() => selectedIndex = index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDarkTheme = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor:
          isDarkTheme ? const Color(0xfff7f7f5) : const Color(0xff111111),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors.copyWith(
        primary:
            isDarkTheme ? const Color(0xfff7f7f5) : const Color(0xff111111),
        surface:
            isDarkTheme ? const Color(0xff181818) : const Color(0xffffffff),
      ),
      scaffoldBackgroundColor:
          isDarkTheme ? const Color(0xff0f0f0f) : const Color(0xfff4f4f2),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
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
              Text(localeCode == 'zh-CN' ? '黑糖 HeiTang' : 'HeiTang',
                  style: Theme.of(context).textTheme.labelLarge),
              Text('Knowledge Workbench',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
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
      child: Text(label,
          style: TextStyle(
              color: onColor, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _DesktopWorkbench extends StatelessWidget {
  const _DesktopWorkbench({
    required this.localeCode,
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
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
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
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
            workflowEvidence: workflowEvidence,
            workflowV2Evidence: workflowV2Evidence,
            externalCapabilities: externalCapabilities,
            parserBackends: parserBackends,
            skillGovernanceReport: skillGovernanceReport,
            methodologyMap: methodologyMap,
            skillSuiteWorkflow: skillSuiteWorkflow,
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
              leading: Icon(
                  selected ? Icons.circle : Icons.radio_button_unchecked,
                  size: 16),
              title: Text(page.title(localeCode, contracts),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  view.assetTypes.isEmpty
                      ? page.id
                      : view.assetTypes.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
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
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
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
                  child: Text(pages[index].title(localeCode, contracts),
                      overflow: TextOverflow.ellipsis),
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
            workflowEvidence: workflowEvidence,
            workflowV2Evidence: workflowV2Evidence,
            externalCapabilities: externalCapabilities,
            parserBackends: parserBackends,
            skillGovernanceReport: skillGovernanceReport,
            methodologyMap: methodologyMap,
            skillSuiteWorkflow: skillSuiteWorkflow,
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
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
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
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final int columns;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;

  @override
  Widget build(BuildContext context) {
    final isSkillFactory = page.id == 'skill-factory';
    final cards = isSkillFactory
        ? const <_CardCopy>[]
        : _cardsFor(
            page.id,
            localeCode,
            contracts,
            workflowEvidence,
            workflowV2Evidence,
            externalCapabilities,
            parserBackends,
            skillGovernanceReport,
            methodologyMap);
    final corePanels = <Widget>[];
    final actionById = <String, ContractAction>{};
    for (final pageId in page.pageIds) {
      for (final action in coreActionsForPage(pageId, contracts)) {
        actionById[action.id] = action;
      }
    }
    final pageActions = actionById.values.where(
      (action) =>
          page.id != 'dashboard' &&
          (page.id != 'agent-factory-runtime' ||
              const {
                'standalone_agent_generation',
                'kb_bound_agent_generation',
              }.contains(action.id)),
    );
    for (final action in pageActions) {
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
          Text(page.title(localeCode, contracts),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(page.description(localeCode),
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          if (page.id == 'dashboard') ...[
            TaskWorkbenchSurface(
              localeCode: localeCode,
              workspace: coreWorkspace,
            ),
            const SizedBox(height: 20),
          ],
          if (isSkillFactory)
            SkillFactoryWorkflowSurface(
              localeCode: localeCode,
              workflow: skillSuiteWorkflow,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: columns == 1 ? 204 : 188,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => _WorkbenchCard(
                title: cards[index].title,
                body: cards[index].body,
                localeCode: localeCode,
              ),
            ),
          if (page.pageIds.any(_showsParserBackends)) ...[
            const SizedBox(height: 20),
            ParserBackendEvidenceDashboard(
              matrix: parserBackends,
              localeCode: localeCode,
            ),
          ],
          if (corePanels.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Core Bridge',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
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

  List<_CardCopy> _cardsFor(
    String id,
    String localeCode,
    WorkbenchContracts contracts,
    P1WorkflowEvidence workflowEvidence,
    P1WorkflowEvidence workflowV2Evidence,
    ExternalCapabilityRegistry externalCapabilities,
    ParserBackendMatrix parserBackends,
    Map<String, dynamic> skillGovernanceReport,
    Map<String, dynamic> methodologyMap,
  ) {
    final zh = localeCode == 'zh-CN';
    final views = page.pageIds
        .map((pageId) => _contractViewForId(pageId, contracts))
        .toList(growable: false);
    final actions = views
        .expand((view) => _actionsForView(view, contracts))
        .toList(growable: false);
    final reports = views
        .expand((view) => _reportsForView(view, contracts))
        .toList(growable: false);
    final artifacts = views
        .expand((view) => _artifactsForView(view, contracts))
        .toList(growable: false);
    final common = views.expand((view) => view.assetTypes).isEmpty
        ? (zh ? '合同样例' : 'Contract sample')
        : views.expand((view) => view.assetTypes).join(' · ');
    final externalProjects = views
        .map((view) => view.corePageId)
        .expand(externalCapabilities.projectsForCorePage)
        .fold(<String, ExternalCapabilityProject>{}, (projects, project) {
          projects[project.projectId] = project;
          return projects;
        })
        .values
        .toList(growable: false);
    final providerProjects = externalProjects
        .where((project) =>
            project.contractStatus.contains('provider_required') ||
            project.requiresApiKey ||
            project.requiresNetwork ||
            project.requiresExternalRuntime)
        .toList(growable: false);
    final templateProjects = externalProjects
        .where(
            (project) => project.contractStatus.contains('template_reference'))
        .toList(growable: false);
    final governanceChecks =
        (skillGovernanceReport['checks'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final governanceUiContract = (skillGovernanceReport['ui_contract'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final diffCheck = (governanceChecks['diff_comparison'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final installabilityCheck =
        (governanceChecks['installability'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final validationCheck =
        (governanceChecks['validation'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final tokenBudgetCheck =
        (governanceChecks['token_budget'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final methodologyModules =
        (methodologyMap['methodology_modules'] as List?) ?? const <dynamic>[];
    final firstMethodologyModule = methodologyModules.isEmpty
        ? const <String, dynamic>{}
        : (methodologyModules.first as Map).cast<String, dynamic>();
    final methodologyEvidence =
        (methodologyMap['source_evidence'] as List?) ?? const <dynamic>[];
    final methodologyRisks =
        (methodologyMap['risk_flags'] as List?) ?? const <dynamic>[];
    final unsupportedClaims =
        (methodologyMap['unsupported_claim_detection'] as Map?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return [
      _CardCopy(zh ? 'Core 来源' : 'Core source', contracts.source.coreCommit),
      _CardCopy(
          zh ? '操作契约' : 'Action contracts',
          actions.isEmpty
              ? common
              : actions.map((action) => action.id).take(3).join(' · ')),
      _CardCopy(
          zh ? '报告契约' : 'Report contracts',
          reports.isEmpty
              ? '${contracts.status.reportCount}'
              : reports.map((report) => report.id).take(3).join(' · ')),
      _CardCopy(
          zh ? '产物契约' : 'Artifact contracts',
          artifacts.isEmpty
              ? '${contracts.status.assetCount}'
              : artifacts.map((artifact) => artifact.id).take(3).join(' · ')),
      _CardCopy(zh ? '任务状态' : 'Task statuses',
          contracts.taskSchema.statuses.join(' · ')),
      _CardCopy(zh ? '门禁状态' : 'Gate status',
          '${contracts.gate.status} · not_v4_0_workbench_rc=${contracts.gate.notV4WorkbenchRc}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? 'P1-RWF-V1 状态' : 'P1-RWF-V1 status',
            '${workflowEvidence.status} · full_gate=${workflowEvidence.fullGateStatus}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? '命令漂移' : 'Command drift',
            'drift_count=${workflowEvidence.driftCount} · fixture_only_real=${workflowEvidence.fixtureOnlyCountedAsReal}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? '黄金工作流' : 'Golden workflows',
            '${workflowEvidence.workflowCount} · ${workflowEvidence.evidenceLevelCounts.entries.map((entry) => '${entry.key}:${entry.value}').join(' · ')}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? '剩余阻塞' : 'Remaining blockers',
            workflowEvidence.remainingBlockers.take(2).join(' · ')),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? 'P1-RWF-V2 状态' : 'P1-RWF-V2 status',
            '${workflowV2Evidence.status} · full_gate=${workflowV2Evidence.fullGateStatus}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? '57 action 矩阵' : '57 action matrix',
            '${workflowV2Evidence.passedActionCount}/${workflowV2Evidence.executionTargetCount} passed · failed=${workflowV2Evidence.failedActionCount}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? '产物 / 报告断言' : 'Artifact / report assertions',
            'artifact=${workflowV2Evidence.artifactAssertionStatus} · report=${workflowV2Evidence.reportAssertionStatus} · error=${workflowV2Evidence.errorBoundaryStatus}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? '用户路径闭环' : 'User path closure',
            '${workflowV2Evidence.userPathClosureStatus} · ${workflowV2Evidence.userPathPassedCount}/${workflowV2Evidence.userPathCount} paths'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? 'UI 门禁' : 'UI gate',
            'ui_full_operation_pending=${workflowV2Evidence.uiFullOperationPending} · rc_candidate=${workflowV2Evidence.readyForV4RcCandidate} · ready_for_v4_rc=${workflowV2Evidence.readyForV4Rc}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(
            zh ? 'Provider/secret blocked' : 'Provider/secret blocked',
            workflowV2Evidence.blockedActions
                .map((action) => '${action.actionId}:${action.classification}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.any(_showsExternalCapabilities))
        _CardCopy(zh ? 'S/A 外部能力' : 'S/A external capabilities',
            'S=${externalCapabilities.sProjectCount} · A=${externalCapabilities.aProjectCount} · anchors=${externalCapabilities.internalCapabilityAnchorCount}'),
      if (page.pageIds.any(_showsExternalCapabilities))
        _CardCopy(zh ? 'Adapter 边界' : 'Adapter boundary',
            'planned=${externalCapabilities.plannedAdapterCount} · future=${externalCapabilities.futureAdapterCount} · ready=false'),
      if (page.pageIds.any(_showsExternalCapabilities))
        _CardCopy(zh ? 'Provider 边界' : 'Provider boundary',
            'provider_required=${externalCapabilities.providerRequiredCount} · local_ready=false'),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(zh ? 'Parser Backend Matrix' : 'Parser Backend Matrix',
            '${parserBackends.releaseVersion} · ${parserBackends.backends.length} backends · static_runtime=${parserBackends.staticWorkbenchRuntimeExecutionClaimed}'),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Status Detail' : 'Backend Status Detail',
            parserBackends.backends
                .map((backend) => '${backend.backendId}:${backend.status}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Install Mode' : 'Backend Install Mode',
            parserBackends.backends
                .map((backend) =>
                    '${backend.backendId}:${backend.optionalExtra ?? backend.dependencyMode}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Last Acceptance' : 'Backend Last Acceptance',
            parserBackends.backends
                .map((backend) =>
                    '${backend.backendId}:dep=${backend.dependencyAvailable},run=${backend.runtimeInvoked}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh
                ? 'Backend Capability Boundaries'
                : 'Backend Capability Boundaries',
            parserBackends.backends
                .map((backend) =>
                    '${backend.backendId}:${backend.validatedStableSurface.join('/')}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Known Limitations' : 'Backend Known Limitations',
            '${parserBackends.backend('unstructured')?.knownLimitations.first ?? 'limited_surface'} · default_heavy_deps=${parserBackends.defaultHeavyDependenciesBundled}'),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(zh ? 'Backend Evidence Link' : 'Backend Evidence Link',
            '${parserBackends.acceptanceReportPath} · ${parserBackends.knownLimitationReportPath}'),
      if (_showsParserBackends(id))
        _CardCopy(
            zh ? 'Optional Dependency Reason' : 'Optional Dependency Reason',
            'optional_gated=${parserBackends.optionalDependencyGatedCount} · no_static_execution=${parserBackends.backends.every((backend) => !backend.staticWorkbenchExecutable)}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(zh ? 'Skill Governance Report' : 'Skill Governance Report',
            '${skillGovernanceReport['skill_name'] ?? 'unknown'} · status=${skillGovernanceReport['status']} · release_ready=${skillGovernanceReport['release_ready']}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(zh ? 'Diff baseline' : 'Diff baseline',
            'diff=${diffCheck['status']} · baseline=${diffCheck['baseline_provided']} · changed=${diffCheck['changed_file_count']}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(
            zh ? 'Validation / installability' : 'Validation / installability',
            'validation=${validationCheck['status']} · installability=${installabilityCheck['status']} · token=${tokenBudgetCheck['status']}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(
            zh ? 'Workbench display evidence' : 'Workbench display evidence',
            'asset=${governanceUiContract['asset_id']} · display=${governanceUiContract['ready_for_workbench_display']} · static_only=true'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? '方法论地图' : 'Methodology Map',
            '${methodologyMap['source_package_id']} · modules=${methodologyMap['module_count']} · confidence=${methodologyMap['confidence']}'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? 'Evidence Windows' : 'Evidence Windows',
            'count=${methodologyEvidence.length} · ${methodologyEvidence.take(3).join(' · ')}'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? '方法论模块' : 'Methodology Module',
            '${firstMethodologyModule['title']} · concepts=${(firstMethodologyModule['concepts'] as List?)?.length ?? 0} · principles=${(firstMethodologyModule['principles'] as List?)?.length ?? 0} · workflows=${(firstMethodologyModule['workflows'] as List?)?.length ?? 0}'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? '来源追踪 / 风险' : 'Source Trace / Risk',
            'trace=${methodologyEvidence.length} · unsupported=${unsupportedClaims['status']} · risks=${methodologyRisks.isEmpty ? 'none' : methodologyRisks.join('/')} · static_only=true'),
      if (externalProjects.isNotEmpty)
        _CardCopy(
            zh ? '页面映射' : 'Mapped external projects',
            externalProjects
                .map((project) =>
                    '${project.projectName}:${project.contractStatus.join('/')}')
                .take(2)
                .join(' · ')),
      if (providerProjects.isNotEmpty)
        _CardCopy(
            zh ? 'blocked_reason' : 'blocked_reason',
            providerProjects
                .map((project) =>
                    '${project.projectId}:${project.blockedReason}')
                .take(2)
                .join(' · ')),
      if (templateProjects.isNotEmpty)
        _CardCopy(
            zh ? '模板参考' : 'Template references',
            templateProjects
                .map((project) => project.projectName)
                .take(3)
                .join(' · ')),
      if (page.pageIds.contains('operation-gate'))
        _CardCopy(zh ? 'S/A 不影响 P1' : 'S/A does not affect P1',
            'p1_gate_changed=${externalCapabilities.releaseBoundary['p1_gate_changed']} · v4_0_started=${externalCapabilities.releaseBoundary['v4_0_started']}'),
      if (page.pageIds.contains('capability-matrix'))
        _CardCopy(
            zh ? 'Action 分类' : 'Action classification',
            workflowV2Evidence.actionResults
                .map((action) => '${action.actionId}:${action.status}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.contains('capability-matrix'))
        _CardCopy(zh ? '能力域' : 'Capability areas',
            '${contracts.capabilities.areas.length}'),
      if (page.pageIds.contains('task-job-center'))
        _CardCopy(
            zh ? 'Task evidence' : 'Task evidence',
            workflowV2Evidence.actionResults
                .map((action) => '${action.actionId}:${action.assertionStatus}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.contains('artifact-management'))
        _CardCopy(
            zh ? 'Artifact evidence' : 'Artifact evidence',
            workflowV2Evidence.actionResults
                .map((action) => '${action.actionId}:${action.artifactCount}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.contains('reports-audit'))
        _CardCopy(
            zh ? 'Gate impact' : 'Gate impact',
            workflowV2Evidence.userPaths
                .map((path) => '${path.userPathId}:${path.gateImpact}')
                .take(1)
                .join('')),
      if (page.pageIds.contains('agent-factory-runtime'))
        _CardCopy(zh ? 'Agent 模式' : 'Agent modes',
            contracts.agent.supportedModes.join(' · ')),
      if (page.pageIds.contains('error-repair-center'))
        _CardCopy(zh ? '错误码' : 'Error codes',
            contracts.errors.errorStates.join(' · ')),
      if (page.pageIds.contains('error-repair-center'))
        _CardCopy(
            zh ? 'Blocked reason' : 'Blocked reason',
            workflowV2Evidence.blockedActions
                .map((action) => action.blockedReason)
                .take(1)
                .join('')),
      if (page.pageIds.contains('template-library'))
        _CardCopy(
            zh ? '模板' : 'Templates',
            contracts.templates.templates
                .map((template) => template.id)
                .take(3)
                .join(' · ')),
    ];
  }
}

class _WorkbenchScaffold extends StatelessWidget {
  const _WorkbenchScaffold({
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
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
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
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
        final isTablet =
            constraints.maxWidth >= 720 && constraints.maxWidth < 1040;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: _BrandHeader(localeCode: localeCode, compact: isPhone),
            actions: [
              IconButton(
                tooltip: isDark ? 'Light mode' : 'Dark mode',
                onPressed: () =>
                    onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark),
                icon: Icon(isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined),
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
                  workflowEvidence: workflowEvidence,
                  workflowV2Evidence: workflowV2Evidence,
                  externalCapabilities: externalCapabilities,
                  parserBackends: parserBackends,
                  skillGovernanceReport: skillGovernanceReport,
                  methodologyMap: methodologyMap,
                  skillSuiteWorkflow: skillSuiteWorkflow,
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
                  workflowEvidence: workflowEvidence,
                  workflowV2Evidence: workflowV2Evidence,
                  externalCapabilities: externalCapabilities,
                  parserBackends: parserBackends,
                  skillGovernanceReport: skillGovernanceReport,
                  methodologyMap: methodologyMap,
                  skillSuiteWorkflow: skillSuiteWorkflow,
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

ContractView _contractViewFor(
    WorkbenchPage page, WorkbenchContracts contracts) {
  return _contractViewForId(page.id, contracts);
}

ContractView _contractViewForId(String pageId, WorkbenchContracts contracts) {
  for (final view in contracts.navigation.views) {
    if (view.id == pageId) {
      return view;
    }
  }
  return ContractView(
      id: pageId,
      label: pageId,
      assetTypes: const [],
      corePageId: pageId,
      zhLabel: pageId);
}

List<ContractAction> _actionsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.actions.actions
      .where((action) => action.pageId == view.corePageId)
      .toList(growable: false);
}

List<ContractReport> _reportsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.reports.reports
      .where((report) => report.pageId == view.corePageId)
      .toList(growable: false);
}

List<ContractAsset> _artifactsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.assets.assets
      .where((asset) => asset.pageId == view.corePageId)
      .toList(growable: false);
}

bool _showsWorkflowEvidence(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'task-job-center',
    'artifact-management',
    'error-repair-center',
    'reports-audit',
  }.contains(pageId);
}

bool _showsV2Evidence(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'capability-matrix',
    'task-job-center',
    'artifact-management',
    'error-repair-center',
    'reports-audit',
  }.contains(pageId);
}

bool _showsExternalCapabilities(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'capability-matrix',
    'vector-hub-provider-storage',
    'retrieval-verification',
    'reports-audit',
    'template-library',
    'skill-factory',
    'memory-center',
  }.contains(pageId);
}

bool _showsParserBackends(String pageId) {
  return const {
    'dashboard',
    'import-parsing',
    'capability-matrix',
    'operation-gate',
    'reports-audit',
    'artifact-management',
    'error-repair-center',
  }.contains(pageId);
}

bool _showsSkillGovernance(String pageId) {
  return pageId == 'skill-factory';
}

bool _showsMethodology(String pageId) {
  return pageId == 'skill-factory';
}

const sampleSkillGovernanceReport = <String, dynamic>{
  'skill_governance_report_version': 'v4.2-p2.2-1',
  'status': 'pass',
  'release_ready': true,
  'skill_name': 'README Operations Skill',
  'checks': {
    'validation': {'status': 'pass'},
    'diff_comparison': {
      'status': 'pass',
      'baseline_provided': true,
      'changed_file_count': 3,
    },
    'installability': {'status': 'pass'},
    'token_budget': {'status': 'pass'},
  },
  'ui_contract': {
    'asset_id': 'skill_governance_report_json',
    'ready_for_workbench_display': true,
  },
};

const sampleMethodologyMap = <String, dynamic>{
  'methodology_map_version': 'v4.2-p2.2-1',
  'source_package_id': 'pkg-operations',
  'module_count': 2,
  'confidence': 0.91,
  'risk_flags': <String>[],
  'source_evidence': <String>['window_001', 'window_002'],
  'unsupported_claim_detection': {
    'status': 'pass',
    'excluded_count': 0,
  },
  'methodology_modules': <Map<String, dynamic>>[
    {
      'module_id': 'methodology_module_001',
      'title': 'Evidence-led Operations',
      'concepts': <Map<String, dynamic>>[
        {'statement': 'Evidence-led Operations'}
      ],
      'principles': <Map<String, dynamic>>[
        {'statement': 'Use local evidence and prefer narrow scope.'}
      ],
      'workflows': <Map<String, dynamic>>[
        {'statement': 'First inspect the source, then apply the decision rule.'}
      ],
    },
    {
      'module_id': 'methodology_module_002',
      'title': 'Review Boundary',
      'concepts': <Map<String, dynamic>>[
        {'statement': 'Review Boundary'}
      ],
      'principles': <Map<String, dynamic>>[
        {'statement': 'Unsupported claims require review.'}
      ],
      'workflows': <Map<String, dynamic>>[],
    },
  ],
};

class _WorkbenchCard extends StatelessWidget {
  const _WorkbenchCard(
      {required this.title, required this.body, required this.localeCode});

  final String title;
  final String body;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: textTheme.labelMedium,
                ),
                child: Text(localeCode == 'zh-CN' ? '显示边界' : 'Show boundary')),
          ],
        ),
      ),
    );
  }
}
