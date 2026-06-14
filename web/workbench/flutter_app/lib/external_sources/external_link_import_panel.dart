import 'dart:convert';

import 'package:flutter/material.dart';

import '../core_bridge/local_core_bridge.dart';

class ExternalLinkImportPanel extends StatefulWidget {
  const ExternalLinkImportPanel({
    super.key,
    required this.coreBridge,
    required this.coreCli,
    required this.workingDirectory,
    required this.workspace,
    required this.enabled,
    required this.isWebRuntime,
    required this.localeCode,
  });

  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String workingDirectory;
  final String workspace;
  final bool enabled;
  final bool isWebRuntime;
  final String localeCode;

  @override
  State<ExternalLinkImportPanel> createState() =>
      _ExternalLinkImportPanelState();
}

class _ExternalLinkImportPanelState extends State<ExternalLinkImportPanel> {
  final _urlController = TextEditingController();
  bool _running = false;
  String _status = 'ready';
  Map<String, dynamic> _result = const <String, dynamic>{};

  bool get _zh => widget.localeCode == 'zh-CN';

  String get _outputPath =>
      '${widget.workspace}/workbench_runs/ingest_external_link';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final blockedReason = _blockedReason;
    return Card(
      key: const Key('external-link-import-panel'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _zh ? '外部链接导入' : 'External Link Import',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusBadge(status: _status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _zh
                  ? '当前执行公开 HTTP/HTML 单链接导入，生成文本块、source trace、evidence map、content hash 与回链。'
                  : 'Imports one public HTTP/HTML URL into text chunks, source trace, evidence map, content hash, and backlink.',
            ),
            const SizedBox(height: 8),
            Text(
              _zh
                  ? '边界：平台预检、OpenCLI、手动证据是独立能力；Browser、OCR、视频转写和 Knowledge Verification 未由此入口完成。'
                  : 'Boundary: platform preflight, OpenCLI, and manual evidence are separate capabilities; Browser, OCR, video transcription, and Knowledge Verification are not completed here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('external-link-url-input'),
              controller: _urlController,
              enabled: blockedReason == null && !_running,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: _zh ? '公开网页 URL' : 'Public web URL',
                hintText: 'https://example.com/article',
                border: const OutlineInputBorder(),
              ),
            ),
            if (blockedReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'blocked_reason: $blockedReason',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.error, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('external-link-import-action'),
              onPressed: blockedReason == null && !_running ? _run : null,
              icon: _running
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(
                _running
                    ? (_zh ? '导入中' : 'Importing')
                    : (_zh ? '导入链接' : 'Import link'),
              ),
            ),
            if (_running) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text(
                _zh
                    ? '正在执行预检、公开读取、正文抽取、chunk 与证据追踪。'
                    : 'Running preflight, public fetch, extraction, chunking, and evidence tracing.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(color: colors.outlineVariant),
              _ResultLine(
                  label: 'readability_state',
                  value: '${_result['readability_state'] ?? '-'}'),
              _ResultLine(
                  label: 'progress_events',
                  value: '${_result['progress_events'] ?? '-'}'),
              _ResultLine(
                  label: 'source_trace',
                  value: '${_result['source_trace'] ?? '-'}'),
              _ResultLine(
                  label: 'evidence_map',
                  value: '${_result['evidence_map'] ?? '-'}'),
              _ResultLine(
                  label: 'backlink', value: '${_result['backlink'] ?? '-'}'),
              if ('${_result['failure_reason'] ?? ''}'.isNotEmpty)
                _ResultLine(
                    label: 'failure_reason',
                    value: '${_result['failure_reason']}'),
              if ('${_result['repair_suggestion'] ?? ''}'.isNotEmpty)
                _ResultLine(
                    label: 'repair_suggestion',
                    value: '${_result['repair_suggestion']}'),
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
    return null;
  }

  Future<void> _run() async {
    final url = _urlController.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.userInfo.isNotEmpty) {
      setState(() {
        _status = 'blocked';
        _result = <String, dynamic>{
          'failure_reason':
              'Only credential-free public HTTP/HTTPS URLs are accepted.',
          'repair_suggestion': 'Enter a public http:// or https:// URL.',
        };
      });
      return;
    }

    setState(() {
      _running = true;
      _status = 'running';
      _result = const <String, dynamic>{};
    });
    final request = CoreBridgeRequest(
      actionId: 'ingest_external_link',
      coreCli: widget.coreCli,
      workingDirectory: widget.workingDirectory,
      allowedPathRoot: widget.workspace,
      arguments: <String>[
        'ingest-link',
        url,
        '--output',
        _outputPath,
        '--timeout-seconds',
        '30',
        '--respect-robots',
      ],
    );
    final bridgeResult =
        await widget.coreBridge.run(request, isWeb: widget.isWebRuntime);
    if (!mounted) {
      return;
    }
    final structured = _decodeResult(bridgeResult.stdout);
    setState(() {
      _running = false;
      _status = '${structured['status'] ?? bridgeResult.status}';
      _result = <String, dynamic>{
        'readability_state': structured['readability_state'] ?? '-',
        'progress_events': structured['progress_events'] ??
            '$_outputPath/progress_events.jsonl',
        'source_trace': structured['source_trace'] ??
            '$_outputPath/external_source_trace.json',
        'evidence_map': structured['evidence_map'] ??
            '$_outputPath/external_evidence_map.json',
        'backlink': structured['backlink'] ?? url,
        'failure_reason': structured['failure_reason'] ??
            (bridgeResult.status == 'pass' ? '' : bridgeResult.stderr),
        'repair_suggestion': structured['repair_suggestion'] ?? '',
      };
    });
  }

  Map<String, dynamic> _decodeResult(String stdout) {
    for (final line in stdout.trim().split('\n').reversed) {
      try {
        final value = jsonDecode(line.trim());
        if (value is Map<String, dynamic>) {
          return value;
        }
      } on FormatException {
        continue;
      }
    }
    return const <String, dynamic>{};
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final positive = status == 'passed';
    final negative = status == 'failed' || status == 'blocked';
    final color = positive
        ? colors.primary
        : negative
            ? colors.error
            : colors.surfaceContainerHighest;
    final foreground = positive
        ? colors.onPrimary
        : negative
            ? colors.onError
            : colors.onSurfaceVariant;
    return DecoratedBox(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status,
          key: const Key('external-link-import-status'),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
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
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
