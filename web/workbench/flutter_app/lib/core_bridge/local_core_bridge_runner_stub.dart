import 'local_core_bridge.dart';

Future<CoreBridgeProcessResult> runCoreBridgeProcess(CoreBridgeRequest request) async {
  return const CoreBridgeProcessResult(
    exitCode: -1,
    stdout: '',
    stderr: 'Local Core CLI execution is not available in this runtime.',
  );
}
