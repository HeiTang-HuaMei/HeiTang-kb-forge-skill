import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SkillFactoryWorkflowSurface extends StatefulWidget {
  const SkillFactoryWorkflowSurface({
    super.key,
    required this.localeCode,
    this.workflow,
  });

  final String localeCode;
  final Map<String, dynamic>? workflow;

  @override
  State<SkillFactoryWorkflowSurface> createState() =>
      _SkillFactoryWorkflowSurfaceState();
}

class _SkillFactoryWorkflowSurfaceState
    extends State<SkillFactoryWorkflowSurface>
    with SingleTickerProviderStateMixin {
  static const _tabs = <String>[
    'overview',
    'evidence',
    'methodology',
    'candidates',
    'hierarchy',
    'suite',
    'reports',
    'export',
  ];

  late final TabController _tabController =
      TabController(length: _tabs.length, vsync: this);
  late final Future<Map<String, dynamic>> _workflowFuture =
      widget.workflow == null
          ? _loadWorkflow()
          : Future<Map<String, dynamic>>.value(widget.workflow);
  int selectedIndex = 0;

  Future<Map<String, dynamic>> _loadWorkflow() async {
    try {
      return (jsonDecode(await rootBundle.loadString(
              'assets/fixtures/p2_2/skill_suite_workflow.json')) as Map)
          .cast<String, dynamic>();
    } catch (_) {
      return sampleSkillSuiteWorkflow;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _workflowFuture,
      initialData: widget.workflow ?? sampleSkillSuiteWorkflow,
      builder: (context, snapshot) {
        final workflow = snapshot.data ?? sampleSkillSuiteWorkflow;
        return _WorkflowContent(
          workflow: workflow,
          localeCode: widget.localeCode,
          tabController: _tabController,
          selectedIndex: selectedIndex,
          onTabSelected: (index) => setState(() => selectedIndex = index),
        );
      },
    );
  }
}

class _WorkflowContent extends StatelessWidget {
  const _WorkflowContent({
    required this.workflow,
    required this.localeCode,
    required this.tabController,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final Map<String, dynamic> workflow;
  final String localeCode;
  final TabController tabController;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  bool get zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final metadata = _map(workflow['metadata']);
    final package = _map(workflow['knowledge_package']);
    final reports = _map(workflow['reports']);
    final governance = _map(reports['governance']);
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 14,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zh
                          ? 'Knowledge-to-Skill Suite 工作流'
                          : 'Knowledge-to-Skill Suite Workflow',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${package['package_id']} · ${package['source_count']} sources · ${package['chunk_count']} chunks',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zh
                          ? 'Core 证据快照。Web 仅展示可审计产物，不执行本地 CLI。'
                          : 'Core evidence snapshot. Web displays auditable artifacts and does not execute the local CLI.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusPill(
                    icon: Icons.inventory_2_outlined,
                    label: '${metadata['release_version']}',
                    color: colors.primary,
                  ),
                  _StatusPill(
                    icon: Icons.pending_actions_outlined,
                    label: '${metadata['release_state']}',
                    color: colors.tertiary,
                  ),
                  _StatusPill(
                    icon: Icons.verified_outlined,
                    label:
                        'governance=${governance['status'] ?? 'review_required'}',
                    color: governance['status'] == 'pass'
                        ? Colors.green.shade700
                        : colors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PipelineStrip(localeCode: localeCode),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: onTabSelected,
            tabs: [
              _tab(
                  'overview', Icons.dashboard_outlined, zh ? '总览' : 'Overview'),
              _tab('evidence', Icons.fact_check_outlined,
                  zh ? '证据' : 'Evidence'),
              _tab('methodology', Icons.account_tree_outlined,
                  zh ? '方法论' : 'Methodology'),
              _tab('candidates', Icons.playlist_add_check_outlined,
                  zh ? '候选' : 'Candidates'),
              _tab('hierarchy', Icons.schema_outlined, zh ? '层级' : 'Hierarchy'),
              _tab('suite', Icons.hub_outlined, zh ? '套件' : 'Suite'),
              _tab('reports', Icons.assessment_outlined, zh ? '报告' : 'Reports'),
              _tab('export', Icons.archive_outlined, zh ? '导出' : 'Export'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: ValueKey('workflow-view-${_tabId(selectedIndex)}'),
          child: _selectedView(),
        ),
      ],
    );
  }

  Tab _tab(String id, IconData icon, String label) {
    return Tab(
      key: ValueKey('workflow-tab-$id'),
      icon: Icon(icon, size: 18),
      text: label,
      height: 56,
    );
  }

  String _tabId(int index) {
    const ids = <String>[
      'overview',
      'evidence',
      'methodology',
      'candidates',
      'hierarchy',
      'suite',
      'reports',
      'export',
    ];
    return ids[index];
  }

  Widget _selectedView() {
    switch (selectedIndex) {
      case 1:
        return _evidenceView();
      case 2:
        return _methodologyView();
      case 3:
        return _candidatesView();
      case 4:
        return _hierarchyView();
      case 5:
        return _suiteView();
      case 6:
        return _reportsView();
      case 7:
        return _exportView();
      default:
        return _overviewView();
    }
  }

  Widget _overviewView() {
    final package = _map(workflow['knowledge_package']);
    final methodology = _map(workflow['methodology']);
    final suite = _map(workflow['suite']);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _MetricSection(
                icon: Icons.inventory_2_outlined,
                title: zh ? '知识包' : 'Knowledge Package',
                status: '${package['status']}',
                rows: {
                  zh ? '来源' : 'Sources': '${package['source_count']}',
                  zh ? '分块' : 'Chunks': '${package['chunk_count']}',
                  zh ? '包 ID' : 'Package ID': '${package['package_id']}',
                },
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricSection(
                icon: Icons.account_tree_outlined,
                title: zh ? '方法论' : 'Methodology',
                status: '${methodology['status']}',
                rows: {
                  zh ? '模块' : 'Modules':
                      '${_list(methodology['modules']).length}',
                  zh ? '置信度' : 'Confidence': '${methodology['confidence']}',
                  zh ? '来源包' : 'Source package':
                      '${methodology['source_package_id']}',
                },
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricSection(
                icon: Icons.hub_outlined,
                title: zh ? 'Skill Suite' : 'Skill Suite',
                status: '${suite['status']}',
                rows: {
                  'Skills': '${suite['skill_count']}',
                  zh ? '路由规则' : 'Routing rules':
                      '${_list(suite['routing_rules']).length}',
                  zh ? '依赖边' : 'Dependency edges':
                      '${_list(suite['dependency_edges']).length}',
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _evidenceView() {
    final windows = _list(workflow['evidence_windows']);
    return _SurfaceSection(
      title: zh ? 'Evidence Windows' : 'Evidence Windows',
      subtitle: zh
          ? '每个窗口保留来源、引用、置信度与风险标记。'
          : 'Each window preserves source, citation, confidence, and risk flags.',
      children: [
        for (final item in windows)
          _DataRowBlock(
            title: '${_map(item)['title']}',
            badge: 'confidence=${_map(item)['confidence']}',
            rows: {
              'id': '${_map(item)['evidence_id']}',
              zh ? '来源' : 'Source': '${_map(item)['source_path']}',
              zh ? '引用' : 'Citation': '${_map(item)['citation']}',
              zh ? '风险' : 'Risk': _list(_map(item)['risk_flags']).isEmpty
                  ? 'none'
                  : _list(_map(item)['risk_flags']).join(', '),
            },
          ),
      ],
    );
  }

  Widget _methodologyView() {
    final methodology = _map(workflow['methodology']);
    final modules = _list(methodology['modules']);
    return _SurfaceSection(
      title: zh ? 'Methodology Modules' : 'Methodology Modules',
      subtitle:
          'source_package=${methodology['source_package_id']} · confidence=${methodology['confidence']}',
      children: [
        for (final item in modules)
          _DataRowBlock(
            title: '${_map(item)['title']}',
            badge: '${_map(item)['status']}',
            rows: {
              'id': '${_map(item)['module_id']}',
              zh ? '原则' : 'Principle': '${_map(item)['principle']}',
              zh ? '工作流' : 'Workflow': '${_map(item)['workflow']}',
              zh ? '证据' : 'Evidence':
                  _list(_map(item)['evidence_ids']).join(', '),
            },
          ),
      ],
    );
  }

  Widget _candidatesView() {
    final candidates = _list(workflow['candidates']);
    return _SurfaceSection(
      title: zh ? 'Skill Candidates' : 'Skill Candidates',
      subtitle: zh
          ? '候选 Skill 保留类型、触发条件、证据与 merge/split 建议。'
          : 'Candidates retain type, trigger, evidence, and merge/split recommendations.',
      children: [
        for (final item in candidates)
          _DataRowBlock(
            title: '${_map(item)['title']}',
            badge:
                '${_map(item)['type']} · ${_map(item)['status']} · ${_map(item)['confidence']}',
            rows: {
              'id': '${_map(item)['candidate_id']}',
              zh ? '触发' : 'Trigger': '${_map(item)['trigger']}',
              zh ? '证据' : 'Evidence':
                  _list(_map(item)['evidence_ids']).join(', '),
              zh ? '建议' : 'Recommendation': '${_map(item)['recommendation']}',
            },
          ),
      ],
    );
  }

  Widget _hierarchyView() {
    final hierarchy = _map(workflow['hierarchy']);
    final levels = _map(hierarchy['levels']);
    return _SurfaceSection(
      title: zh ? 'Skill Hierarchy' : 'Skill Hierarchy',
      subtitle: '${hierarchy['status']}',
      children: [
        for (final entry in levels.entries)
          _DataRowBlock(
            title: entry.key,
            badge: '${_list(entry.value).length} skills',
            rows: {
              zh ? 'Skill IDs' : 'Skill IDs': _list(entry.value).join(', '),
            },
          ),
      ],
    );
  }

  Widget _suiteView() {
    final suite = _map(workflow['suite']);
    return _SurfaceSection(
      title: zh ? 'Skill Suite Contract' : 'Skill Suite Contract',
      subtitle:
          '${suite['suite_id']} · ${suite['status']} · skills=${suite['skill_count']}',
      children: [
        _DataRowBlock(
          title: zh ? 'Routing Rules' : 'Routing Rules',
          badge: '${_list(suite['routing_rules']).length}',
          rows: {
            for (final item in _list(suite['routing_rules']))
              '${_map(item)['trigger']}': '${_map(item)['skill_id']}',
          },
        ),
        _DataRowBlock(
          title: zh ? 'Dependency Graph' : 'Dependency Graph',
          badge: '${_list(suite['dependency_edges']).length}',
          rows: {
            for (final item in _list(suite['dependency_edges']))
              '${_map(item)['from']}': '${_map(item)['to']}',
          },
        ),
      ],
    );
  }

  Widget _reportsView() {
    final reports = _map(workflow['reports']);
    return _SurfaceSection(
      title: zh ? 'Governance Reports' : 'Governance Reports',
      subtitle: zh
          ? 'Validation、diff、installability 与 governance 均来自 Core 报告。'
          : 'Validation, diff, installability, and governance come from Core reports.',
      children: [
        for (final entry in reports.entries)
          _DataRowBlock(
            title: entry.key,
            badge: '${_map(entry.value)['status']}',
            rows: {
              'release_ready': '${_map(entry.value)['release_ready'] ?? false}',
              if (entry.key == 'diff')
                'baseline_provided':
                    '${_map(entry.value)['baseline_provided']}',
              if (entry.key == 'diff')
                'added/removed/changed':
                    '${_map(entry.value)['added_count']}/${_map(entry.value)['removed_count']}/${_map(entry.value)['changed_count']}',
              'report_path': '${_map(entry.value)['report_path']}',
            },
          ),
      ],
    );
  }

  Widget _exportView() {
    final export = _map(workflow['export']);
    final boundaries = _map(export['runtime_boundary']);
    return _SurfaceSection(
      title: zh ? 'Skill Pack Export' : 'Skill Pack Export',
      subtitle: '${export['status']} · ${export['manifest_path']}',
      children: [
        _DataRowBlock(
          title: zh ? 'Pack Manifest' : 'Pack Manifest',
          badge: '${export['file_count']} files',
          rows: {
            'local_first': '${export['local_first']}',
            'provider_required': '${boundaries['provider_required']}',
            'external_runtime_required':
                '${boundaries['external_runtime_required']}',
            'platform_binding': '${boundaries['platform_binding']}',
          },
        ),
        _DataRowBlock(
          title: zh ? 'Web Boundary' : 'Web Boundary',
          badge: 'static_only',
          rows: {
            'runtime_execution_claimed':
                '${_map(workflow['metadata'])['runtime_execution_claimed']}',
            'tests_require_real_llm_api_network':
                '${workflow['tests_require_real_llm_api_network']}',
          },
        ),
      ],
    );
  }
}

class _PipelineStrip extends StatelessWidget {
  const _PipelineStrip({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final zh = localeCode == 'zh-CN';
    final stages = <(IconData, String)>[
      (Icons.inventory_2_outlined, zh ? '知识包' : 'Knowledge Package'),
      (Icons.fact_check_outlined, zh ? '证据' : 'Evidence'),
      (Icons.account_tree_outlined, zh ? '方法论' : 'Methodology'),
      (Icons.playlist_add_check_outlined, zh ? '候选' : 'Candidates'),
      (Icons.schema_outlined, zh ? '层级' : 'Hierarchy'),
      (Icons.hub_outlined, 'Skill Suite'),
      (Icons.assessment_outlined, zh ? '报告' : 'Reports'),
      (Icons.archive_outlined, zh ? '导出' : 'Export'),
    ];
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var index = 0; index < stages.length; index++) ...[
            _PipelineStage(icon: stages[index].$1, label: stages[index].$2),
            if (index < stages.length - 1)
              Icon(Icons.chevron_right,
                  size: 18, color: colors.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

class _PipelineStage extends StatelessWidget {
  const _PipelineStage({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SurfaceSection extends StatelessWidget {
  const _SurfaceSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const Divider(height: 24),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({
    required this.icon,
    required this.title,
    required this.status,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final String status;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return _SurfaceSection(
      title: title,
      subtitle: status,
      children: [
        _DataRowBlock(
          title: title,
          badge: status,
          rows: rows,
          icon: icon,
        ),
      ],
    );
  }
}

class _DataRowBlock extends StatelessWidget {
  const _DataRowBlock({
    required this.title,
    required this.badge,
    required this.rows,
    this.icon = Icons.description_outlined,
  });

  final String title;
  final String badge;
  final Map<String, String> rows;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(
              icon: Icons.check_circle_outline,
              label: badge,
              color: colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final entry in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 148,
                  child: Text(
                    entry.key,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : const <String, dynamic>{};

List<dynamic> _list(dynamic value) => value is List ? value : const <dynamic>[];

const sampleSkillSuiteWorkflow = <String, dynamic>{
  'metadata': {
    'release_version': 'v4.2.0',
    'release_state': 'release_candidate',
    'p2_2_status': 'implementation_complete_release_pending',
    'core_commit': 'ffb0c1f3375eb1fc365f1ee385806b60bfcc7e43',
    'fixture_kind': 'contract_evidence_snapshot',
    'runtime_execution_claimed': false,
  },
  'knowledge_package': {
    'package_id': 'pkg-operations',
    'status': 'validated',
    'source_count': 3,
    'chunk_count': 18,
  },
  'evidence_windows': [
    {
      'evidence_id': 'window_001',
      'title': 'Evidence-led operations',
      'source_path': 'knowledge/operations.md',
      'citation': 'operations.md#review-boundary',
      'confidence': 0.94,
      'risk_flags': <String>[],
    },
    {
      'evidence_id': 'window_002',
      'title': 'Scoped validation',
      'source_path': 'knowledge/testing.md',
      'citation': 'testing.md#changed-file-impact',
      'confidence': 0.91,
      'risk_flags': <String>['requires_release_review'],
    },
  ],
  'methodology': {
    'source_package_id': 'pkg-operations',
    'status': 'evidence_backed',
    'confidence': 0.92,
    'modules': [
      {
        'module_id': 'methodology_module_001',
        'title': 'Evidence-led Operations',
        'status': 'supported',
        'principle': 'Prefer repository evidence over unsupported claims.',
        'workflow': 'Inspect, classify, validate, and record.',
        'evidence_ids': <String>['window_001'],
      },
      {
        'module_id': 'methodology_module_002',
        'title': 'Scoped Release Review',
        'status': 'supported',
        'principle': 'Escalate validation only when impact conditions trigger.',
        'workflow': 'Select impact gate, review evidence, then release.',
        'evidence_ids': <String>['window_002'],
      },
    ],
  },
  'candidates': [
    {
      'candidate_id': 'planning-release-governance',
      'title': 'Release Governance Planner',
      'type': 'planning',
      'status': 'accepted',
      'confidence': 0.93,
      'trigger': 'Plan a governed release.',
      'evidence_ids': <String>['window_001', 'window_002'],
      'recommendation': 'keep',
    },
    {
      'candidate_id': 'functional-impact-validation',
      'title': 'Impact Validation',
      'type': 'functional',
      'status': 'accepted',
      'confidence': 0.91,
      'trigger': 'Select validation for changed files.',
      'evidence_ids': <String>['window_002'],
      'recommendation': 'keep',
    },
    {
      'candidate_id': 'atomic-record-evidence',
      'title': 'Record Validation Evidence',
      'type': 'atomic',
      'status': 'accepted',
      'confidence': 0.9,
      'trigger': 'Persist a validation result.',
      'evidence_ids': <String>['window_001'],
      'recommendation': 'keep',
    },
  ],
  'hierarchy': {
    'status': 'pass',
    'levels': {
      'planning': <String>['planning-release-governance'],
      'functional': <String>['functional-impact-validation'],
      'atomic': <String>['atomic-record-evidence'],
    },
  },
  'suite': {
    'suite_id': 'operations-governance-suite',
    'status': 'ready',
    'skill_count': 3,
    'routing_rules': [
      {
        'trigger': 'release planning',
        'skill_id': 'planning-release-governance'
      },
      {
        'trigger': 'changed file validation',
        'skill_id': 'functional-impact-validation'
      },
    ],
    'dependency_edges': [
      {
        'from': 'planning-release-governance',
        'to': 'functional-impact-validation'
      },
      {'from': 'functional-impact-validation', 'to': 'atomic-record-evidence'},
    ],
  },
  'reports': {
    'validation': {
      'status': 'pass',
      'release_ready': true,
      'report_path': 'reports/suite_validation_report.json',
    },
    'diff': {
      'status': 'pass',
      'release_ready': true,
      'baseline_provided': true,
      'added_count': 3,
      'removed_count': 0,
      'changed_count': 0,
      'report_path': 'reports/suite_diff_report.json',
    },
    'installability': {
      'status': 'pass',
      'release_ready': true,
      'report_path': 'reports/suite_installability_report.json',
    },
    'governance': {
      'status': 'pass',
      'release_ready': true,
      'report_path': 'reports/suite_governance_report.json',
    },
  },
  'export': {
    'status': 'ready',
    'file_count': 14,
    'local_first': true,
    'manifest_path': 'skill_pack_manifest.json',
    'runtime_boundary': {
      'provider_required': false,
      'external_runtime_required': false,
      'platform_binding': false,
    },
  },
  'tests_require_real_llm_api_network': false,
};
