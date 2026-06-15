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
    final outputContract = CoreOutputPathContract(workspace);
    return LayoutBuilder(
      key: const Key('task-workbench-surface'),
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final workflow = _GuidedWorkflow(
          localeCode: localeCode,
          workspace: workspace,
          tasks: snapshots,
          onRetry: onRetry,
          onCancel: onCancel,
        );
        final sidePanel = _WorkbenchSidePanel(
          localeCode: localeCode,
          tasks: snapshots,
          workspace: workspace,
        );
        final mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkbenchSummary(
              localeCode: localeCode,
              totalTasks: snapshots.length,
              workspace: workspace,
            ),
            const SizedBox(height: 16),
            _WorkbenchCommandPanel(
              localeCode: localeCode,
              workspace: workspace,
              isWebRuntime: isWebRuntime,
            ),
            const SizedBox(height: 16),
            workflow,
            const SizedBox(height: 18),
            _AdvancedTaskDetails(
              localeCode: localeCode,
              outputContract: outputContract,
              tasks: snapshots,
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
              const SizedBox(width: 16),
              SizedBox(width: 300, child: sidePanel),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mainColumn,
            const SizedBox(height: 18),
            sidePanel,
          ],
        );
      },
    );
  }
}

class _GuidedWorkflow extends StatelessWidget {
  const _GuidedWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.tasks,
    this.onRetry,
    this.onCancel,
  });

  final String localeCode;
  final String workspace;
  final List<WorkbenchTaskSnapshot> tasks;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _Section(
      key: const Key('workbench-progress-area'),
      title: _zh ? '知识供应链' : 'Knowledge Supply Chain',
      eyebrow: _zh ? '五步引导工作流' : 'Five-step guided workflow',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1180
              ? 3
              : constraints.maxWidth >= 720
                  ? 2
                  : 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkflowStepper(
                localeCode: localeCode,
                tasks: tasks,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _workflowSteps.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 276,
                ),
                itemBuilder: (context, index) {
                  final step = _workflowSteps[index];
                  final task = tasks[step.taskIndex];
                  return _ProductTaskCard(
                    step: step,
                    task: task,
                    index: index,
                    localeCode: localeCode,
                    workspace: workspace,
                    onRetry: onRetry,
                    onCancel: onCancel,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkflowStepper extends StatelessWidget {
  const _WorkflowStepper({
    required this.localeCode,
    required this.tasks,
  });

  final String localeCode;
  final List<WorkbenchTaskSnapshot> tasks;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('workflow-stepper'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Wrap(
            spacing: compact ? 8 : 10,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _workflowSteps.length; index++)
                _StepperNode(
                  index: index,
                  title: _workflowSteps[index].title(_zh),
                  status: tasks[_workflowSteps[index].taskIndex].status,
                  compact: compact,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepperNode extends StatelessWidget {
  const _StepperNode({
    required this.index,
    required this.title,
    required this.status,
    required this.compact,
  });

  final int index;
  final String title;
  final WorkbenchTaskStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = status != WorkbenchTaskStatus.pending;
    return Container(
      width: compact ? 148 : 172,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          _StageNumber(index: index),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchCommandPanel extends StatelessWidget {
  const _WorkbenchCommandPanel({
    required this.localeCode,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final String workspace;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('workbench-command-panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _zh ? '本地资料输入台' : 'Local Material Console',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _zh
                          ? '先确认资料来源和输出目录，再推进知识供应链；没有真实结果不会展示完成。'
                          : 'Confirm the material source and output directory before moving the knowledge chain forward; no real result means no completed state.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ExecutionBadge(
                localeCode: localeCode,
                isWebRuntime: isWebRuntime,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              final sourceCard = _ConsoleActionCard(
                key: const Key('material-source-console-card'),
                icon: Icons.folder_copy_outlined,
                label: _zh ? '资料来源' : 'Material source',
                title: _zh ? '选择本地文件或文件夹' : 'Choose local files',
                body: _zh
                    ? '等待桌面端提供真实路径。当前页面只展示安全输入边界，不伪造完成结果。'
                    : 'Waiting for a real desktop path. This page shows the safe input boundary and never fabricates completion.',
                actionIcon: Icons.folder_open_outlined,
                actionLabel: _zh ? '等待本地输入' : 'Waiting for local input',
                emphasized: true,
              );
              final targetCard = _ConsoleActionCard(
                key: const Key('output-target-console-card'),
                icon: Icons.drive_file_move_outline,
                label: _zh ? '输出目标' : 'Output target',
                title: _zh ? '导入清单' : 'Import manifest',
                body: '$workspace/workbench_runs/import_manifest',
                actionIcon: Icons.playlist_add_check_outlined,
                actionLabel: _zh ? '生成导入清单' : 'Create import manifest',
              );
              final gateCard = _ConsoleActionCard(
                key: const Key('import-gate-console-card'),
                icon: Icons.verified_user_outlined,
                label: _zh ? '导入门禁' : 'Import gate',
                title: _zh ? '等待真实输入' : 'Waiting for input',
                body: _zh
                    ? '无 Core 结果不会展示完成'
                    : 'No Core result, no completed state',
                actionIcon: Icons.lock_outline,
                actionLabel: _zh ? '门禁未开放' : 'Gate closed',
              );

              if (!wide) {
                return Column(
                  children: [
                    sourceCard,
                    const SizedBox(height: 12),
                    targetCard,
                    const SizedBox(height: 12),
                    gateCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: sourceCard),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        targetCard,
                        const SizedBox(height: 12),
                        gateCard,
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineOutputPath(
                localeCode: localeCode,
                path: '$workspace/workbench_runs/import_manifest',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsoleActionCard extends StatelessWidget {
  const _ConsoleActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.actionIcon,
    required this.actionLabel,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String title;
  final String body;
  final IconData actionIcon;
  final String actionLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primary.withValues(alpha: 0.05)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emphasized
              ? colors.primary.withValues(alpha: 0.24)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: emphasized
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(icon,
                    size: 19,
                    color:
                        emphasized ? colors.primary : colors.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            maxLines: emphasized ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (emphasized) ...[
            const SizedBox(height: 14),
            const _MaterialFormatStrip(),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: null,
            icon: Icon(actionIcon),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                actionLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: colors.onSurfaceVariant,
              minimumSize: const Size.fromHeight(40),
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialFormatStrip extends StatelessWidget {
  const _MaterialFormatStrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formats = ['PDF', 'DOCX', 'PPTX', 'XLSX', 'MD', 'HTML'];
    return Container(
      key: const Key('material-format-strip'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.upload_file_outlined,
              size: 18, color: colors.onSurfaceVariant),
          for (final format in formats)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                format,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWebRuntime
                ? Icons.public_off_outlined
                : Icons.desktop_windows_outlined,
            size: 18,
            color: isWebRuntime ? colors.onSecondaryContainer : colors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            isWebRuntime
                ? (_zh ? 'Web 安全展示' : 'Web-safe view')
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

class _InlineOutputPath extends StatelessWidget {
  const _InlineOutputPath({
    required this.localeCode,
    required this.path,
  });

  final String localeCode;
  final String path;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drive_file_move_outline,
              size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${_zh ? '输出' : 'Output'}: $path',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedTaskDetails extends StatelessWidget {
  const _AdvancedTaskDetails({
    required this.localeCode,
    required this.outputContract,
    required this.tasks,
    this.onRetry,
    this.onCancel,
  });

  final String localeCode;
  final CoreOutputPathContract outputContract;
  final List<WorkbenchTaskSnapshot> tasks;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      key: const Key('workbench-advanced-task-details'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      title: Text(_zh ? '高级边界详情' : 'Advanced Boundary Details',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(_zh
          ? '展开后查看六阶段模型、七种状态、输出路径和错误恢复边界。'
          : 'Expand to inspect the six-stage model, seven states, output paths, and recovery boundaries.'),
      children: [
        _Section(
          key: const Key('workbench-input-area'),
          title: _zh ? '输入区' : 'Input',
          eyebrow: _zh ? '本地边界' : 'Local boundary',
          child: _BoundaryCard(
            title: _zh ? '本地工作区输入' : 'Local workspace input',
            body: _zh
                ? '选择本地文件或目录后再启动允许的 Core 操作。默认不连接云服务，不读取 Provider secret。'
                : 'Select a local file or folder before an allowlisted Core action. Cloud services and provider secrets are not used by default.',
            detail: 'workspace=${outputContract.workspace}',
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          key: const Key('workbench-progress-area'),
          title: _zh ? '任务进度区' : 'Task progress',
          eyebrow: _zh ? '6 个阶段 · 默认等待开始' : '6 stages · pending by default',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 328,
                ),
                itemBuilder: (context, index) => _TaskCard(
                  task: tasks[index],
                  index: index,
                  localeCode: localeCode,
                  onRetry: onRetry,
                  onCancel: onCancel,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          key: const Key('workbench-output-area'),
          title: _zh ? '输出结果区' : 'Output results',
          eyebrow: _zh ? '无真实结果不完成' : 'No result, no completion',
          child: _BoundaryCard(
            title: _zh ? '受控输出路径' : 'Controlled output paths',
            body: _zh
                ? '只有真实 Core 结果返回后才能显示已完成。当前卡片为等待开始，不生成假产物。'
                : 'Completed is shown only after a real Core result. Current cards are pending and do not invent artifacts.',
            detail:
                'example=${outputContract.forAction('knowledge_splitting')}',
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          key: const Key('workbench-evidence-area'),
          title: _zh ? '证据 / 报告区' : 'Evidence and reports',
          eyebrow: _zh ? '完成需要证据' : 'Evidence required',
          child: _BoundaryCard(
            title: _zh ? '完成证据要求' : 'Completion evidence',
            body: _zh
                ? 'completed 必须同时具备 100% 进度、输出路径和 evidence/report 路径。'
                : 'Completed requires 100% progress, an output path, and an evidence or report path.',
            detail: 'manifest · validation_report · failure_matrix',
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          key: const Key('workbench-error-area'),
          title: _zh ? '错误与重试区' : 'Errors and retry',
          eyebrow: _zh ? '恢复动作保持显式' : 'Recovery stays explicit',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in WorkbenchTaskStatus.values)
                    _StatusPill(status: status, localeCode: localeCode),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _zh
                    ? 'failed 保留错误；retryable 允许有限重试；running 可取消；blocked 显示下一安全动作。'
                    : 'Failed preserves the error, retryable permits bounded retry, running can be cancelled, and blocked exposes the next safe action.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowStep {
  const _WorkflowStep({
    required this.zhTitle,
    required this.enTitle,
    required this.zhNextAction,
    required this.enNextAction,
    required this.outputActionId,
    required this.taskIndex,
  });

  final String zhTitle;
  final String enTitle;
  final String zhNextAction;
  final String enNextAction;
  final String outputActionId;
  final int taskIndex;

  String title(bool zh) => zh ? zhTitle : enTitle;

  String nextAction(bool zh) => zh ? zhNextAction : enNextAction;
}

const _workflowSteps = <_WorkflowStep>[
  _WorkflowStep(
    zhTitle: '导入资料',
    enTitle: 'Import Materials',
    zhNextAction: '选择本地文件或文件夹',
    enNextAction: 'Choose a local file or folder',
    outputActionId: 'file_import',
    taskIndex: 0,
  ),
  _WorkflowStep(
    zhTitle: '构建知识库',
    enTitle: 'Build Knowledge Package',
    zhNextAction: '检查解析结果并开始切分',
    enNextAction: 'Review parsed content and start splitting',
    outputActionId: 'knowledge_splitting',
    taskIndex: 2,
  ),
  _WorkflowStep(
    zhTitle: '生成 Skill',
    enTitle: 'Generate Skill',
    zhNextAction: '确认知识包草稿',
    enNextAction: 'Confirm the knowledge package draft',
    outputActionId: 'skill_generation',
    taskIndex: 3,
  ),
  _WorkflowStep(
    zhTitle: '生成 Agent 包',
    enTitle: 'Generate Agent Package',
    zhNextAction: '生成包草稿',
    enNextAction: 'Generate the package draft',
    outputActionId: 'agent_package_generation',
    taskIndex: 4,
  ),
  _WorkflowStep(
    zhTitle: '验证与导出',
    enTitle: 'Validate & Export',
    zhNextAction: '验证清单、报告与恢复路径',
    enNextAction: 'Validate manifests, reports, and recovery paths',
    outputActionId: 'validation',
    taskIndex: 5,
  ),
];

class _ProductTaskCard extends StatelessWidget {
  const _ProductTaskCard({
    required this.step,
    required this.task,
    required this.index,
    required this.localeCode,
    required this.workspace,
    this.onRetry,
    this.onCancel,
  });

  final _WorkflowStep step;
  final WorkbenchTaskSnapshot task;
  final int index;
  final String localeCode;
  final String workspace;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outputContract = CoreOutputPathContract(workspace);
    final canShowActions = (task.status.canRetry && onRetry != null) ||
        (task.status.canCancel && onCancel != null);
    return Card(
      key: Key('workflow-step-${index + 1}'),
      color: index == 0 ? colors.surface : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: index == 0
                  ? colors.primary.withValues(alpha: 0.06)
                  : colors.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StageNumber(index: index),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title(_zh),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _zh
                            ? '工作流阶段 ${index + 1}'
                            : 'Workflow stage ${index + 1}',
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
                const SizedBox(width: 8),
                _StatusPill(status: task.status, localeCode: localeCode),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskProgressSummary(
                    key: Key('workflow-progress-${index + 1}'),
                    localeCode: localeCode,
                    progress: task.progress,
                    status: task.status,
                  ),
                  const SizedBox(height: 10),
                  _ProductTaskLine(
                    label: _zh ? '下一步' : 'Next action',
                    value: step.nextAction(_zh),
                  ),
                  _ProductTaskLine(
                    label: _zh ? '输出位置' : 'Output path',
                    value: outputContract.forAction(step.outputActionId),
                  ),
                  if (canShowActions) ...[
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (task.status.canRetry && onRetry != null)
                          FilledButton.tonal(
                            onPressed: () => onRetry!(task),
                            child: Text(_zh ? '重试' : 'Retry'),
                          ),
                        if (task.status.canCancel && onCancel != null)
                          TextButton(
                            onPressed: () => onCancel!(task),
                            child: Text(_zh ? '取消' : 'Cancel'),
                          ),
                      ],
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

class _TaskProgressSummary extends StatelessWidget {
  const _TaskProgressSummary({
    super.key,
    required this.localeCode,
    required this.progress,
    required this.status,
  });

  final String localeCode;
  final double progress;
  final WorkbenchTaskStatus status;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusCopy(status, _zh),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTaskLine extends StatelessWidget {
  const _ProductTaskLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _statusCopy(WorkbenchTaskStatus status, bool zh) {
  switch (status) {
    case WorkbenchTaskStatus.pending:
      return zh ? '等待开始' : 'Waiting';
    case WorkbenchTaskStatus.running:
      return zh ? '进行中' : 'Running';
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
  }
}

class _WorkbenchSummary extends StatelessWidget {
  const _WorkbenchSummary({
    required this.localeCode,
    required this.totalTasks,
    required this.workspace,
  });

  final String localeCode;
  final int totalTasks;
  final String workspace;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.04),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(Icons.account_tree_outlined,
                        color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroBadge(
                            label:
                                _zh ? 'Campaign 4 工作台' : 'Campaign 4 Workbench',
                            icon: Icons.view_quilt_outlined,
                          ),
                          _HeroBadge(
                            label: _zh ? '本地优先' : 'Local first',
                            icon: Icons.shield_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _zh
                            ? '本地 Agent 知识供应链'
                            : 'Local Agent Knowledge Supply Chain',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _zh
                            ? '从资料导入到验证导出，所有阶段默认等待真实输入；没有 Core 结果不会展示完成。'
                            : 'Move from import to validation with every stage waiting for real input; no Core result means no completed state.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryMetric(
                  label: _zh ? '任务阶段' : 'Task stages',
                  value: '$totalTasks',
                  icon: Icons.account_tree_outlined,
                ),
                _SummaryMetric(
                  label: _zh ? '默认状态' : 'Default state',
                  value: _zh
                      ? _statusCopy(WorkbenchTaskStatus.pending, true)
                      : WorkbenchTaskStatus.pending.value,
                  icon: Icons.hourglass_empty_outlined,
                ),
                _SummaryMetric(
                  label: _zh ? '完成规则' : 'Completion rule',
                  value: _zh ? '结果 + 证据' : 'result + evidence',
                  icon: Icons.verified_outlined,
                ),
                _SummaryMetric(
                  label: _zh ? '工作区' : 'Workspace',
                  value: workspace,
                  icon: Icons.folder_outlined,
                  wide: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HeroWorkflowStrip(localeCode: localeCode),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
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

class _HeroWorkflowStrip extends StatelessWidget {
  const _HeroWorkflowStrip({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labels = _zh
        ? ['导入资料', '构建知识库', '生成 Skill', '生成 Agent 包', '验证与导出']
        : [
            'Import Materials',
            'Build Knowledge Package',
            'Generate Skill',
            'Generate Agent Package',
            'Validate & Export',
          ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < labels.length; index++)
            _HeroWorkflowStep(index: index, label: labels[index]),
        ],
      ),
    );
  }
}

class _HeroWorkflowStep extends StatelessWidget {
  const _HeroWorkflowStep({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onSurface,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.surface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: wide ? 280 : 142,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
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
        .where((task) => task.status == WorkbenchTaskStatus.pending)
        .length;
    final runningCount = tasks
        .where((task) => task.status == WorkbenchTaskStatus.running)
        .length;
    final completedCount = tasks
        .where((task) => task.status == WorkbenchTaskStatus.completed)
        .length;
    final failedCount = tasks
        .where((task) =>
            task.status == WorkbenchTaskStatus.failed ||
            task.status == WorkbenchTaskStatus.retryable ||
            task.status == WorkbenchTaskStatus.blocked)
        .length;
    final completion = tasks.isEmpty ? 0.0 : completedCount / tasks.length;
    return Column(
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
                value: '$completedCount/${tasks.length}'),
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
            _SidePanelLine(
                label: _zh ? '导入清单' : 'Import manifest',
                value: '$workspace/workbench_runs/import_manifest'),
            _SidePanelLine(
                label: _zh ? '验证报告' : 'Validation report',
                value: '$workspace/workbench_runs/validation_report'),
          ],
        ),
        const SizedBox(height: 12),
        _SidePanelCard(
          title: _zh ? '最近活动' : 'Recent Activity',
          icon: Icons.timeline_outlined,
          children: [
            _ActivityLine(
              icon: Icons.file_upload_outlined,
              title: _zh ? '导入阶段等待资料' : 'Import is waiting for material',
              detail: _zh ? '尚未收到本地输入' : 'No local input received yet',
            ),
            _ActivityLine(
              icon: Icons.rule_folder_outlined,
              title: _zh ? '完成门禁保持关闭' : 'Completion gate remains closed',
              detail: _zh
                  ? '没有真实 Core 结果不会展示完成'
                  : 'No real Core result, no completion',
            ),
            _ActivityLine(
              icon: Icons.shield_outlined,
              title: _zh ? '本地优先边界生效' : 'Local-first boundary active',
              detail: _zh ? '云服务默认关闭' : 'Cloud services are off by default',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SidePanelCard(
          title: _zh ? '工作台操作' : 'Workbench Actions',
          icon: Icons.tune_outlined,
          children: [
            _SidePanelAction(
              icon: Icons.compare_arrows_outlined,
              label: _zh ? '查看输出路径' : 'Review output paths',
            ),
            _SidePanelAction(
              icon: Icons.replay_outlined,
              label: _zh ? '等待可重试任务' : 'Wait for retryable task',
            ),
            _SidePanelAction(
              icon: Icons.fact_check_outlined,
              label: _zh ? '打开高级边界详情' : 'Open advanced boundary details',
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

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({
    required this.icon,
    required this.title,
    required this.detail,
  });

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

class _SidePanelAction extends StatelessWidget {
  const _SidePanelAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon, size: 17),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurfaceVariant,
          disabledForegroundColor: colors.onSurfaceVariant,
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(38),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.index,
    required this.localeCode,
    this.onRetry,
    this.onCancel,
  });

  final WorkbenchTaskSnapshot task;
  final int index;
  final String localeCode;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: Key('task-card-${task.stage.id}'),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StageNumber(index: index),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _stageLabel(task.stage, _zh),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusPill(status: task.status, localeCode: localeCode),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: Key('task-progress-${task.stage.id}'),
                minHeight: 8,
                value: task.progress,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(task.progress * 100).round()}% · ${task.currentStep}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'input', value: task.inputRequired),
            _InfoRow(label: 'output', value: task.outputTarget),
            if (task.evidencePath.isNotEmpty)
              _InfoRow(label: 'evidence', value: task.evidencePath),
            if (task.failureReason.isNotEmpty)
              _InfoRow(label: 'error', value: task.failureReason),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  task.nextSafeAction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: task.status.canRetry && onRetry != null
                      ? () => onRetry!(task)
                      : null,
                  child: Text(_zh ? '重试' : 'Retry'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: task.status.canCancel && onCancel != null
                      ? () => onCancel!(task)
                      : null,
                  child: Text(_zh ? '取消' : 'Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageNumber extends StatelessWidget {
  const _StageNumber({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox.square(
        dimension: 28,
        child: Center(
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.child,
  });

  final String title;
  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({
    required this.title,
    required this.body,
    required this.detail,
  });

  final String title;
  final String body;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 8),
            SelectableText(detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.localeCode});

  final WorkbenchTaskStatus status;
  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = switch (status) {
      WorkbenchTaskStatus.completed => colors.primary,
      WorkbenchTaskStatus.failed => colors.errorContainer,
      WorkbenchTaskStatus.retryable => colors.tertiaryContainer,
      WorkbenchTaskStatus.cancelled => colors.secondaryContainer,
      WorkbenchTaskStatus.blocked => colors.errorContainer,
      WorkbenchTaskStatus.running => colors.primaryContainer,
      WorkbenchTaskStatus.pending => colors.surfaceContainerHighest,
    };
    final foreground = switch (status) {
      WorkbenchTaskStatus.completed => colors.onPrimary,
      WorkbenchTaskStatus.failed => colors.onErrorContainer,
      WorkbenchTaskStatus.retryable => colors.onTertiaryContainer,
      WorkbenchTaskStatus.cancelled => colors.onSecondaryContainer,
      WorkbenchTaskStatus.blocked => colors.onErrorContainer,
      WorkbenchTaskStatus.running => colors.onPrimaryContainer,
      WorkbenchTaskStatus.pending => colors.onSurfaceVariant,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          _statusCopy(status, _zh),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: foreground, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _stageLabel(WorkbenchTaskStage stage, bool zh) {
  switch (stage) {
    case WorkbenchTaskStage.fileImport:
      return zh ? '文件导入' : 'File import';
    case WorkbenchTaskStage.parsing:
      return zh ? '解析' : 'Parsing';
    case WorkbenchTaskStage.knowledgeSplitting:
      return zh ? '知识切分' : 'Knowledge splitting';
    case WorkbenchTaskStage.skillGeneration:
      return zh ? 'Skill 生成' : 'Skill generation';
    case WorkbenchTaskStage.agentPackageGeneration:
      return zh ? 'Agent 包生成' : 'Agent package generation';
    case WorkbenchTaskStage.validation:
      return zh ? '验证' : 'Validation';
  }
}
