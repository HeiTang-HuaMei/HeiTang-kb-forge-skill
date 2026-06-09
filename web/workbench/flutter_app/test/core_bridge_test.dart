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

    expect(bridge.buildCommand(request), ['python', 'workspace-list', '--workspace', r'C:\workspace']);
  });

  test('rejects shell metacharacters and non-allowlisted commands', () {
    const bridge = LocalCoreBridge();

    expect(
      () => bridge.buildCommand(
        const CoreBridgeRequest(
          actionId: 'package_build',
          coreCli: 'python',
          workingDirectory: r'C:\repo',
          arguments: ['build', '--input', r'C:\input && del C:\x', '--output', r'C:\output'],
        ),
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId, 'errorId', 'core_bridge_shell_syntax_rejected')),
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
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId, 'errorId', 'core_bridge_command_not_allowed')),
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
        arguments: ['build', '--input', r'C:\input', '--output', r'C:\output', '--sample-key=sk-live-secret'],
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
          arguments: ['build', '--input', r'C:\input', '--output', r'C:\output'],
        ),
        isWeb: true,
      ),
      throwsA(isA<CoreBridgeException>().having((error) => error.errorId, 'errorId', 'core_bridge_web_unsupported')),
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
