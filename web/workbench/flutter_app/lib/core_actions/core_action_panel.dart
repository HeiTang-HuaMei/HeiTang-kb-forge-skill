import 'package:flutter/material.dart';

import '../contracts/workbench_contracts.dart';
import '../core_bridge/local_core_bridge.dart';

class CoreActionPanel extends StatefulWidget {
  const CoreActionPanel({
    super.key,
    required this.action,
    required this.request,
    required this.coreBridge,
    required this.isWebRuntime,
    required this.enabled,
    required this.localeCode,
  });

  final ContractAction action;
  final CoreBridgeRequest request;
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

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final commandPreview = redactSecrets([widget.request.coreCli, ...widget.request.arguments].join(' '));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.action.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                _StatusPill(result: result),
              ],
            ),
            const SizedBox(height: 8),
            Text(_zh ? '桌面本地 Core CLI 最小闭环。Web 运行时不会执行本地命令。' : 'Minimal desktop local Core CLI path. Web runtime does not execute local commands.'),
            const SizedBox(height: 12),
            Text(commandPreview, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.enabled && !running ? _run : null,
              icon: running ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
              label: Text(running ? (_zh ? '运行中' : 'Running') : (_zh ? '运行 Core 操作' : 'Run Core action')),
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Divider(color: colors.outlineVariant),
              const SizedBox(height: 8),
              _ResultLine(label: 'status', value: result!.status),
              _ResultLine(label: 'error_id', value: result!.errorId.isEmpty ? '-' : result!.errorId),
              _ResultLine(label: 'exit_code', value: '${result!.exitCode ?? '-'}'),
              if (result!.stdout.isNotEmpty) _ResultLine(label: 'sanitized_stdout', value: result!.stdout),
              if (result!.stderr.isNotEmpty) _ResultLine(label: 'sanitized_stderr', value: result!.stderr),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _run() async {
    setState(() => running = true);
    final nextResult = await widget.coreBridge.run(widget.request, isWeb: widget.isWebRuntime);
    if (!mounted) {
      return;
    }
    setState(() {
      result = nextResult;
      running = false;
    });
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.result});

  final CoreBridgeResult? result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = result?.status ?? 'idle';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status == 'pass' ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: status == 'pass' ? colors.onPrimary : colors.onSurfaceVariant,
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
          SizedBox(width: 128, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
