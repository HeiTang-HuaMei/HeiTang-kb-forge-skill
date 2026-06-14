import 'dart:convert';
import 'dart:io' show Process;

import 'local_core_bridge.dart';

Future<CoreBridgeProcessResult> runCoreBridgeProcess(
    CoreBridgeRequest request) async {
  final process = await Process.start(
    request.coreCli,
    request.arguments,
    workingDirectory: request.workingDirectory,
    environment: request.environment.isEmpty ? null : request.environment,
    runInShell: false,
  );
  final stdoutFuture = utf8.decoder.bind(process.stdout).join();
  final stderrFuture = utf8.decoder.bind(process.stderr).join();
  final exitFuture = process.exitCode;
  final token = request.cancellationToken;
  final outcome = await Future.any([
    exitFuture.then((_) => _ProcessOutcome.exited),
    Future<void>.delayed(request.timeout).then((_) => _ProcessOutcome.timedOut),
    if (token != null)
      token.whenCancelled.then((_) => _ProcessOutcome.cancelled),
  ]);
  if (outcome != _ProcessOutcome.exited) {
    process.kill();
    await exitFuture;
  }
  final cancelled = outcome == _ProcessOutcome.cancelled;
  final timedOut = outcome == _ProcessOutcome.timedOut;
  return CoreBridgeProcessResult(
    exitCode: cancelled || timedOut ? -1 : await exitFuture,
    stdout: await stdoutFuture,
    stderr: await stderrFuture,
    cancelled: cancelled,
    timedOut: timedOut,
  );
}

enum _ProcessOutcome {
  exited,
  timedOut,
  cancelled,
}
