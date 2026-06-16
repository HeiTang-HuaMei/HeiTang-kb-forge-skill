import 'package:flutter/material.dart';

import '../contracts/workbench_contracts.dart';
import '../core_bridge/local_core_bridge.dart';

class CoreActionPanel extends StatefulWidget {
  const CoreActionPanel({
    super.key,
    required this.action,
    required this.coreBridge,
    required this.isWebRuntime,
    required this.enabled,
    required this.localeCode,
    this.request,
  });

  final ContractAction action;
  final CoreBridgeRequest? request;
  final LocalCoreBridge coreBridge;
  final bool isWebRuntime;
  final bool enabled;
  final String localeCode;

  @override
  State<CoreActionPanel> createState() => _CoreActionPanelState();
}

class _CoreActionPanelState extends State<CoreActionPanel> {
  CoreBridgeResult? result;
  bool running = false;
  CoreBridgeCancellationToken? cancellationToken;
  int attemptCount = 0;

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final commandPreview = widget.request == null
        ? (widget.action.command.isEmpty
            ? 'not_runnable'
            : widget.action.command)
        : redactSecrets(
            [widget.request!.coreCli, ...widget.request!.arguments].join(' '));
    final blockedReason = _blockedReason;
    final canRun = blockedReason == null &&
        !running &&
        (result == null || result!.cancelled);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.action.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                _StatusPill(result: result),
              ],
            ),
            const SizedBox(height: 8),
            Text(_zh
                ? '桌面应用可执行本地 Core；Flutter Web 应用中本地命令保持禁用。'
                : 'The desktop app can execute local Core actions; local commands stay disabled in the Flutter Web app.'),
            if (blockedReason != null) ...[
              const SizedBox(height: 8),
              Text(
                  _zh
                      ? '当前环境不可执行本地命令。'
                      : 'Local command execution is unavailable in this environment.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.error, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: canRun ? _run : null,
              icon: running
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(running
                  ? (_zh ? '运行中' : 'Running')
                  : (_zh ? '运行 Core 操作' : 'Run Core action')),
            ),
            if (running) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('core-action-cancel'),
                onPressed: _cancel,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(_zh ? '取消本地操作' : 'Cancel local action'),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 12),
              Divider(color: colors.outlineVariant),
              const SizedBox(height: 8),
              _ResultLine(label: _zh ? '状态' : 'Status', value: result!.status),
              if (result!.outputPath != null)
                _ResultLine(
                    label: _zh ? '输出位置' : 'Output path',
                    value: result!.outputPath!),
              if (result!.errorId.isNotEmpty)
                _ResultLine(
                    label: _zh ? '错误' : 'Error', value: result!.errorId),
              if (result!.stderr.isNotEmpty)
                _ResultLine(
                    label: _zh ? '说明' : 'Message', value: result!.stderr),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(_zh ? '技术详情' : 'Technical Details'),
                children: [
                  _ResultLine(label: 'command', value: commandPreview),
                  if (blockedReason != null)
                    _ResultLine(label: 'blocked_reason', value: blockedReason),
                  _ResultLine(
                      label: 'error_id',
                      value: result!.errorId.isEmpty ? '-' : result!.errorId),
                  _ResultLine(
                      label: 'exit_code', value: '${result!.exitCode ?? '-'}'),
                  _ResultLine(
                      label: 'retryable', value: '${result!.retryable}'),
                  _ResultLine(
                      label: 'attempt',
                      value:
                          '${result!.attempt}/${widget.request!.retryPolicy.maxAttempts}'),
                  if (result!.stdout.isNotEmpty)
                    _ResultLine(
                        label: 'sanitized_stdout', value: result!.stdout),
                  if (result!.stderr.isNotEmpty)
                    _ResultLine(
                        label: 'sanitized_stderr', value: result!.stderr),
                ],
              ),
              if (result!.retryable) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('core-action-retry'),
                  onPressed: running ? null : () => _run(retry: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(_zh ? '有限重试' : 'Retry'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String? get _blockedReason {
    if (widget.isWebRuntime) {
      return 'web_local_cli_unsupported';
    }
    if (!widget.enabled) {
      return 'desktop_support_disabled';
    }
    if (widget.request != null) {
      return null;
    }
    if (!widget.action.desktopEnabled) {
      return widget.action.desktopBlockedReason.isNotEmpty
          ? widget.action.desktopBlockedReason
          : widget.action.blockedReason.isNotEmpty
              ? widget.action.blockedReason
              : 'desktop_support_pending';
    }
    return 'local_request_mapping_missing';
  }

  Future<void> _run({bool retry = false}) async {
    final baseRequest = widget.request;
    if (baseRequest == null) {
      return;
    }
    final nextAttempt = retry ? attemptCount + 1 : 1;
    if (nextAttempt > baseRequest.retryPolicy.maxAttempts) {
      return;
    }
    final token = CoreBridgeCancellationToken();
    setState(() {
      running = true;
      cancellationToken = token;
      attemptCount = nextAttempt;
    });
    CoreBridgeResult? nextResult;
    try {
      nextResult = await widget.coreBridge.run(
        baseRequest.withAttempt(nextAttempt).withCancellation(token),
        isWeb: widget.isWebRuntime,
      );
    } catch (error) {
      final cancelled = token.isCancelled;
      final retryable = nextAttempt < baseRequest.retryPolicy.maxAttempts &&
          baseRequest.retryPolicy.retryOnProcessFailure &&
          !cancelled;
      nextResult = CoreBridgeResult(
        status: cancelled
            ? 'cancelled'
            : retryable
                ? 'retryable'
                : 'fail',
        actionId: baseRequest.actionId,
        exitCode: -1,
        stdout: '',
        stderr: redactSecrets('Core bridge UI action failed: $error'),
        commandPreview:
            redactCommand([baseRequest.coreCli, ...baseRequest.arguments]),
        errorId: 'core_action_panel_bridge_failed',
        timedOut: false,
        cancelled: cancelled,
        retryable: retryable,
        outputPath: baseRequest.outputPath,
        attempt: nextAttempt,
      );
    } finally {
      if (mounted) {
        setState(() {
          result = nextResult;
          running = false;
          cancellationToken = null;
        });
      }
    }
  }

  void _cancel() {
    cancellationToken?.cancel();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.result});

  final CoreBridgeResult? result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = result?.status ?? 'idle';
    final isFailure =
        status == 'fail' || status == 'retryable' || status == 'blocked';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status == 'pass'
            ? colors.primary
            : isFailure
                ? colors.errorContainer
                : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: status == 'pass'
                    ? colors.onPrimary
                    : isFailure
                        ? colors.onErrorContainer
                        : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 128,
              child:
                  Text(label, style: Theme.of(context).textTheme.labelMedium)),
          Expanded(
              child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
