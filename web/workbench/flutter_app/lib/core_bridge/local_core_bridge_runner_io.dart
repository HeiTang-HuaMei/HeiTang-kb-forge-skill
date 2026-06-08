import 'dart:io' show Process;

import 'local_core_bridge.dart';

Future<CoreBridgeProcessResult> runCoreBridgeProcess(CoreBridgeRequest request) async {
  final result = await Process.run(
    request.coreCli,
    request.arguments,
    workingDirectory: request.workingDirectory,
    environment: request.environment.isEmpty ? null : request.environment,
    runInShell: false,
  );
  return CoreBridgeProcessResult(
    exitCode: result.exitCode,
    stdout: '${result.stdout}',
    stderr: '${result.stderr}',
  );
}
