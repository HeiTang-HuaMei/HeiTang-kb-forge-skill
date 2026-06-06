import 'package:flutter/material.dart';

void main() {
  runApp(const HeiTangWorkbenchApp());
}

const brandAssets = <String>[
  'assets/brand/black_cat_head.svg',
  'assets/brand/black_tiger_head.svg',
];

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

final pages = <WorkbenchPage>[
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

  String title(String localeCode) => localeCode == 'zh-CN' ? zhTitle : enTitle;
  String description(String localeCode) => localeCode == 'zh-CN' ? zhDescription : enDescription;
}

class HeiTangWorkbenchApp extends StatefulWidget {
  const HeiTangWorkbenchApp({super.key});

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
    return MaterialApp(
      title: 'HeiTang Knowledge Workbench',
      debugShowCheckedModeBanner: false,
      locale: localeCode == 'zh-CN' ? const Locale('zh', 'CN') : const Locale('en', 'US'),
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
                Padding(
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
              selectedIndex: selectedIndex,
              onPageChanged: (index) => setState(() => selectedIndex = index),
            ) : _DesktopWorkbench(
              localeCode: localeCode,
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
        background: isDarkTheme ? const Color(0xff0f0f0f) : const Color(0xfff4f4f2),
      ),
      scaffoldBackgroundColor: isDarkTheme ? const Color(0xff0f0f0f) : const Color(0xfff4f4f2),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          _MascotBadge(label: '猫'),
          const SizedBox(width: 4),
          _MascotBadge(label: '虎'),
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
    required this.selectedIndex,
    required this.isTablet,
    required this.onPageChanged,
  });

  final String localeCode;
  final int selectedIndex;
  final bool isTablet;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          extended: !isTablet,
          selectedIndex: selectedIndex,
          onDestinationSelected: onPageChanged,
          destinations: pages.map((page) => NavigationRailDestination(
            icon: const Icon(Icons.radio_button_unchecked),
            selectedIcon: const Icon(Icons.circle),
            label: Text(page.title(localeCode)),
          )).toList(),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _PageSurface(page: pages[selectedIndex], localeCode: localeCode, columns: isTablet ? 2 : 3)),
      ],
    );
  }
}

class _PhoneWorkbench extends StatelessWidget {
  const _PhoneWorkbench({
    required this.localeCode,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  final String localeCode;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<int>(
            value: selectedIndex,
            decoration: InputDecoration(
              labelText: localeCode == 'zh-CN' ? '页面' : 'Page',
              border: const OutlineInputBorder(),
            ),
            items: [
              for (var index = 0; index < pages.length; index++)
                DropdownMenuItem(value: index, child: Text(pages[index].title(localeCode))),
            ],
            onChanged: (value) {
              if (value != null) {
                onPageChanged(value);
              }
            },
          ),
        ),
        Expanded(child: _PageSurface(page: pages[selectedIndex], localeCode: localeCode, columns: 1)),
      ],
    );
  }
}

class _PageSurface extends StatelessWidget {
  const _PageSurface({required this.page, required this.localeCode, required this.columns});

  final WorkbenchPage page;
  final String localeCode;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final cards = _cardsFor(page.id, localeCode);

    return SingleChildScrollView(
      padding: EdgeInsets.all(columns == 1 ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(page.title(localeCode), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
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
              childAspectRatio: columns == 1 ? 2.6 : 1.55,
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

  List<_CardCopy> _cardsFor(String id, String localeCode) {
    final zh = localeCode == 'zh-CN';
    final common = zh ? '模拟数据 · 预留 API' : 'Mock data · Reserved API';
    final map = <String, List<_CardCopy>>{
      'dashboard': [_CardCopy(zh ? '知识库' : 'Knowledge bases', '3'), _CardCopy(zh ? '复核风险' : 'Review risks', '2'), _CardCopy(zh ? '供应商' : 'Providers', common)],
      'file-upload': [_CardCopy(zh ? '拖放上传' : 'Dropzone', common), _CardCopy(zh ? '解析器状态' : 'Parser status', 'Docling · Marker · Plain Text')],
      'job-progress': [_CardCopy(zh ? '运行中' : 'Running', '68%'), _CardCopy(zh ? '阶段' : 'Stages', zh ? '上传 / 解析 / 复核' : 'Upload / Parse / Review')],
      'knowledge-base-list': [_CardCopy(zh ? '可信库' : 'Trusted KBs', '2'), _CardCopy(zh ? '草稿库' : 'Draft KBs', '1')],
      'knowledge-base-detail': [_CardCopy(zh ? '分片' : 'Chunks', '1836'), _CardCopy(zh ? '绑定 Agent' : 'Bound agents', 'Research · Writer')],
      'review-queue': [_CardCopy(zh ? '高风险' : 'High risk', '1'), _CardCopy(zh ? '待校正' : 'Needs correction', common)],
      'corrected-text-editor': [_CardCopy(zh ? '校正文稿' : 'Corrected text', zh ? '只写入模拟状态' : 'Mock state only'), _CardCopy(zh ? '复核动作' : 'Review actions', common)],
      'kb-query': [_CardCopy(zh ? '证据回答' : 'Grounded answer', zh ? '引用优先' : 'Citation first'), _CardCopy(zh ? '拒答策略' : 'Abstain policy', common)],
      'document-generation': [_CardCopy(zh ? '发布简报' : 'Launch brief', '18 citations'), _CardCopy(zh ? '策略复核包' : 'Policy pack', '31 citations')],
      'agent-skill-management': [_CardCopy('Research Analyst', 'OpenAI'), _CardCopy('Document Writer', 'Azure OpenAI'), _CardCopy('Evidence Reviewer', 'Local')],
      'multi-agent-workflow': [_CardCopy(zh ? '工作流共享记忆' : 'Workflow shared memory', 'mem-workflow-launch'), _CardCopy(zh ? '交接链路' : 'Handoff trace', 'Research -> Writer -> Reviewer')],
      'memory-scope-viewer': [_CardCopy(zh ? 'Agent 私有记忆' : 'Agent private memory', 'isolated'), _CardCopy(zh ? '工作流共享' : 'Workflow shared', 'scoped')],
      'settings': [_CardCopy(zh ? '供应商' : 'Providers', 'OpenAI · Azure · Local'), _CardCopy(zh ? '回答策略' : 'Answer policy', 'grounded_only'), _CardCopy(zh ? '记忆策略' : 'Memory policy', 'private_by_default')],
      'export-center': [_CardCopy(zh ? '演示包' : 'Demo package', 'zip'), _CardCopy(zh ? '复核 CSV' : 'Review CSV', common)],
    };
    return map[id] ?? [_CardCopy(page.title(localeCode), common)];
  }
}

class _CardCopy {
  const _CardCopy(this.title, this.body);

  final String title;
  final String body;
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
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            FilledButton(onPressed: () {}, child: Text(localeCode == 'zh-CN' ? '打开' : 'Open')),
          ],
        ),
      ),
    );
  }
}
