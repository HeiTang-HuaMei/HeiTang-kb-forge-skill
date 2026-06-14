import 'package:flutter/material.dart';

import '../core_bridge/core_bridge_contract.dart';
import 'task_model.dart';

class TaskWorkbenchSurface extends StatelessWidget {
  const TaskWorkbenchSurface({
    super.key,
    required this.localeCode,
    required this.workspace,
    this.tasks,
    this.onRetry,
    this.onCancel,
  });

  final String localeCode;
  final String workspace;
  final List<WorkbenchTaskSnapshot>? tasks;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final snapshots = tasks ?? initialWorkbenchTasks(workspace);
    final outputContract = CoreOutputPathContract(workspace);
    return Column(
      key: const Key('task-workbench-surface'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkbenchSummary(
          localeCode: localeCode,
          totalTasks: snapshots.length,
          workspace: workspace,
        ),
        const SizedBox(height: 18),
        _Section(
          key: const Key('workbench-input-area'),
          title: _zh ? '输入区' : 'Input',
          eyebrow: _zh ? '本地边界' : 'Local boundary',
          child: _BoundaryCard(
            title: _zh ? '本地工作区输入' : 'Local workspace input',
            body: _zh
                ? '选择本地文件或目录后再启动允许的 Core 操作。默认不连接云服务，不读取 Provider secret。'
                : 'Select a local file or folder before an allowlisted Core action. Cloud services and provider secrets are not used by default.',
            detail: 'workspace=$workspace',
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          key: const Key('workbench-progress-area'),
          title: _zh ? '任务进度区' : 'Task progress',
          eyebrow: _zh ? '6 个阶段 · 默认 pending' : '6 stages · pending by default',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 328,
                ),
                itemBuilder: (context, index) => _TaskCard(
                  task: snapshots[index],
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
                ? '只有真实 Core 结果返回后才能显示 completed。当前卡片为 pending，不生成假产物。'
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
                    _StatusPill(status: status),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 18,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SummaryMetric(
              label: _zh ? '任务阶段' : 'Task stages',
              value: '$totalTasks',
            ),
            _SummaryMetric(
              label: _zh ? '默认状态' : 'Default state',
              value: 'pending',
            ),
            _SummaryMetric(
              label: _zh ? '完成规则' : 'Completion rule',
              value: _zh ? '结果 + 证据' : 'result + evidence',
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                _zh
                    ? '工作台先呈现边界、进度与恢复路径；真实 Core 结果返回前不会展示 completed。'
                    : 'The workbench surfaces boundaries, progress, and recovery paths before any completed state is shown.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SelectableText(
                'workspace=$workspace',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 116,
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
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
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
                _StatusPill(status: task.status),
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
  const _StatusPill({required this.status});

  final WorkbenchTaskStatus status;

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
          status.value,
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
