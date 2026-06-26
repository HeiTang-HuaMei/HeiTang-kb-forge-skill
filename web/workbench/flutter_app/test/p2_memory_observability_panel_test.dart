import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Directory> createWorkspace() async {
    final dir =
        Directory.systemTemp.createTempSync('kb_forge_p2_memory_panel_');
    addTearDown(() async {
      for (var attempt = 0; attempt < 5; attempt += 1) {
        if (!dir.existsSync()) return;
        try {
          dir.deleteSync(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    });
    return dir;
  }

  Rc6RuntimeController buildController(Directory workspace) {
    return Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
          exitCode: 0,
          stdout: 'ok',
          stderr: '',
        ),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
  }

  List<Map<String, dynamic>> readJsonlFile(String path) {
    return File(path)
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
  }

  test('p2 memory observability panel creates user-blackbox evidence package',
      () async {
    final workspace = await createWorkspace();
    final controller = buildController(workspace);

    await controller.initialize();
    final summaryPath =
        await controller.runMemoryObservabilityPanelAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;

    expect(summary['schema_version'],
        'prd_v3_memory_observability_panel_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'memory_observability_panel');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'],
        'P2-42 TencentDB Agent Memory Adapter Evaluation / Optional Integration');
    expect(summary['memory_card_count'], 2);
    expect(summary['source_trace_count'], 2);
    expect(summary['timeline_event_count'], 2);
    expect(summary['failed_checks'], isEmpty);

    final memoryIndex = jsonDecode(
        File(summary['memory_index_reference_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(memoryIndex['status'], '已可用');
    expect(memoryIndex['title'], '工作区记忆');
    expect(memoryIndex['next_action'], '查看工作区记忆');
    expect(memoryIndex['memory_card_count'], 2);

    final sourceTrace = readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTrace, hasLength(2));
    expect(sourceTrace.every((row) => row['test_marker'] == true), isTrue);

    final timeline = readJsonlFile(summary['event_timeline_path'] as String);
    expect(timeline.map((row) => row['event_type']),
        contains('memory_panel_refreshed'));

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecycle['status'], 'pass');
    expect(lifecycle['restart_recovery'],
        contains('initialize reloads memory index'));
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['status'], 'pass');
    expect(boundary['external_project_name_user_visible'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundary['local_model_training_used'], isFalse);
    expect(boundary['gpu_training_used'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'external_project_name_user_visible',
        'provider_adapter_parser_user_visible',
        'capability_matrix_user_visible',
        'redis_vector_service_packaged_into_exe',
        'external_memory_service_connected',
        'external_model_called',
        'local_model_training_used',
        'gpu_training_used',
        'real_memory_applied',
        'real_user_data_deleted',
        'secret_plaintext_written',
        'stage_chain_mutated',
        'packaging_architecture_changed',
        'network_call_made',
        'new_dependency_added',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final reloaded = buildController(workspace);
    await reloaded.initialize();
    expect(reloaded.state.memoryIndexReferencePath,
        summary['memory_index_reference_path']);
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'memory_observability_panel_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'memory_observability_panel_summary' &&
            record.status == 'completed'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'memory_observability_panel_index' &&
            record.status == 'completed'),
        isTrue);
  });

  test('workspace memory action opens preview without implementation names',
      () async {
    final workspace = await createWorkspace();
    final controller = buildController(workspace);
    await controller.initialize();
    await controller.runMemoryObservabilityPanelAcceptance();

    const visibleEntry = '工作区记忆';
    final visibleStatus =
        controller.state.memoryIndexReferencePath.isEmpty ? '本地模式' : '增强记忆已生成';
    const actionLabel = '查看工作区记忆';
    final actionEnabled = controller.state.memoryIndexReferencePath.isNotEmpty;
    final preview = actionEnabled
        ? await controller.readWorkspaceTextArtifact(
            controller.state.memoryIndexReferencePath)
        : '';

    expect(visibleEntry, '工作区记忆');
    expect(visibleStatus, '增强记忆已生成');
    expect(actionLabel, '查看工作区记忆');
    expect(actionEnabled, isTrue);
    expect(preview, contains('工作区记忆'));
    expect(preview, contains('已可用'));
    expect(preview, contains('最近记忆活动'));
    expect(preview, isNot(contains('Provider')));
    expect(preview, isNot(contains('Adapter')));
    expect(preview, isNot(contains('Parser')));
    expect(preview, isNot(contains('Capability Matrix')));
    expect(preview, isNot(contains('dependency_gated')));
    expect(preview, isNot(contains('0/')));
  });
}
