import 'package:flutter/material.dart';

import '../core_bridge/core_bridge_contract.dart';
import 'task_model.dart';

class TaskWorkbenchSurface extends StatelessWidget {
  const TaskWorkbenchSurface({
    super.key,
    required this.localeCode,
    required this.workspace,
    this.isWebRuntime = false,
    this.tasks,
    this.onRetry,
    this.onCancel,
  });

  final String localeCode;
  final String workspace;
  final bool isWebRuntime;
  final List<WorkbenchTaskSnapshot>? tasks;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  @override
  Widget build(BuildContext context) {
    final snapshots = tasks ?? initialWorkbenchTasks(workspace);
    return LayoutBuilder(
      key: const Key('task-workbench-surface'),
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final sidePanel = _WorkbenchSidePanel(
          localeCode: localeCode,
          tasks: snapshots,
          workspace: workspace,
        );
        final mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentTaskPanel(
              localeCode: localeCode,
              workspace: workspace,
              tasks: snapshots,
              isWebRuntime: isWebRuntime,
              onRetry: onRetry,
              onCancel: onCancel,
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: mainColumn),
              const SizedBox(width: 12),
              SizedBox(width: 316, child: sidePanel),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mainColumn,
            const SizedBox(height: 12),
            sidePanel,
          ],
        );
      },
    );
  }
}

class _CurrentTaskPanel extends StatelessWidget {
  const _CurrentTaskPanel({
    required this.localeCode,
    required this.workspace,
    required this.tasks,
    required this.isWebRuntime,
    this.onRetry,
    this.onCancel,
  });

  final String localeCode;
  final String workspace;
  final List<WorkbenchTaskSnapshot> tasks;
  final bool isWebRuntime;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = tasks.firstWhere(
      (task) => !task.status.countsAsSucceeded,
      orElse: () => tasks.first,
    );
    final outputContract = CoreOutputPathContract(workspace);
    return Container(
      key: const Key('dashboard-current-task-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final icon = Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard_customize_outlined,
                  color: Colors.white, size: 23),
            );
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _HeroBadge(
                    label: _zh ? '当前任务' : 'Current task',
                    icon: Icons.adjust_outlined,
                  ),
                  _HeroBadge(
                    label: _zh ? '本地优先' : 'Local first',
                    icon: Icons.shield_outlined,
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  _zh
                      ? '导入资料 → 解析资料 → 构建知识库'
                      : 'Import Materials -> Parse Materials -> Build Knowledge Base',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _zh
                      ? '一个产物驱动的知识供应链：每一阶段接收上游产物，生成本阶段产物，再交给下一阶段。'
                      : 'One artifact-driven knowledge supply chain: each stage consumes an upstream artifact, produces its output, then hands off downstream.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: copy),
                  ]),
                  const SizedBox(height: 10),
                  _ExecutionBadge(
                      localeCode: localeCode, isWebRuntime: isWebRuntime),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: copy),
                const SizedBox(width: 12),
                _ExecutionBadge(
                    localeCode: localeCode, isWebRuntime: isWebRuntime),
              ],
            );
          }),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final primary = _DashboardTaskBlock(
              title: _zh ? '一个主操作' : 'One primary action',
              value: _zh ? '选择本地文件或文件夹' : 'Choose a local file or folder',
              icon: Icons.folder_open_outlined,
              emphasized: true,
            );
            final progress = _DashboardTaskBlock(
              title: _zh ? '当前阶段状态' : 'Current stage status',
              value: _statusCopy(current.status, _zh),
              icon: Icons.hourglass_empty_outlined,
            );
            final output = _DashboardTaskBlock(
              title: _zh ? '预期产物' : 'Expected output',
              value: outputContract.forAction('file_import'),
              icon: Icons.drive_file_move_outline,
            );
            if (!wide) {
              return Column(children: [
                primary,
                const SizedBox(height: 10),
                progress,
                const SizedBox(height: 10),
                output,
              ]);
            }
            return Row(children: [
              Expanded(flex: 5, child: primary),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: progress),
              const SizedBox(width: 10),
              Expanded(flex: 4, child: output),
            ]);
          }),
          _TaskControlActions(
            localeCode: localeCode,
            task: current,
            onRetry: onRetry,
            onCancel: onCancel,
          ),
          const SizedBox(height: 12),
          _DashboardChainSummary(localeCode: localeCode),
          const SizedBox(height: 12),
          _DashboardCompactActivity(
              localeCode: localeCode, workspace: workspace),
        ],
      ),
    );
  }
}

class _TaskControlActions extends StatelessWidget {
  const _TaskControlActions({
    required this.localeCode,
    required this.task,
    this.onRetry,
    this.onCancel,
  });

  final String localeCode;
  final WorkbenchTaskSnapshot task;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (task.status.canCancel && onCancel != null) {
      actions.add(OutlinedButton.icon(
        key: Key('task-control-cancel-${task.stage.id}'),
        onPressed: () => onCancel?.call(task),
        icon: const Icon(Icons.pause_circle_outline),
        label: Text(_zh ? '取消任务' : 'Cancel task'),
      ));
    }
    if (task.status.canRetry && onRetry != null) {
      actions.add(FilledButton.icon(
        key: Key('task-control-retry-${task.stage.id}'),
        onPressed: () => onRetry?.call(task),
        icon: const Icon(Icons.refresh_outlined),
        label: Text(_zh ? '重试任务' : 'Retry task'),
      ));
    }
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        key: const Key('task-control-actions'),
        spacing: 8,
        runSpacing: 8,
        children: actions,
      ),
    );
  }
}

class _DashboardTaskBlock extends StatelessWidget {
  const _DashboardTaskBlock({
    required this.title,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: emphasized
              ? colors.primary.withValues(alpha: 0.28)
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 3),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCompactActivity extends StatelessWidget {
  const _DashboardCompactActivity({
    required this.localeCode,
    required this.workspace,
  });

  final String localeCode;
  final String workspace;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 820;
      final outputs = _DashboardMiniList(
        title: _zh ? '最近输出' : 'Recent Outputs',
        rows: [
          [
            _zh ? '导入清单' : 'Import manifest',
            '$workspace/workbench_runs/import_manifest'
          ],
          [
            _zh ? '验证报告' : 'Validation report',
            '$workspace/workbench_runs/validation_report'
          ],
        ],
      );
      final activity = _DashboardMiniList(
        title: _zh ? '最近活动' : 'Recent Activity',
        rows: [
          [
            _zh ? '导入阶段' : 'Import stage',
            _zh ? '等待资料' : 'Waiting for material'
          ],
          [_zh ? '完成门禁' : 'Completion gate', _zh ? '保持关闭' : 'Closed'],
        ],
      );
      if (!wide) {
        return Column(
            children: [outputs, const SizedBox(height: 10), activity]);
      }
      return Row(children: [
        Expanded(child: outputs),
        const SizedBox(width: 10),
        Expanded(child: activity),
      ]);
    });
  }
}

class _DashboardMiniList extends StatelessWidget {
  const _DashboardMiniList({required this.title, required this.rows});

  final String title;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                      child: Text(row[0],
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w800))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(row[1],
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardChainSummary extends StatelessWidget {
  const _DashboardChainSummary({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rows = _zh
        ? [
            ['导入资料', '新来源', '导入清单 / 来源清单', '解析资料'],
            ['解析资料', '导入清单', '解析内容 / 解析报告', '构建知识库'],
            ['构建知识库', '解析内容', '知识库 / 文档切片清单', '生成 Skill'],
            ['生成 Skill', '知识库', 'Skill 草稿 / 验证报告', 'Agent Creation Package 映射'],
            [
              'Agent Creation Package',
              '知识库 + Skill',
              '输入映射 / 包预览 / 导出草稿',
              '验证与导出'
            ],
            ['验证与导出', '全部产物', '报告 / 受控导出摘要', '完成交接'],
          ]
        : [
            [
              'Import Materials',
              'New source',
              'Import manifest / source inventory',
              'Parse Materials'
            ],
            [
              'Parse Materials',
              'Import manifest',
              'Parsed content / parsing report',
              'Build Knowledge Base'
            ],
            [
              'Build Knowledge Base',
              'Parsed content',
              'Knowledge Base / chunk inventory',
              'Generate Skill'
            ],
            [
              'Generate Skill',
              'Knowledge Base',
              'Skill draft / validation report',
              'Agent Creation Package mapping'
            ],
            [
              'Agent Creation Package',
              'Knowledge Base + Skills',
              'Input mapping / package preview / export draft',
              'Validate & Export'
            ],
            [
              'Validate & Export',
              'All artifacts',
              'Reports / controlled export summary',
              'Handoff complete'
            ],
          ];
    return _DashboardMiniList(
      title: _zh ? '产物交接链' : 'Artifact Handoff Chain',
      rows: rows
          .map((row) => [
                row[0],
                '${_zh ? '承接' : 'Input'}: ${row[1]} · ${_zh ? '产物' : 'Output'}: ${row[2]} · ${_zh ? '下一阶段' : 'Next'}: ${row[3]}'
              ])
          .toList(growable: false),
    );
  }
}

class _ExecutionBadge extends StatelessWidget {
  const _ExecutionBadge({
    required this.localeCode,
    required this.isWebRuntime,
  });

  final String localeCode;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isWebRuntime
            ? colors.secondaryContainer
            : colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWebRuntime
                ? Icons.public_outlined
                : Icons.desktop_windows_outlined,
            size: 18,
            color: isWebRuntime ? colors.onSecondaryContainer : colors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            isWebRuntime
                ? (_zh ? 'Flutter Web 运行' : 'Flutter Web running')
                : (_zh ? '桌面可执行' : 'Desktop ready'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isWebRuntime
                      ? colors.onSecondaryContainer
                      : colors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

String _statusCopy(WorkbenchTaskStatus status, bool zh) {
  switch (status) {
    case WorkbenchTaskStatus.pending:
      return zh ? '等待开始' : 'Waiting';
    case WorkbenchTaskStatus.queued:
      return zh ? '已排队' : 'Queued';
    case WorkbenchTaskStatus.running:
      return zh ? '进行中' : 'Running';
    case WorkbenchTaskStatus.succeeded:
      return zh ? '已成功' : 'Succeeded';
    case WorkbenchTaskStatus.completed:
      return zh ? '已完成' : 'Completed';
    case WorkbenchTaskStatus.failed:
      return zh ? '失败' : 'Failed';
    case WorkbenchTaskStatus.retryable:
      return zh ? '可重试' : 'Retryable';
    case WorkbenchTaskStatus.cancelled:
      return zh ? '已取消' : 'Cancelled';
    case WorkbenchTaskStatus.blocked:
      return zh ? '已阻塞' : 'Blocked';
    case WorkbenchTaskStatus.degraded:
      return zh ? '降级可用' : 'Degraded';
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchSidePanel extends StatelessWidget {
  const _WorkbenchSidePanel({
    required this.localeCode,
    required this.tasks,
    required this.workspace,
  });

  final String localeCode;
  final List<WorkbenchTaskSnapshot> tasks;
  final String workspace;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final pendingCount = tasks
        .where((task) =>
            task.status == WorkbenchTaskStatus.pending ||
            task.status == WorkbenchTaskStatus.queued)
        .length;
    final runningCount = tasks
        .where((task) => task.status == WorkbenchTaskStatus.running)
        .length;
    final completedCount =
        tasks.where((task) => task.status.countsAsSucceeded).length;
    final failedCount = tasks
        .where((task) =>
            task.status == WorkbenchTaskStatus.failed ||
            task.status == WorkbenchTaskStatus.retryable ||
            task.status == WorkbenchTaskStatus.blocked ||
            task.status == WorkbenchTaskStatus.degraded)
        .length;
    final completion = tasks.isEmpty ? 0.0 : completedCount / tasks.length;
    return Column(
      key: const Key('workbench-side-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidePanelCard(
          title: _zh ? '工作台概览' : 'Workbench Overview',
          icon: Icons.dashboard_customize_outlined,
          emphasized: true,
          children: [
            _ProgressDial(
              localeCode: localeCode,
              progress: completion,
              centerText: '${(completion * 100).round()}%',
              caption: _zh ? '真实完成度' : 'Real completion',
            ),
            const SizedBox(height: 12),
            _SidePanelLine(
                label: _zh ? '已完成阶段' : 'Completed stages',
                value: _zh
                    ? '$completedCount 个，共 ${tasks.length} 个'
                    : '$completedCount of ${tasks.length}'),
          ],
        ),
        const SizedBox(height: 14),
        _SidePanelSectionLabel(label: _zh ? '运行状态' : 'Run Status'),
        const SizedBox(height: 8),
        _SidePanelCard(
          title: _zh ? '队列状态' : 'Queue Status',
          icon: Icons.pending_actions_outlined,
          children: [
            _QueueStatusGrid(
              items: [
                _QueueStatusItem(
                  label: _zh ? '等待' : 'Waiting',
                  value: '$pendingCount',
                  icon: Icons.hourglass_empty_outlined,
                ),
                _QueueStatusItem(
                  label: _zh ? '运行' : 'Running',
                  value: '$runningCount',
                  icon: Icons.play_circle_outline,
                ),
                _QueueStatusItem(
                  label: _zh ? '需处理' : 'Attention',
                  value: '$failedCount',
                  icon: Icons.error_outline,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SidePanelCard(
          title: _zh ? '本地执行' : 'Local Execution',
          icon: Icons.desktop_windows_outlined,
          children: [
            _SidePanelLine(
                label: _zh ? 'Web 模式' : 'Web mode',
                value: _zh ? '安全展示' : 'Safe view'),
            _SidePanelLine(
                label: _zh ? '云服务' : 'Cloud services',
                value: _zh ? '默认关闭' : 'Off by default'),
            _SidePanelLine(
                label: _zh ? '运行时声明' : 'Runtime claims',
                value: _zh ? '未完成' : 'Not complete'),
          ],
        ),
        const SizedBox(height: 14),
        _SidePanelSectionLabel(label: _zh ? '输出与活动' : 'Outputs and Activity'),
        const SizedBox(height: 8),
        _SidePanelCard(
          title: _zh ? '最近输出' : 'Recent Outputs',
          icon: Icons.folder_open_outlined,
          children: [
            _OutputPathLine(
              label: _zh ? '导入清单' : 'Import manifest',
              path: '$workspace/workbench_runs/import_manifest',
            ),
            _OutputPathLine(
              label: _zh ? '验证报告' : 'Validation report',
              path: '$workspace/workbench_runs/validation_report',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SidePanelCard(
          title: _zh ? '最近活动' : 'Recent Activity',
          icon: Icons.timeline_outlined,
          children: [
            _ActivityLine(
              time: _zh ? '现在' : 'Now',
              icon: Icons.file_upload_outlined,
              title: _zh ? '导入阶段等待资料' : 'Import is waiting for material',
              detail: _zh ? '尚未收到本地输入' : 'No local input received yet',
            ),
            _ActivityLine(
              time: _zh ? '门禁' : 'Gate',
              icon: Icons.rule_folder_outlined,
              title: _zh ? '完成门禁保持关闭' : 'Completion gate remains closed',
              detail: _zh
                  ? '没有真实 Core 结果不会展示完成'
                  : 'No real Core result, no completion',
            ),
            _ActivityLine(
              time: _zh ? '安全' : 'Safe',
              icon: Icons.shield_outlined,
              title: _zh ? '本地优先边界生效' : 'Local-first boundary active',
              detail: _zh ? '云服务默认关闭' : 'Cloud services are off by default',
            ),
          ],
        ),
      ],
    );
  }
}

class _SidePanelSectionLabel extends StatelessWidget {
  const _SidePanelSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _ProgressDial extends StatelessWidget {
  const _ProgressDial({
    required this.localeCode,
    required this.progress,
    required this.centerText,
    required this.caption,
  });

  final String localeCode;
  final double progress;
  final String centerText;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox.square(
          dimension: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: 76,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  value: progress,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              Text(
                centerText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            caption,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _SidePanelCard extends StatelessWidget {
  const _SidePanelCard({
    required this.title,
    required this.children,
    this.icon,
    this.emphasized = false,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color:
          emphasized ? colors.primary.withValues(alpha: 0.05) : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(emphasized ? 18 : 16),
        side: BorderSide(
          color: emphasized
              ? colors.primary.withValues(alpha: 0.28)
              : colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: emphasized
                          ? colors.primary.withValues(alpha: 0.12)
                          : colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color:
                          emphasized ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _QueueStatusItem {
  const _QueueStatusItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _QueueStatusGrid extends StatelessWidget {
  const _QueueStatusGrid({required this.items});

  final List<_QueueStatusItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            width: 78,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SidePanelLine extends StatelessWidget {
  const _SidePanelLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    )),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
          ),
        ],
      ),
    );
  }
}

class _OutputPathLine extends StatelessWidget {
  const _OutputPathLine({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: Key('side-output-$label'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(Icons.folder_open_outlined,
                size: 16, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({
    required this.time,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final String time;
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        )),
                const SizedBox(height: 2),
                Text(detail,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
