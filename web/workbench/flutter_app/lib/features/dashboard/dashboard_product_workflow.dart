part of '../../main.dart';

class _DesktopDashboardSurface extends StatelessWidget {
  const _DesktopDashboardSurface({
    required this.localeCode,
    required this.contracts,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.externalCapabilities,
    required this.workspace,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ExternalCapabilityRegistry externalCapabilities;
  final String workspace;
  final bool isWebRuntime;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final wide = width >= 1500;
      final standard = width >= 1100;
      final spacious = width >= 1900;
      final spacing = wide ? 20.0 : 14.0;
      final maxContentWidth = spacious
          ? 1840.0
          : wide
              ? 1760.0
              : standard
                  ? 1680.0
                  : width;
      final heroHeight = wide ? 196.0 : 184.0;
      final primaryRowHeight = wide ? 376.0 : 334.0;
      final secondaryRowHeight = wide ? 246.0 : 212.0;

      final assetOverview = _DashboardAssetOverviewCard(
        localeCode: localeCode,
        workspace: workspace,
        runtime: runtime,
        onPageChanged: onPageChanged,
      );
      final mainFlow = _DashboardMainFlowCard(
        localeCode: localeCode,
        runtime: runtime,
        onPageChanged: onPageChanged,
      );
      final recentTasks = _DashboardRecentTasks(
        localeCode: localeCode,
        onPageChanged: onPageChanged,
      );
      final recentActivity = _DashboardRecentActivity(
        localeCode: localeCode,
        workflowV2Evidence: workflowV2Evidence,
        parserBackends: parserBackends,
        onPageChanged: onPageChanged,
      );
      final recentOutputs = _DashboardArtifactOverview(
        localeCode: localeCode,
        onPageChanged: onPageChanged,
      );

      return _FigmaPageCanvas(
        spacing: spacing,
        maxContentWidth: maxContentWidth,
        constrainHeight: false,
        children: [
          SizedBox(
            height: heroHeight,
            child: _DashboardHeroCard(
              localeCode: localeCode,
              runtime: runtime,
              onPageChanged: onPageChanged,
            ),
          ),
          if (width >= 900)
            _DashboardResponsiveRow(
              height: primaryRowHeight,
              spacing: spacing,
              flexes: const [5, 7],
              children: [assetOverview, mainFlow],
            )
          else ...[
            SizedBox(height: 300, child: assetOverview),
            SizedBox(height: 314, child: mainFlow),
          ],
          if (width >= 1100)
            _DashboardResponsiveRow(
              height: secondaryRowHeight,
              spacing: spacing,
              flexes: const [5, 3, 3],
              children: [recentTasks, recentActivity, recentOutputs],
            )
          else if (width >= 760) ...[
            _DashboardResponsiveRow(
              height: secondaryRowHeight,
              spacing: spacing,
              flexes: const [3, 2],
              children: [recentTasks, recentActivity],
            ),
            SizedBox(height: secondaryRowHeight, child: recentOutputs),
          ] else ...[
            SizedBox(height: 220, child: recentTasks),
            SizedBox(height: 220, child: recentActivity),
            SizedBox(height: 220, child: recentOutputs),
          ],
          _DashboardIsolationNotice(localeCode: localeCode),
        ],
      );
    });
  }
}

class _DashboardResponsiveRow extends StatelessWidget {
  const _DashboardResponsiveRow({
    required this.height,
    required this.children,
    required this.flexes,
    required this.spacing,
  });

  final double height;
  final List<Widget> children;
  final List<int> flexes;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            Expanded(flex: flexes[index], child: children[index]),
          ],
        ],
      ),
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({
    required this.localeCode,
    required this.runtime,
    required this.onPageChanged,
  });

  final String localeCode;
  final Rc6RuntimeState runtime;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final action = _dashboardNextAction(runtime, _zh);
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final visual = _HTKWTokens.visualTokens(brightness);
    final heroAccent = _HTKWTokens.moduleColor(action.pageId);
    final generatedCount = [
          runtime.hasMarkdown,
          runtime.hasExportedDocument,
          runtime.hasSkill,
          runtime.hasAgent,
          runtime.hasAgentDialogue,
          runtime.hasMultiAgentDiscussion,
        ].where((value) => value).length +
        runtime.agentArtifacts.length;
    final metricChips = [
      _DashboardMetricChipData(
        _zh ? '${runtime.sourceCount} 个来源' : '${runtime.sourceCount} sources',
        Icons.library_books_outlined,
        _HTKWTokens.moduleDocument,
      ),
      _DashboardMetricChipData(
        runtime.hasKnowledgeBase
            ? (_zh ? '知识库可用' : 'KB ready')
            : (_zh ? '知识库待建' : 'KB pending'),
        Icons.account_tree_outlined,
        _HTKWTokens.moduleKnowledge,
      ),
      _DashboardMetricChipData(
        generatedCount == 0
            ? (_zh ? '成果待生成' : 'Outputs pending')
            : (_zh ? '$generatedCount 个成果' : '$generatedCount outputs'),
        Icons.folder_copy_outlined,
        _HTKWTokens.moduleArtifact,
      ),
    ];
    final heroBase = dark
        ? visual.surfaceRaised
        : Color.alphaBlend(
            heroAccent.withValues(alpha: 0.035),
            colors.surface,
          );
    final decoration = BoxDecoration(
      color: heroBase,
      borderRadius: BorderRadius.circular(_DesktopGrid.radiusPanel),
      border: Border.all(
        color: _HTKWTokens.moduleBorderTint(
          action.pageId,
          brightness,
          lightAlpha: 0.11,
          darkAlpha: 0.14,
        ),
      ),
      boxShadow: visual.shadow,
    );
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 280;
      if (narrow) {
        return Container(
          key: const Key('dashboard-hero-card'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: decoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _zh ? '知识资产' : 'Knowledge assets',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              _DashboardMetricChip(data: metricChips.first),
              const SizedBox(height: 8),
              _PrimaryProductAction(
                label: action.title,
                icon: action.icon,
                onPressed: () => onPageChanged(_pageIndexById(action.pageId)),
              ),
            ],
          ),
        );
      }
      return Container(
        key: const Key('dashboard-hero-card'),
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth >= 1500 ? 32 : 24,
          constraints.maxWidth >= 1500 ? 24 : 18,
          constraints.maxWidth >= 1500 ? 30 : 24,
          constraints.maxWidth >= 1500 ? 24 : 18,
        ),
        decoration: decoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _DashboardHeroCopy(
                zh: _zh,
                action: action,
                metricChips: metricChips,
                onPageChanged: onPageChanged,
              ),
            ),
            if (constraints.maxWidth >= 720) ...[
              SizedBox(width: constraints.maxWidth >= 1500 ? 32 : 22),
              Container(
                width: 1,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: heroAccent.withValues(alpha: dark ? 0.1 : 0.08),
                ),
              ),
              SizedBox(width: constraints.maxWidth >= 1500 ? 32 : 22),
              Flexible(
                flex: 0,
                child: _DashboardKnowledgeGlyph(zh: _zh),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _DashboardHeroCopy extends StatelessWidget {
  const _DashboardHeroCopy({
    required this.zh,
    required this.action,
    required this.metricChips,
    required this.onPageChanged,
  });

  final bool zh;
  final _DashboardActionRow action;
  final List<_DashboardMetricChipData> metricChips;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          zh ? '把资料变成可用的知识资产' : 'Turn materials into usable knowledge assets',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                height: 1.08,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          zh
              ? '整理资料、构建知识库、验证质量，最后生成文档、技能与助手。'
              : 'Organize sources, build a knowledge base, verify quality, then generate documents, skills, and assistants.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.24,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final chip in metricChips) _DashboardMetricChip(data: chip),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 128),
              child: IntrinsicWidth(
                child: _PrimaryProductAction(
                  label: action.title,
                  icon: action.icon,
                  fullWidth: false,
                  onPressed: () => onPageChanged(_pageIndexById(action.pageId)),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 118),
              child: IntrinsicWidth(
                child: _DisplayAction(
                  label: zh ? '查看流程' : 'View flow',
                  icon: Icons.route_outlined,
                  fullWidth: false,
                  onPressed: () =>
                      onPageChanged(_pageIndexById('document-library')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardMetricChipData {
  const _DashboardMetricChipData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _DashboardMetricChip extends StatelessWidget {
  const _DashboardMetricChip({required this.data});

  final _DashboardMetricChipData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: dark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
        border: Border.all(
          color: data.color.withValues(alpha: dark ? 0.18 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 13, color: data.color),
          const SizedBox(width: 5),
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardKnowledgeGlyph extends StatelessWidget {
  const _DashboardKnowledgeGlyph({
    required this.zh,
  });

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('dashboard-knowledge-asset-glyph'),
      width: 396,
      height: 148,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _HTKWTokens.glassSurface(brightness),
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusPanel),
        border:
            Border.all(color: Colors.white.withValues(alpha: dark ? 0.1 : 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DashboardGlyphStageCard(
                    color: _HTKWTokens.moduleDocument,
                    icon: Icons.snippet_folder_outlined,
                    title: zh ? '资料' : 'Materials',
                    subtitle: zh ? '导入整理' : 'Import',
                  ),
                ),
                _DashboardGlyphConnector(
                  color: colors.onSurfaceVariant.withValues(
                    alpha: dark ? 0.22 : 0.18,
                  ),
                ),
                Expanded(
                  child: _DashboardGlyphStageCard(
                    color: _HTKWTokens.moduleRetrieval,
                    icon: Icons.account_tree_outlined,
                    title: zh ? '知识库' : 'Knowledge',
                    subtitle: zh ? '构建验证' : 'Build',
                  ),
                ),
                _DashboardGlyphConnector(
                  color: colors.onSurfaceVariant.withValues(
                    alpha: dark ? 0.22 : 0.18,
                  ),
                ),
                Expanded(
                  child: _DashboardGlyphStageCard(
                    color: _HTKWTokens.moduleGeneration,
                    icon: Icons.file_present_outlined,
                    title: zh ? '成果' : 'Outputs',
                    subtitle: zh ? '生成输出' : 'Generate',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: dark ? 0.07 : 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _HTKWTokens.visualTokens(brightness).borderSubtle,
              ),
            ),
            child: Text(
              zh ? '资料变成可复用资产' : 'Reusable knowledge asset',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGlyphConnector extends StatelessWidget {
  const _DashboardGlyphConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Icon(Icons.chevron_right, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _DashboardGlyphStageCard extends StatelessWidget {
  const _DashboardGlyphStageCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: dark ? 0.2 : 0.13)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.17 : 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: dark ? 0.78 : 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAssetOverviewCard extends StatelessWidget {
  const _DashboardAssetOverviewCard({
    required this.localeCode,
    required this.workspace,
    required this.runtime,
    required this.onPageChanged,
  });

  final String localeCode;
  final String workspace;
  final Rc6RuntimeState runtime;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final workspaceLabel = _displayNameForPath(workspace).trim().isEmpty
        ? (_zh ? '默认工作区' : 'Default Workspace')
        : _displayNameForPath(workspace);
    final rows = [
      _DashboardOverviewRow(
        _zh ? '当前工作区' : 'Current Workspace',
        workspaceLabel,
        Icons.workspaces_outline,
        'workbook',
      ),
      _DashboardOverviewRow(
        _zh ? '配置状态' : 'Configuration',
        runtime.parseReportPath.isEmpty
            ? (_zh ? '本地模式，等待整理资料' : 'Local mode, waiting organize')
            : (_zh ? '本地模式，资料已整理' : 'Local mode, organized'),
        Icons.tune_outlined,
        'settings',
      ),
      _DashboardOverviewRow(
        _zh ? '文档库' : 'Document Library',
        runtime.hasImportedFile
            ? (_zh
                ? '${runtime.sourceCount} 个真实来源'
                : '${runtime.sourceCount} real sources')
            : (_zh ? '等待导入真实资料' : 'Waiting real imports'),
        Icons.library_books_outlined,
        'document-library',
      ),
      _DashboardOverviewRow(
        _zh ? '知识库' : 'Knowledge Base',
        runtime.hasKnowledgeBase
            ? (_zh ? '已构建，可测试' : 'Built, testable')
            : (_zh ? '等待构建知识体系' : 'Waiting build'),
        Icons.account_tree_outlined,
        'knowledge-package-management',
      ),
      _DashboardOverviewRow(
        _zh ? '技能' : 'Skills',
        runtime.hasSkill
            ? (_zh ? '已生成，可绑定助手' : 'Generated, assistant-ready')
            : (_zh ? '等待生成可复用技能' : 'Waiting reusable skills'),
        Icons.extension_outlined,
        'skill-factory',
      ),
      _DashboardOverviewRow(
        _zh ? '助手' : 'Assistants',
        runtime.hasAgent
            ? (_zh ? '已创建，可对话' : 'Created, chat-ready')
            : (_zh ? '创建后可承接任务' : 'Create to run tasks'),
        Icons.smart_toy_outlined,
        'agent-factory-runtime',
      ),
    ];
    final generatedCount = [
          runtime.hasMarkdown,
          runtime.hasExportedDocument,
          runtime.hasSkill,
          runtime.hasAgent,
          runtime.hasAgentDialogue,
          runtime.hasMultiAgentDiscussion,
        ].where((value) => value).length +
        runtime.agentArtifacts.length;
    return _FigmaCard(
      keyName: 'dashboard-asset-overview',
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FigmaSectionHeader(
                  icon: Icons.space_dashboard_outlined,
                  accentColor: _HTKWTokens.moduleDocument,
                  title: _zh ? '工作区资产' : 'Workspace Assets',
                  subtitle: _zh
                      ? '资料、知识库、技能与助手在当前工作区内承接'
                      : 'Sources, KBs, skills, and assistants stay in this workspace',
                ),
              ),
              _DashboardAssetStatusPill(
                label: generatedCount == 0
                    ? (_zh ? '待产出' : 'Pending')
                    : (_zh ? '$generatedCount 个成果' : '$generatedCount outputs'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _LocalScrollBox(
              bottomPadding: 4,
              child: Column(
                children: [
                  for (final row in rows) ...[
                    _DashboardOverviewRowTile(
                      row: row,
                      onTap: () => onPageChanged(_pageIndexById(row.pageId)),
                    ),
                    if (row != rows.last)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DashboardAssetSummary(
            label: _zh ? '当前工作区摘要' : 'Workspace Summary',
            value: runtime.hasImportedFile
                ? (_zh
                    ? '$workspaceLabel · ${runtime.sourceCount} 个来源'
                    : '$workspaceLabel · ${runtime.sourceCount} sources')
                : (_zh
                    ? '$workspaceLabel · 等待导入资料'
                    : '$workspaceLabel · waiting sources'),
          ),
        ],
      ),
    );
  }
}

class _DashboardAssetStatusPill extends StatelessWidget {
  const _DashboardAssetStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _HTKWTokens.moduleArtifact.withValues(
          alpha: brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
        border: Border.all(
          color: _HTKWTokens.moduleArtifact.withValues(
            alpha: brightness == Brightness.dark ? 0.18 : 0.12,
          ),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _HTKWTokens.moduleArtifact,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DashboardAssetSummary extends StatelessWidget {
  const _DashboardAssetSummary({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _HTKWTokens.recessedSurface(brightness),
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMainFlowCard extends StatelessWidget {
  const _DashboardMainFlowCard({
    required this.localeCode,
    required this.runtime,
    required this.onPageChanged,
  });

  final String localeCode;
  final Rc6RuntimeState runtime;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final steps = [
      _DashboardFlowStep(
        '1',
        _zh ? '文档库：整理资料' : 'Library: organize materials',
        _zh ? '导入来源并抽取可复用片段' : 'Import sources and extract reusable segments',
        'document-library',
        runtime.parseReportPath.isNotEmpty
            ? (_zh ? '已完成' : 'Done')
            : runtime.hasImportedFile
                ? (_zh ? '进行中' : 'In progress')
                : (_zh ? '未开始' : 'Not started'),
      ),
      _DashboardFlowStep(
        '2',
        _zh ? '知识库：构建知识体系' : 'Knowledge Base: build system',
        _zh
            ? '把整理结果沉淀成可检索知识'
            : 'Turn organized material into searchable knowledge',
        'knowledge-package-management',
        runtime.hasKnowledgeBase
            ? (_zh ? '已完成' : 'Done')
            : runtime.parseReportPath.isNotEmpty
                ? (_zh ? '进行中' : 'In progress')
                : (_zh ? '未开始' : 'Not started'),
      ),
      _DashboardFlowStep(
        '3',
        _zh ? '知识库：验证质量' : 'KB: verify quality',
        _zh ? '验证证据、引用和回答质量' : 'Verify evidence, citations, and answer quality',
        'retrieval-verification',
        runtime.searchStatus == Rc6SearchStatus.success
            ? (_zh ? '已完成' : 'Done')
            : runtime.hasKnowledgeBase
                ? (_zh ? '进行中' : 'In progress')
                : (_zh ? '未开始' : 'Not started'),
      ),
      _DashboardFlowStep(
        '4',
        _zh ? '文档生成：输出专业文档' : 'Document: generate outputs',
        _zh ? '把验证后的知识输出为文档草稿' : 'Draft documents from verified knowledge',
        'document-generation',
        runtime.hasMarkdown
            ? (_zh ? '已完成' : 'Done')
            : runtime.hasKnowledgeBase
                ? (_zh ? '进行中' : 'In progress')
                : (_zh ? '未开始' : 'Not started'),
      ),
      _DashboardFlowStep(
        '5',
        _zh ? '技能与助手：沉淀复用能力' : 'Skills and assistants: reusable capability',
        _zh
            ? '生成技能，交给助手承接任务'
            : 'Generate skills and let assistants carry tasks',
        'skill-factory',
        runtime.hasSkill || runtime.hasAgent
            ? (_zh ? '已完成' : 'Done')
            : runtime.hasMarkdown
                ? (_zh ? '进行中' : 'In progress')
                : (_zh ? '未开始' : 'Not started'),
      ),
    ];
    final doneLabel = _zh ? '已完成' : 'Done';
    final progress = steps.where((step) => step.status == doneLabel).length;
    return _FigmaCard(
      keyName: 'dashboard-main-flow',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FigmaSectionHeader(
                  icon: Icons.route_outlined,
                  accentColor: _HTKWTokens.moduleKnowledge,
                  title: _zh ? '知识供应链进度' : 'Knowledge Workflow Progress',
                  subtitle: _zh
                      ? '从资料到成果的可追溯生产流程'
                      : 'Traceable production flow from sources to outputs',
                ),
              ),
              _DashboardAssetStatusPill(
                label: '$progress / ${steps.length}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _LocalScrollBox(
              bottomPadding: 4,
              child: Column(
                children: [
                  for (var index = 0; index < steps.length; index++)
                    _DashboardFlowStepCard(
                      step: steps[index],
                      done: steps[index].status == (_zh ? '已完成' : 'Done'),
                      first: index == 0,
                      last: index == steps.length - 1,
                      active: steps[index].status ==
                              (_zh ? '进行中' : 'In progress') ||
                          (index == 0 &&
                              steps.every((step) =>
                                  step.status !=
                                  (_zh ? '进行中' : 'In progress'))),
                      onTap: () =>
                          onPageChanged(_pageIndexById(steps[index].pageId)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardFlowStep {
  const _DashboardFlowStep(
    this.number,
    this.title,
    this.description,
    this.pageId,
    this.status,
  );

  final String number;
  final String title;
  final String description;
  final String pageId;
  final String status;
}

class _DashboardFlowStepCard extends StatelessWidget {
  const _DashboardFlowStepCard({
    required this.step,
    required this.active,
    required this.done,
    required this.first,
    required this.last,
    required this.onTap,
  });

  final _DashboardFlowStep step;
  final bool active;
  final bool done;
  final bool first;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = done
        ? _HTKWTokens.moduleArtifact
        : _HTKWTokens.moduleColor(step.pageId);
    final activeBackground = accent.withValues(
      alpha: brightness == Brightness.dark ? 0.1 : 0.055,
    );
    return Material(
      color: active ? activeBackground : Colors.transparent,
      borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 44,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 1,
                        color: first
                            ? Colors.transparent
                            : accent.withValues(alpha: 0.22),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? accent
                            : done
                                ? _HTKWTokens.moduleArtifact
                                : colors.surfaceContainerHigh,
                        border: Border.all(
                          color: accent.withValues(
                              alpha: active || done ? 0.22 : 0.12),
                        ),
                        borderRadius:
                            BorderRadius.circular(_DesktopGrid.radiusSmall),
                      ),
                      child: Text(
                        done ? '✓' : step.number,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: active
                                  ? colors.onPrimary
                                  : done
                                      ? Colors.white
                                      : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 1,
                        color: last
                            ? Colors.transparent
                            : accent.withValues(alpha: 0.22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w600,
                            height: 1.08,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${step.description} · ${step.status}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: active ? accent : colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardOverviewRow {
  const _DashboardOverviewRow(
    this.label,
    this.value,
    this.icon,
    this.pageId,
  );

  final String label;
  final String value;
  final IconData icon;
  final String pageId;
}

class _DashboardOverviewRowTile extends StatelessWidget {
  const _DashboardOverviewRowTile({
    required this.row,
    required this.onTap,
  });

  final _DashboardOverviewRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = _HTKWTokens.moduleColor(row.pageId);
    return Semantics(
      button: true,
      label: row.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: accent.withValues(
              alpha: brightness == Brightness.dark ? 0.1 : 0.06),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: brightness == Brightness.dark ? 0.13 : 0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(_DesktopGrid.radiusSmall),
                    border: Border.all(
                      color: accent.withValues(
                        alpha: brightness == Brightness.dark ? 0.18 : 0.12,
                      ),
                    ),
                  ),
                  child: Icon(row.icon, size: 14, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    size: 16,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.68)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardIsolationNotice extends StatelessWidget {
  const _DashboardIsolationNotice({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final zh = localeCode == 'zh-CN';
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = zh
        ? '默认隔离：当前工作区的数据、知识库、技能、助手与其它工作区相互隔离。'
        : 'Default isolation: data, knowledge bases, skills, and assistants stay isolated in the current workspace.';
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 980;
      return Tooltip(
        message: message,
        child: Container(
          key: const Key('dashboard-isolation-notice'),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: (isDark
                    ? colors.surfaceContainer
                    : colors.surfaceContainerLowest)
                .withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _HTKWTokens.visualTokens(Theme.of(context).brightness)
                  .borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child:
                    Icon(Icons.lock_outline, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DashboardRecentTasks extends StatefulWidget {
  const _DashboardRecentTasks({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  @override
  State<_DashboardRecentTasks> createState() => _DashboardRecentTasksState();
}

class _DashboardRecentTasksState extends State<_DashboardRecentTasks> {
  bool get _zh => widget.localeCode == 'zh-CN';

  Future<void> _clearTasks(
      Rc6RuntimeController? rc6, List<_DashboardTaskRow> rows) async {
    if (rc6 == null || rc6.state.running || rows.isEmpty) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '清空最近任务？' : 'Clear recent tasks?',
      body: _zh
          ? '这会删除当前显示的真实任务记录和对应产物；原始输入文件夹不会被删除。'
          : 'This deletes the currently displayed real task records and artifacts; original source folders are not deleted.',
    );
    if (!confirmed) return;
    for (final row in rows.reversed) {
      await rc6.clearRecentTaskArtifacts(row.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final rows = <_DashboardTaskRow>[
      if (runtime.hasImportedFile)
        _DashboardTaskRow(
          'import',
          _zh ? '导入来源文件' : 'Import sources',
          _zh ? '文档库' : 'Document Library',
          _zh ? '${runtime.sourceCount} 个文件' : '${runtime.sourceCount} files',
          Icons.upload_file_outlined,
          'document-library',
        ),
      if (runtime.parseReportPath.isNotEmpty)
        _DashboardTaskRow(
          'parse',
          _zh ? '整理资料' : 'Organize materials',
          _zh ? '文档库' : 'Document Library',
          _zh ? '整理结果已生成' : 'organized result ready',
          Icons.document_scanner_outlined,
          'document-library',
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardTaskRow(
          'kb',
          _zh ? '生成知识库' : 'Generate knowledge base',
          _zh ? '知识库' : 'Knowledge',
          _zh ? '可测试' : 'ready to test',
          Icons.storage_outlined,
          'knowledge-package-management',
        ),
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _DashboardTaskRow(
          'search',
          _zh ? '知识库验证' : 'KB verification',
          _zh ? '知识库' : 'Knowledge Base',
          _zh
              ? '${runtime.searchResults.length} 条结果'
              : '${runtime.searchResults.length} results',
          Icons.manage_search_outlined,
          'retrieval-verification',
        ),
      if (runtime.hasMarkdown)
        _DashboardTaskRow(
          'doc',
          _zh ? '生成文档' : 'Generate document',
          _zh ? '文档生成' : 'Generation',
          runtime.hasExportedDocument
              ? (_zh ? '已导出' : 'exported')
              : (_zh ? '待导出' : 'waiting export'),
          Icons.description_outlined,
          'document-generation',
        ),
      if (runtime.hasSkill)
        _DashboardTaskRow(
          'skill',
          _zh ? '生成技能' : 'Generate skill',
          _zh ? '技能生成' : 'Skill Builder',
          _displayNameForPath(runtime.skillPath),
          Icons.extension_outlined,
          'skill-factory',
        ),
      if (runtime.hasAgent)
        _DashboardTaskRow(
          'agent',
          _zh ? '创建助手' : 'Create assistant',
          _zh ? '我的助手' : 'My Assistants',
          runtime.hasAgentDialogueExport
              ? (_zh ? '已导出对话' : 'dialogue exported')
              : runtime.hasAgentDialogue
                  ? (_zh ? '已对话' : 'chat saved')
                  : runtime.hasMultiAgentDiscussion
                      ? (_zh ? '已讨论' : 'discussion saved')
                      : (_zh ? '已生成' : 'generated'),
          Icons.smart_toy_outlined,
          'agent-factory-runtime',
        ),
    ];
    final visibleRows = rows;
    return _FigmaCard(
      keyName: 'dashboard-next-actions',
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardPanelTitle(
            title: _zh ? '继续任务' : 'Continue Tasks',
            trailing: TextButton.icon(
              onPressed: visibleRows.isEmpty
                  ? null
                  : () => _clearTasks(rc6, visibleRows),
              icon: const Icon(Icons.delete_sweep_outlined, size: 15),
              label: Text(_zh ? '清空' : 'Clear'),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: visibleRows.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: _DashboardTaskCard(
                      title: _zh ? '添加资料' : 'Add materials',
                      type: _zh ? '下一步' : 'Next step',
                      status: _zh ? '导入真实来源后开始整理' : 'Import sources to start',
                      icon: Icons.upload_file_outlined,
                      pageId: 'document-library',
                      hint: _zh
                          ? '下一步：整理资料并生成知识库'
                          : 'Next: organize and build a KB',
                      onTap: () => widget
                          .onPageChanged(_pageIndexById('document-library')),
                    ),
                  )
                : _LocalScrollBox(
                    bottomPadding: 4,
                    child: Column(
                      children: [
                        for (final row in visibleRows) ...[
                          _DashboardTaskCard(
                            title: row.title,
                            type: row.type,
                            status: row.status,
                            icon: row.icon,
                            pageId: row.pageId,
                            hint: _dashboardTaskHint(row.pageId, _zh),
                            onTap: () => widget
                                .onPageChanged(_pageIndexById(row.pageId)),
                          ),
                          if (row != visibleRows.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardRecentActivity extends StatelessWidget {
  const _DashboardRecentActivity({
    required this.localeCode,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.onPageChanged,
  });

  final String localeCode;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final ledgerRows = runtime.eventLedgerRecords
        .map((record) => _DashboardActivityRow(
              _dashboardEventTitle(record, _zh),
              _dashboardEventDetail(record, _zh),
              _dashboardPageForModule(record.module),
            ))
        .take(5)
        .toList(growable: false);
    final rows = [
      if (runtime.hasImportedFile)
        _DashboardActivityRow(
          _zh ? '新增资料' : 'Materials added',
          _zh ? '${runtime.sourceCount} 个来源' : '${runtime.sourceCount} sources',
          'document-library',
        ),
      if (runtime.parseReportPath.isNotEmpty)
        _DashboardActivityRow(
          _zh ? '资料已整理' : 'Materials organized',
          _zh ? '${runtime.chunkCount} 个片段' : '${runtime.chunkCount} chunks',
          'document-library',
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardActivityRow(
          _zh ? '知识库已更新' : 'Knowledge base updated',
          _zh ? '本地可测试' : 'local test ready',
          'knowledge-package-management',
        ),
      if (runtime.hasMarkdown)
        _DashboardActivityRow(
          _zh ? '文档已生成' : 'Document generated',
          _displayNameForPath(runtime.generatedMarkdownPath),
          'document-generation',
        ),
      if (runtime.hasAgent || runtime.hasMultiAgentDiscussion)
        _DashboardActivityRow(
          _zh ? '助手有新记录' : 'Assistant activity',
          runtime.hasMultiAgentDiscussion
              ? (_zh ? '讨论报告' : 'discussion report')
              : (_zh ? '对话记录' : 'dialogue record'),
          'agent-factory-runtime',
        ),
    ];
    final fallback = [
      _DashboardActivityRow(
        _zh ? '配置状态' : 'Configuration',
        _zh ? '本地模式' : 'local mode',
        'workspace',
      ),
      _DashboardActivityRow(
        _zh ? '技能' : 'Skills',
        runtime.hasSkill
            ? (_zh ? '已生成' : 'generated')
            : (_zh ? '等待生成' : 'waiting'),
        'skill-factory',
      ),
      _DashboardActivityRow(
        _zh ? '助手' : 'Assistants',
        runtime.hasAgent
            ? (_zh ? '已创建' : 'created')
            : (_zh ? '等待创建' : 'waiting'),
        'agent-factory-runtime',
      ),
      _DashboardActivityRow(
        _zh ? '助手对话' : 'Assistant dialogue',
        runtime.hasAgentDialogue
            ? (_zh ? '已保存' : 'saved')
            : (_zh ? '等待对话' : 'waiting'),
        'agent-factory-runtime',
      ),
      _DashboardActivityRow(
        _zh ? '工作小组' : 'Work group',
        runtime.hasMultiAgentDiscussion
            ? (_zh ? '已生成' : 'generated')
            : (_zh ? '等待处理' : 'waiting'),
        'agent-factory-runtime',
      ),
    ];
    final displayRows =
        (ledgerRows.isNotEmpty ? ledgerRows : (rows.isEmpty ? fallback : rows))
            .take(5)
            .toList();
    return _FigmaCard(
      keyName: 'dashboard-recent-activity',
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardPanelTitle(
            title: _zh ? '最近动态' : 'Recent Activity',
            trailing: _DashboardHeaderAction(
              label: _zh ? '查看全部动态' : 'View all activity',
              onPressed: () => onPageChanged(_pageIndexById('reports-audit')),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _LocalScrollBox(
              bottomPadding: 4,
              child: Column(
                children: [
                  for (var index = 0; index < displayRows.length; index++) ...[
                    _DashboardActivityTimelineRow(
                      title: displayRows[index].title,
                      detail: displayRows[index].detail,
                      pageId: displayRows[index].pageId,
                      first: index == 0,
                      last: index == displayRows.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActivityRow {
  const _DashboardActivityRow(this.title, this.detail, this.pageId);

  final String title;
  final String detail;
  final String pageId;
}

String _dashboardEventTitle(Rc6EventLedgerRecord record, bool zh) {
  final target = record.targetName.trim();
  final base = switch (record.eventType) {
    'add_document' || 'import_document' => zh ? '新增资料' : 'Materials added',
    'delete_document' => zh ? '资料已删除' : 'Material deleted',
    'organize_document' => zh ? '资料已整理' : 'Materials organized',
    'generate_knowledge_base' => zh ? '知识库已更新' : 'Knowledge base updated',
    'delete_knowledge_base' => zh ? '知识库已删除' : 'Knowledge base deleted',
    'validate_knowledge_base' => zh ? '知识库已验证' : 'Knowledge base verified',
    'generate_document' => zh ? '文档已生成' : 'Document generated',
    'generate_skill' => zh ? '技能已生成' : 'Skill generated',
    'create_agent' => zh ? '助手已创建' : 'Assistant created',
    'edit_agent' => zh ? '助手已更新' : 'Assistant updated',
    'delete_agent' => zh ? '助手已删除' : 'Assistant deleted',
    'send_agent_message' => zh ? '助手有新对话' : 'Assistant replied',
    'save_artifact' => zh ? '成果已保存' : 'Output saved',
    'delete_artifact' => zh ? '成果已删除' : 'Output deleted',
    'export_document' => zh ? '文档已导出' : 'Document exported',
    'export_artifact' => zh ? '成果已导出' : 'Output exported',
    'failure_event' => zh ? '操作失败' : 'Action failed',
    _ => record.action.isEmpty ? (zh ? '操作记录' : 'Activity') : record.action,
  };
  return target.isEmpty ? base : '$base · $target';
}

String _dashboardEventDetail(Rc6EventLedgerRecord record, bool zh) {
  if (record.errorMessage.trim().isNotEmpty) {
    return record.errorMessage.trim();
  }
  final status = record.status.trim().isEmpty ? 'recorded' : record.status;
  final path = record.artifactPath.trim();
  if (path.isNotEmpty) {
    return _displayNameForPath(path);
  }
  return zh ? _zhStatusLabel(status) : status;
}

String _dashboardPageForModule(String module) => switch (module) {
      'document_library' => 'document-library',
      'knowledge_base' => 'knowledge-package-management',
      'document_generation' => 'document-generation',
      'skill' => 'skill-factory',
      'agent' => 'agent-factory-runtime',
      'artifact_center' => 'artifact-center',
      _ => 'workspace',
    };

String _dashboardArtifactDetail(Rc6ArtifactRecord artifact, bool zh) {
  final status = artifact.status.trim();
  final type = artifact.artifactType.trim();
  final label = zh ? _zhStatusLabel(status) : status;
  if (type.isEmpty) return label;
  return label.isEmpty ? type : '$type · $label';
}

String _zhStatusLabel(String status) => switch (status) {
      'completed' => '已完成',
      'failed' => '失败',
      'llm_completed' => '真实模型已回复',
      'local_fallback' => '本地占位回复',
      'local_fallback_saved' => '本地占位成果',
      'llm_completed_saved' => '真实回复成果',
      'exported' => '已导出',
      'deleted' => '已删除',
      _ => status,
    };

class _DashboardPanelTitle extends StatelessWidget {
  const _DashboardPanelTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _HTKWTokens.visualTokens(Theme.of(context).brightness)
                .borderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DashboardHeaderAction extends StatelessWidget {
  const _DashboardHeaderAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DashboardTaskCard extends StatelessWidget {
  const _DashboardTaskCard({
    required this.title,
    required this.type,
    required this.status,
    required this.icon,
    required this.pageId,
    required this.hint,
    required this.onTap,
  });

  final String title;
  final String type;
  final String status;
  final IconData icon;
  final String pageId;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = _HTKWTokens.moduleColor(pageId);
    final progress = switch (pageId) {
      'document-library' => 0.32,
      'knowledge-package-management' => 0.48,
      'retrieval-verification' => 0.62,
      'document-generation' => 0.76,
      'skill-factory' => 0.86,
      'agent-factory-runtime' => 0.92,
      _ => 0.28,
    };
    return Material(
      color: accent.withValues(
          alpha: brightness == Brightness.dark ? 0.08 : 0.055),
      borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
            border: Border.all(
              color: accent.withValues(
                  alpha: brightness == Brightness.dark ? 0.14 : 0.1),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(
                            alpha: brightness == Brightness.dark ? 0.16 : 0.1),
                        borderRadius:
                            BorderRadius.circular(_DesktopGrid.radiusSmall),
                      ),
                      child: Icon(icon, size: 17, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$type · $status',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: accent.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right,
                        size: 16,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.54)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: progress,
                  color: accent.withValues(alpha: 0.86),
                  backgroundColor: accent.withValues(
                    alpha: brightness == Brightness.dark ? 0.12 : 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dashboardTaskHint(String pageId, bool zh) => switch (pageId) {
      'document-library' =>
        zh ? '下一步：整理资料并生成知识库' : 'Next: organize and build a KB',
      'knowledge-package-management' =>
        zh ? '下一步：测试引用质量' : 'Next: test citation quality',
      'retrieval-verification' => zh ? '下一步：沉淀文档草稿' : 'Next: draft a document',
      'document-generation' =>
        zh ? '下一步：保存或导出成果' : 'Next: save or export output',
      'skill-factory' =>
        zh ? '下一步：复用为助手能力' : 'Next: reuse as assistant capability',
      'agent-factory-runtime' =>
        zh ? '下一步：查看助手记录' : 'Next: review assistant records',
      _ => zh ? '下一步：继续完善工作区' : 'Next: continue the workspace',
    };

class _DashboardActivityTimelineRow extends StatelessWidget {
  const _DashboardActivityTimelineRow({
    required this.title,
    required this.detail,
    required this.pageId,
    required this.first,
    required this.last,
  });

  final String title;
  final String detail;
  final String pageId;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _HTKWTokens.moduleColor(pageId);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1,
                    color: first
                        ? Colors.transparent
                        : _HTKWTokens.visualTokens(Theme.of(context).brightness)
                            .borderSubtle,
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: last
                        ? Colors.transparent
                        : _HTKWTokens.visualTokens(Theme.of(context).brightness)
                            .borderSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

_DashboardActionRow _dashboardNextAction(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) {
    return _DashboardActionRow(
      zh ? '添加资料' : 'Add materials',
      zh ? '当前工作区还没有资料。' : 'The current workspace has no materials yet.',
      Icons.file_upload_outlined,
      'document-library',
      false,
    );
  }
  if (runtime.parseReportPath.isEmpty) {
    return _DashboardActionRow(
      zh ? '整理资料' : 'Organize materials',
      zh
          ? '已有资料，下一步需要整理后才能生成知识库。'
          : 'Materials exist; organize them before building a knowledge base.',
      Icons.document_scanner_outlined,
      'document-library',
      false,
    );
  }
  if (!runtime.hasKnowledgeBase) {
    return _DashboardActionRow(
      zh ? '生成知识库' : 'Generate knowledge base',
      zh
          ? '资料已整理，可以从文档库生成知识库。'
          : 'Materials are organized and ready for a knowledge base.',
      Icons.account_tree_outlined,
      'knowledge-package-management',
      false,
    );
  }
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return _DashboardActionRow(
      zh ? '验证知识库' : 'Verify knowledge base',
      zh
          ? '知识库已生成，建议先用问题验证证据和引用。'
          : 'Knowledge base exists; test evidence and citations next.',
      Icons.manage_search_outlined,
      'retrieval-verification',
      false,
    );
  }
  if (!runtime.hasMarkdown) {
    return _DashboardActionRow(
      zh ? '生成文档' : 'Generate document',
      zh
          ? '知识库已通过测试，可以生成文档草稿。'
          : 'The knowledge base has test results; generate a document draft.',
      Icons.edit_document,
      'document-generation',
      false,
    );
  }
  if (runtime.hasExportedDocument || runtime.hasSkill || runtime.hasAgent) {
    return _DashboardActionRow(
      zh ? '查看成果' : 'View outputs',
      zh
          ? '已有可查看成果，可以打开全部成果导出或追溯。'
          : 'Outputs are available for preview, export, or trace.',
      Icons.folder_copy_outlined,
      'artifact-center',
      true,
    );
  }
  return _DashboardActionRow(
    zh ? '生成技能' : 'Generate skill',
    zh
        ? '已有文档草稿，可以继续生成技能或创建助手。'
        : 'A document draft exists; continue with skills or assistants.',
    Icons.extension_outlined,
    'skill-factory',
    false,
  );
}

class _DashboardActionRow {
  const _DashboardActionRow(
      this.title, this.detail, this.icon, this.pageId, this.done);

  final String title;
  final String detail;
  final IconData icon;
  final String pageId;
  final bool done;
}

class _DashboardTaskRow {
  const _DashboardTaskRow(
      this.id, this.title, this.type, this.status, this.icon, this.pageId);

  final String id;
  final String title;
  final String type;
  final String status;
  final IconData icon;
  final String pageId;
}

class _DashboardArtifactOverview extends StatelessWidget {
  const _DashboardArtifactOverview({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final catalogRows = runtime.artifactRecords
        .where((artifact) => artifact.isActive)
        .map((artifact) => _DashboardActivityRow(
              artifact.title.trim().isEmpty
                  ? (_zh ? '成果' : 'Output')
                  : artifact.title.trim(),
              _dashboardArtifactDetail(artifact, _zh),
              _dashboardPageForModule(artifact.sourceModule),
            ))
        .take(3)
        .toList(growable: false);
    final rows = [
      for (final artifact in runtime.agentArtifacts)
        _DashboardActivityRow(
          artifact.agentName.isEmpty
              ? (_zh ? '助手回复成果' : 'Assistant reply output')
              : (_zh
                  ? '${artifact.agentName}回复成果'
                  : '${artifact.agentName} reply output'),
          _zh ? '助手成果' : 'Assistant output',
          'artifact-center',
        ),
      if (runtime.hasMarkdown)
        _DashboardActivityRow(
          _zh ? '生成文档' : 'Generated document',
          _zh ? '文档' : 'Doc',
          'document-generation',
        ),
      if (runtime.hasExportedDocument)
        _DashboardActivityRow(
          _zh ? '导出文档' : 'Exported document',
          _zh ? '导出' : 'Export',
          'artifact-center',
        ),
      if (runtime.hasSkill)
        _DashboardActivityRow(
          _zh ? '知识技能' : 'Knowledge skill',
          'Skill',
          'skill-factory',
        ),
      if (runtime.hasAgent)
        _DashboardActivityRow(
          _zh ? '知识助手' : 'Knowledge assistant',
          _zh ? '助手' : 'Assistant',
          'agent-factory-runtime',
        ),
      if (runtime.hasMultiAgentDiscussion)
        _DashboardActivityRow(
          _zh ? '工作小组报告' : 'Work group report',
          _zh ? '小组' : 'Work group',
          'agent-factory-runtime',
        ),
    ];
    final hasOutputs = catalogRows.isNotEmpty || rows.isNotEmpty;
    final sourceRows = catalogRows.isNotEmpty ? catalogRows : rows;
    final displayRows = (sourceRows.isEmpty
            ? [
                _DashboardActivityRow(
                  _zh ? '还没有成果' : 'No output yet',
                  _zh ? '先生成文档或技能' : 'generate a document or skill',
                  'artifact-center',
                )
              ]
            : sourceRows)
        .take(3)
        .toList();
    return _FigmaCard(
      keyName: 'dashboard-artifact-overview',
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardPanelTitle(
            title: _zh ? '最近成果' : 'Recent Outputs',
          ),
          const SizedBox(height: 10),
          Expanded(
            child: hasOutputs
                ? _LocalScrollBox(
                    bottomPadding: 4,
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < displayRows.length;
                            index++) ...[
                          _DashboardOutputPreviewRow(
                            title: displayRows[index].title,
                            detail: displayRows[index].detail,
                            pageId: displayRows[index].pageId,
                            onTap: () => onPageChanged(
                                _pageIndexById('artifact-center')),
                          ),
                          if (index < displayRows.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  )
                : _DashboardOutputPreviewRow(
                    title: displayRows.first.title,
                    detail: displayRows.first.detail,
                    pageId: displayRows.first.pageId,
                    expanded: true,
                    onTap: () =>
                        onPageChanged(_pageIndexById('artifact-center')),
                  ),
          ),
          SizedBox(
            height: 34,
            child: _DisplayAction(
              label: _zh ? '查看全部成果' : 'View all outputs',
              icon: Icons.folder_copy_outlined,
              onPressed: () => onPageChanged(_pageIndexById('artifact-center')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardOutputPreviewRow extends StatelessWidget {
  const _DashboardOutputPreviewRow({
    required this.title,
    required this.detail,
    required this.pageId,
    required this.onTap,
    this.expanded = false,
  });

  final String title;
  final String detail;
  final String pageId;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = _HTKWTokens.moduleColor(pageId);
    final empty = title.contains('还没有') || title.contains('No output');
    return Material(
      color: Color.alphaBlend(
        accent.withValues(alpha: brightness == Brightness.dark ? 0.08 : 0.04),
        _HTKWTokens.glassSurface(brightness),
      ),
      borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
        onTap: onTap,
        child: Container(
          height: expanded ? double.infinity : 58,
          constraints: BoxConstraints(minHeight: expanded ? 78 : 58),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 14 : 12,
            vertical: expanded ? 12 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
            border: Border.all(
              color: accent.withValues(
                  alpha: brightness == Brightness.dark ? 0.14 : 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: expanded ? 42 : 34,
                height: expanded ? 42 : 34,
                decoration: BoxDecoration(
                  color: accent.withValues(
                      alpha: brightness == Brightness.dark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(_DesktopGrid.radiusSmall),
                ),
                child: Icon(_dashboardOutputIcon(pageId),
                    size: expanded ? 20 : 17, color: accent),
              ),
              SizedBox(width: expanded ? 12 : 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: expanded ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: expanded ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: expanded ? 10 : 8),
              Icon(
                empty ? Icons.add_circle_outline : Icons.open_in_new_outlined,
                size: 16,
                color: colors.onSurfaceVariant.withValues(alpha: 0.64),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _dashboardOutputIcon(String pageId) => switch (pageId) {
      'document-generation' => Icons.description_outlined,
      'skill-factory' => Icons.extension_outlined,
      'agent-factory-runtime' => Icons.smart_toy_outlined,
      _ => Icons.folder_copy_outlined,
    };
