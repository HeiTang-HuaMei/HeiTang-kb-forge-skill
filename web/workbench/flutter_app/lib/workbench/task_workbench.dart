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
        _Section(
          key: const Key('workbench-input-area'),
          title: _zh ? '输入区' : 'Input',
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
                  mainAxisExtent: 280,
                ),
                itemBuilder: (context, index) => _TaskCard(
                  task: snapshots[index],
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

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.localeCode,
    this.onRetry,
    this.onCancel,
  });

  final WorkbenchTaskSnapshot task;
  final String localeCode;
  final ValueChanged<WorkbenchTaskSnapshot>? onRetry;
  final ValueChanged<WorkbenchTaskSnapshot>? onCancel;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('task-card-${task.stage.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            const SizedBox(height: 12),
            LinearProgressIndicator(
              key: Key('task-progress-${task.stage.id}'),
              value: task.progress,
            ),
            const SizedBox(height: 8),
            Text('${(task.progress * 100).round()}% · ${task.currentStep}'),
            const SizedBox(height: 8),
            Text('input: ${task.inputRequired}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('output: ${task.outputTarget}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (task.evidencePath.isNotEmpty)
              Text('evidence: ${task.evidencePath}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (task.failureReason.isNotEmpty)
              Text('error: ${task.failureReason}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text(
              task.nextSafeAction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
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

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    return Card(
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
                style: Theme.of(context).textTheme.bodySmall),
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
    final color = switch (status) {
      WorkbenchTaskStatus.completed => colors.primary,
      WorkbenchTaskStatus.failed => colors.error,
      WorkbenchTaskStatus.retryable => colors.tertiary,
      WorkbenchTaskStatus.cancelled => colors.secondary,
      WorkbenchTaskStatus.blocked => colors.errorContainer,
      WorkbenchTaskStatus.running => colors.primaryContainer,
      WorkbenchTaskStatus.pending => colors.surfaceContainerHighest,
    };
    return DecoratedBox(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status.value,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w700),
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
