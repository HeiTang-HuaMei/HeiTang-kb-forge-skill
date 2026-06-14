import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';

void main() {
  test('builds allowlisted core commands without shell execution', () {
    const bridge = LocalCoreBridge();
    const request = CoreBridgeRequest(
      actionId: 'workspace_inspect',
      coreCli: 'python',
      workingDirectory: r'C:\repo',
      arguments: ['workspace-list', '--workspace', r'C:\workspace'],
    );

    expect(bridge.buildCommand(request),
        ['python', 'workspace-list', '--workspace', r'C:\workspace']);
  });

  test('allows skill governance report core command', () {
    const bridge = LocalCoreBridge();
    const request = CoreBridgeRequest(
      actionId: 'skill_governance_report',
      coreCli: 'python',
      workingDirectory: r'C:\repo',
      arguments: [
        'skill-governance-report',
        '--skill',
        r'C:\workspace\skill',
        '--output',
        r'C:\workspace\out'
      ],
    );

    expect(bridge.buildCommand(request), [
      'python',
      'skill-governance-report',
      '--skill',
      r'C:\workspace\skill',
      '--output',
      r'C:\workspace\out'
    ]);
  });

  test('allows methodology extraction core command', () {
    const bridge = LocalCoreBridge();
    const request = CoreBridgeRequest(
      actionId: 'extract_methodology',
      coreCli: 'python',
      workingDirectory: r'C:\repo',
      arguments: [
        'extract-methodology',
        '--kb',
        r'C:\workspace\package',
        '--out',
        r'C:\workspace\out'
      ],
    );

    expect(bridge.buildCommand(request), [
      'python',
      'extract-methodology',
      '--kb',
      r'C:\workspace\package',
      '--out',
      r'C:\workspace\out'
    ]);
  });

  test('allows document backend core commands', () {
    const bridge = LocalCoreBridge();
    const requests = <CoreBridgeRequest>[
      CoreBridgeRequest(
        actionId: 'preflight_documents',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'preflight-documents',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'batch_import_documents',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'batch-import-documents',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'run_document_understanding',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'run-document-understanding',
          '--input',
          r'C:\workspace\input',
          '--preflight',
          r'C:\workspace\preflight',
          '--runtime-config',
          r'C:\workspace\runtime_backend_config.json',
          '--output',
          r'C:\workspace\out',
          '--progress-jsonl'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'build_knowledge_base',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'build-knowledge-base',
          '--document-understanding',
          r'C:\workspace\document_understanding',
          '--output',
          r'C:\workspace\out',
          '--progress-jsonl'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'build_knowledge_package',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'build-knowledge-package',
          '--knowledge-base',
          r'C:\workspace\knowledge_base',
          '--output',
          r'C:\workspace\out',
          '--progress-jsonl'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'fallback_parser_contract',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'fallback-parser-contract',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_marker_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['check-marker-backend', '--output', r'C:\workspace\out'],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_marker_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-marker-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_docling_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['check-docling-backend', '--output', r'C:\workspace\out'],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_docling_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-docling-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'run_docling_convert',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'run-docling-convert',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'run_marker_convert',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'run-marker-convert',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_unstructured_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'check-unstructured-backend',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_unstructured_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-unstructured-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_mineru_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['check-mineru-backend', '--output', r'C:\workspace\out'],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_mineru_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-mineru-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'run_mineru_document_understanding',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'run-mineru-document-understanding',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_opendataloader_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'check-opendataloader-backend',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_opendataloader_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-opendataloader-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'run_opendataloader_convert',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'run-opendataloader-convert',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_surya_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['check-surya-backend', '--output', r'C:\workspace\out'],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_surya_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-surya-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'check_paddleocr_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['check-paddleocr-backend', '--output', r'C:\workspace\out'],
      ),
      CoreBridgeRequest(
        actionId: 'smoke_paddleocr_backend',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'smoke-paddleocr-backend',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
      CoreBridgeRequest(
        actionId: 'run_paddleocr_ocr',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'run-paddleocr-ocr',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\out'
        ],
      ),
    ];

    for (final request in requests) {
      expect(bridge.buildCommand(request).first, 'python');
      expect(bridge.buildCommand(request)[1], request.arguments.first);
    }
  });

  test('rejects shell metacharacters and non-allowlisted commands', () {
    const bridge = LocalCoreBridge();

    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'package_build',
          coreCli: 'python',
          workingDirectory: r'C:\repo',
          arguments: [
            'build',
            '--input',
            r'C:\input && del C:\x',
            '--output',
            r'C:\output'
          ],
        ),
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
          'errorId', 'core_bridge_shell_syntax_rejected')),
    );

    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'package_build',
          coreCli: 'python',
          workingDirectory: r'C:\repo',
          arguments: ['cmd', '--package', r'C:\package'],
        ),
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
          'errorId', 'core_bridge_command_not_allowed')),
    );
  });

  test('rejects secret environment and redacts command output', () async {
    const bridge = LocalCoreBridge(
      runner: _fakeRunner,
    );

    final rejected = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['build', '--input', r'C:\input', '--output', r'C:\output'],
        environment: {'HEITANG_LLM_API_KEY': 'sk-live-secret'},
      ),
    );

    expect(rejected.status, 'blocked');
    expect(rejected.errorId, 'core_bridge_secret_env_rejected');

    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: [
          'build',
          '--input',
          r'C:\input',
          '--output',
          r'C:\output',
          '--sample-key=sk-live-secret'
        ],
      ),
    );

    expect(result.status, 'pass');
    expect(result.stdout, contains('<redacted>'));
    expect(result.commandPreview.join(' '), contains('<redacted>'));
    expect(result.commandPreview.join(' '), isNot(contains('sk-live-secret')));
  });

  test('marks timed out core operations without invoking a shell', () async {
    const bridge = LocalCoreBridge(
      runner: _slowRunner,
    );

    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['build', '--input', r'C:\input', '--output', r'C:\output'],
        timeout: Duration(milliseconds: 1),
      ),
    );

    expect(result.status, 'fail');
    expect(result.errorId, 'core_operation_timeout');
    expect(result.timedOut, isTrue);
    expect(result.exitCode, -1);
  });

  test('marks non-zero exit code as failed and redacts stderr', () async {
    const bridge = LocalCoreBridge(
      runner: _failedRunner,
    );

    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        arguments: ['build', '--input', r'C:\input', '--output', r'C:\output'],
      ),
    );

    expect(result.status, 'fail');
    expect(result.errorId, 'core_operation_failed');
    expect(result.exitCode, 2);
    expect(result.stderr, contains('<redacted>'));
    expect(result.stderr, isNot(contains('sk-live-secret')));
  });

  test('marks web runtime unsupported for local cli bridge', () {
    const bridge = LocalCoreBridge();

    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'build_package',
          coreCli: 'python',
          workingDirectory: r'C:\repo',
          arguments: [
            'build',
            '--input',
            r'C:\input',
            '--output',
            r'C:\output'
          ],
        ),
        isWeb: true,
      ),
      throwsA(isA<CoreBridgeException>().having(
          (error) => error.errorId, 'errorId', 'core_bridge_web_unsupported')),
    );
  });
}

Future<CoreBridgeProcessResult> _fakeRunner(CoreBridgeRequest request) async {
  return const CoreBridgeProcessResult(
    exitCode: 0,
    stdout: 'ok token=sk-live-secret',
    stderr: '',
  );
}

Future<CoreBridgeProcessResult> _slowRunner(CoreBridgeRequest request) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return const CoreBridgeProcessResult(exitCode: 0, stdout: '', stderr: '');
}

Future<CoreBridgeProcessResult> _failedRunner(CoreBridgeRequest request) async {
  return const CoreBridgeProcessResult(
    exitCode: 2,
    stdout: '',
    stderr: 'failed api_key=sk-live-secret',
  );
}
