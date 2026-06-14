import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/external_sources/external_link_import_panel.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  test('registers completed P0 external-source commands only', () {
    const bridge = LocalCoreBridge();
    const expected = <String, String>{
      'ingest_external_link': 'ingest-link',
      'detect_platform_link': 'detect-platform-link',
      'preflight_platform_link': 'preflight-platform-link',
      'check_opencli_external_verification':
          'check-opencli-external-verification',
      'verify_external_source': 'verify-external-source',
      'import_manual_evidence': 'import-manual-evidence',
      'build_external_source_unified_trace':
          'build-external-source-unified-trace',
    };

    for (final entry in expected.entries) {
      expect(bridge.allowedActions[entry.key], [entry.value]);
    }
    expect(bridge.allowedActions,
        isNot(contains('start_authenticated_browser_session')));
    expect(bridge.allowedActions, isNot(contains('transcribe_video_source')));
    expect(bridge.allowedActions, isNot(contains('verify_knowledge_base')));
  });

  test('rejects shell executables and unsafe external-link arguments', () {
    const bridge = LocalCoreBridge();

    for (final shell in const [
      'cmd.exe',
      'powershell.exe',
      'pwsh',
      'bash',
      'sh'
    ]) {
      expect(
        () => bridge.buildCommand(
          CoreBridgeRequest(
            actionId: 'ingest_external_link',
            coreCli: shell,
            workingDirectory: r'C:\repo',
            arguments: const [
              'ingest-link',
              'https://example.com',
              '--output',
              r'C:\workspace\out'
            ],
          ),
        ),
        throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
            'errorId', 'core_bridge_shell_executable_rejected')),
      );
    }

    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'ingest_external_link',
          coreCli: 'heitang-kb-forge',
          workingDirectory: r'C:\repo',
          arguments: [
            'ingest-link',
            'file:///C:/secret.txt',
            '--output',
            r'C:\workspace\out'
          ],
        ),
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
          'errorId', 'external_link_import_url_rejected')),
    );
    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'ingest_external_link',
          coreCli: 'heitang-kb-forge',
          workingDirectory: r'C:\repo',
          allowedPathRoot: r'C:\workspace',
          arguments: [
            'ingest-link',
            'https://example.com',
            '--output',
            r'C:\outside\out'
          ],
        ),
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
          'errorId', 'external_link_import_path_boundary_rejected')),
    );
    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'ingest_external_link',
          coreCli: 'heitang-kb-forge',
          workingDirectory: r'C:\repo',
          arguments: [
            'ingest-link',
            'https://user:secret@example.com',
            '--output',
            r'C:\workspace\out'
          ],
        ),
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
          'errorId', 'external_link_import_url_rejected')),
    );
  });

  testWidgets('runs real ingest-link request and displays traceable result',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    final requests = <CoreBridgeRequest>[];
    final bridge = LocalCoreBridge(
      runner: (request) async {
        requests.add(request);
        return CoreBridgeProcessResult(
          exitCode: 0,
          stdout: jsonEncode({
            'status': 'passed',
            'readability_state': 'public_readable',
            'backlink': 'https://example.com/article',
            'source_trace':
                r'C:\workspace/workbench_runs/ingest_external_link/external_source_trace.json',
            'evidence_map':
                r'C:\workspace/workbench_runs/ingest_external_link/external_evidence_map.json',
            'progress_events':
                r'C:\workspace/workbench_runs/ingest_external_link/progress_events.jsonl',
          }),
          stderr: '',
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalLinkImportPanel(
            coreBridge: bridge,
            coreCli: 'heitang-kb-forge',
            workingDirectory: r'C:\repo',
            workspace: r'C:\workspace',
            enabled: true,
            isWebRuntime: false,
            localeCode: 'zh-CN',
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('external-link-url-input')),
        'https://example.com/article');
    await tester.tap(find.byKey(const Key('external-link-import-action')));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.actionId, 'ingest_external_link');
    expect(requests.single.allowedPathRoot, r'C:\workspace');
    expect(requests.single.arguments, [
      'ingest-link',
      'https://example.com/article',
      '--output',
      r'C:\workspace/workbench_runs/ingest_external_link',
      '--timeout-seconds',
      '30',
      '--respect-robots',
    ]);
    expect(find.text('passed'), findsOneWidget);
    expect(find.text('public_readable'), findsOneWidget);
    expect(find.text('https://example.com/article'), findsWidgets);
    expect(find.textContaining('external_source_trace.json'), findsOneWidget);
    expect(find.textContaining('progress_events.jsonl'), findsOneWidget);
  });

  testWidgets('isolates invalid input without invoking Core', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    var invoked = false;
    final bridge = LocalCoreBridge(
      runner: (request) async {
        invoked = true;
        return const CoreBridgeProcessResult(
            exitCode: 0, stdout: '', stderr: '');
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalLinkImportPanel(
            coreBridge: bridge,
            coreCli: 'heitang-kb-forge',
            workingDirectory: r'C:\repo',
            workspace: r'C:\workspace',
            enabled: true,
            isWebRuntime: false,
            localeCode: 'en-US',
          ),
        ),
      ),
    );
    await tester.enterText(
        find.byKey(const Key('external-link-url-input')), 'file:///secret.txt');
    await tester.tap(find.byKey(const Key('external-link-import-action')));
    await tester.pump();

    expect(invoked, isFalse);
    expect(find.text('blocked'), findsOneWidget);
    expect(find.textContaining('credential-free public HTTP/HTTPS'),
        findsOneWidget);
  });

  testWidgets('displays structured runtime failure and repair guidance',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    final bridge = LocalCoreBridge(
      runner: (request) async => CoreBridgeProcessResult(
        exitCode: 1,
        stdout: jsonEncode({
          'status': 'failed',
          'readability_state': 'needs_manual_evidence',
          'failure_reason': 'Public source returned HTTP 403.',
          'repair_suggestion':
              'Use platform preflight or provide manual evidence; do not bypass login.',
          'backlink': 'https://example.com/private',
        }),
        stderr: 'Core operation failed.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalLinkImportPanel(
            coreBridge: bridge,
            coreCli: 'heitang-kb-forge',
            workingDirectory: r'C:\repo',
            workspace: r'C:\workspace',
            enabled: true,
            isWebRuntime: false,
            localeCode: 'en-US',
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('external-link-url-input')),
        'https://example.com/private');
    await tester.tap(find.byKey(const Key('external-link-import-action')));
    await tester.pumpAndSettle();

    expect(find.text('failed'), findsOneWidget);
    expect(find.text('needs_manual_evidence'), findsOneWidget);
    expect(find.textContaining('HTTP 403'), findsOneWidget);
    expect(find.textContaining('do not bypass login'), findsOneWidget);
  });

  testWidgets('keeps web runtime blocked and does not claim later capabilities',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExternalLinkImportPanel(
            coreBridge: LocalCoreBridge(),
            coreCli: 'heitang-kb-forge',
            workingDirectory: '.',
            workspace: '.',
            enabled: true,
            isWebRuntime: true,
            localeCode: 'zh-CN',
          ),
        ),
      ),
    );

    expect(find.textContaining('blocked_reason: web_local_cli_unsupported'),
        findsOneWidget);
    expect(find.textContaining('Browser、OCR、视频转写'), findsOneWidget);
    expect(find.textContaining('Knowledge Verification'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const Key('external-link-import-action')))
            .onPressed,
        isNull);
  });

  testWidgets('embeds the entry in Import and Parsing without new navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        initialSelectedIndex:
            pages.indexWhere((page) => page.id == 'import-parsing'),
        isWebRuntime: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, hasLength(18));
    expect(find.byKey(const Key('external-link-import-panel')), findsOneWidget);
    expect(find.text('外部链接导入'), findsOneWidget);
    expect(
        find.byKey(const Key('external-link-import-action')), findsOneWidget);
    expect(find.textContaining('Browser、OCR、视频转写'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
