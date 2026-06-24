import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Directory> createWorkspace() async {
    final dir = Directory.systemTemp.createTempSync('kb_forge_rc6_widget_');
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    return dir;
  }

  Future<void> pumpWorkbench(WidgetTester tester,
      {Future<void> Function(Directory workspace)? setupWorkspace}) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    final workspace = await createWorkspace();
    if (setupWorkspace != null) {
      await setupWorkspace(workspace);
    }
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        campaign6AgentRuntimeStatus: sampleCampaign6AgentRuntimeStatus,
        campaign7ConfigurationStatus: sampleCampaign7ConfigurationStatus,
        campaign9DesktopDeliveryStatus: sampleCampaign9DesktopDeliveryStatus,
        isWebRuntime: false,
        enableLocalCoreActions: false,
        coreWorkspace: workspace.path,
      ),
    );
    await tester.pumpAndSettle();
  }

  void writeGeneratedDocumentExport(Directory output, String format) {
    final file =
        File('${output.path}${Platform.pathSeparator}generated.$format');
    if (format == 'pdf') {
      file.writeAsBytesSync('%PDF-1.4\n% test document\n'.codeUnits);
    } else {
      file.writeAsStringSync('generated $format from real input');
    }
    File('${output.path}${Platform.pathSeparator}generated_file_report.json')
        .writeAsStringSync(jsonEncode({
      'status': 'pass',
      'files': {
        format: file.path,
      },
    }));
  }

  void writeDuRecords(Directory workspace, List<String> relativePaths) {
    final du = Directory('${workspace.path}${Platform.pathSeparator}du')
      ..createSync(recursive: true);
    final normalized =
        Directory('${du.path}${Platform.pathSeparator}normalized_sources')
          ..createSync(recursive: true);
    final rows = <String>[];
    for (var index = 0; index < relativePaths.length; index += 1) {
      final normalizedPath =
          '${normalized.path}${Platform.pathSeparator}${index + 1}.md';
      File(normalizedPath)
          .writeAsStringSync('normalized ${relativePaths[index]}');
      rows.add(jsonEncode({
        'relative_path': relativePaths[index],
        'normalized_path': normalizedPath,
      }));
    }
    File('${du.path}${Platform.pathSeparator}document_understanding_records.jsonl')
        .writeAsStringSync('${rows.join('\n')}\n');
  }

  String jsonl(List<Map<String, Object?>> rows) =>
      '${rows.map(jsonEncode).join('\n')}\n';

  List<Map<String, dynamic>> readJsonlFile(String path) => File(path)
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map((line) => jsonDecode(line) as Map<String, dynamic>)
      .toList(growable: false);

  void writeStage2PreflightFixture(Directory workspace) {
    final standardDir =
        Directory('${workspace.path}${Platform.pathSeparator}standard_packages')
          ..createSync(recursive: true);
    final orchestrationDir =
        Directory('${workspace.path}${Platform.pathSeparator}orchestration')
          ..createSync(recursive: true);
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    final knowledgeBasesDir =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    final packageManifestPath =
        '${standardDir.path}${Platform.pathSeparator}package_manifest.json';
    final contentPackagePath =
        '${standardDir.path}${Platform.pathSeparator}content_package.jsonl';
    final okfKbManifestPath =
        '${kbDir.path}${Platform.pathSeparator}okf_kb_manifest.json';
    File(packageManifestPath).writeAsStringSync(jsonEncode({
      'standard': 'okf_candidate',
      'okf_runtime_enabled': true,
    }));
    File(contentPackagePath).writeAsStringSync(jsonl([
      {'chunk_id': 'okf_c1', 'text': 'okf runtime content'}
    ]));
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {'chunk_id': 'okf_kb_c1', 'text': 'okf kb chunk'}
    ]));
    File(okfKbManifestPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_kb_from_standard_package.v1',
      'status': 'pass',
      'okf_runtime_enabled': true,
    }));
    File('${standardDir.path}${Platform.pathSeparator}okf_runtime_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_okf_runtime_manifest.v1',
      'runtime_loaded': true,
      'export_import_runtime_available': true,
      'kb_build_runtime_available': true,
      'external_runtime': false,
      'package_manifest_path': packageManifestPath,
      'content_package_path': contentPackagePath,
      'kb_manifest_path': okfKbManifestPath,
    }));
    File('${standardDir.path}${Platform.pathSeparator}audit_history.jsonl')
        .writeAsStringSync(jsonl([
      {
        'action': 'export_standard_knowledge_package',
        'status': 'completed',
      },
      {
        'action': 'import_standard_knowledge_package',
        'status': 'completed',
      },
      {
        'action': 'build_kb_from_standard_package',
        'status': 'completed',
      },
    ]));
    File('${orchestrationDir.path}${Platform.pathSeparator}orchestration_plan.jsonl')
        .writeAsStringSync(jsonl([
      {
        'action': 'export_standard_knowledge_package',
        'status': 'completed',
        'boundary': {'okf_runtime_enabled': true},
      },
      {
        'action': 'import_standard_knowledge_package',
        'status': 'completed',
        'boundary': {'okf_runtime_enabled': true},
      },
      {
        'action': 'build_kb_from_standard_package',
        'status': 'completed',
        'boundary': {'okf_runtime_enabled': true},
      },
    ]));
    File('${knowledgeBasesDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'knowledge_bases': [
        {
          'kb_id': 'K_OKF1',
          'okf_runtime_enabled': true,
          'source_standard_package_manifest': packageManifestPath,
        }
      ],
    }));
  }

  void writeStage2SkillRuntimeFixture(Directory workspace) {
    final operationsDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations')
      ..createSync(recursive: true);
    final versionDir =
        Directory('${operationsDir.path}${Platform.pathSeparator}versions')
          ..createSync(recursive: true);
    final snapshot1 = '${versionDir.path}${Platform.pathSeparator}v1.md';
    final snapshot2 = '${versionDir.path}${Platform.pathSeparator}v2.md';
    final fusedSkillPath =
        '${operationsDir.path}${Platform.pathSeparator}fused_skill.md';
    final fusedManifestPath =
        '${operationsDir.path}${Platform.pathSeparator}fused_manifest.json';
    final operationManifestPath =
        '${operationsDir.path}${Platform.pathSeparator}skill_operation_manifest.json';
    final operationHistoryPath =
        '${operationsDir.path}${Platform.pathSeparator}skill_operation_history.json';
    final versionManifestPath =
        '${operationsDir.path}${Platform.pathSeparator}skill_version_manifest.json';
    final diffPath =
        '${operationsDir.path}${Platform.pathSeparator}skill_version_diff_report.json';
    final rollbackPath =
        '${operationsDir.path}${Platform.pathSeparator}skill_rollback_manifest.json';
    final auditPath =
        '${operationsDir.path}${Platform.pathSeparator}skill_runtime_audit.jsonl';
    File(snapshot1).writeAsStringSync('# v1');
    File(snapshot2).writeAsStringSync('# v2');
    File(fusedSkillPath).writeAsStringSync('# fused');
    File(fusedManifestPath).writeAsStringSync(jsonEncode({
      'source_mode': 'skill_plus_kb_fusion',
      'secret_plaintext_written': false,
    }));
    File(operationManifestPath).writeAsStringSync(jsonEncode({
      'requested_operation': 'fusion',
    }));
    File(operationHistoryPath).writeAsStringSync(jsonEncode({
      'records': [
        {'action': 'skill_operation_fusion', 'status': 'completed'}
      ],
    }));
    File(versionManifestPath).writeAsStringSync(jsonEncode({
      'versions': [
        {'version': 'v1', 'snapshot_path': snapshot1},
        {'version': 'v2', 'snapshot_path': snapshot2},
      ],
    }));
    File(diffPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_version_diff_report.v1',
      'status': 'pass',
      'secret_plaintext_written': false,
    }));
    File(rollbackPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_rollback_manifest.v1',
      'rollback_supported': true,
      'rollback_target_snapshot_path': snapshot1,
      'secret_plaintext_written': false,
    }));
    File(auditPath).writeAsStringSync(jsonl([
      {
        'action': 'skill_secondary_fusion',
        'secondary_fusion_runtime_available': true,
        'multi_version_runtime_available': true,
      }
    ]));
    File('${operationsDir.path}${Platform.pathSeparator}skill_runtime_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_runtime_manifest.v1',
      'runtime_loaded': true,
      'secondary_fusion_runtime_available': true,
      'multi_version_runtime_available': true,
      'version_count': 2,
      'versions': [
        {'version_id': 'v1', 'snapshot_path': snapshot1},
        {'version_id': 'v2', 'snapshot_path': snapshot2},
      ],
      'fused_skill_path': fusedSkillPath,
      'fused_manifest_path': fusedManifestPath,
      'operation_manifest_path': operationManifestPath,
      'operation_history_path': operationHistoryPath,
      'version_manifest_path': versionManifestPath,
      'version_diff_report_path': diffPath,
      'rollback_manifest_path': rollbackPath,
      'runtime_audit_path': auditPath,
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'external_skill_localization'],
      },
      'secret_plaintext_written': false,
    }));
  }

  void writeStage2AgentPermissionFixture(Directory workspace) {
    final auditDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit')
      ..createSync(recursive: true);
    final matrixPath =
        '${auditDir.path}${Platform.pathSeparator}workspace_permission_matrix.json';
    final permissionAuditPath =
        '${auditDir.path}${Platform.pathSeparator}permission_audit.json';
    final blockReportPath =
        '${auditDir.path}${Platform.pathSeparator}unauthorized_access_block_report.json';
    final runtimeAuditPath =
        '${auditDir.path}${Platform.pathSeparator}authorization_runtime_audit.jsonl';
    final validationReportPath =
        '${auditDir.path}${Platform.pathSeparator}agent_validation_report.json';
    final runHistoryPath =
        '${auditDir.path}${Platform.pathSeparator}run_history.json';
    File(matrixPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_agent_workspace_permission_matrix.v1',
      'status': 'pass',
      'matrix': [
        {'workspace_id': 'W_A'},
        {'workspace_id': 'W_M'},
        {
          'workspace_id': 'W_B',
          'can_read_sibling_workspace': false,
          'can_write_sibling_workspace': false,
        },
        {
          'workspace_id': 'W_C',
          'can_read_sibling_workspace': false,
          'can_write_sibling_workspace': false,
        },
      ],
      'blocked_capabilities': [
        'cross_workspace_write',
        'sibling_workspace_access',
        'plaintext_secret_read',
        'arbitrary_shell',
        'computer_use',
      ],
    }));
    File(permissionAuditPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_agent_permission_audit.v1',
      'status': 'pass',
      'workspace_permission_matrix_path': matrixPath,
    }));
    final cases = [
      {'expected_decision': 'allow', 'decision': 'allow'},
      for (final code in [
        'tool_not_allowlisted',
        'sibling_workspace_access',
        'plaintext_secret_read',
        'arbitrary_shell',
      ])
        {
          'expected_decision': 'deny',
          'decision': 'deny',
          'error_code': code,
        },
    ];
    File(blockReportPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_agent_unauthorized_access_block_report.v1',
      'status': 'pass',
      'case_count': cases.length,
      'cases': cases,
      'unauthorized_resources_selectable': false,
      'secret_plaintext_written': false,
    }));
    File(runtimeAuditPath).writeAsStringSync(jsonl([
      for (final item in cases)
        {
          'decision': item['decision'],
          if (item['error_code'] != null) 'error_code': item['error_code'],
        }
    ]));
    File(validationReportPath).writeAsStringSync(jsonEncode({
      'status': 'pass',
      'block_report_path': blockReportPath,
      'runtime_audit_path': runtimeAuditPath,
    }));
    File(runHistoryPath).writeAsStringSync(jsonEncode({
      'records': [
        {'action': 'authorization_runtime_audit', 'status': 'pass'}
      ],
    }));
  }

  void writeStage2IndustrialSmokeFixture(Directory workspace) {
    final acceptanceDir =
        Directory('${workspace.path}${Platform.pathSeparator}acceptance')
          ..createSync(recursive: true);
    final artifact = File(
        '${acceptanceDir.path}${Platform.pathSeparator}industrial_smoke_artifact.txt')
      ..writeAsStringSync('artifact');
    File('${acceptanceDir.path}${Platform.pathSeparator}industrial_exe_smoke_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_industrial_exe_smoke_report.v1',
      'status': 'passed',
      'step_count': 38,
      'step_results': [
        for (var index = 1; index <= 38; index += 1)
          {
            'step_id': index,
            'status': 'passed',
            'artifact': artifact.path,
          }
      ],
    }));
  }

  void writeStage2ExeLaunchSmokeFixture(Directory workspace) {
    final acceptanceDir =
        Directory('${workspace.path}${Platform.pathSeparator}acceptance')
          ..createSync(recursive: true);
    final exePath =
        '${acceptanceDir.path}${Platform.pathSeparator}heitang_workbench.exe';
    final exeBytes = <int>[0x4d, 0x5a, ...List<int>.filled(32769, 0)];
    File(exePath).writeAsBytesSync(exeBytes);
    final logPath =
        '${acceptanceDir.path}${Platform.pathSeparator}exe_launch_smoke.log';
    File(logPath).writeAsStringSync('launched');
    File('${acceptanceDir.path}${Platform.pathSeparator}exe_launch_smoke_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_exe_launch_smoke_report.v1',
      'status': 'passed',
      'platform': 'windows',
      'generated_by': 'scripts/smoke_windows_exe_launch.ps1',
      'exe_path': exePath,
      'exe_size_bytes': exeBytes.length,
      'exe_sha256':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'launched': true,
      'process_started': true,
      'process_id': 1000,
      'crashed': false,
      'startup_timeout': false,
      'log_path': logPath,
      'secret_plaintext_written': false,
    }));
  }

  void writeN8nReadinessFixture(Directory workspace) {
    final a2aDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001')
      ..createSync(recursive: true);
    final multiAgentDir =
        Directory('${workspace.path}${Platform.pathSeparator}multi_agent')
          ..createSync(recursive: true);
    final roundLogPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_rounds.jsonl';
    final runtimeAuditPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_runtime_audit.jsonl';
    final conflictPath =
        '${multiAgentDir.path}${Platform.pathSeparator}a2a_conflict_report.json';
    final consensusPath =
        '${multiAgentDir.path}${Platform.pathSeparator}a2a_consensus_report.json';
    final workflowReportPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_collaboration_report.md';
    final discussionManifestPath =
        '${multiAgentDir.path}${Platform.pathSeparator}multi_agent_discussion_manifest.json';
    File(roundLogPath).writeAsStringSync(jsonl([
      {'round': 1, 'output': 'one'},
      {'round': 2, 'output': 'two'},
      {'round': 3, 'output': 'three'},
    ]));
    File(runtimeAuditPath).writeAsStringSync(jsonl([
      {'round': 1, 'status': 'completed'},
      {'round': 2, 'status': 'completed'},
      {'round': 3, 'status': 'completed'},
    ]));
    File(conflictPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_conflict_report.v1',
      'round_count': 3,
    }));
    File(consensusPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_consensus_report.v1',
      'status': 'pass',
      'ready_for_export': true,
    }));
    File(workflowReportPath).writeAsStringSync('# A2A export');
    File(discussionManifestPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_multi_agent_discussion_manifest.v1',
      'a2a_conflict_report_path': conflictPath,
      'a2a_consensus_report_path': consensusPath,
    }));
    File('${a2aDir.path}${Platform.pathSeparator}a2a_session_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_session_manifest.v1',
      'status': 'report_generated',
      'round_limit': 3,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
      'conflict_report_path': conflictPath,
      'consensus_report_path': consensusPath,
    }));
  }

  void writeStage3FullProviderEvidenceFixture(Directory workspace) {
    writeStage2PreflightFixture(workspace);
    writeStage2SkillRuntimeFixture(workspace);
    writeStage2AgentPermissionFixture(workspace);
    writeStage2IndustrialSmokeFixture(workspace);
    writeStage2ExeLaunchSmokeFixture(workspace);
    writeN8nReadinessFixture(workspace);

    final duDir = Directory('${workspace.path}${Platform.pathSeparator}du')
      ..createSync(recursive: true);
    final normalizedDir =
        Directory('${duDir.path}${Platform.pathSeparator}normalized_sources')
          ..createSync(recursive: true);
    final normalizedAlpha =
        '${normalizedDir.path}${Platform.pathSeparator}alpha.md';
    final normalizedImage =
        '${normalizedDir.path}${Platform.pathSeparator}image.md';
    File(normalizedAlpha).writeAsStringSync('normalized parser evidence');
    File(normalizedImage).writeAsStringSync('normalized OCR evidence');
    File('${duDir.path}${Platform.pathSeparator}document_understanding_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_document_understanding_manifest.v1',
      'status': 'completed',
      'success_count': 2,
      'failed_count': 0,
      'normalized_source_count': 2,
    }));
    File('${duDir.path}${Platform.pathSeparator}document_understanding_records.jsonl')
        .writeAsStringSync(jsonl([
      {
        'relative_path': 'alpha.pdf',
        'normalized_path': normalizedAlpha,
      },
      {
        'relative_path': 'scan.png',
        'normalized_path': normalizedImage,
        'ocr_text': 'normalized OCR evidence',
        'ocr_provider': 'local_fixture_ocr',
      },
    ]));
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_source_manifest.v1',
      'status': 'imported',
      'source_count': 2,
      'sources': [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.pdf',
          'relative_path': 'alpha.pdf',
          'extension': '.pdf',
          'image_count': 0,
        },
        {
          'document_id': 'doc_scan',
          'source_name': 'scan.png',
          'relative_path': 'scan.png',
          'extension': '.png',
          'image_count': 1,
        },
      ],
    }));

    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {
        'chunk_id': 'c_stage3_1',
        'source_path': 'input/stage3.md',
        'text': 'stage3 full provider matrix evidence',
      },
    ]));
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync(jsonEncode({
      'status': 'searchable',
      'source_count': 1,
      'chunk_count': 1,
    }));
    File('${kbDir.path}${Platform.pathSeparator}index_profile.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_index_profile.v1',
      'status': 'ready',
      'vector_index_enabled': true,
      'vector_store': 'local_vector_reference',
    }));
    File('${kbDir.path}${Platform.pathSeparator}vector_index_reference.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_vector_index_reference.v1',
      'vector_store': 'local_vector_reference',
      'chunk_count': 1,
      'external_vector_db_required': false,
      'secret_plaintext_written': false,
    }));
    File('${kbDir.path}${Platform.pathSeparator}index_build_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_index_build_report.v1',
      'status': 'pass',
      'chunk_count': 1,
    }));
    File('${kbDir.path}${Platform.pathSeparator}index_metadata.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_index_metadata.v1',
      'index_type': 'hybrid_local',
      'chunk_count': 1,
    }));
    File('${kbDir.path}${Platform.pathSeparator}memory_index_reference.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_memory_index_reference.v1',
      'memory_scope': 'agent_long_term_memory',
      'memory_store': 'separate_from_kb_index',
    }));

    final kbRoot =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    for (final id in ['K1', 'K2']) {
      final dir = Directory('${kbRoot.path}${Platform.pathSeparator}$id')
        ..createSync(recursive: true);
      File('${dir.path}${Platform.pathSeparator}manifest.json')
          .writeAsStringSync('{"status":"searchable"}');
      File('${dir.path}${Platform.pathSeparator}chunks.jsonl')
          .writeAsStringSync('{"chunk_id":"$id-c1"}\n');
    }
    File('${kbRoot.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': 'Stage3 Alpha KB',
          'status': 'searchable',
          'operation': 'build',
          'chunk_count': 1,
        },
        {
          'kb_id': 'K2',
          'kb_name': 'Stage3 Beta KB',
          'status': 'searchable',
          'operation': 'build',
          'chunk_count': 1,
        },
      ],
    }));

    final queryDir =
        Directory('${workspace.path}${Platform.pathSeparator}query')
          ..createSync(recursive: true);
    File('${queryDir.path}${Platform.pathSeparator}multi_kb_query_result.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_multi_kb_query_result.v1',
      'query': 'stage3 authorized full matrix',
      'selected_kb_ids': ['K1', 'K2'],
      'result_count': 2,
      'selected_count': 2,
      'external_validation_status': 'not_enabled_local_only',
      'results': [
        {
          'chunk_id': 'K1-c1',
          'kb_id': 'K1',
          'title': 'Stage3 K1 evidence',
          'source_path': 'K1-source.md',
          'text': 'anysearchskill authorized query evidence',
          'score': 0.91,
          'citation': 'K1#chunk=1',
          'published_at': '2026-06-10',
          'time_window': 'last_30_days',
        },
        {
          'chunk_id': 'K2-c1',
          'kb_id': 'K2',
          'title': 'Stage3 K2 evidence',
          'source_path': 'K2-source.md',
          'text': 'last30days authorized time window evidence',
          'score': 0.9,
          'citation': 'K2#chunk=1',
          'metadata': {'time_window': 'last_30_days'},
        },
      ],
    }));
    File('${queryDir.path}${Platform.pathSeparator}retrieval_plan.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_retrieval_plan.v1',
      'selected_kb_count': 2,
    }));
    File('${queryDir.path}${Platform.pathSeparator}rerank_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_retrieval_rerank_report.v1',
      'result_count': 2,
    }));
    File('${queryDir.path}${Platform.pathSeparator}citation_coverage_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_retrieval_citation_coverage.v1',
      'result_count': 2,
      'citation_coverage': 1.0,
    }));
    File('${queryDir.path}${Platform.pathSeparator}conflict_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_retrieval_conflict_report.v1',
      'conflict_count': 0,
    }));
    File('${queryDir.path}${Platform.pathSeparator}external_validation_boundary.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_external_validation_boundary.v1',
      'external_calls_made': false,
      'secret_plaintext_written': false,
    }));

    final skillRoot =
        Directory('${workspace.path}${Platform.pathSeparator}skill')
          ..createSync(recursive: true);
    final primaryDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    final localizedDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2')
      ..createSync(recursive: true);
    final fusedDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}fused_product_ops_skill')
      ..createSync(recursive: true);
    final operationsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}operations')
          ..createSync(recursive: true);
    final versionsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}versions')
          ..createSync(recursive: true);
    final v1 = Directory('${versionsDir.path}${Platform.pathSeparator}v1')
      ..createSync(recursive: true);
    final v2 = Directory('${versionsDir.path}${Platform.pathSeparator}v2')
      ..createSync(recursive: true);
    final v1Snapshot = '${v1.path}${Platform.pathSeparator}SKILL.md';
    final v2Snapshot = '${v2.path}${Platform.pathSeparator}SKILL.md';
    File(v1Snapshot).writeAsStringSync('# Skill v1\n');
    File(v2Snapshot).writeAsStringSync('# Skill v2\n');
    File('${primaryDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Knowledge QA Skill\n');
    File('${primaryDir.path}${Platform.pathSeparator}skill_config.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S1',
      'source_mode': 'from_kb',
      'target_platform': 'codex',
      'status': 'validated',
    }));
    File('${localizedDir.path}${Platform.pathSeparator}localized_skill_manifest.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S2',
      'source_mode': 'external_skill_fusion',
      'status': 'validated',
    }));
    File('${localizedDir.path}${Platform.pathSeparator}diff_summary.md')
        .writeAsStringSync('# localized diff\n');
    File('${fusedDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Fused product ops Skill\n');
    File('${fusedDir.path}${Platform.pathSeparator}skill_manifest.json')
        .writeAsStringSync(jsonEncode({
      'skill_id': 'S3',
      'source_mode': 'skill_plus_kb_fusion',
      'status': 'validated',
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_generation_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_real_input_skill_generation.v1',
      'source_modes': ['from_kb', 'external_skill_fusion'],
      'selected_generation_config': {
        'skill_type': 'product',
        'target_platform': 'codex',
      },
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'skill_validation'],
      },
      'secret_plaintext_written': false,
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_package_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_package_manifest.v1',
      'status': 'ready',
      'skill_packages': [
        {'skill_id': 'S1', 'schema_id': 'mmskills_local_schema.v1'}
      ],
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'skill_validation'],
      },
      'secret_plaintext_written': false,
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_validation_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_factory_validation.v1',
      'status': 'pass',
      'ready_for_agent_binding': true,
      'secret_plaintext_written': false,
    }));
    File('${operationsDir.path}${Platform.pathSeparator}agent_binding_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_agent_binding_manifest.v1',
      'status': 'bound',
      'agent_id': 'knowledge_qa_agent',
    }));
    File('${operationsDir.path}${Platform.pathSeparator}skill_version_diff_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_version_diff_report.v1',
      'status': 'pass',
    }));
    File('${operationsDir.path}${Platform.pathSeparator}skill_runtime_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_runtime_manifest.v1',
      'runtime_loaded': true,
      'external_runtime': false,
      'secondary_fusion_runtime_available': true,
      'multi_version_runtime_available': true,
      'version_count': 2,
      'versions': [
        {'version_id': 'v1', 'snapshot_path': v1Snapshot},
        {'version_id': 'v2', 'snapshot_path': v2Snapshot},
      ],
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'external_skill_localization'],
      },
      'secret_plaintext_written': false,
    }));

    final agentRoot =
        Directory('${workspace.path}${Platform.pathSeparator}agent')
          ..createSync(recursive: true);
    final auditRoot =
        Directory('${agentRoot.path}${Platform.pathSeparator}audit')
          ..createSync(recursive: true);
    File('${agentRoot.path}${Platform.pathSeparator}agent_generation_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_agent_generation_manifest.v1',
      'agent_id': 'agent_memory_probe',
      'memory': {'long_term': 'memory_index_reference'},
    }));
    File('${auditRoot.path}${Platform.pathSeparator}permission_audit.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_agent_permission_audit.v1',
      'agent_id': 'agent_memory_probe',
      'permission_checks': ['memory_permission_boundary'],
    }));
    File('${auditRoot.path}${Platform.pathSeparator}agent_validation_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_agent_validation_report.v1',
      'status': 'pass',
      'agent_id': 'agent_memory_probe',
      'checks': [
        {'check_id': 'memory_separated_from_kb_index', 'status': 'pass'},
      ],
    }));

    final structuredDir = Directory(
        '${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured')
      ..createSync(recursive: true);
    final jsonPath =
        '${structuredDir.path}${Platform.pathSeparator}knowledge_export.json';
    final csvPath =
        '${structuredDir.path}${Platform.pathSeparator}knowledge_export.csv';
    File(jsonPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_structured_document_export_payload.v1',
      'status': 'pass',
      'sources': [
        {'source_name': 'source.md', 'relative_path': 'input/source.md'}
      ],
      'retrieval': {
        'results': [
          {'title': 'real export evidence', 'citation': 'source.md#chunk=1'}
        ],
      },
      'retrieval_results': [
        {'title': 'real export evidence', 'citation': 'source.md#chunk=1'}
      ],
      'redaction': {'secret_plaintext_written': false},
    }));
    File(csvPath).writeAsStringSync(
        'record_type,title,citation\nretrieval_result,real export evidence,source.md#chunk=1\n');
    File('${structuredDir.path}${Platform.pathSeparator}structured_export_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_structured_document_export.v1',
      'status': 'pass',
      'json_output': jsonPath,
      'csv_output': csvPath,
    }));

    final videoDir = Directory(
        '${agentRoot.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}video')
      ..createSync(recursive: true);
    final toolDir = Directory('${agentRoot.path}${Platform.pathSeparator}tool')
      ..createSync(recursive: true);
    final externalSkillDir = Directory(
        '${agentRoot.path}${Platform.pathSeparator}external_skills${Platform.pathSeparator}video_generation_skill')
      ..createSync(recursive: true);
    File('${videoDir.path}${Platform.pathSeparator}prompt.txt')
        .writeAsStringSync('video handoff prompt');
    File('${videoDir.path}${Platform.pathSeparator}cost_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_tool_cost_report.v1',
      'tool_id': 'video.generate',
      'api_call_count': 0,
    }));
    File('${videoDir.path}${Platform.pathSeparator}video_task_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_video_task_manifest.v1',
      'tool_id': 'video.generate',
      'fake_video_generated': false,
      'api_called': false,
    }));
    File('${toolDir.path}${Platform.pathSeparator}tool_call_log.jsonl')
        .writeAsStringSync(jsonl([
      {
        'schema_version': 'prd_v3_tool_call_log_record.v1',
        'tool_id': 'video.generate',
        'api_called': false,
      }
    ]));
    File('${externalSkillDir.path}${Platform.pathSeparator}skill_dependency_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_dependency_report.v1',
      'missing_provider_configs': ['video_custom_http_stub'],
    }));

    writeStage2PreflightFixture(workspace);
    writeStage2SkillRuntimeFixture(workspace);
    writeStage2AgentPermissionFixture(workspace);
    writeStage2IndustrialSmokeFixture(workspace);
    writeStage2ExeLaunchSmokeFixture(workspace);
    writeN8nReadinessFixture(workspace);
  }

  void expectIndustrialIndexArtifacts(String kbRoot,
      {String? kbId, Rc6RuntimeState? state}) {
    final indexProfile =
        File('$kbRoot${Platform.pathSeparator}index_profile.json');
    final keywordIndex =
        File('$kbRoot${Platform.pathSeparator}keyword_index.json');
    final vectorIndex =
        File('$kbRoot${Platform.pathSeparator}vector_index_reference.json');
    final metadataIndex =
        File('$kbRoot${Platform.pathSeparator}metadata_index.json');
    final citationIndex =
        File('$kbRoot${Platform.pathSeparator}citation_index.json');
    final memoryIndex =
        File('$kbRoot${Platform.pathSeparator}memory_index_reference.json');
    final indexBuildReport =
        File('$kbRoot${Platform.pathSeparator}index_build_report.json');
    final indexMetadata =
        File('$kbRoot${Platform.pathSeparator}index_metadata.json');

    for (final file in [
      indexProfile,
      keywordIndex,
      vectorIndex,
      metadataIndex,
      citationIndex,
      memoryIndex,
      indexBuildReport,
      indexMetadata,
    ]) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }

    expect(
        indexProfile.readAsStringSync(), contains('prd_v3_index_profile.v1'));
    expect(
        keywordIndex.readAsStringSync(), contains('prd_v3_keyword_index.v1'));
    expect(vectorIndex.readAsStringSync(),
        contains('prd_v3_vector_index_reference.v1'));
    expect(
        metadataIndex.readAsStringSync(), contains('prd_v3_metadata_index.v1'));
    expect(
        citationIndex.readAsStringSync(), contains('prd_v3_citation_index.v1'));
    expect(memoryIndex.readAsStringSync(),
        contains('prd_v3_memory_index_reference.v1'));
    expect(indexBuildReport.readAsStringSync(),
        contains('prd_v3_index_build_report.v1'));
    expect(
        indexMetadata.readAsStringSync(), contains('prd_v3_index_metadata.v1'));
    if (kbId != null) {
      expect(indexMetadata.readAsStringSync(), contains('"kb_id": "$kbId"'));
    }
    if (state != null) {
      expect(state.indexProfilePath, indexProfile.path);
      expect(state.keywordIndexPath, keywordIndex.path);
      expect(state.vectorIndexReferencePath, vectorIndex.path);
      expect(state.metadataIndexPath, metadataIndex.path);
      expect(state.citationIndexPath, citationIndex.path);
      expect(state.memoryIndexReferencePath, memoryIndex.path);
      expect(state.indexBuildReportPath, indexBuildReport.path);
    }
  }

  void expectMainKnowledgeArtifacts(
      Directory workspace, Rc6RuntimeState state) {
    final kbRoot = '${workspace.path}${Platform.pathSeparator}kb';
    final sourceMap = File('$kbRoot${Platform.pathSeparator}source_map.json');
    final indexMetadata =
        File('$kbRoot${Platform.pathSeparator}index_metadata.json');
    final buildLog = File('$kbRoot${Platform.pathSeparator}build.log');
    final errorLog = File('$kbRoot${Platform.pathSeparator}error.log');

    expect(state.sourceMapPath, sourceMap.path);
    expect(state.indexMetadataPath, indexMetadata.path);
    expect(state.buildLogPath, buildLog.path);
    expect(state.errorLogPath, errorLog.path);
    final sourceMapRaw = sourceMap.readAsStringSync();
    expect(sourceMapRaw, contains('prd_v2_source_map.v1'));
    final sourceMapPayload = jsonDecode(sourceMapRaw) as Map<String, dynamic>;
    final sourceDocs =
        (sourceMapPayload['documents'] as List? ?? const []).cast<Map>();
    expect(
        sourceDocs
            .map((doc) => doc['chunk_count'])
            .whereType<int>()
            .fold<int>(0, (total, count) => total + count),
        greaterThan(0));
    expectIndustrialIndexArtifacts(kbRoot, kbId: 'current_kb', state: state);
    expect(buildLog.readAsStringSync(),
        contains('schema_version=prd_v2_kb_build_log.v1'));
    expect(errorLog.readAsStringSync().trim(), isNotEmpty);
  }

  testWidgets('rc7 document library shows product-owned document state',
      (tester) async {
    await pumpWorkbench(tester);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-library')));
    await tester.tap(find.byKey(const Key('sidebar-document-library')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);
    await tester.tap(find.byKey(const Key('document-library-tab-1')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library')), findsOneWidget);
    expect(find.text('等待导入真实文档'), findsOneWidget);
    expect(find.textContaining('display_only'), findsNothing);
    expect(find.textContaining('示例行保持'), findsNothing);
    expect(find.text('刷新文档列表'), findsNothing);
    expect(find.text('生成知识库'), findsOneWidget);
    final buildButton = tester.widget<FilledButton>(find.ancestor(
      of: find.text('生成知识库'),
      matching: find.byType(FilledButton),
    ));
    expect(buildButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prd document library exposes search sort and multi-select',
      (tester) async {
    await pumpWorkbench(tester, setupWorkspace: (workspace) async {
      final input = Directory('${workspace.path}${Platform.pathSeparator}input')
        ..createSync(recursive: true);
      File('${input.path}${Platform.pathSeparator}alpha.md')
          .writeAsStringSync('alpha document');
      File('${input.path}${Platform.pathSeparator}beta.txt')
          .writeAsStringSync('beta document');
      File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
          .writeAsStringSync(jsonEncode({
        'schema_version': 'rc10_source_manifest.v1',
        'status': 'imported',
        'source_path': input.path,
        'source_name': 'input',
        'source_count': 2,
        'sources': [
          {
            'source_path': '${input.path}${Platform.pathSeparator}alpha.md',
            'source_name': 'alpha.md',
            'relative_path': 'alpha.md',
            'source_type': 'local_file',
            'size_bytes': 14,
          },
          {
            'source_path': '${input.path}${Platform.pathSeparator}beta.txt',
            'source_name': 'beta.txt',
            'relative_path': 'beta.txt',
            'source_type': 'local_file',
            'size_bytes': 13,
          },
        ],
        'workspace': workspace.path,
      }));
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-library')));
    await tester.tap(find.byKey(const Key('sidebar-document-library')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-library-tab-1')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('document-library-search-input')), findsOneWidget);
    expect(find.text('名称升序'), findsOneWidget);
    expect(find.text('名称降序'), findsOneWidget);
    expect(find.text('类型排序'), findsOneWidget);
    expect(find.text('导入文档后可在这里多选、预览和批量删除。'), findsOneWidget);
    expect(find.text('删除当前文档'), findsNothing);
    expect(find.text('更多文档操作'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rc8 retrieval keeps evidence, scoring, and authorization in one console',
      (tester) async {
    await pumpWorkbench(tester);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-retrieval-verification')));
    await tester.tap(find.byKey(const Key('sidebar-retrieval-verification')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('所选知识库'), findsOneWidget);
    expect(find.text('知识库'), findsWidgets);
    expect(find.text('引用来源'), findsOneWidget);
    expect(find.text('证据选择'), findsWidgets);
    expect(find.text('证据片段'), findsOneWidget);
    expect(find.text('人工纠偏'), findsOneWidget);
    expect(find.text('外部核对边界'), findsOneWidget);
    expect(find.text('证据结果'), findsNothing);
    expect(find.text('外部边界'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc7 skill and agent pages keep capabilities on owned pages',
      (tester) async {
    await pumpWorkbench(tester);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('从知识库生成'), findsOneWidget);
    expect(find.text('导入模板技能'), findsWidgets);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);

    await tester.tap(find.text('导入模板技能').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('skill-external-localization')), findsOneWidget);

    await tester.tap(find.text('版本操作').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);

    await tester.tap(find.text('检查导出').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-agent-factory-runtime')));
    await tester.tap(find.byKey(const Key('sidebar-agent-factory-runtime')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-workspace-setup')), findsOneWidget);
    expect(find.text('单个助手'), findsWidgets);
    await tester.tap(find.byKey(const Key('page-tab-1')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('简单构造'), findsWidgets);
    expect(find.text('复杂构造'), findsOneWidget);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('运行 Owner input 链路'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);
    expect(find.text('创建助手并进入对话'), findsWidgets);
    expect(find.text('多个助手讨论'), findsOneWidget);
    await tester.tap(find.byKey(const Key('page-tab-2')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('multi-agent-discussion-product-flow')),
        findsOneWidget);
    expect(find.text('让多个助手一起讨论'), findsOneWidget);
    expect(find.textContaining('arbitrary shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('rc6 full chain requires real import before execution', () async {
    final workspace = await createWorkspace();
    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'unexpected', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.runMinimumE2E();

    expect(requests, isEmpty);
    expect(controller.state.phase, Rc6RuntimePhase.failed);
    expect(controller.state.lastMessage, contains('文件选择器导入真实文件'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
            .existsSync(),
        isFalse);
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}input')
            .existsSync(),
        isFalse);
  });

  test('rc10 importing another file appends instead of replacing library state',
      () async {
    final workspace = await createWorkspace();
    final sourceDir =
        Directory('${workspace.path}${Platform.pathSeparator}source_files')
          ..createSync(recursive: true);
    final first = File('${sourceDir.path}${Platform.pathSeparator}alpha.md')
      ..writeAsStringSync([
        '# Alpha',
        'alpha real document with https://example.com/ref',
        '![chart](chart.png)',
        '',
        '| A | B |',
        '|---|---|',
        '| 1 | 2 |',
      ].join('\n'));
    final second = File('${sourceDir.path}${Platform.pathSeparator}beta.txt')
      ..writeAsStringSync('beta real document');
    final requests = <CoreBridgeRequest>[];
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (request) async {
              requests.add(request);
              final output = Directory(request.outputPath!)
                ..createSync(recursive: true);
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync(
                      '{"status":"completed","imported_count":2}');
              return const CoreBridgeProcessResult(
                  exitCode: 0, stdout: 'ok', stderr: '');
            },
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    await controller.importFilePath(first.path);
    await controller.importFilePath(second.path);

    final manifestFile =
        File('${workspace.path}${Platform.pathSeparator}source_manifest.json');
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final sources = (manifest['sources'] as List).cast<Map>();
    expect(requests.map((request) => request.actionId),
        everyElement('batch_import_documents'));
    expect(sources.map((source) => source['source_name']),
        containsAll(['alpha.md', 'beta.txt']));
    expect(sources.map((source) => source['document_id']),
        everyElement(startsWith('doc_')));
    expect(
        sources.map((source) => source['document_id']).toSet(), hasLength(2));
    final alpha =
        sources.firstWhere((source) => source['source_name'] == 'alpha.md');
    final beta =
        sources.firstWhere((source) => source['source_name'] == 'beta.txt');
    expect(alpha['extension'], '.md');
    expect(alpha['word_count'], greaterThan(5));
    expect(alpha['image_count'], 1);
    expect(alpha['table_count'], 1);
    expect(alpha['link_count'], 1);
    expect(alpha['structure_status'], 'local_text_scan');
    expect(beta['extension'], '.txt');
    expect(beta['word_count'], greaterThanOrEqualTo(3));
    expect(beta['structure_status'], 'local_text_scan');
    expect(controller.state.sourceCount, 2);
    expect(controller.state.sourceNames, containsAll(['alpha.md', 'beta.txt']));
    expect(controller.state.sourceRecords, hasLength(2));
    expect(controller.state.sourceRecords.map((source) => source.documentId),
        containsAll(sources.map((source) => source['document_id'])));
    expect(
        File('${workspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}alpha.md')
            .existsSync(),
        isTrue);
    expect(
        File('${workspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}beta.txt')
            .existsSync(),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.sourceCount, 2);
    expect(reloaded.state.sourceRecords.map((source) => source.sourceName),
        containsAll(['alpha.md', 'beta.txt']));
    expect(reloaded.state.sourceRecords.map((source) => source.documentId),
        containsAll(sources.map((source) => source['document_id'])));
  });

  test('prd document library imports web links as real source records',
      () async {
    final workspace = await createWorkspace();
    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}batch_import_report.json')
              .writeAsStringSync('{"status":"completed","imported_count":1}');
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.importWebLink('https://example.com/a/b?topic=kb');
    await controller.importWebLink('https://example.com/a/b?topic=kb');

    final manifestFile =
        File('${workspace.path}${Platform.pathSeparator}source_manifest.json');
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final sources = (manifest['sources'] as List).cast<Map>();
    expect(requests.map((request) => request.actionId),
        everyElement('batch_import_documents'));
    expect(sources, hasLength(2));
    expect(sources.map((source) => source['source_type']),
        everyElement('web_link'));
    expect(sources.map((source) => source['source_name']),
        everyElement(endsWith('.url.md')));
    expect(controller.state.sourceNames, hasLength(2));
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}input')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.url.md'))
            .length,
        2);
  });

  test('prd settings persist storage provider config without plaintext secrets',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    final savedPath = await controller.saveStorageProviderSettings(
      redisHost: '127.0.0.1',
      redisPort: 6379,
      redisKeyPrefix: 'heitang:',
      redisPassword: 'super-secret-password',
      qdrantEndpoint: 'http://127.0.0.1:6333',
      qdrantCollection: 'heitang_kb',
      qdrantDimension: 1536,
      qdrantApiKey: 'qdrant-secret-key',
    );

    final savedFile = File(savedPath);
    expect(savedFile.existsSync(), isTrue);
    final raw = savedFile.readAsStringSync();
    expect(raw, isNot(contains('super-secret-password')));
    expect(raw, isNot(contains('qdrant-secret-key')));
    expect(raw, contains('runtime_input_not_persisted'));
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    expect((saved['redis'] as Map)['status'], 'configured_not_tested');
    expect((saved['qdrant'] as Map)['collection'], 'heitang_kb');
    expect((saved['exporters'] as Map)['markdown'], isA<Map>());

    final reloadedController = buildController();
    await reloadedController.initialize();
    final reloaded = await reloadedController.loadStorageProviderSettings();
    expect((reloaded['redis'] as Map)['host'], '127.0.0.1');
    expect((reloaded['redis'] as Map)['key_prefix'], 'heitang:');
    expect((reloaded['qdrant'] as Map)['dimension'], 1536);
    expect((reloaded['provider'] as Map)['api_key_display'], contains('*'));
  });

  test('project config profile lifecycle persists and protects active profile',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    var profiles = await controller.loadProjectConfigProfiles();
    expect(profiles, hasLength(1));
    expect(profiles.single.profileId, 'default_local');
    expect(profiles.single.isActive, isTrue);

    final blockedDelete =
        await controller.deleteProjectConfigProfile('default_local');
    expect(blockedDelete, isFalse);

    final cloud = await controller.createProjectConfigProfile(
      displayName: '云机服务配置',
      mode: 'hybrid',
    );
    expect(cloud.mode, 'hybrid');
    final copy = await controller.copyProjectConfigProfile(cloud.profileId);
    expect(copy.rollbackFromProfileId, cloud.profileId);
    final edited = await controller.updateProjectConfigProfile(
      cloud.profileId,
      displayName: '云机服务配置 v2',
      mode: 'cloud',
    );
    expect(edited.version, 2);
    expect(edited.mode, 'cloud');

    final testId = await controller.testProjectConfigProfile(cloud.profileId);
    expect(testId, startsWith('profile_test_'));
    final activated =
        await controller.activateProjectConfigProfile(cloud.profileId);
    expect(activated.isActive, isTrue);

    profiles = await controller.loadProjectConfigProfiles();
    expect(profiles.where((profile) => profile.isActive), hasLength(1));
    expect(profiles.firstWhere((profile) => profile.isActive).profileId,
        cloud.profileId);
    final activeDelete =
        await controller.deleteProjectConfigProfile(cloud.profileId);
    expect(activeDelete, isFalse);
    final inactiveDelete =
        await controller.deleteProjectConfigProfile(copy.profileId);
    expect(inactiveDelete, isTrue);

    await controller.rollbackProjectConfigProfile();
    profiles = await controller.loadProjectConfigProfiles();
    expect(profiles.firstWhere((profile) => profile.isActive).profileId,
        'default_local');

    final reloaded = buildController();
    await reloaded.initialize();
    final reloadedProfiles = await reloaded.loadProjectConfigProfiles();
    expect(reloadedProfiles.firstWhere((profile) => profile.isActive).profileId,
        'default_local');

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final profileRaw =
        File('$configDir${Platform.pathSeparator}project_config_profiles.json')
            .readAsStringSync();
    expect(profileRaw, contains('prd_v3_project_config_profiles.v1'));
    expect(profileRaw, isNot(contains('super-secret-password')));
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    expect(runtimeStatus['schema_version'],
        'prd_v3_project_config_runtime_status.v1');
    expect((runtimeStatus['active_profile'] as Map)['profile_id'],
        'default_local');
    expect(
        (runtimeStatus['module_status'] as Map)['agent_workbench'], isA<Map>());
    final configAssetsPath = runtimeStatus['config_assets_path'] as String;
    final configAssets =
        jsonDecode(File(configAssetsPath).readAsStringSync()) as Map;
    expect(configAssets['schema_version'], 'prd_v3_project_config_assets.v1');
    final assets = configAssets['config_assets'] as Map;
    expect(
        assets.keys,
        containsAll([
          'storage_path',
          'llm_provider',
          'model_gateway_provider',
          'embedding_provider',
          'search_provider',
          'ocr_provider',
          'pdf_parser_provider',
          'exporter_provider',
          'redis',
          'vector_db',
          'network_authorization',
          'agent_memory_tool_policy',
        ]));
    expect((assets['storage_path'] as Map)['path_write_test'], '连接成功');
    expect((assets['model_gateway_provider'] as Map)['status'], '未配置');
    expect((assets['model_gateway_provider'] as Map)['secret_masked'], isTrue);
    expect((assets['exporter_provider'] as Map)['formats'], isA<Map>());
    expect(((assets['exporter_provider'] as Map)['formats'] as Map)['docx'],
        containsPair('button_enabled', false));
    expect(configAssets, isNot(contains('enabled_real')));
    final activationLog =
        File('$configDir${Platform.pathSeparator}profile_activation_log.jsonl')
            .readAsStringSync();
    expect(activationLog, contains('previous_profile_id'));
    expect(activationLog, isNot(contains('super-secret-password')));
    final changeLog =
        File('$configDir${Platform.pathSeparator}profile_change_log.jsonl')
            .readAsStringSync();
    expect(changeLog, contains('"action":"copy"'));
    final testLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(testLog, contains('"config_type":"project_config_profile"'));
    expect(testLog, isNot(contains('super-secret-password')));

    final smokePath = await reloaded.runStage3ProfilePersistenceSmoke();
    final smokeReport =
        jsonDecode(File(smokePath).readAsStringSync()) as Map<String, dynamic>;
    expect(smokeReport['schema_version'],
        'prd_v3_stage3_profile_persistence_smoke.v1');
    expect(smokeReport['status'], 'passed');
    expect(smokeReport['profile_a_id'], 'default_local');
    expect(smokeReport['profile_b_id'], isNot(''));
    expect(smokeReport['active_profile_persisted'], isTrue);
    expect(smokeReport['profile_count_protected'], isTrue);
    expect(smokeReport['delete_active_blocked'], isTrue);
    expect(smokeReport['delete_inactive_succeeded'], isTrue);
    expect(smokeReport['runtime_status_synced'], isTrue);
    expect(smokeReport['downstream_modules_synced'], isTrue);
    expect(
        (smokeReport['restart_simulation']
            as Map)['profiles_reloaded_from_disk'],
        isTrue);
    expect(smokeReport['manual_exe_ui_claimed'], isFalse);
    expect(smokeReport['secret_plaintext_written'], isFalse);
    expect(smokeReport['normal_ui_project_name_visible'], isFalse);
    expect(smokeReport['hot_swap_project_concept_visible'], isFalse);
    expect(smokeReport['external_runtime_executed'], isFalse);
    expect(smokeReport['workflow_executed'], isFalse);
    expect(jsonEncode(smokeReport), isNot(contains('super-secret-password')));
    expect(jsonEncode(smokeReport), isNot(contains('热插拔')));
    final smokeLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(
        smokeLog, contains('"config_type":"stage3_profile_persistence_smoke"'));
  });

  test('project config activation synchronizes downstream module status',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    final cloud = await controller.createProjectConfigProfile(
      displayName: '外部服务配置',
      mode: 'hybrid',
    );
    await controller.saveStorageProviderSettings(
      redisHost: '127.0.0.1',
      redisPort: 6379,
      redisKeyPrefix: 'heitang:',
      redisPassword: '',
      qdrantEndpoint: 'http://127.0.0.1:6333',
      qdrantCollection: 'heitang_kb',
      qdrantDimension: 768,
      qdrantApiKey: '',
    );
    await controller.activateProjectConfigProfile(cloud.profileId);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final moduleStatus = runtimeStatus['module_status'] as Map;
    expect((runtimeStatus['active_profile'] as Map)['profile_id'],
        cloud.profileId);
    expect((moduleStatus['dashboard'] as Map)['current_profile'], '外部服务配置');
    expect((moduleStatus['document_library'] as Map)['storage_path'],
        workspace.path);
    expect((moduleStatus['knowledge_base'] as Map)['index_backend'], '本地索引');
    expect((moduleStatus['knowledge_base'] as Map)['embedding_dimension'], 768);
    expect(
        (moduleStatus['retrieval_verification']
            as Map)['external_fact_verification'],
        '已配置未测试');
    expect(
        (moduleStatus['document_generation'] as Map)['office_export_available'],
        isFalse);
    expect(
        (moduleStatus['agent_workbench']
            as Map)['unauthorized_resources_selectable'],
        isFalse);
    expect((runtimeStatus['degradation'] as Map)['vector_failure'],
        contains('知识库回退本地索引'));
  });

  test('provider failure degradation writes masked config test logs', () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    final redisFailure = await controller.testRedisConnection(
      host: '127.0.0.1',
      port: 6379,
      keyPrefix: 'heitang:',
      password: '',
    );
    expect(
        redisFailure.status,
        anyOf(
          'missing_password',
          'auth_failed',
          'connection_failed',
          'ping_failed',
        ));
    expect(redisFailure.status, isNot('connected'));
    final vectorInvalid = await controller.testQdrantConnection(
      endpoint: 'not-a-url',
      collection: 'heitang_kb',
      dimension: 0,
      apiKey: 'qdrant-secret-token',
    );
    expect(vectorInvalid.status, 'invalid_endpoint');

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final moduleStatus = runtimeStatus['module_status'] as Map;
    expect((moduleStatus['agent_workbench'] as Map)['redis_memory_status'],
        '降级为本地模式');
    expect((moduleStatus['knowledge_base'] as Map)['index_backend'], '本地索引');
    expect((runtimeStatus['degradation'] as Map)['redis_failure'],
        contains('A2A 会话状态降级为本地文件'));
    expect((runtimeStatus['degradation'] as Map)['llm_failure'],
        contains('文档解析和本地导入可用'));

    final testLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(testLog, contains('"config_type":"redis"'));
    expect(testLog, contains('"config_type":"vector_db"'));
    expect(testLog, contains('"secret_masked":true'));
    expect(testLog, isNot(contains('qdrant-secret-token')));
    expect(testLog, isNot(contains('HEITANG_REDIS_PASSWORD=')));
  });

  test('model gateway provider persists masked config and syncs runtime status',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    final settingsPath = await controller.saveModelGatewayProviderConfig(
      displayName: 'AI Relay Gateway',
      gatewayType: 'custom_openai_compatible',
      baseUrl: 'https://relay.example.test/v1?sample=opaque-param',
      credential: 'runtime-input-token',
      adminUrl: 'https://relay.example.test/admin?sample=opaque-param',
      supportsStreaming: true,
      supportsEmbeddings: true,
      supportsFallback: true,
      supportsUsageStats: true,
    );
    final successReportPath =
        await controller.testModelGatewayProvider(simulatedStatus: 'success');
    final successReport =
        jsonDecode(File(successReportPath).readAsStringSync()) as Map;
    expect(
        successReport['schema_version'], 'prd_v3_model_gateway_test_report.v1');
    expect(successReport['status'], '连接成功');
    expect(successReport['external_call_performed'], isFalse);
    expect(successReport['paid_api_called'], isFalse);
    expect(successReport['secret_plaintext_written'], isFalse);
    expect(
        successReport['affected_modules'],
        containsAll(
            ['document_generation', 'skill_factory', 'agent_workbench']));

    final authReportPath = await controller.testModelGatewayProvider(
        simulatedStatus: 'auth_failure');
    final authReport =
        jsonDecode(File(authReportPath).readAsStringSync()) as Map;
    expect(authReport['status'], '鉴权失败');
    await controller.testModelGatewayProvider(simulatedStatus: 'timeout');
    await controller.testModelGatewayProvider(simulatedStatus: 'rate_limited');
    await controller.testModelGatewayProvider(
        simulatedStatus: 'upstream_unavailable');
    final fallbackReportPath =
        await controller.testModelGatewayProvider(simulatedStatus: 'fallback');

    final settingsRaw = File(settingsPath).readAsStringSync();
    expect(settingsRaw, contains('"model_gateway"'));
    expect(settingsRaw, contains('runtime_input_not_persisted'));
    expect(settingsRaw, isNot(contains('runtime-input-token')));
    expect(settingsRaw, isNot(contains('opaque-param')));
    expect(settingsRaw, isNot(contains('RELAY_' 'API_KEY')));

    final settings = jsonDecode(settingsRaw) as Map;
    final gateway = settings['model_gateway'] as Map;
    expect(gateway['gateway_type'], 'custom_openai_compatible');
    expect(gateway['base_url'], 'https://relay.example.test/v1');
    expect(gateway['admin_url'], 'https://relay.example.test/admin');
    expect(gateway['api_key_ref'], 'runtime_input_not_persisted');
    expect(gateway['secret_plaintext_written'], isFalse);

    final fallbackReport =
        jsonDecode(File(fallbackReportPath).readAsStringSync()) as Map;
    expect(fallbackReport['status'], 'fallback 已触发');
    expect(fallbackReport['fallback_triggered'], isTrue);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final modelGatewayDir = '$configDir${Platform.pathSeparator}model_gateway';
    final usageReport = jsonDecode(File(
            '$modelGatewayDir${Platform.pathSeparator}model_gateway_usage_report.json')
        .readAsStringSync()) as Map;
    expect(
        usageReport['schema_version'], 'prd_v3_model_gateway_usage_report.v1');
    expect(usageReport['secret_plaintext_written'], isFalse);
    expect(usageReport['route_usage_summary'], isA<List>());
    final gatewayFallbackReport = jsonDecode(File(
            '$modelGatewayDir${Platform.pathSeparator}model_gateway_fallback_report.json')
        .readAsStringSync()) as Map;
    expect(
        (gatewayFallbackReport['local_degradation']
            as Map)['local_import_available'],
        isTrue);
    final referenceRegistry = jsonDecode(File(
            '$modelGatewayDir${Platform.pathSeparator}model_gateway_reference_registry.json')
        .readAsStringSync()) as Map;
    final referenceStatuses =
        ((referenceRegistry['registered_references'] as List).cast<Map>())
            .map((entry) => entry['status'])
            .toList(growable: false);
    expect(referenceStatuses, contains('absorbed_into_architecture'));
    expect(referenceStatuses, contains('deferred_with_blocker'));
    expect(referenceStatuses, isNot(contains('reference_only')));
    expect(referenceStatuses, isNot(contains('needs_verification')));
    expect(referenceRegistry['runtime_dependency'], isFalse);
    final routePool = jsonDecode(
        File('$modelGatewayDir${Platform.pathSeparator}model_route_pool.json')
            .readAsStringSync()) as Map;
    expect(routePool['schema_version'], 'prd_v3_model_route_pool.v1');
    expect(routePool['plan_name'], '模型网关与大模型接入配置能力补全计划');
    expect((routePool['gateway_pool'] as List), isNotEmpty);
    expect((routePool['direct_provider_pool'] as List), hasLength(7));
    expect(routePool['model_route_count'], greaterThanOrEqualTo(34));
    final modelRoutes = (routePool['model_routes'] as List).cast<Map>();
    expect(modelRoutes.map((route) => route['route_scope']),
        containsAll(['skill_generation', 'external_skill_localization']));
    expect(modelRoutes.map((route) => route['route_scope']),
        containsAll(['document_generation', 'okf_compilation']));
    expect(modelRoutes.map((route) => route['route_scope']),
        containsAll(['agent_chat', 'a2a_consensus', 'tool_reasoning']));
    final embeddingRoute = modelRoutes
        .firstWhere((route) => route['model_route_id'] == 'route_embedding');
    expect((embeddingRoute['capabilities'] as Map)['embedding'], isTrue);
    expect((embeddingRoute['capabilities'] as Map)['chat'], isFalse);
    expect(routePool['embedding_route_separated_from_chat'], isTrue);

    final routeBinding = jsonDecode(File(
            '$modelGatewayDir${Platform.pathSeparator}model_route_binding_matrix.json')
        .readAsStringSync()) as Map;
    expect(
        routeBinding['schema_version'], 'prd_v3_model_route_binding_matrix.v1');
    final routeBindingModules = ((routeBinding['bindings'] as List).cast<Map>())
        .map((binding) => binding['module'])
        .toList(growable: false);
    expect(
        routeBindingModules,
        containsAll([
          'document_library_pipeline',
          'okf_pipeline',
          'document_generation',
          'skill_factory',
          'agent_workbench',
          'a2a',
          'tool_reasoning',
          'embedding',
        ]));
    expect(routeBinding['embedding_route_separated_from_chat'], isTrue);
    final usageCostPolicy = jsonDecode(File(
            '$modelGatewayDir${Platform.pathSeparator}model_usage_cost_policy.json')
        .readAsStringSync()) as Map;
    expect(
        usageCostPolicy['schema_version'], 'prd_v3_model_usage_cost_policy.v1');
    expect(usageCostPolicy['usage_audit_enabled'], isTrue);
    expect(usageCostPolicy['cost_audit_enabled'], isTrue);
    expect(usageCostPolicy['export_plaintext_secret'], isFalse);

    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final activeProfile = runtimeStatus['active_profile'] as Map;
    expect(
        activeProfile['model_gateway_config_id'], 'gateway_openai_compatible');
    final moduleStatus = runtimeStatus['module_status'] as Map;
    expect((moduleStatus['document_generation'] as Map)['model_gateway_status'],
        'fallback 已触发');
    expect((moduleStatus['skill_factory'] as Map)['model_gateway_status'],
        'fallback 已触发');
    expect((moduleStatus['agent_workbench'] as Map)['active_model_gateway'],
        'gateway_openai_compatible');
    expect((runtimeStatus['model_route_summary'] as Map)['model_route_count'],
        greaterThanOrEqualTo(34));
    expect(
        (runtimeStatus['model_route_summary']
            as Map)['embedding_route_separated_from_chat'],
        isTrue);
    expect(
        (moduleStatus['document_library'] as Map)['model_routes'], isA<Map>());
    expect((moduleStatus['knowledge_base'] as Map)['okf_model_routes'],
        isA<Map>());
    expect((moduleStatus['document_generation'] as Map)['model_routes'],
        isA<Map>());
    expect((moduleStatus['skill_factory'] as Map)['model_routes'], isA<Map>());
    expect(
        (moduleStatus['agent_workbench'] as Map)['model_routes'], isA<Map>());
    expect((moduleStatus['agent_workbench'] as Map)['a2a_model_routes'],
        isA<Map>());
    expect((moduleStatus['agent_workbench'] as Map)['tool_reasoning_routes'],
        isA<Map>());
    expect((runtimeStatus['degradation'] as Map)['model_gateway_failure'],
        contains('本地导入'));
    final configAssetsPath = runtimeStatus['config_assets_path'] as String;
    final configAssets =
        jsonDecode(File(configAssetsPath).readAsStringSync()) as Map;
    expect((configAssets['config_assets'] as Map)['model_gateway_provider'],
        containsPair('reference_status', 'needs_verification'));
    expect((configAssets['config_assets'] as Map)['model_route_pool'],
        containsPair('model_route_pool_enabled', true));

    final testLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(testLog, contains('"config_type":"model_gateway_provider"'));
    expect(testLog, contains('"secret_masked":true'));
    expect(testLog, isNot(contains('runtime-input-token')));
    expect(testLog, isNot(contains('opaque-param')));
    expect(
        File('$modelGatewayDir${Platform.pathSeparator}model_gateway_audit.jsonl')
            .readAsStringSync(),
        isNot(contains('runtime-input-token')));
    expect(
        File('$modelGatewayDir${Platform.pathSeparator}model_route_audit.jsonl')
            .readAsStringSync(),
        allOf(
          contains('prd_v3_model_route_audit_event.v1'),
          isNot(contains('runtime-input-token')),
        ));
  });

  test(
      'prd settings and parallel task validation produce industrial audit artifacts',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    final providerSettingsPath = await controller.saveProviderRuntimeSettings(
      llmProvider: 'official_openai',
      modelId: 'gpt-industrial',
      embeddingProvider: 'local_keyword_embedding',
      searchProvider: 'local_index',
      parserProvider: 'local_parser',
      ocrProvider: 'optional_ocr',
      apiKey: 'redacted-runtime-input',
    );
    final exporterSettingsPath = await controller.saveExporterSettings(
      docxExporter: 'office_exporter_optional',
      pdfExporter: 'pdf_exporter_optional',
      pptxExporter: 'pptx_exporter_optional',
      exportRoot: '${workspace.path}${Platform.pathSeparator}export',
    );
    final providerValidationPath =
        await controller.validateProviderRuntimeSettings();
    final exporterValidationPath = await controller.validateExporterSettings();
    final parallelReportPath =
        await controller.runParallelTaskCapacityValidation(taskCount: 8);
    final providerHealthPath =
        await controller.testAllRegisteredProviderCapabilities();
    final profiles = await controller.loadProjectConfigProfiles();
    expect(profiles, isNotEmpty);

    final providerRaw = File(providerSettingsPath).readAsStringSync();
    expect(providerRaw, isNot(contains('redacted-runtime-input')));
    expect(providerRaw, contains('runtime_input_not_persisted'));
    final providerValidation =
        jsonDecode(File(providerValidationPath).readAsStringSync()) as Map;
    expect(providerValidation['schema_version'],
        'prd_v3_provider_validation_report.v1');
    expect(providerValidation['secret_plaintext_written'], isFalse);
    expect(providerValidation['stage_3_provider_capability_activation'],
        'validated');
    expect(providerValidation['registered_project_loading_visible_to_user'],
        isFalse);
    final activationMatrixPath =
        providerValidation['provider_activation_matrix_path'] as String;
    final lifecycleHistoryPath =
        providerValidation['provider_lifecycle_history_path'] as String;
    final rollbackManifestPath =
        providerValidation['provider_rollback_manifest_path'] as String;
    final activationMatrix =
        jsonDecode(File(activationMatrixPath).readAsStringSync()) as Map;
    expect(activationMatrix['schema_version'],
        'prd_v3_provider_activation_matrix.v1');
    expect(activationMatrix['status'], 'validated');
    expect(
        (activationMatrix['user_concept_boundary']
            as Map)['hot_swap_project_concept_visible'],
        isFalse);
    expect(
        (activationMatrix['registered_project_boundary']
            as Map)['loaded_project_count'],
        0);
    expect(activationMatrix['activation_entries'], hasLength(8));
    final lifecycleHistory = File(lifecycleHistoryPath)
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(lifecycleHistory.map((event) => event['event_type']),
        containsAll(['validated', 'fallback_confirmed']));
    expect(
        lifecycleHistory
            .every((event) => event['secret_plaintext_written'] == false),
        isTrue);
    final rollbackManifest =
        jsonDecode(File(rollbackManifestPath).readAsStringSync()) as Map;
    expect(rollbackManifest['schema_version'],
        'prd_v3_provider_rollback_manifest.v1');
    expect(rollbackManifest['rollback_supported'], isTrue);
    expect(rollbackManifest['rollback_targets'], hasLength(8));

    final exporter = jsonDecode(File(exporterSettingsPath).readAsStringSync())
        as Map<String, dynamic>;
    expect((exporter['exporters'] as Map)['markdown'], isA<Map>());
    final exporterValidation =
        jsonDecode(File(exporterValidationPath).readAsStringSync()) as Map;
    expect(exporterValidation['schema_version'],
        'prd_v3_exporter_validation_report.v1');
    expect(exporterValidation['dependency_gated_formats'],
        containsAll(['docx', 'pdf', 'pptx']));

    final parallelReport =
        jsonDecode(File(parallelReportPath).readAsStringSync()) as Map;
    expect(parallelReport['schema_version'],
        'prd_v3_parallel_task_capacity_report.v1');
    expect(parallelReport['status'], 'passed');
    expect(parallelReport['supports_multi_task_parallelism'], isTrue);
    expect(parallelReport['supports_failure_isolation'], isTrue);
    expect(parallelReport['supports_recovery_retry'], isTrue);
    expect(parallelReport['provider_capability_isolation_status'], 'validated');
    expect(parallelReport['providerized_task_execution_ready'], isTrue);

    final isolationMatrix = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}tasks${Platform.pathSeparator}parallel_validation${Platform.pathSeparator}task_isolation_matrix.json')
        .readAsStringSync()) as Map;
    expect(
        isolationMatrix['schema_version'], 'prd_v3_task_isolation_matrix.v1');
    expect(isolationMatrix['status'], 'isolated');
    expect(isolationMatrix['tasks'], hasLength(8));
    final recoveryReport = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}tasks${Platform.pathSeparator}parallel_validation${Platform.pathSeparator}task_recovery_report.json')
        .readAsStringSync()) as Map;
    expect(recoveryReport['schema_version'], 'prd_v3_task_recovery_report.v1');
    expect(recoveryReport['retry_status'], 'succeeded');
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    expect(runtimeStatus['schema_version'],
        'prd_v3_project_config_runtime_status.v1');
    expect((runtimeStatus['module_status'] as Map)['document_generation'],
        isA<Map>());
    expect(
        ((runtimeStatus['module_status'] as Map)['document_generation']
            as Map)['provider_binding'],
        isA<Map>());
    expect(
        (((runtimeStatus['module_status'] as Map)['document_generation']
            as Map)['provider_binding'] as Map)['user_status'],
        '降级为本地模式');
    expect((runtimeStatus['degradation'] as Map)['redis_failure'],
        contains('Agent 短期记忆'));
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['registered_provider_count'],
        29);
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['ready_for_user_selection_count'],
        0);
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['external_runtime_load_allowed'],
        isFalse);
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['stage_2_preflight_status'],
        'blocked');
    final runtimePreflight =
        (runtimeStatus['stage_2_industrial_preflight'] as Map);
    expect(runtimePreflight['schema_version'],
        'prd_v3_stage2_industrial_preflight.v1');
    expect(runtimePreflight['status'], 'blocked');
    expect(runtimePreflight['runtime_load_allowed'], isFalse);
    expect(
        runtimePreflight['failed_checks'],
        containsAll([
          'okf_bundle_runtime_export_import',
          'okf_runtime_to_kb_build',
          'a2a_multi_round_collaboration',
          'industrial_exe_smoke_38_step',
          'industrial_exe_launch_smoke',
        ]));
    final registeredMatrixPath =
        runtimeStatus['registered_provider_integration_matrix_path'] as String;
    final registeredMatrix =
        jsonDecode(File(registeredMatrixPath).readAsStringSync()) as Map;
    expect(registeredMatrix['schema_version'],
        'prd_v3_registered_provider_integration_matrix.v1');
    expect(
        (registeredMatrix['registered_project_boundary']
            as Map)['registered_provider_count'],
        29);
    expect(
        (registeredMatrix['registered_project_boundary']
            as Map)['loaded_project_count'],
        0);
    expect(
        (registeredMatrix['registered_project_boundary']
            as Map)['registered_project_names_visible_to_user'],
        isFalse);
    expect(runtimeStatus['provider_adapter_contracts_path'], isA<String>());
    final providerEntries =
        (registeredMatrix['provider_entries'] as List).cast<Map>();
    expect(providerEntries, hasLength(29));
    expect(providerEntries.map((entry) => entry['provider_ref']).toSet(),
        hasLength(26));
    final providerAdapterContractsPath =
        registeredMatrix['provider_adapter_contracts_path'] as String;
    expect(runtimeStatus['provider_adapter_contracts_path'],
        providerAdapterContractsPath);
    final providerAdapterContracts =
        jsonDecode(File(providerAdapterContractsPath).readAsStringSync())
            as Map;
    expect(providerAdapterContracts['schema_version'],
        'prd_v3_provider_adapter_contracts.v1');
    expect(providerAdapterContracts['contract_count'], 26);
    expect(providerAdapterContracts['provider_mapping_count'], 29);
    expect(providerAdapterContracts['runtime_loaded_count'], 0);
    expect(providerAdapterContracts['ready_for_user_selection_count'], 0);
    expect(
        providerAdapterContracts['normal_ui_project_names_visible'], isFalse);
    expect(providerAdapterContracts['secret_plaintext_written'], isFalse);
    final adapterContracts =
        (providerAdapterContracts['contracts'] as List).cast<Map>();
    expect(adapterContracts.map((contract) => contract['provider_ref']).toSet(),
        hasLength(26));
    expect(
        adapterContracts.every((contract) =>
            (contract['health_check_actions'] as List).isNotEmpty),
        isTrue);
    expect(
        adapterContracts.every((contract) =>
            (contract['required_config_refs'] as List).isNotEmpty),
        isTrue);
    expect(
        adapterContracts.every((contract) =>
            (contract['activation_prerequisites'] as List).isNotEmpty),
        isTrue);
    expect(
        adapterContracts
            .every((contract) => contract['runtime_loaded'] == false),
        isTrue);
    expect(
        adapterContracts
            .every((contract) => contract['ready_for_user_selection'] == false),
        isTrue);
    expect(
        adapterContracts.every((contract) => contract['secret_masked'] == true),
        isTrue);
    final providerAdapterReadinessPath =
        runtimeStatus['provider_adapter_readiness_report_path'] as String;
    final providerAdapterReadiness =
        jsonDecode(File(providerAdapterReadinessPath).readAsStringSync())
            as Map;
    expect(providerAdapterReadiness['schema_version'],
        'prd_v3_provider_adapter_readiness_report.v1');
    expect(providerAdapterReadiness['contracts_path'],
        providerAdapterContractsPath);
    expect(providerAdapterReadiness['contract_count'], 26);
    expect(providerAdapterReadiness['readiness_entry_count'], 26);
    expect(providerAdapterReadiness['runtime_loaded_count'], 0);
    expect(providerAdapterReadiness['ready_for_user_selection_count'], 3);
    expect(providerAdapterReadiness['external_runtime_load_allowed'], isFalse);
    expect(
        (providerAdapterReadiness['stage_2_industrial_preflight']
            as Map)['status'],
        'blocked');
    expect(
        providerAdapterReadiness['normal_ui_project_names_visible'], isFalse);
    expect(providerAdapterReadiness['secret_plaintext_written'], isFalse);
    final readinessEntries =
        (providerAdapterReadiness['readiness_entries'] as List).cast<Map>();
    expect(readinessEntries, hasLength(26));
    final readyProviderRefs = readinessEntries
        .where((entry) => entry['ready_for_user_selection'] == true)
        .map((entry) => entry['provider_ref'])
        .toSet();
    expect(readyProviderRefs,
        {'mattpocock_skills', 'ai_marketing_skills', 'andrej_karpathy_skills'});
    expect(readinessEntries.every((entry) => entry['runtime_loaded'] == false),
        isTrue);
    expect(readinessEntries.every((entry) => entry['secret_masked'] == true),
        isTrue);
    expect(
        readinessEntries.map((entry) => entry['status']).toSet(),
        containsAll([
          '配置缺失',
          '已配置未测试',
          '已禁用',
          '需启动外部服务',
        ]));
    final blockedRagEvaluationReadiness = readinessEntries
        .where((entry) =>
            ['ragas', 'deepeval'].contains(entry['provider_ref']) &&
            (entry['capability_ids'] as List).contains('retrieval_provider'))
        .toList(growable: false);
    expect(blockedRagEvaluationReadiness, hasLength(2));
    expect(
        blockedRagEvaluationReadiness.every((entry) =>
            entry['status'] == '已配置未测试' &&
            entry['ready_for_user_selection'] == false &&
            entry['runtime_loaded'] == false),
        isTrue);
    final highRiskProviderExpectations = {
      'anysearchskill': {
        'status': '已禁用',
        'error_code': 'network_authorization_disabled',
        'gate_kind': 'network_search_provider_gate',
      },
      'last30days_skill': {
        'status': '需安装外部服务',
        'error_code': 'dependency_or_network_gate_required',
        'gate_kind': 'network_time_window_adapter_gate',
      },
      'seedance2_skill': {
        'status': '已禁用',
        'error_code': 'network_authorization_disabled',
        'gate_kind': 'secret_masked_video_skill_gate',
      },
      'rtk': {
        'status': '需启动外部服务',
        'error_code': 'external_runtime_required',
        'gate_kind': 'external_runtime_agent_tool_gate',
      },
    };
    for (final expectation in highRiskProviderExpectations.entries) {
      final entry = readinessEntries
          .firstWhere((item) => item['provider_ref'] == expectation.key);
      expect(entry['status'], expectation.value['status']);
      expect(entry['error_code'], expectation.value['error_code']);
      expect(entry['ready_for_user_selection'], isFalse);
      expect(entry['runtime_loaded'], isFalse);
      expect(entry['runtime_load_allowed'], isFalse);
      expect((entry['blocked_reasons'] as List), isNotEmpty);
      expect(entry['gate_kind'], expectation.value['gate_kind']);
      expect((entry['gate_audit'] as Map)['gate_kind'],
          expectation.value['gate_kind']);
      expect((entry['gate_audit'] as Map)['fallback_preserves_local_chain'],
          isTrue);
      final probe = jsonDecode(
          File((entry['test_artifacts'] as List).cast<String>().single)
              .readAsStringSync()) as Map<String, dynamic>;
      expect(probe['schema_version'],
          'prd_v3_provider_adapter_probe_high_risk_gate.v1');
      expect(probe['provider_ref'], expectation.key);
      expect(probe['gate_kind'], expectation.value['gate_kind']);
      expect((probe['gate_audit'] as Map)['gate_kind'],
          expectation.value['gate_kind']);
      expect((probe['gate_audit'] as Map)['network_call_attempted'], isFalse);
      if (expectation.key == 'rtk') {
        expect(
            (probe['gate_audit'] as Map)['permission_boundary_status'], '配置缺失');
        expect(probe['blocked_reasons'],
            contains('agent_permission_runtime_passed'));
      }
      expect(
          (probe['gate_audit'] as Map)['external_runtime_executed'], isFalse);
      expect((probe['gate_audit'] as Map)['fallback_preserves_local_chain'],
          isTrue);
      expect(probe['passed'], isFalse);
      expect(probe['ready_for_user_selection'], isFalse);
      expect(probe['runtime_loaded'], isFalse);
      expect(probe['selection_allowed'], isFalse);
      expect(probe['fallback_preserves_local_chain'], isTrue);
      expect(probe['network_call_attempted'], isFalse);
      expect(probe['external_runtime_executed'], isFalse);
      expect(probe['vendor_runtime_loaded'], isFalse);
      expect(probe['normal_ui_project_name_visible'], isFalse);
      expect(probe['secret_masked'], isTrue);
      expect(probe['secret_plaintext_written'], isFalse);
    }
    expect(
        readinessEntries
            .every((entry) => entry.containsKey('missing_config_refs')),
        isTrue);
    final readinessLogPath =
        providerAdapterReadiness['readiness_log_path'] as String;
    expect(File(readinessLogPath).readAsLinesSync(), hasLength(26));
    expect(providerEntries.every((entry) => entry['runtime_loaded'] == false),
        isTrue);
    expect(
        providerEntries
            .every((entry) => entry['visible_in_normal_ui'] == false),
        isTrue);
    expect(
        providerEntries.map((entry) => entry['capability_id']).toSet(),
        containsAll([
          'document_parser_ocr',
          'knowledge_embedding_vector',
          'retrieval_provider',
          'document_exporter',
          'skill_template_provider',
          'agent_model_tools_memory',
          'workflow_collaboration_export',
          'governance_audit_provider',
        ]));
    expect(
        providerEntries.where((entry) =>
            entry['capability_id'] == 'document_exporter' &&
            entry['provider_ref'] == 'n8n'),
        isEmpty);
    expect(
        providerEntries.where((entry) =>
            entry['capability_id'] == 'workflow_collaboration_export' &&
            entry['provider_ref'] == 'n8n'),
        hasLength(1));
    final registeredActivationLogPath =
        runtimeStatus['registered_provider_activation_log_path'] as String;
    final registeredActivationLog =
        File(registeredActivationLogPath).readAsLinesSync();
    expect(registeredActivationLog, hasLength(29));
    final registeredRollbackPath =
        runtimeStatus['registered_provider_rollback_manifest_path'] as String;
    final registeredRollback =
        jsonDecode(File(registeredRollbackPath).readAsStringSync()) as Map;
    expect(registeredRollback['schema_version'],
        'prd_v3_registered_provider_rollback_manifest.v1');
    expect((registeredRollback['rollback_targets'] as List), hasLength(29));
    final bindingPath =
        runtimeStatus['provider_capability_binding_manifest_path'] as String;
    final bindingManifest =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(bindingManifest['schema_version'],
        'prd_v3_provider_capability_binding_manifest.v1');
    expect(bindingManifest['binding_count'], 8);
    expect(bindingManifest['registered_provider_loaded_count'], 0);
    expect(bindingManifest['external_runtime_load_allowed'], isFalse);
    expect((bindingManifest['stage_2_industrial_preflight'] as Map)['status'],
        'blocked');
    expect(bindingManifest['local_fallback_binding_count'], 6);
    expect(bindingManifest['normal_ui_project_names_visible'], isFalse);
    expect(bindingManifest['secret_plaintext_written'], isFalse);
    final bindings = (bindingManifest['bindings'] as List).cast<Map>();
    expect(bindings, hasLength(8));
    final skillTemplateBinding = bindings.firstWhere(
        (binding) => binding['capability_id'] == 'skill_template_provider');
    expect(
        skillTemplateBinding['active_provider_ref'], 'andrej_karpathy_skills');
    expect(skillTemplateBinding['active_provider_kind'], 'registered_provider');
    expect(skillTemplateBinding['selection_allowed'], isTrue);
    final governanceBinding = bindings.firstWhere(
        (binding) => binding['capability_id'] == 'governance_audit_provider');
    expect(governanceBinding['active_provider_ref'], 'mattpocock_skills');
    expect(governanceBinding['active_provider_kind'], 'registered_provider');
    expect(governanceBinding['selection_allowed'], isTrue);
    expect(
        bindings
            .where((binding) =>
                binding['capability_id'] != 'skill_template_provider' &&
                binding['capability_id'] != 'governance_audit_provider')
            .every((binding) =>
                binding['active_provider_kind'] == 'local_fallback'),
        isTrue);
    expect(
        bindings
            .where((binding) =>
                binding['capability_id'] != 'skill_template_provider' &&
                binding['capability_id'] != 'governance_audit_provider')
            .every((binding) => binding['selection_allowed'] == false),
        isTrue);
    expect(bindings.every((binding) => binding['runtime_loaded'] == false),
        isTrue);
    expect(
        bindings.every(
            (binding) => binding['unauthorized_resources_selectable'] == false),
        isTrue);
    expect(
        bindings.every((binding) => binding['secret_masked'] == true), isTrue);
    expect(runtimeStatus['registered_provider_health_report_path'],
        providerHealthPath);
    final providerHealth =
        jsonDecode(File(providerHealthPath).readAsStringSync()) as Map;
    expect(providerHealth['schema_version'],
        'prd_v3_registered_provider_health_report.v1');
    expect(providerHealth['provider_adapter_contracts_path'],
        providerAdapterContractsPath);
    expect(providerHealth['provider_adapter_readiness_report_path'],
        providerAdapterReadinessPath);
    final providerRegistrySummaryPath =
        providerHealth['provider_registry_readiness_summary_path'] as String;
    expect(runtimeStatus['provider_registry_readiness_summary_path'],
        providerRegistrySummaryPath);
    final runtimeLoadEligibilityPath =
        runtimeStatus['provider_runtime_load_eligibility_manifest_path']
            as String;
    expect(providerHealth['provider_runtime_load_eligibility_manifest_path'],
        runtimeLoadEligibilityPath);
    expect(providerHealth['provider_entry_count'], 29);
    expect(providerHealth['provider_mapping_count'], 29);
    expect(providerHealth['unique_provider_ref_count'], 26);
    expect(providerHealth['registry_class_counts'], {
      'capability_provider': 21,
      'template_asset': 7,
      'architecture_reference': 1,
    });
    expect(providerHealth['architecture_reference_status_counts'], {
      'candidate_reference': 0,
      'absorbed_into_architecture': 29,
      'rejected_no_architecture_gain': 0,
      'deferred_with_blocker': 0,
    });
    expect(providerHealth['capability_area_count'], 8);
    expect(providerHealth['all_entries_checked'], isTrue);
    expect(providerHealth['runtime_loaded_count'], 0);
    expect(providerHealth['ready_for_user_selection_count'], 4);
    expect(providerHealth['ready_mapping_count'], 4);
    expect(providerHealth['ready_unique_provider_count'], 3);
    expect(providerHealth['external_runtime_load_allowed'], isFalse);
    expect((providerHealth['stage_2_industrial_preflight'] as Map)['status'],
        'blocked');
    expect(providerHealth['normal_ui_project_names_visible'], isFalse);
    expect(providerHealth['unverified_entries_marked_ready'], isFalse);
    expect(providerHealth['secret_plaintext_written'], isFalse);
    final registrySummary =
        jsonDecode(File(providerRegistrySummaryPath).readAsStringSync()) as Map;
    expect(registrySummary['schema_version'],
        'prd_v3_provider_registry_readiness_summary.v1');
    expect(registrySummary['provider_count'], 26);
    expect(registrySummary['provider_mapping_count'], 29);
    expect(registrySummary['capability_area_count'], 8);
    expect(registrySummary['ready_provider_count'], 3);
    expect(registrySummary['runtime_loaded_count'], 0);
    expect(registrySummary['external_runtime_load_eligible_count'], 0);
    expect(
        (registrySummary['user_concept_boundary']
            as Map)['external_project_names_visible_in_normal_ui'],
        isFalse);
    expect(
        (registrySummary['user_concept_boundary']
            as Map)['hot_swap_project_concept_visible'],
        isFalse);
    expect(
        (registrySummary['failure_isolation']
            as Map)['unavailable_provider_blocks_main_chain'],
        isFalse);
    final fullLoadingMatrixPath =
        runtimeStatus['stage3_full_provider_loading_matrix_path'] as String;
    expect(providerHealth['stage3_full_provider_loading_matrix_path'],
        fullLoadingMatrixPath);
    final fullLoadingMatrix =
        jsonDecode(File(fullLoadingMatrixPath).readAsStringSync()) as Map;
    expect(fullLoadingMatrix['schema_version'],
        'prd_v3_stage3_full_provider_loading_matrix.v1');
    expect(fullLoadingMatrix['status'], 'matrix_ready');
    expect(fullLoadingMatrix['provider_count'], 26);
    expect(fullLoadingMatrix['target_counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
    });
    expect(fullLoadingMatrix['actual_counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
    });
    expect(fullLoadingMatrix['normal_ui_project_names_visible'], isFalse);
    expect(fullLoadingMatrix['hot_swap_project_concept_visible'], isFalse);
    expect(fullLoadingMatrix['secret_plaintext_written'], isFalse);
    final fullLoadingRows =
        (fullLoadingMatrix['rows'] as List).cast<Map<String, dynamic>>();
    expect(fullLoadingRows, hasLength(26));
    expect(
        fullLoadingRows.map((row) => row['provider_ref']).toSet().length, 26);
    expect(
        fullLoadingRows.every((row) =>
            row.containsKey('loaded_configured') &&
            row.containsKey('runtime_ready') &&
            row.containsKey('downstream_bound') &&
            row.containsKey('fallback_verified') &&
            row.containsKey('audit_verified') &&
            row.containsKey('rollback_verified') &&
            row.containsKey('exe_verified') &&
            row.containsKey('source_artifacts')),
        isTrue);
    for (final row in fullLoadingRows) {
      final artifacts = row['source_artifacts'] as Map;
      expect(artifacts['config_schema_path'], providerAdapterContractsPath);
      expect(artifacts['profile_binding_path'], providerRegistrySummaryPath);
      expect(artifacts['readiness_report_path'], providerAdapterReadinessPath);
      expect(artifacts['health_report_path'], providerHealthPath);
      expect(artifacts['rollback_manifest_path'],
          runtimeStatus['registered_provider_rollback_manifest_path']);
      expect(artifacts['audit_log_path'],
          runtimeStatus['registered_provider_activation_log_path']);
      expect(artifacts['exe_preflight_path'], isA<String>());
    }
    expect(
        fullLoadingRows
            .every((row) => row['normal_ui_project_name_visible'] == false),
        isTrue);
    expect(
        fullLoadingRows
            .every((row) => row['hot_swap_project_concept_visible'] == false),
        isTrue);
    expect(
        fullLoadingRows
            .every((row) => row['secret_plaintext_written'] == false),
        isTrue);
    expect(
        fullLoadingRows.where(
            (row) => row['registry_entry_class'] == 'capability_provider'),
        hasLength(19));
    expect(
        fullLoadingRows
            .where((row) => row['registry_entry_class'] == 'template_asset'),
        hasLength(6));
    expect(
        fullLoadingRows.where(
            (row) => row['registry_entry_class'] == 'architecture_reference'),
        hasLength(1));
    final llamaIndexRow = fullLoadingRows
        .firstWhere((row) => row['provider_ref'] == 'llamaindex');
    expect(llamaIndexRow['registry_entry_class'], 'architecture_reference');
    expect(llamaIndexRow['architecture_reference_status'],
        'absorbed_into_architecture');
    expect(llamaIndexRow['runtime_loaded'], isFalse);
    expect(llamaIndexRow['runtime_ready'], isTrue);
    final fullLoadingTemplateRows = fullLoadingRows
        .where((row) => row['registry_entry_class'] == 'template_asset')
        .toList(growable: false);
    expect(
        fullLoadingTemplateRows.every((row) =>
            row['runtime_loaded'] == false &&
            (row['runtime_load_class'] == 'template_manifest_only' ||
                row['runtime_load_class'] == 'template_asset_manifest_only')),
        isTrue);
    final providerRows = (registrySummary['provider_rows'] as List).cast<Map>();
    expect(providerRows, hasLength(26));
    final n8nSummary =
        providerRows.firstWhere((entry) => entry['provider_ref'] == 'n8n');
    expect(n8nSummary['requires_external_runtime'], isTrue);
    expect(n8nSummary['runtime_load_allowed'], isFalse);
    expect(n8nSummary['external_runtime_load_eligible'], isFalse);
    expect(n8nSummary['runtime_loaded'], isFalse);
    expect(n8nSummary['rollback_supported'], isTrue);
    expect(n8nSummary['normal_ui_project_name_visible'], isFalse);
    expect(n8nSummary['secret_plaintext_written'], isFalse);
    final mattpocockSummary = providerRows
        .firstWhere((entry) => entry['provider_ref'] == 'mattpocock_skills');
    expect(mattpocockSummary['ready_for_user_selection'], isTrue);
    expect(mattpocockSummary['runtime_loaded'], isFalse);
    expect(
        (mattpocockSummary['capability_ids'] as List),
        containsAll([
          'skill_template_provider',
          'governance_audit_provider',
        ]));
    final lifecycleAuditSummaryPath =
        runtimeStatus['provider_lifecycle_audit_summary_path'] as String;
    final lifecycleAuditSummary =
        jsonDecode(File(lifecycleAuditSummaryPath).readAsStringSync()) as Map;
    expect(lifecycleAuditSummary['schema_version'],
        'prd_v3_provider_lifecycle_audit_summary.v1');
    expect(
        (lifecycleAuditSummary['provider_counts']
            as Map)['registered_provider_count'],
        26);
    expect(
        (lifecycleAuditSummary['provider_counts']
            as Map)['provider_mapping_count'],
        29);
    expect(
        (lifecycleAuditSummary['provider_counts']
            as Map)['runtime_loaded_count'],
        0);
    expect(
        (lifecycleAuditSummary['event_counts']
            as Map)['registered_activation_event_count'],
        29);
    expect(
        (lifecycleAuditSummary['source_artifacts']
            as Map)['registry_readiness_summary_path'],
        providerRegistrySummaryPath);
    expect(
        (lifecycleAuditSummary['industrial_boundaries']
            as Map)['normal_ui_project_names_visible'],
        isFalse);
    expect(
        (lifecycleAuditSummary['industrial_boundaries']
            as Map)['secret_plaintext_written'],
        isFalse);
    final coverageAuditPath =
        runtimeStatus['provider_integration_coverage_audit_path'] as String;
    final coverageAudit =
        jsonDecode(File(coverageAuditPath).readAsStringSync()) as Map;
    expect(coverageAudit['schema_version'],
        'prd_v3_provider_integration_coverage_audit.v1');
    expect(coverageAudit['status'], 'passed');
    expect(coverageAudit['provider_mapping_count'], 29);
    expect(coverageAudit['unique_provider_ref_count'], 26);
    expect(coverageAudit['capability_area_count'], 8);
    expect(coverageAudit['covered_mapping_count'], 29);
    expect(coverageAudit['failed_mapping_count'], 0);
    expect(coverageAudit['failed_mappings'], isEmpty);
    expect(coverageAudit['normal_ui_project_names_visible'], isFalse);
    expect(coverageAudit['hot_swap_project_concept_visible'], isFalse);
    expect(coverageAudit['external_runtime_executed'], isFalse);
    expect(coverageAudit['workflow_executed'], isFalse);
    expect(coverageAudit['secret_plaintext_written'], isFalse);
    final coverageRows = (coverageAudit['coverage_rows'] as List).cast<Map>();
    expect(coverageRows, hasLength(29));
    expect(
        coverageRows.every((row) =>
            row['coverage_status'] == 'passed' &&
            (row['missing_evidence'] as List).isEmpty),
        isTrue);
    for (final row in coverageRows) {
      final absorption = row['architecture_absorption'] as Map;
      final status = absorption['status'] as String;
      expect(
          absorption['decision_source'],
          anyOf('stage3_architecture_absorption_gate',
              'stage3_provider_registry_classification_gate'));
      expect(absorption['source_consumed'], isTrue);
      expect(absorption['learning_note_only'], isFalse);
      expect(absorption['indefinite_reference_allowed'], isFalse);
      expect(status, isNot(anyOf('reference_only', 'needs_verification')));
      if (status == 'absorbed_into_architecture') {
        expect(absorption['worth_absorbing'], isTrue);
        expect(absorption['absorption_required_now'], isTrue);
        expect(absorption['architecture_delivery_required'], isTrue);
        expect(absorption['absorbed_targets'] as List, isNotEmpty);
        final delivery = absorption['parallel_architecture_delivery'] as Map;
        expect(delivery['runtime_boundary'], isTrue);
        expect(delivery['ui_information_architecture'], isTrue);
        expect(delivery['capability_id'], row['capability_id']);
        expect(
            delivery['provider_classification'], row['registry_entry_class']);
        expect(absorption['blocker'], '');
        expect(absorption['rejection_reason'], '');
      } else if (status == 'deferred_with_blocker') {
        expect(absorption['worth_absorbing'], isTrue);
        expect(absorption['absorption_required_now'], isFalse);
        expect(absorption['blocker'] as String, isNotEmpty);
        expect(absorption['absorbed_targets'] as List, isEmpty);
        expect(absorption['parallel_architecture_delivery'] as Map, isEmpty);
      } else if (status == 'rejected_no_architecture_gain') {
        expect(absorption['worth_absorbing'], isFalse);
        expect(absorption['absorption_required_now'], isFalse);
        expect(absorption['rejection_reason'] as String, isNotEmpty);
        expect(absorption['absorbed_targets'] as List, isEmpty);
        expect(absorption['parallel_architecture_delivery'] as Map, isEmpty);
      } else {
        fail('Unexpected architecture reference status: $status');
      }
    }
    final sourceRegistryPath =
        '${Directory.current.path}${Platform.pathSeparator}assets${Platform.pathSeparator}external${Platform.pathSeparator}provider_capability_status.json';
    final sourceRegistryRaw = File(sourceRegistryPath).readAsStringSync();
    expect(sourceRegistryRaw,
        isNot(contains('"stage3_current_classification": "reference_only"')));
    expect(sourceRegistryRaw,
        isNot(contains('"runtime_load_class": "reference_only"')));
    expect(sourceRegistryRaw,
        isNot(contains('"architecture_reference_status": "reference_only"')));
    final sourceRegistry =
        jsonDecode(sourceRegistryRaw) as Map<String, dynamic>;
    expect(sourceRegistry['schema_version'],
        'prd_v3_provider_capability_status.v2');
    expect(sourceRegistry['indefinite_reference_state_allowed'], isFalse);
    expect(sourceRegistry['legacy_reference_only_contracts_are_trace_only'],
        isTrue);
    expect(
        (sourceRegistry['registry_entry_class_counts']
            as Map)['capability_provider'],
        19);
    expect(
        (sourceRegistry['architecture_reference_status_counts']
            as Map)['absorbed_into_architecture'],
        26);
    expect(
        coverageRows
            .every((row) => row['source_classification_consumed'] == true),
        isTrue);
    expect(
        coverageRows.every((row) =>
            (row['architecture_absorption'] as Map)['source_consumed'] == true),
        isTrue);
    final n8nCoverage = coverageRows.firstWhere((row) =>
        row['provider_ref'] == 'n8n' &&
        row['capability_id'] == 'workflow_collaboration_export');
    expect(n8nCoverage['requires_external_runtime'], isTrue);
    expect(n8nCoverage['runtime_loaded'], isFalse);
    expect((n8nCoverage['affected_modules'] as List),
        containsAll(['agent_workbench', 'artifact_center']));
    final templateRows = coverageRows
        .where((row) => row['registry_entry_class'] == 'template_asset')
        .toList(growable: false);
    expect(templateRows, hasLength(7));
    expect(
        templateRows.every((row) =>
            row['runtime_load_class'] == 'template_manifest_only' &&
            (row['architecture_absorption'] as Map)['status'] ==
                'absorbed_into_architecture'),
        isTrue);
    final architectureReferenceRows = coverageRows
        .where((row) => row['registry_entry_class'] == 'architecture_reference')
        .toList(growable: false);
    expect(architectureReferenceRows, hasLength(1));
    expect(
        architectureReferenceRows
            .every((row) => row['runtime_load_class'] != 'reference_only'),
        isTrue);
    expect(
        architectureReferenceRows.every((row) =>
            row['runtime_load_class'] == 'architecture_reference_no_runtime'),
        isTrue);
    final llamaindexCoverage = architectureReferenceRows
        .firstWhere((row) => row['provider_ref'] == 'llamaindex');
    expect(llamaindexCoverage['architecture_reference_status'],
        'absorbed_into_architecture');
    final llamaindexAbsorption =
        llamaindexCoverage['architecture_absorption'] as Map;
    expect(llamaindexAbsorption['architecture_delivery_required'], isTrue);
    expect(llamaindexAbsorption['blocker'], '');
    expect(
        llamaindexAbsorption['absorbed_targets'] as List,
        containsAll([
          'contract',
          'schema',
          'runtime_boundary',
          'ui_information_architecture',
          'test_gate',
          'audit_model',
          'fallback_strategy',
          'provider_loading_rule',
        ]));
    expect(
        (llamaindexAbsorption['parallel_architecture_delivery']
            as Map)['runtime_boundary'],
        isTrue);
    expect(llamaindexCoverage['runtime_loaded'], isFalse);
    expect(architectureReferenceRows.any((row) => row['provider_ref'] == 'rtk'),
        isFalse);
    final evaluationProviderRows = coverageRows
        .where((row) =>
            ['ragas', 'deepeval'].contains(row['provider_ref']) &&
            row['registry_entry_class'] == 'capability_provider')
        .toList(growable: false);
    expect(evaluationProviderRows, hasLength(4));
    expect(
        evaluationProviderRows.every((row) =>
            row['architecture_reference_status'] ==
                'absorbed_into_architecture' &&
            row['runtime_load_class'] == 'local_capability_enhancement'),
        isTrue);
    final rtkProviderRows = coverageRows
        .where((row) =>
            row['provider_ref'] == 'rtk' &&
            row['registry_entry_class'] == 'capability_provider')
        .toList(growable: false);
    expect(rtkProviderRows, hasLength(1));
    expect(rtkProviderRows.single['runtime_load_class'],
        'external_health_check_required');
    expect(rtkProviderRows.single['architecture_reference_status'],
        'absorbed_into_architecture');
    expect(rtkProviderRows.single['gate_kind'],
        'external_runtime_agent_tool_gate');
    expect(
        (rtkProviderRows.single['gate_audit']
            as Map)['external_runtime_executed'],
        isFalse);
    final userCatalogPath =
        runtimeStatus['provider_capability_user_catalog_path'] as String;
    final userCatalog =
        jsonDecode(File(userCatalogPath).readAsStringSync()) as Map;
    expect(userCatalog['schema_version'],
        'prd_v3_provider_capability_user_catalog.v1');
    expect(userCatalog['status'], 'passed');
    expect(userCatalog['capability_count'], 8);
    expect(userCatalog['runtime_loaded_capability_count'], 0);
    expect(userCatalog['normal_ui_project_names_visible'], isFalse);
    expect(userCatalog['hot_swap_project_concept_visible'], isFalse);
    expect(userCatalog['external_runtime_executed'], isFalse);
    expect(userCatalog['workflow_executed'], isFalse);
    expect(userCatalog['secret_plaintext_written'], isFalse);
    final userCatalogEntries = (userCatalog['entries'] as List).cast<Map>();
    expect(userCatalogEntries, hasLength(8));
    expect(
        userCatalogEntries.map((entry) => entry['display_name']).toSet(),
        containsAll([
          '解析 / OCR',
          'Embedding / 向量库',
          '文档导出',
          'Agent 模型 / 工具 / 记忆',
          'A2A / 工作流导出',
        ]));
    expect(
        jsonEncode(userCatalogEntries),
        isNot(anyOf(
          contains('n8n'),
          contains('docling'),
          contains('paddleocr'),
          contains('sirchmunk'),
          contains('hot-swap'),
          contains('热插拔'),
        )));
    final parserCatalogEntry = userCatalogEntries
        .firstWhere((entry) => entry['capability_id'] == 'document_parser_ocr');
    expect(parserCatalogEntry['configuration_entry'], '文档库');
    expect(parserCatalogEntry['current_behavior'], contains('本地解析'));
    final agentCatalogEntry = userCatalogEntries.firstWhere(
        (entry) => entry['capability_id'] == 'agent_model_tools_memory');
    expect(agentCatalogEntry['configuration_entry'], 'Agent 工作台');
    expect(agentCatalogEntry['normal_ui_project_name_visible'], isFalse);
    final healthEntries =
        (providerHealth['health_entries'] as List).cast<Map>();
    expect(healthEntries, hasLength(29));
    expect(healthEntries.every((entry) => entry['runtime_loaded'] == false),
        isTrue);
    final selectableHealthRefs = healthEntries
        .where((entry) => entry['selection_allowed'] == true)
        .map((entry) => entry['provider_ref'])
        .toSet();
    expect(selectableHealthRefs,
        {'mattpocock_skills', 'ai_marketing_skills', 'andrej_karpathy_skills'});
    expect(
        healthEntries.every((entry) => entry['secret_masked'] == true), isTrue);
    final templateHealthEntries = healthEntries
        .where((entry) => entry['registry_entry_class'] == 'template_asset')
        .toList(growable: false);
    expect(templateHealthEntries, hasLength(7));
    expect(
        templateHealthEntries.every((entry) =>
            entry['runtime_load_class'] == 'template_manifest_only' &&
            (entry['template_asset_contract']
                    as Map)['runtime_load_required'] ==
                false &&
            (entry['template_asset_contract'] as Map)['validation_required'] ==
                true &&
            entry['requires_external_runtime'] == false),
        isTrue);
    expect(
        healthEntries.map((entry) => entry['health_status']).toSet(),
        containsAll([
          '配置缺失',
          '已配置未测试',
          '已禁用',
          '需启动外部服务',
        ]));
    final blockedRagEvaluationHealth = healthEntries
        .where((entry) =>
            ['ragas', 'deepeval'].contains(entry['provider_ref']) &&
            entry['capability_id'] == 'retrieval_provider')
        .toList(growable: false);
    expect(blockedRagEvaluationHealth, hasLength(2));
    expect(
        blockedRagEvaluationHealth.every((entry) =>
            entry['health_status'] == '已配置未测试' &&
            entry['ready_for_user_selection'] == false &&
            entry['runtime_loaded'] == false),
        isTrue);
    for (final expectation in highRiskProviderExpectations.entries) {
      final highRiskHealth = healthEntries
          .where((entry) => entry['provider_ref'] == expectation.key)
          .toList(growable: false);
      expect(highRiskHealth, isNotEmpty);
      expect(
          highRiskHealth.every((entry) =>
              entry['health_status'] == expectation.value['status'] &&
              entry['selection_allowed'] == false &&
              entry['runtime_loaded'] == false &&
              entry['runtime_load_allowed'] == false &&
              entry['gate_kind'] == expectation.value['gate_kind'] &&
              (entry['gate_audit'] as Map)['fallback_preserves_local_chain'] ==
                  true),
          isTrue);
    }
    expect(
        healthEntries.every((entry) => entry.containsKey('blocked_reason_zh')),
        isTrue);
    final healthLogPath = providerHealth['health_log_path'] as String;
    expect(File(healthLogPath).readAsLinesSync(), hasLength(29));
    final stabilityPath = providerHealth['stability_report_path'] as String;
    final stability = jsonDecode(File(stabilityPath).readAsStringSync()) as Map;
    expect(stability['schema_version'],
        'prd_v3_registered_provider_hot_swap_stability_report.v1');
    expect(stability['provider_entry_count'], 29);
    expect(stability['runtime_loaded_count'], 0);
    expect(stability['external_runtime_load_allowed'], isFalse);
    expect((stability['stage_2_industrial_preflight'] as Map)['status'],
        'blocked');
    expect(stability['failure_isolation_validated'], isTrue);
    expect(stability['local_fallback_available'], isTrue);
    expect(stability['rollback_supported_count'], 29);
    expect(
        stability['unavailable_provider_does_not_block_local_chain'], isTrue);
    expect(stability['registered_project_names_visible_in_normal_ui'], isFalse);
    expect(stability['secret_plaintext_written'], isFalse);
    expect((stability['downstream_binding_checks'] as List), isNotEmpty);
    final runtimeLoadEligibility =
        jsonDecode(File(runtimeLoadEligibilityPath).readAsStringSync()) as Map;
    expect(runtimeLoadEligibility['schema_version'],
        'prd_v3_provider_runtime_load_eligibility_manifest.v1');
    expect(runtimeLoadEligibility['stage_2_runtime_load_allowed'], isFalse);
    expect(runtimeLoadEligibility['provider_entry_count'], 29);
    expect(runtimeLoadEligibility['runtime_loaded_count'], 0);
    expect(runtimeLoadEligibility['external_runtime_load_eligible_count'], 0);
    expect(runtimeLoadEligibility['normal_ui_project_names_visible'], isFalse);
    expect(runtimeLoadEligibility['secret_plaintext_written'], isFalse);
    final eligibilityEntries =
        (runtimeLoadEligibility['entries'] as List).cast<Map>();
    expect(eligibilityEntries, hasLength(29));
    expect(
        eligibilityEntries
            .where((entry) =>
                entry['provider_ref'] == 'n8n' &&
                entry['requires_external_runtime'] == true)
            .length,
        1);
    expect(
        eligibilityEntries.every((entry) =>
            entry['runtime_loaded'] == false &&
            entry['external_runtime_load_eligible'] == false),
        isTrue);
    final templateEligibilityEntries = eligibilityEntries
        .where((entry) => entry['registry_entry_class'] == 'template_asset')
        .toList(growable: false);
    expect(templateEligibilityEntries, hasLength(7));
    expect(
        templateEligibilityEntries.every((entry) =>
            entry['execution_mode'] == 'template_asset_manifest_only' &&
            entry['external_runtime_load_eligible'] == false &&
            (entry['template_asset_contract']
                    as Map)['runtime_load_required'] ==
                false),
        isTrue);
    expect(
        eligibilityEntries
            .where((entry) =>
                entry['registry_entry_class'] == 'architecture_reference')
            .every((entry) =>
                entry['execution_mode'] == 'architecture_reference' &&
                entry['runtime_load_class'] != 'reference_only'),
        isTrue);
    for (final expectation in highRiskProviderExpectations.entries) {
      final rows = eligibilityEntries
          .where((entry) => entry['provider_ref'] == expectation.key)
          .toList(growable: false);
      expect(rows, isNotEmpty);
      expect(
          rows.every((entry) =>
              entry['gate_kind'] == expectation.value['gate_kind'] &&
              (entry['gate_audit'] as Map)['fallback_preserves_local_chain'] ==
                  true &&
              (entry['gate_audit'] as Map)['external_runtime_executed'] ==
                  false),
          isTrue);
    }

    final activated =
        await controller.activateRegisteredProviderCapability('docling');
    expect(activated, isFalse);
    final blockedBindingManifest =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(blockedBindingManifest['action'], 'blocked_activate');
    expect(blockedBindingManifest['selected_provider_runtime_loaded'], isFalse);
    final rolledBack =
        await controller.rollbackRegisteredProviderCapability('docling');
    expect(rolledBack, isTrue);
    final rollbackBindingManifest =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(rollbackBindingManifest['action'], 'rollback');
    expect(
        rollbackBindingManifest['selected_provider_runtime_loaded'], isFalse);
    final highRiskActivated = await controller
        .activateRegisteredProviderCapability('seedance2_skill');
    expect(highRiskActivated, isFalse);
    final highRiskBlockedBindingManifest =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(highRiskBlockedBindingManifest['action'], 'blocked_activate');
    expect(highRiskBlockedBindingManifest['selected_provider_ref'],
        'seedance2_skill');
    expect(highRiskBlockedBindingManifest['selected_provider_runtime_loaded'],
        isFalse);
    final selectionLog = File(
            '$configDir${Platform.pathSeparator}registered_provider_selection_log.jsonl')
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(selectionLog.map((event) => event['action']),
        containsAll(['activate', 'rollback']));
    final doclingSelectionEvent =
        selectionLog.firstWhere((event) => event['provider_ref'] == 'docling');
    expect(doclingSelectionEvent['action'], 'activate');
    expect(doclingSelectionEvent['status'], '已配置未测试');
    expect(
        selectionLog
            .every((event) => event['runtime_loaded_after_event'] == false),
        isTrue);
    final highRiskSelectionEvent = selectionLog
        .lastWhere((event) => event['provider_ref'] == 'seedance2_skill');
    expect(highRiskSelectionEvent['action'], 'activate');
    expect(highRiskSelectionEvent['status'], '已禁用');
    expect(highRiskSelectionEvent['blocked_reason'], contains('网络授权'));
    expect(
        highRiskSelectionEvent['gate_kind'], 'secret_masked_video_skill_gate');
    expect(
        (highRiskSelectionEvent['gate_audit']
            as Map)['secret_plaintext_written'],
        isFalse);
    expect(
        selectionLog.every((event) => event['secret_masked'] == true), isTrue);
    final configTestLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(configTestLog, contains('"config_type":"provider_runtime"'));
    expect(configTestLog, contains('"config_type":"exporter"'));
    expect(configTestLog, isNot(contains('redacted-runtime-input')));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.providerRuntimeSettingsPath,
        endsWith('provider_runtime_settings.json'));
    expect(reloaded.state.providerValidationReportPath,
        endsWith('provider_validation_report.json'));
    expect(reloaded.state.providerLifecycleAuditSummaryPath,
        endsWith('provider_lifecycle_audit_summary.json'));
    expect(reloaded.state.exporterValidationReportPath,
        endsWith('exporter_validation_report.json'));
    expect(reloaded.state.parallelTaskCapacityReportPath,
        endsWith('parallel_task_capacity_report.json'));
    expect(reloaded.state.taskIsolationMatrixPath,
        endsWith('task_isolation_matrix.json'));
    expect(reloaded.state.taskRecoveryReportPath,
        endsWith('task_recovery_report.json'));
  });

  test('stage3 authorized profile proves full provider loading matrix evidence',
      () async {
    final workspace = await createWorkspace();
    writeStage3FullProviderEvidenceFixture(workspace);
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    const secret = 'stage3-full-matrix-secret';
    await controller.saveProviderRuntimeSettings(
      llmProvider: 'official_openai',
      modelId: 'gpt-stage3-full-matrix',
      embeddingProvider: 'local_keyword_embedding',
      searchProvider: 'web_authorized_search',
      parserProvider: 'local_parser',
      ocrProvider: 'optional_ocr',
      apiKey: secret,
    );
    final profile = await controller.createProjectConfigProfile(
      displayName: 'Stage3 授权能力增强配置',
      mode: 'hybrid',
    );
    await controller.activateProjectConfigProfile(profile.profileId);
    final healthPath = await controller.testAllRegisteredProviderCapabilities();

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final preflight =
        runtimeStatus['stage_2_industrial_preflight'] as Map<String, dynamic>;
    expect(preflight['status'], 'passed');
    expect(preflight['runtime_load_allowed'], isTrue);
    expect(preflight['failed_checks'], isEmpty);

    final readiness = jsonDecode(
        File(runtimeStatus['provider_adapter_readiness_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(readiness['contract_count'], 26);
    expect(readiness['readiness_entry_count'], 26);
    expect(readiness['ready_for_user_selection_count'], 25);
    expect(readiness['external_runtime_load_allowed'], isTrue);
    expect(readiness['normal_ui_project_names_visible'], isFalse);
    expect(readiness['secret_plaintext_written'], isFalse);
    expect(File(readiness['readiness_log_path'] as String).readAsStringSync(),
        isNot(contains(secret)));

    final readinessEntries =
        (readiness['readiness_entries'] as List).cast<Map<String, dynamic>>();
    const expectedProviderRefs = {
      'ai_marketing_skills',
      'andrej_karpathy_skills',
      'anysearchskill',
      'deepeval',
      'docling',
      'jellyfish',
      'last30days_skill',
      'llamaindex',
      'llm_wiki_v2',
      'marker',
      'mattpocock_skills',
      'mineru',
      'mmskills',
      'n8n',
      'opendataloader',
      'paddleocr',
      'rag_anything',
      'ragas',
      'rtk',
      'seedance2_skill',
      'sirchmunk',
      'skill_prompt_generator',
      'story_flicks',
      'surya',
      'unstructured',
      'weknora',
    };
    expect(readinessEntries.map((entry) => entry['provider_ref']).toSet(),
        expectedProviderRefs);
    expect(
        readinessEntries
            .where((entry) => entry['provider_ref'] != 'llamaindex')
            .every((entry) =>
                entry['status'] == '连接成功' &&
                entry['ready_for_user_selection'] == true &&
                entry['secret_masked'] == true &&
                (entry['test_artifacts'] as List).isNotEmpty),
        isTrue);
    final llamaindexReadiness = readinessEntries
        .firstWhere((entry) => entry['provider_ref'] == 'llamaindex');
    expect(llamaindexReadiness['status'], '配置缺失');
    expect(llamaindexReadiness['ready_for_user_selection'], isFalse);
    expect(llamaindexReadiness['runtime_loaded'], isFalse);
    for (final providerRef in [
      'anysearchskill',
      'last30days_skill',
      'seedance2_skill',
      'rtk',
    ]) {
      final entry = readinessEntries
          .firstWhere((item) => item['provider_ref'] == providerRef);
      expect(entry['gate_kind'], isNotEmpty);
      final probeRaw =
          File((entry['test_artifacts'] as List).cast<String>().single)
              .readAsStringSync();
      expect(probeRaw, isNot(contains(secret)));
      final probe = jsonDecode(probeRaw) as Map<String, dynamic>;
      expect(probe['passed'], isTrue);
      expect(probe['network_call_attempted'], isFalse);
      expect(probe['external_runtime_executed'], isFalse);
      expect(probe['vendor_runtime_loaded'], isFalse);
      expect(probe['secret_plaintext_written'], isFalse);
    }

    final health =
        jsonDecode(File(healthPath).readAsStringSync()) as Map<String, dynamic>;
    expect(health['unique_provider_ref_count'], 26);
    expect(health['ready_unique_provider_count'], 25);
    expect(health['ready_for_user_selection_count'], 28);
    expect(health['runtime_loaded_count'], 0);
    expect(health['external_runtime_load_allowed'], isTrue);
    expect(health['normal_ui_project_names_visible'], isFalse);
    expect(health['secret_plaintext_written'], isFalse);
    expect(
        health['stage3_final_provider_acceptance_report_path'], isA<String>());

    final registrySummary = jsonDecode(
        File(health['provider_registry_readiness_summary_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(registrySummary['provider_count'], 26);
    expect(registrySummary['provider_mapping_count'], 29);
    expect(registrySummary['ready_provider_count'], 25);
    expect(registrySummary['runtime_loaded_count'], 0);
    expect(registrySummary['external_runtime_load_eligible_count'], 2);
    expect(
        (registrySummary['user_concept_boundary']
            as Map)['external_project_names_visible_in_normal_ui'],
        isFalse);
    expect(
        (registrySummary['failure_isolation']
            as Map)['unavailable_provider_blocks_main_chain'],
        isFalse);

    final fullMatrix = jsonDecode(File(
            runtimeStatus['stage3_full_provider_loading_matrix_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(fullMatrix['schema_version'],
        'prd_v3_stage3_full_provider_loading_matrix.v1');
    expect(fullMatrix['status'], 'matrix_ready');
    expect(fullMatrix['provider_count'], 26);
    expect(fullMatrix['target_counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
    });
    expect(fullMatrix['actual_counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
    });
    expect(fullMatrix['loaded_configured_count'], 26);
    expect(fullMatrix['runtime_ready_count'], 26);
    expect(fullMatrix['downstream_bound_count'], 26);
    expect(fullMatrix['fallback_verified_count'], 26);
    expect(fullMatrix['audit_verified_count'], 26);
    expect(fullMatrix['rollback_verified_count'], 26);
    expect(fullMatrix['exe_verified_count'], 26);
    expect(fullMatrix['normal_ui_project_names_visible'], isFalse);
    expect(fullMatrix['hot_swap_project_concept_visible'], isFalse);
    expect(fullMatrix['secret_plaintext_written'], isFalse);
    final industrialAcceptanceRows =
        (fullMatrix['industrial_acceptance_rows'] as List)
            .cast<Map<String, dynamic>>();
    expect(industrialAcceptanceRows, hasLength(26));
    expect(industrialAcceptanceRows.map((row) => row['provider_ref']).toSet(),
        expectedProviderRefs);
    expect(
        industrialAcceptanceRows.every((row) =>
            row['loaded_configured'] == true &&
            row['runtime_ready'] == true &&
            row['downstream_bound'] == true &&
            row['fallback_verified'] == true &&
            row['audit_verified'] == true &&
            row['rollback_verified'] == true &&
            row['exe_verified'] == true &&
            row['acceptance_state'] == 'passed' &&
            row['normal_ui_project_name_visible'] == false &&
            row['hot_swap_project_concept_visible'] == false &&
            row['external_runtime_executed'] == false &&
            row['workflow_executed'] == false &&
            row['secret_plaintext_written'] == false),
        isTrue);
    final acceptanceReportPath = (fullMatrix['source_artifacts']
        as Map)['stage3_provider_industrial_acceptance_report_path'] as String;
    final acceptanceReport =
        jsonDecode(File(acceptanceReportPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(acceptanceReport['schema_version'],
        'prd_v3_stage3_provider_industrial_acceptance_report.v1');
    expect(acceptanceReport['status'], 'passed');
    expect(acceptanceReport['provider_ref_count'], 26);
    expect(acceptanceReport['actual_counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
    });
    for (final row in industrialAcceptanceRows) {
      final evidence = row['evidence_paths'] as Map<String, dynamic>;
      for (final key in [
        'config_schema_path',
        'profile_binding_path',
        'readiness_report_path',
        'health_report_path',
        'runtime_status_path',
        'downstream_binding_path',
        'fallback_matrix_path',
        'rollback_manifest_path',
        'exe_preflight_path',
        'industrial_entry_manifest_path',
      ]) {
        expect(File(evidence[key] as String).existsSync(), isTrue,
            reason: '${row['provider_ref']} missing $key');
      }
      expect(
          (evidence['provider_probe_paths'] as List)
              .cast<String>()
              .every((path) => File(path).existsSync()),
          isTrue);
    }

    final industrialReport = jsonDecode(File(
            runtimeStatus['stage3_industrial_provider_loading_report_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(industrialReport['schema_version'],
        'prd_v3_stage3_industrial_provider_loading_report.v1');
    expect(industrialReport['status'], 'passed');
    expect(industrialReport['provider_ref_count'], 26);
    expect(industrialReport['provider_mapping_count'], 29);
    expect(industrialReport['registry_class_counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
    });
    final classificationPolicy =
        industrialReport['classification_policy'] as Map<String, dynamic>;
    expect(
        classificationPolicy['reference_only_allowed_as_final_state'], isFalse);
    expect(classificationPolicy['learning_note_only_accepted'], isFalse);
    expect(
        classificationPolicy[
            'absorbed_references_require_parallel_architecture_delivery'],
        isTrue);
    expect(classificationPolicy['rejected_references_require_reason'], isTrue);
    expect(classificationPolicy['deferred_references_require_named_blocker'],
        isTrue);
    expect(
        classificationPolicy['future_references_require_resolution'], isTrue);
    expect(
        classificationPolicy[
            'future_references_must_not_remain_learning_notes'],
        isTrue);
    expect(industrialReport['normal_ui_project_names_visible'], isFalse);
    expect(industrialReport['hot_swap_project_concept_visible'], isFalse);
    expect(industrialReport['secret_plaintext_written'], isFalse);
    expect(industrialReport['failed_decisions'], isEmpty);
    expect(industrialReport['failed_future_reference_decisions'], isEmpty);
    final finalAcceptanceReport = jsonDecode(File(
            runtimeStatus['stage3_final_provider_acceptance_report_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(finalAcceptanceReport['schema_version'],
        'prd_v3_stage3_final_provider_acceptance_report.v1');
    expect(finalAcceptanceReport['status'], 'passed');
    expect(finalAcceptanceReport['failed_requirements'], isEmpty);
    expect(finalAcceptanceReport['counts'], {
      'capability_provider': 19,
      'template_asset': 6,
      'architecture_reference': 1,
      'total': 26,
    });
    expect(finalAcceptanceReport['final_conclusion'],
        contains('19 个 Provider 配件已完成可配置、可测试、可审计、可回滚的工业级接入'));
    expect(finalAcceptanceReport['final_conclusion'],
        contains('6 个模板资产已进入真实资产库并可绑定'));
    expect(finalAcceptanceReport['final_conclusion'],
        contains('1 个架构参考已吸收到产品架构实现'));
    final finalRequirementResults =
        finalAcceptanceReport['requirement_results'] as Map<String, dynamic>;
    expect(
        finalRequirementResults.values.every((value) => value == true), isTrue);
    expect((finalAcceptanceReport['provider_refs'] as List), hasLength(19));
    expect(
        (finalAcceptanceReport['template_asset_refs'] as List), hasLength(6));
    expect(
        finalAcceptanceReport['architecture_reference_refs'], ['llamaindex']);
    expect(
        (finalAcceptanceReport['exe_smoke']
            as Map)['industrial_38_step_status'],
        'passed');
    expect(
        (finalAcceptanceReport['exe_smoke'] as Map)['launch_status'], 'passed');
    expect(finalAcceptanceReport['normal_ui_project_names_visible'], isFalse);
    expect(finalAcceptanceReport['hot_swap_project_concept_visible'], isFalse);
    expect(finalAcceptanceReport['secret_plaintext_written'], isFalse);
    final finalSources =
        finalAcceptanceReport['source_artifacts'] as Map<String, dynamic>;
    for (final key in [
      'health_report_path',
      'full_loading_matrix_path',
      'industrial_provider_loading_report_path',
      'provider_acceptance_report_path',
      'industrial_exe_smoke_report_path',
      'exe_launch_smoke_report_path',
    ]) {
      expect(File(finalSources[key] as String).existsSync(), isTrue,
          reason: 'final acceptance missing $key');
    }
    final futureReferenceIntake =
        industrialReport['future_reference_intake'] as Map<String, dynamic>;
    expect(futureReferenceIntake['schema_version'],
        'prd_v3_stage3_future_reference_intake.v1');
    expect(futureReferenceIntake['status'], 'passed');
    expect(futureReferenceIntake['decision_count'], 7);
    expect(futureReferenceIntake['class_counts'], {
      'capability_provider': 0,
      'template_asset': 1,
      'architecture_reference': 6,
    });
    expect(futureReferenceIntake['status_counts'], {
      'candidate_reference': 0,
      'absorbed_into_architecture': 1,
      'rejected_no_architecture_gain': 4,
      'deferred_with_blocker': 2,
    });
    expect(futureReferenceIntake['reference_only_allowed_as_final_state'],
        isFalse);
    expect(futureReferenceIntake['learning_note_only_accepted'], isFalse);
    expect(futureReferenceIntake['indefinite_reference_allowed'], isFalse);
    final futureReferenceDecisions =
        (industrialReport['future_reference_decisions'] as List)
            .cast<Map<String, dynamic>>();
    expect(futureReferenceDecisions, hasLength(7));
    expect(
        futureReferenceDecisions.every((row) =>
            row['acceptance_state'] == 'accepted' &&
            row['learning_note_only'] == false &&
            row['indefinite_reference_allowed'] == false &&
            row['runtime_dependency_added'] == false &&
            row['normal_ui_project_name_visible'] == false),
        isTrue);
    final absorbedFutureReferences = futureReferenceDecisions
        .where((row) =>
            row['architecture_reference_status'] ==
            'absorbed_into_architecture')
        .toList(growable: false);
    expect(absorbedFutureReferences, hasLength(1));
    expect(absorbedFutureReferences.single['architecture_delivery_required'],
        isTrue);
    expect(absorbedFutureReferences.single['absorbed_targets'] as List,
        isNotEmpty);
    final rejectedFutureReferences = futureReferenceDecisions
        .where((row) =>
            row['architecture_reference_status'] ==
            'rejected_no_architecture_gain')
        .toList(growable: false);
    expect(rejectedFutureReferences, hasLength(4));
    expect(
        rejectedFutureReferences.every((row) =>
            row['worth_absorbing'] == false &&
            row['rejection_reason'] is String &&
            (row['rejection_reason'] as String).isNotEmpty &&
            (row['absorbed_targets'] as List).isEmpty),
        isTrue);
    final deferredFutureReferences = futureReferenceDecisions
        .where((row) =>
            row['architecture_reference_status'] == 'deferred_with_blocker')
        .toList(growable: false);
    expect(deferredFutureReferences, hasLength(2));
    expect(
        deferredFutureReferences.every((row) =>
            row['worth_absorbing'] == true &&
            row['blocker'] is String &&
            (row['blocker'] as String).isNotEmpty &&
            (row['absorbed_targets'] as List).isEmpty),
        isTrue);

    final rows = (fullMatrix['rows'] as List).cast<Map<String, dynamic>>();
    expect(rows, hasLength(26));
    expect(
        rows.map((row) => row['provider_ref']).toSet(), expectedProviderRefs);
    expect(
        rows.every((row) =>
            row['loaded_configured'] == true &&
            row['runtime_ready'] == true &&
            row['downstream_bound'] == true &&
            row['fallback_verified'] == true &&
            row['audit_verified'] == true &&
            row['rollback_verified'] == true &&
            row['exe_verified'] == true &&
            row['external_runtime_executed'] == false &&
            row['workflow_executed'] == false &&
            row['normal_ui_project_name_visible'] == false &&
            row['hot_swap_project_concept_visible'] == false &&
            row['secret_plaintext_written'] == false),
        isTrue);
    expect(
        rows.where(
            (row) => row['registry_entry_class'] == 'capability_provider'),
        hasLength(19));
    final providerRows = rows
        .where((row) => row['registry_entry_class'] == 'capability_provider')
        .toList(growable: false);
    expect(providerRows, hasLength(19));
    for (final row in providerRows) {
      final evidence = row['source_artifacts'] as Map<String, dynamic>;
      for (final key in [
        'provider_config_schema_path',
        'provider_profile_binding_path',
        'provider_runtime_status_path',
        'provider_fallback_degradation_path',
        'provider_audit_log_path',
        'provider_rollback_evidence_path',
        'provider_exe_smoke_evidence_path',
        'provider_industrial_acceptance_path',
      ]) {
        expect(File(evidence[key] as String).existsSync(), isTrue,
            reason: '${row['provider_ref']} missing $key');
      }
      final providerAcceptance = jsonDecode(
          File(evidence['provider_industrial_acceptance_path'] as String)
              .readAsStringSync()) as Map<String, dynamic>;
      expect(providerAcceptance['schema_version'],
          'prd_v3_stage3_provider_industrial_evidence.v1');
      expect(providerAcceptance['provider_ref'], row['provider_ref']);
      expect(providerAcceptance['evidence_complete'], isTrue);
      expect(providerAcceptance['loaded_configured'], isTrue);
      expect(providerAcceptance['runtime_ready'], isTrue);
      expect(providerAcceptance['downstream_bound'], isTrue);
      expect(providerAcceptance['fallback_verified'], isTrue);
      expect(providerAcceptance['audit_verified'], isTrue);
      expect(providerAcceptance['rollback_verified'], isTrue);
      expect(providerAcceptance['exe_verified'], isTrue);
      expect(providerAcceptance['normal_ui_project_name_visible'], isFalse);
      expect(providerAcceptance['hot_swap_project_concept_visible'], isFalse);
      expect(providerAcceptance['secret_plaintext_written'], isFalse);
    }
    expect(rows.where((row) => row['registry_entry_class'] == 'template_asset'),
        hasLength(6));
    expect(
        rows.where(
            (row) => row['registry_entry_class'] == 'architecture_reference'),
        hasLength(1));

    final llamaindex =
        rows.firstWhere((row) => row['provider_ref'] == 'llamaindex');
    expect(llamaindex['registry_entry_class'], 'architecture_reference');
    expect(llamaindex['architecture_reference_status'],
        'absorbed_into_architecture');
    expect(llamaindex['runtime_loaded'], isFalse);
    expect(
        llamaindex['runtime_load_class'], 'architecture_reference_no_runtime');
    expect((llamaindex['acceptance_notes'] as String),
        contains('index/RAG contract'));
    final llamaindexAcceptance = industrialAcceptanceRows
        .firstWhere((row) => row['provider_ref'] == 'llamaindex');
    final llamaindexManifest = jsonDecode(File(
            (llamaindexAcceptance['evidence_paths']
                as Map)['industrial_entry_manifest_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(llamaindexManifest['schema_version'],
        'prd_v3_stage3_architecture_absorption_manifest.v1');
    expect(llamaindexManifest['runtime_load_required'], isFalse);
    expect(llamaindexManifest['index_schema'], isTrue);
    expect(llamaindexManifest['retrieval_pipeline_contract'], isTrue);
    expect(llamaindexManifest['rag_orchestration_boundary'], isTrue);
    expect(llamaindexManifest['chunk_node_metadata_model'], isTrue);
    expect(llamaindexManifest['retrieval_trace'], isTrue);
    expect(llamaindexManifest['fallback_strategy'], isTrue);
    expect(llamaindexManifest['test_gate'], isTrue);
    expect(llamaindexManifest['audit_model'], isTrue);
    expect(llamaindexManifest['architecture_evidence_complete'], isTrue);
    final llamaindexEvidencePaths =
        llamaindexManifest['architecture_evidence_paths']
            as Map<String, dynamic>;
    for (final key in [
      'index_schema_path',
      'retrieval_pipeline_contract_path',
      'rag_orchestration_boundary_path',
      'chunk_node_metadata_model_path',
      'retrieval_trace_schema_path',
      'fallback_strategy_path',
      'test_gate_path',
      'audit_model_path',
      'architecture_audit_log_path',
    ]) {
      expect(File(llamaindexEvidencePaths[key] as String).existsSync(), isTrue,
          reason: 'llamaindex missing $key');
    }
    final retrievalContract = jsonDecode(File(
            llamaindexEvidencePaths['retrieval_pipeline_contract_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(retrievalContract['schema_version'],
        'prd_v3_retrieval_pipeline_contract.v1');
    expect(retrievalContract['runtime_load_required'], isFalse);
    expect(retrievalContract['provider_boundary'],
        contains('no llamaindex runtime load'));
    final ragTestGate = jsonDecode(
        File(llamaindexEvidencePaths['test_gate_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(ragTestGate['schema_version'], 'prd_v3_rag_contract_test_gate.v1');
    expect(ragTestGate['gate_status'], 'passed');
    final industrialDecisions = (industrialReport['provider_decisions'] as List)
        .cast<Map<String, dynamic>>();
    expect(industrialDecisions, hasLength(26));
    expect(industrialDecisions.map((row) => row['provider_ref']).toSet(),
        expectedProviderRefs);
    expect(
        industrialDecisions.every((row) =>
            row['learning_note_only'] == false &&
            row['reference_only_allowed'] == false &&
            row['indefinite_reference_allowed'] == false &&
            row['normal_ui_project_name_visible'] == false &&
            row['hot_swap_project_concept_visible'] == false &&
            row['external_runtime_executed'] == false &&
            row['workflow_executed'] == false &&
            row['secret_plaintext_written'] == false &&
            row['acceptance_state'] == 'accepted'),
        isTrue);
    final architectureDecisions =
        (industrialReport['architecture_reference_decisions'] as List)
            .cast<Map<String, dynamic>>();
    expect(architectureDecisions, hasLength(1));
    final llamaindexDecision = architectureDecisions.single;
    expect(llamaindexDecision['provider_ref'], 'llamaindex');
    expect(llamaindexDecision['stage3_decision'], 'absorbed_into_architecture');
    expect(llamaindexDecision['must_absorb_now'], isTrue);
    expect(llamaindexDecision['must_reject_when_no_gain'], isFalse);
    expect(llamaindexDecision['deferred_requires_blocker'], isFalse);
    expect(llamaindexDecision['blocker'], '');
    expect(llamaindexDecision['rejection_reason'], '');
    expect(llamaindexDecision['worthiness_criteria'],
        contains('improves_provider_rag_agent_or_a2a_abstraction'));
    final llamaindexDelivery =
        llamaindexDecision['parallel_delivery'] as Map<String, dynamic>;
    expect(llamaindexDelivery['contract'], isTrue);
    expect(llamaindexDelivery['schema'], isTrue);
    expect(llamaindexDelivery['runtime_boundary'], isTrue);
    expect(llamaindexDelivery['ui_information_architecture'], isTrue);
    expect(llamaindexDelivery['test_gate'], isTrue);
    expect(llamaindexDelivery['audit_model'], isTrue);
    expect(llamaindexDelivery['fallback_or_degradation'], isTrue);

    final templateRows = rows
        .where((row) => row['registry_entry_class'] == 'template_asset')
        .toList(growable: false);
    expect(
        templateRows.every((row) =>
            row['runtime_loaded'] == false &&
            row['runtime_load_class'] == 'template_manifest_only'),
        isTrue);
    final templateAcceptanceRows = industrialAcceptanceRows
        .where((row) => row['registry_entry_class'] == 'template_asset')
        .toList(growable: false);
    expect(templateAcceptanceRows, hasLength(6));
    for (final row in templateAcceptanceRows) {
      final manifest = jsonDecode(File((row['evidence_paths']
              as Map)['industrial_entry_manifest_path'] as String)
          .readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['schema_version'],
          'prd_v3_skill_template_asset_manifest.v1');
      expect(manifest['runtime_load_required'], isFalse);
      expect(manifest['skill_factory_binding'], isTrue);
      expect(manifest['agent_binding_boundary'], isTrue);
      expect(manifest['source_version'], isNotEmpty);
      expect(manifest['license_boundary'], isNotEmpty);
      expect(manifest['validation_result'], '连接成功');
      expect(manifest['rollback_disable_supported'], isTrue);
      expect(manifest['asset_library_ready'], isTrue);
      expect(manifest['selectable_in_skill_factory'], isTrue);
      expect(manifest['selectable_in_agent_workbench'], isTrue);
      expect(manifest['not_external_service'], isTrue);
      expect(manifest['external_runtime_executed'], isFalse);
      final evidencePaths = manifest['evidence_paths'] as Map<String, dynamic>;
      for (final key in [
        'skill_factory_entry_path',
        'agent_binding_boundary_path',
        'document_template_entry_path',
        'version_snapshot_path',
        'rollback_disable_path',
        'template_asset_audit_log_path',
      ]) {
        expect(File(evidencePaths[key] as String).existsSync(), isTrue,
            reason: '${row['provider_ref']} missing $key');
      }
      final skillFactoryEntry = jsonDecode(
          File(evidencePaths['skill_factory_entry_path'] as String)
              .readAsStringSync()) as Map<String, dynamic>;
      expect(skillFactoryEntry['schema_version'],
          'prd_v3_skill_factory_template_entry.v1');
      expect(skillFactoryEntry['selectable'], isTrue);
      expect(skillFactoryEntry['requires_external_service'], isFalse);
      final agentBinding = jsonDecode(
          File(evidencePaths['agent_binding_boundary_path'] as String)
              .readAsStringSync()) as Map<String, dynamic>;
      expect(agentBinding['schema_version'],
          'prd_v3_agent_template_binding_boundary.v1');
      expect(agentBinding['selectable'], isTrue);
      expect(agentBinding['external_tool_execution_allowed'], isFalse);
      final documentTemplateEntry = jsonDecode(
          File(evidencePaths['document_template_entry_path'] as String)
              .readAsStringSync()) as Map<String, dynamic>;
      expect(documentTemplateEntry['schema_version'],
          'prd_v3_document_template_entry.v1');
      if (row['provider_ref'] == 'ai_marketing_skills' ||
          row['provider_ref'] == 'skill_prompt_generator') {
        expect(documentTemplateEntry['selectable'], isTrue);
      } else {
        expect(documentTemplateEntry['selectable'], isFalse);
      }
    }
    final n8n = rows.firstWhere((row) => row['provider_ref'] == 'n8n');
    final rtk = rows.firstWhere((row) => row['provider_ref'] == 'rtk');
    expect(n8n['requires_external_runtime'], isTrue);
    expect(rtk['requires_external_runtime'], isTrue);
    expect(n8n['runtime_loaded'], isFalse);
    expect(rtk['runtime_loaded'], isFalse);
    expect(n8n['runtime_ready'], isTrue);
    expect(rtk['runtime_ready'], isTrue);
  });

  test('sirchmunk local retrieval adapter becomes selectable after real chunks',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {
        'chunk_id': 'c_sirchmunk_1',
        'source_path': 'input/local_search.md',
        'text': 'sirchmunk local direct file search needle',
      },
    ]));
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync(jsonEncode({
      'status': 'searchable',
      'source_count': 1,
      'chunk_count': 1,
    }));
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['adapter_ready_for_user_selection_count'],
        greaterThanOrEqualTo(3));
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['adapter_runtime_loaded_count'],
        0);

    final readinessPath =
        runtimeStatus['provider_adapter_readiness_report_path'] as String;
    final readiness = jsonDecode(File(readinessPath).readAsStringSync()) as Map;
    final sirchmunkReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'sirchmunk');
    expect(sirchmunkReadiness['status'], '连接成功');
    expect(sirchmunkReadiness['ready_for_user_selection'], isTrue);
    expect(sirchmunkReadiness['runtime_loaded'], isFalse);
    expect(sirchmunkReadiness['test_artifacts'], isNotEmpty);
    final probePath =
        (sirchmunkReadiness['test_artifacts'] as List).first as String;
    final probe = jsonDecode(File(probePath).readAsStringSync()) as Map;
    expect(
        probe['schema_version'], 'prd_v3_provider_adapter_probe_sirchmunk.v1');
    expect(probe['passed'], isTrue);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);

    final bindingPath =
        runtimeStatus['provider_capability_binding_manifest_path'] as String;
    final binding = jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    final retrievalBinding = (binding['bindings'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(retrievalBinding['active_provider_ref'], 'sirchmunk');
    expect(retrievalBinding['active_provider_kind'], 'registered_provider');
    expect(retrievalBinding['selection_allowed'], isTrue);
    expect(retrievalBinding['runtime_loaded'], isFalse);

    final activated =
        await controller.activateRegisteredProviderCapability('sirchmunk');
    expect(activated, isTrue);
    final activatedBinding =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(activatedBinding['action'], 'activate');
    expect(activatedBinding['selected_provider_ref'], 'sirchmunk');
    expect(activatedBinding['selected_provider_runtime_loaded'], isFalse);
    final selectionLog = File(
            '$configDir${Platform.pathSeparator}registered_provider_selection_log.jsonl')
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(selectionLog.last['status'], '连接成功');
    expect(selectionLog.last['runtime_loaded_after_event'], isFalse);
    expect(selectionLog.last['secret_masked'], isTrue);
    final activatedRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List).cast<Map>();
    final retrievalAudit = downstreamBindingAudit
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(retrievalAudit['active_provider_ref'], 'sirchmunk');
    expect(retrievalAudit['active_provider_kind'], 'registered_provider');
    expect((retrievalAudit['affected_modules'] as List),
        contains('retrieval_verification'));
    expect(retrievalAudit['runtime_loaded'], isFalse);
    expect(retrievalAudit['unauthorized_resources_selectable'], isFalse);
    expect(retrievalAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(4));
  });

  test('anysearchskill requires explicit network profile and query evidence',
      () async {
    final workspace = await createWorkspace();
    final kbRoot =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    for (final id in ['K1']) {
      final dir = Directory('${kbRoot.path}${Platform.pathSeparator}$id')
        ..createSync(recursive: true);
      File('${dir.path}${Platform.pathSeparator}manifest.json')
          .writeAsStringSync('{"status":"searchable"}');
      File('${dir.path}${Platform.pathSeparator}chunks.jsonl')
          .writeAsStringSync('{"chunk_id":"$id-c1"}\n');
    }
    File('${kbRoot.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': 'Network Authorized KB',
          'kb_type': '基础知识库',
          'status': 'searchable',
          'operation': 'build',
          'source_documents': [
            {'source_name': 'network.md'}
          ],
          'chunk_count': 1,
        }
      ],
    }));
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}kb_query_result.json')
              .writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert({
              'selected_count': 1,
              'selected': [
                {
                  'chunk_id': 'K1-network-c1',
                  'source_path': 'network-authorized.md',
                  'text': 'anysearchskill authorized query evidence',
                  'score': 0.9,
                }
              ],
            }),
          );
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.searchKnowledgeBases('anysearchskill authorized', ['K1']);
    final cloud = await controller.createProjectConfigProfile(
      displayName: '网络授权检索配置',
      mode: 'hybrid',
    );
    await controller.activateProjectConfigProfile(cloud.profileId);
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final readiness = jsonDecode(
        File(runtimeStatus['provider_adapter_readiness_report_path'] as String)
            .readAsStringSync()) as Map;
    final anySearchReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'anysearchskill');
    expect(anySearchReadiness['status'], '连接成功');
    expect(anySearchReadiness['ready_for_user_selection'], isTrue);
    expect(anySearchReadiness['runtime_loaded'], isFalse);
    expect(anySearchReadiness['runtime_load_allowed'], isFalse);
    expect(anySearchReadiness['gate_kind'], 'network_search_provider_gate');
    final probe = jsonDecode(File((anySearchReadiness['test_artifacts'] as List)
            .cast<String>()
            .single)
        .readAsStringSync()) as Map;
    expect(probe['passed'], isTrue);
    expect(probe['network_authorization'], '连接成功');
    expect(probe['network_call_attempted'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect((probe['gate_audit'] as Map)['provider_domain_allowlist_count'],
        greaterThan(0));
    expect((probe['gate_audit'] as Map)['query_probe_result_count'], 1);

    final activated =
        await controller.activateRegisteredProviderCapability('anysearchskill');
    expect(activated, isTrue);
    final binding = jsonDecode(File(
            runtimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map;
    final retrievalBinding = (binding['bindings'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(retrievalBinding['active_provider_ref'], 'anysearchskill');
    expect(retrievalBinding['runtime_loaded'], isFalse);
    expect(retrievalBinding['selection_allowed'], isTrue);

    final rolledBack =
        await controller.rollbackRegisteredProviderCapability('anysearchskill');
    expect(rolledBack, isTrue);
    final rollbackRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final rollbackBinding = jsonDecode(File(
            rollbackRuntimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map;
    final rollbackRetrievalBinding = (rollbackBinding['bindings'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(rollbackRetrievalBinding['active_provider_kind'], 'local_fallback');
    expect(rollbackRetrievalBinding['active_provider_ref'],
        rollbackRetrievalBinding['fallback_provider']);
    expect(rollbackRetrievalBinding['rollback_suppressed'], isTrue);
    expect(rollbackRetrievalBinding['runtime_loaded'], isFalse);
    expect(rollbackRetrievalBinding['external_runtime_executed'], isFalse);
    final rollbackSelectionState = jsonDecode(File(
            '$configDir${Platform.pathSeparator}provider_capability_selection_state.json')
        .readAsStringSync()) as Map;
    expect(rollbackSelectionState['rollback_suppressed_capability_ids'],
        contains('retrieval_provider'));
    expect(
        (rollbackSelectionState['selected_providers_by_capability'] as Map)
            .containsKey('retrieval_provider'),
        isFalse);
  });

  test('last30days skill requires authorized time window retrieval evidence',
      () async {
    final workspace = await createWorkspace();
    final kbRoot =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    final dir = Directory('${kbRoot.path}${Platform.pathSeparator}K1')
      ..createSync(recursive: true);
    File('${dir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"status":"searchable"}');
    File('${dir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync('{"chunk_id":"K1-c1"}\n');
    File('${kbRoot.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': 'Recent KB',
          'kb_type': '基础知识库',
          'status': 'searchable',
          'operation': 'build',
          'source_documents': [
            {'source_name': 'recent.md'}
          ],
          'chunk_count': 1,
        }
      ],
    }));
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}kb_query_result.json')
              .writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert({
              'selected_count': 1,
              'selected': [
                {
                  'chunk_id': 'K1-recent-c1',
                  'source_path': 'recent.md',
                  'text': 'last30days authorized time window evidence',
                  'score': 0.91,
                  'published_at': '2026-06-10',
                  'time_window': 'last_30_days',
                }
              ],
            }),
          );
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.searchKnowledgeBases('last30days authorized', ['K1']);
    final cloud = await controller.createProjectConfigProfile(
      displayName: '时间窗口检索授权配置',
      mode: 'hybrid',
    );
    await controller.activateProjectConfigProfile(cloud.profileId);
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final readiness = jsonDecode(
        File(runtimeStatus['provider_adapter_readiness_report_path'] as String)
            .readAsStringSync()) as Map;
    final last30daysReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'last30days_skill');
    expect(last30daysReadiness['status'], '连接成功');
    expect(last30daysReadiness['ready_for_user_selection'], isTrue);
    expect(last30daysReadiness['runtime_loaded'], isFalse);
    expect(last30daysReadiness['runtime_load_allowed'], isFalse);
    expect(
        last30daysReadiness['gate_kind'], 'network_time_window_adapter_gate');
    final probe = jsonDecode(File(
            (last30daysReadiness['test_artifacts'] as List)
                .cast<String>()
                .single)
        .readAsStringSync()) as Map;
    expect(probe['passed'], isTrue);
    expect(probe['network_authorization'], '连接成功');
    expect(probe['time_window_evidence_count'], 1);
    expect(probe['network_call_attempted'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);

    final activated = await controller
        .activateRegisteredProviderCapability('last30days_skill');
    expect(activated, isTrue);
    final binding = jsonDecode(File(
            runtimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map;
    final retrievalBinding = (binding['bindings'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(retrievalBinding['active_provider_ref'], 'last30days_skill');
    expect(retrievalBinding['runtime_loaded'], isFalse);
    expect(retrievalBinding['selection_allowed'], isTrue);

    final rolledBack = await controller
        .rollbackRegisteredProviderCapability('last30days_skill');
    expect(rolledBack, isTrue);
    final rollbackRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final rollbackBinding = jsonDecode(File(
            rollbackRuntimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map;
    final rollbackRetrievalBinding = (rollbackBinding['bindings'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(rollbackRetrievalBinding['active_provider_kind'], 'local_fallback');
    expect(rollbackRetrievalBinding['active_provider_ref'],
        rollbackRetrievalBinding['fallback_provider']);
    expect(rollbackRetrievalBinding['rollback_suppressed'], isTrue);
    expect(rollbackRetrievalBinding['runtime_loaded'], isFalse);
    expect(rollbackRetrievalBinding['external_runtime_executed'], isFalse);
    final rollbackSelectionState = jsonDecode(File(
            '$configDir${Platform.pathSeparator}provider_capability_selection_state.json')
        .readAsStringSync()) as Map;
    expect(rollbackSelectionState['rollback_suppressed_capability_ids'],
        contains('retrieval_provider'));
    expect(
        (rollbackSelectionState['selected_providers_by_capability'] as Map)
            .containsKey('retrieval_provider'),
        isFalse);
  });

  test('seedance2 skill remains template asset with masked authorized config',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    const seedanceCredential = 'seedance-runtime-input-secret';
    await controller.saveProviderRuntimeSettings(
      llmProvider: 'official_openai',
      modelId: 'gpt-seedance-template',
      embeddingProvider: 'local_keyword_embedding',
      searchProvider: 'local_index',
      parserProvider: 'local_parser',
      ocrProvider: 'optional_ocr',
      apiKey: seedanceCredential,
    );
    final cloud = await controller.createProjectConfigProfile(
      displayName: '视频模板授权配置',
      mode: 'hybrid',
    );
    await controller.activateProjectConfigProfile(cloud.profileId);
    await controller.testAllRegisteredProviderCapabilities();

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final readiness = jsonDecode(
        File(runtimeStatus['provider_adapter_readiness_report_path'] as String)
            .readAsStringSync()) as Map;
    final seedanceReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'seedance2_skill');
    expect(seedanceReadiness['status'], '连接成功');
    expect(seedanceReadiness['ready_for_user_selection'], isTrue);
    expect(seedanceReadiness['runtime_loaded'], isFalse);
    expect(seedanceReadiness['runtime_load_allowed'], isFalse);
    expect(seedanceReadiness['gate_kind'], 'secret_masked_video_skill_gate');
    expect(
        (seedanceReadiness['gate_audit'] as Map)['secret_ref_status'], '已配置');
    expect((seedanceReadiness['gate_audit'] as Map)['network_call_attempted'],
        isFalse);
    final probePath =
        (seedanceReadiness['test_artifacts'] as List).cast<String>().single;
    final probeRaw = File(probePath).readAsStringSync();
    expect(probeRaw, isNot(contains(seedanceCredential)));
    final probe = jsonDecode(probeRaw) as Map;
    expect(probe['passed'], isTrue);
    expect(probe['runtime_execution_mode'], 'template_asset_manifest_only');
    expect(probe['network_authorization'], '连接成功');
    expect(probe['secret_ref_status'], '已配置');
    expect(probe['network_call_attempted'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    final templateManifestPath =
        probe['template_asset_manifest_path'] as String;
    final templateManifestRaw = File(templateManifestPath).readAsStringSync();
    expect(templateManifestRaw, isNot(contains(seedanceCredential)));
    final templateManifest =
        jsonDecode(templateManifestRaw) as Map<String, dynamic>;
    expect(templateManifest['schema_version'],
        'prd_v3_skill_template_asset_manifest.v1');
    expect(templateManifest['provider_ref'], 'seedance2_skill');
    expect(templateManifest['runtime_load_required'], isFalse);
    expect(templateManifest['external_runtime_executed'], isFalse);
    expect(templateManifest['secret_plaintext_written'], isFalse);

    final activated = await controller
        .activateRegisteredProviderCapability('seedance2_skill');
    expect(activated, isTrue);
    final binding = jsonDecode(File(
            runtimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map;
    final skillBinding = (binding['bindings'] as List).cast<Map>().firstWhere(
        (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(skillBinding['active_provider_ref'], 'seedance2_skill');
    expect(skillBinding['runtime_loaded'], isFalse);
    expect(skillBinding['selection_allowed'], isTrue);

    final rolledBack = await controller
        .rollbackRegisteredProviderCapability('seedance2_skill');
    expect(rolledBack, isTrue);
    final rollbackRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final rollbackBinding = jsonDecode(File(
            rollbackRuntimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map;
    final rollbackSkillBinding = (rollbackBinding['bindings'] as List)
        .cast<Map>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(rollbackSkillBinding['active_provider_kind'], 'local_fallback');
    expect(rollbackSkillBinding['active_provider_ref'],
        rollbackSkillBinding['fallback_provider']);
    expect(rollbackSkillBinding['rollback_suppressed'], isTrue);
    expect(rollbackSkillBinding['runtime_loaded'], isFalse);
    expect(rollbackSkillBinding['external_runtime_executed'], isFalse);
    final rollbackSelectionState = jsonDecode(File(
            '$configDir${Platform.pathSeparator}provider_capability_selection_state.json')
        .readAsStringSync()) as Map;
    expect(rollbackSelectionState['rollback_suppressed_capability_ids'],
        contains('skill_template_provider'));
    expect(
        (rollbackSelectionState['selected_providers_by_capability'] as Map)
            .containsKey('skill_template_provider'),
        isFalse);
    expect(File(templateManifestPath).readAsStringSync(),
        isNot(contains(seedanceCredential)));
  });

  test('rag evaluation adapters become selectable from retrieval validation',
      () async {
    final workspace = await createWorkspace();
    final kbRoot =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    for (final id in ['K1', 'K2']) {
      final dir = Directory('${kbRoot.path}${Platform.pathSeparator}$id')
        ..createSync(recursive: true);
      File('${dir.path}${Platform.pathSeparator}manifest.json')
          .writeAsStringSync('{"status":"searchable"}');
      File('${dir.path}${Platform.pathSeparator}chunks.jsonl')
          .writeAsStringSync('{"chunk_id":"$id-c1"}\n');
    }
    File('${kbRoot.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': 'Alpha KB',
          'kb_type': '基础知识库',
          'status': 'searchable',
          'operation': 'build',
          'source_documents': [
            {'source_name': 'alpha.md'}
          ],
          'chunk_count': 1,
        },
        {
          'kb_id': 'K2',
          'kb_name': 'Beta KB',
          'kb_type': '基础知识库',
          'status': 'searchable',
          'operation': 'build',
          'source_documents': [
            {'source_name': 'beta.md'}
          ],
          'chunk_count': 1,
        },
      ],
    }));

    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          final kbId = request.outputPath!.split(Platform.pathSeparator).last;
          final score = kbId == 'K2' ? 0.91 : 0.62;
          File('${output.path}${Platform.pathSeparator}kb_query_result.json')
              .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
            'selected_count': 1,
            'selected': [
              {
                'chunk_id': '$kbId-c1',
                'source_path': '$kbId-source.md',
                'text': '$kbId contains rag evaluation needle',
                'score': score,
              }
            ],
          }));
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(readinessEntry(readiness, 'ragas')['ready_for_user_selection'],
        isFalse);
    expect(readinessEntry(readiness, 'deepeval')['ready_for_user_selection'],
        isFalse);

    await controller.searchKnowledgeBases('rag evaluation needle', [
      'K1',
      'K2',
    ]);
    final validationPath =
        await controller.saveRetrievalValidationReport(const {});
    final validation =
        jsonDecode(File(validationPath).readAsStringSync()) as Map;
    expect(validation['correction_status'], 'reviewed');
    expect(validation['review_mode'], 'local_evaluation_gate');
    expect(
        (validation['review_evidence'] as Map)['auto_review_passed'], isTrue);
    expect(
        (validation['review_evidence'] as Map)['external_calls_made'], isFalse);
    expect((validation['review_evidence'] as Map)['secret_plaintext_written'],
        isFalse);
    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    readiness = readinessReport(runtimeStatus());

    for (final providerRef in ['ragas', 'deepeval']) {
      final entry = readinessEntry(readiness, providerRef);
      expect(entry['status'], '连接成功');
      expect(entry['ready_for_user_selection'], isTrue);
      expect(entry['runtime_loaded'], isFalse);
      expect(entry['capability_ids'],
          containsAll(['governance_audit_provider', 'retrieval_provider']));
      final probe = jsonDecode(
          File((entry['test_artifacts'] as List).cast<String>().single)
              .readAsStringSync()) as Map<String, dynamic>;
      expect(probe['schema_version'],
          'prd_v3_provider_adapter_probe_rag_evaluation.v1');
      expect(probe['provider_ref'], providerRef);
      expect(probe['passed'], isTrue);
      expect(probe['result_count'], 2);
      expect(probe['conflict_count'], 0);
      expect(probe['network_used'], isFalse);
      expect(probe['secret_plaintext_written'], isFalse);
      expect(probe['external_runtime_executed'], isFalse);
      expect(probe['vendor_runtime_loaded'], isFalse);
    }

    final activated =
        await controller.activateRegisteredProviderCapability('ragas');
    expect(activated, isTrue);
    final binding = jsonDecode(File(
            runtimeStatus()['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final retrievalBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(retrievalBinding['active_provider_ref'], 'ragas');
    expect(retrievalBinding['active_provider_kind'], 'registered_provider');
    expect(retrievalBinding['explicit_selection_applied'], isTrue);
    expect(retrievalBinding['runtime_loaded'], isFalse);
    final governanceBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'governance_audit_provider');
    expect(governanceBinding['active_provider_ref'], 'ragas');
    expect(governanceBinding['active_provider_kind'], 'registered_provider');
    expect(governanceBinding['explicit_selection_applied'], isTrue);
    expect(governanceBinding['runtime_loaded'], isFalse);
    expect(governanceBinding['external_runtime_executed'], isFalse);
    final selectionState = jsonDecode(File(
            '$configDir${Platform.pathSeparator}provider_capability_selection_state.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(selectionState['selected_capability_ids'],
        containsAll(['retrieval_provider', 'governance_audit_provider']));
    expect(
        (selectionState['selected_providers_by_capability']
            as Map)['retrieval_provider'],
        'ragas');
    expect(
        (selectionState['selected_providers_by_capability']
            as Map)['governance_audit_provider'],
        'ragas');
    final rolledBack =
        await controller.rollbackRegisteredProviderCapability('ragas');
    expect(rolledBack, isTrue);
    final rollbackStatus = runtimeStatus();
    final rollbackBinding = jsonDecode(File(
            rollbackStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final rollbackRetrievalBinding = (rollbackBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['capability_id'] == 'retrieval_provider');
    expect(rollbackRetrievalBinding['active_provider_kind'], 'local_fallback');
    expect(rollbackRetrievalBinding['active_provider_ref'],
        rollbackRetrievalBinding['fallback_provider']);
    expect(rollbackRetrievalBinding['rollback_suppressed'], isTrue);
    final rollbackGovernanceBinding = (rollbackBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'governance_audit_provider');
    expect(rollbackGovernanceBinding['active_provider_kind'], 'local_fallback');
    expect(rollbackGovernanceBinding['active_provider_ref'],
        rollbackGovernanceBinding['fallback_provider']);
    expect(rollbackGovernanceBinding['rollback_suppressed'], isTrue);
    expect(rollbackGovernanceBinding['runtime_loaded'], isFalse);
    final rollbackSelectionState = jsonDecode(File(
            '$configDir${Platform.pathSeparator}provider_capability_selection_state.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackSelectionState['rollback_suppressed_capability_ids'],
        containsAll(['retrieval_provider', 'governance_audit_provider']));
    expect(
        (rollbackSelectionState['selected_providers_by_capability'] as Map)
            .containsKey('retrieval_provider'),
        isFalse);
    expect(
        (rollbackSelectionState['selected_providers_by_capability'] as Map)
            .containsKey('governance_audit_provider'),
        isFalse);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    final ragasHealth = (health['health_entries'] as List)
        .cast<Map<String, dynamic>>()
        .where((entry) => entry['provider_ref'] == 'ragas')
        .toList(growable: false);
    expect(ragasHealth, hasLength(2));
    expect(
        ragasHealth.every((entry) =>
            entry['health_status'] == '连接成功' &&
            entry['ready_for_user_selection'] == true &&
            entry['runtime_loaded'] == false),
        isTrue);
  });

  test(
      'mattpocock governance adapter becomes selectable from local rule assets',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['adapter_ready_for_user_selection_count'],
        greaterThanOrEqualTo(2));
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['adapter_runtime_loaded_count'],
        0);

    final readinessPath =
        runtimeStatus['provider_adapter_readiness_report_path'] as String;
    final readiness = jsonDecode(File(readinessPath).readAsStringSync()) as Map;
    final governanceReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'mattpocock_skills');
    expect(governanceReadiness['status'], '连接成功');
    expect(governanceReadiness['ready_for_user_selection'], isTrue);
    expect(governanceReadiness['runtime_loaded'], isFalse);
    final probePath =
        (governanceReadiness['test_artifacts'] as List).first as String;
    final probe = jsonDecode(File(probePath).readAsStringSync()) as Map;
    expect(probe['schema_version'],
        'prd_v3_provider_adapter_probe_mattpocock_skills.v1');
    expect(probe['passed'], isTrue);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect((probe['checked_assets'] as List), hasLength(4));

    final bindingPath =
        runtimeStatus['provider_capability_binding_manifest_path'] as String;
    final binding = jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    final governanceBinding = (binding['bindings'] as List)
        .cast<Map>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'governance_audit_provider');
    expect(governanceBinding['active_provider_ref'], 'mattpocock_skills');
    expect(governanceBinding['active_provider_kind'], 'registered_provider');
    expect(governanceBinding['selection_allowed'], isTrue);
    expect(governanceBinding['runtime_loaded'], isFalse);

    final activated = await controller
        .activateRegisteredProviderCapability('mattpocock_skills');
    expect(activated, isTrue);
    final activatedBinding =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(activatedBinding['action'], 'activate');
    expect(activatedBinding['selected_provider_ref'], 'mattpocock_skills');
    expect(activatedBinding['selected_provider_runtime_loaded'], isFalse);
    final selectionLog = File(
            '$configDir${Platform.pathSeparator}registered_provider_selection_log.jsonl')
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(selectionLog.last['status'], '连接成功');
    expect(selectionLog.last['runtime_loaded_after_event'], isFalse);
    expect(selectionLog.last['secret_masked'], isTrue);
    final activatedRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List).cast<Map>();
    final governanceAudit = downstreamBindingAudit.firstWhere(
        (entry) => entry['capability_id'] == 'governance_audit_provider');
    expect(governanceAudit['active_provider_ref'], 'mattpocock_skills');
    expect(governanceAudit['active_provider_kind'], 'registered_provider');
    expect((governanceAudit['affected_modules'] as List),
        contains('audit_center'));
    expect(governanceAudit['runtime_loaded'], isFalse);
    expect(governanceAudit['unauthorized_resources_selectable'], isFalse);
    expect(governanceAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(3));
  });

  test('llm wiki agent memory adapter requires local agent lifecycle evidence',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final readinessPath =
        runtimeStatus['provider_adapter_readiness_report_path'] as String;
    var readiness = jsonDecode(File(readinessPath).readAsStringSync()) as Map;
    var llmWikiReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'llm_wiki_v2');
    expect(llmWikiReadiness['status'], '已配置未测试');
    expect(llmWikiReadiness['ready_for_user_selection'], isFalse);
    var probePath =
        (llmWikiReadiness['test_artifacts'] as List).first as String;
    var probe = jsonDecode(File(probePath).readAsStringSync()) as Map;
    expect(probe['schema_version'],
        'prd_v3_provider_adapter_probe_llm_wiki_v2.v1');
    expect(probe['passed'], isFalse);
    expect((probe['missing_assets'] as List), isNotEmpty);

    final agentRoot =
        Directory('${workspace.path}${Platform.pathSeparator}agent')
          ..createSync(recursive: true);
    final auditRoot =
        Directory('${agentRoot.path}${Platform.pathSeparator}audit')
          ..createSync(recursive: true);
    final kbRoot = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${agentRoot.path}${Platform.pathSeparator}agent_generation_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_agent_generation_manifest.v1',
      'agent_id': 'agent_memory_probe',
      'memory': {
        'short_term': 'local_session',
        'long_term': 'memory_index_reference',
      },
    }));
    File('${auditRoot.path}${Platform.pathSeparator}permission_audit.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_agent_permission_audit.v1',
      'agent_id': 'agent_memory_probe',
      'permission_checks': [
        'knowledge_base_and_memory_vector_store_separated',
      ],
    }));
    File('${auditRoot.path}${Platform.pathSeparator}agent_validation_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_agent_validation_report.v1',
      'agent_id': 'agent_memory_probe',
      'checks': [
        {
          'check_id': 'memory_separated_from_kb_index',
          'status': 'pass',
        },
      ],
    }));
    File('${kbRoot.path}${Platform.pathSeparator}memory_index_reference.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_memory_index_reference.v1',
      'memory_scope': 'agent_long_term_memory',
      'memory_store': 'separate_from_kb_index',
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final refreshedStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    expect(
        (refreshedStatus['registered_provider_summary']
            as Map)['adapter_ready_for_user_selection_count'],
        greaterThanOrEqualTo(3));
    expect(
        (refreshedStatus['registered_provider_summary']
            as Map)['adapter_runtime_loaded_count'],
        0);
    readiness = jsonDecode(File(
            refreshedStatus['provider_adapter_readiness_report_path'] as String)
        .readAsStringSync()) as Map;
    llmWikiReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'llm_wiki_v2');
    expect(llmWikiReadiness['status'], '连接成功');
    expect(llmWikiReadiness['ready_for_user_selection'], isTrue);
    expect(llmWikiReadiness['runtime_loaded'], isFalse);
    probePath = (llmWikiReadiness['test_artifacts'] as List).first as String;
    probe = jsonDecode(File(probePath).readAsStringSync()) as Map;
    expect(probe['passed'], isTrue);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);
    expect((probe['checked_assets'] as List), hasLength(4));

    final bindingPath =
        refreshedStatus['provider_capability_binding_manifest_path'] as String;
    final binding = jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    final agentBinding = (binding['bindings'] as List).cast<Map>().firstWhere(
        (entry) => entry['capability_id'] == 'agent_model_tools_memory');
    expect(agentBinding['active_provider_ref'], 'llm_wiki_v2');
    expect(agentBinding['active_provider_kind'], 'registered_provider');
    expect(agentBinding['selection_allowed'], isTrue);
    expect(agentBinding['runtime_loaded'], isFalse);

    final activated =
        await controller.activateRegisteredProviderCapability('llm_wiki_v2');
    expect(activated, isTrue);
    final activatedBinding =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(activatedBinding['action'], 'activate');
    expect(activatedBinding['selected_provider_ref'], 'llm_wiki_v2');
    expect(activatedBinding['selected_provider_runtime_loaded'], isFalse);
    final selectionLog = File(
            '$configDir${Platform.pathSeparator}registered_provider_selection_log.jsonl')
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(selectionLog.last['status'], '连接成功');
    expect(selectionLog.last['runtime_loaded_after_event'], isFalse);
    expect(selectionLog.last['secret_masked'], isTrue);
    final activatedRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List).cast<Map>();
    final agentAudit = downstreamBindingAudit.firstWhere(
        (entry) => entry['capability_id'] == 'agent_model_tools_memory');
    expect(agentAudit['active_provider_ref'], 'llm_wiki_v2');
    expect(agentAudit['active_provider_kind'], 'registered_provider');
    expect(
        (agentAudit['affected_modules'] as List), contains('agent_workbench'));
    expect(agentAudit['runtime_loaded'], isFalse);
    expect(agentAudit['unauthorized_resources_selectable'], isFalse);
    expect(agentAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(4));
  });

  test('ai marketing skill adapter becomes selectable from local patterns',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['adapter_ready_for_user_selection_count'],
        greaterThanOrEqualTo(2));
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['adapter_runtime_loaded_count'],
        0);

    final readinessPath =
        runtimeStatus['provider_adapter_readiness_report_path'] as String;
    final readiness = jsonDecode(File(readinessPath).readAsStringSync()) as Map;
    final marketingReadiness = (readiness['readiness_entries'] as List)
        .cast<Map>()
        .firstWhere((entry) => entry['provider_ref'] == 'ai_marketing_skills');
    expect(marketingReadiness['status'], '连接成功');
    expect(marketingReadiness['ready_for_user_selection'], isTrue);
    expect(marketingReadiness['runtime_loaded'], isFalse);
    final probePath =
        (marketingReadiness['test_artifacts'] as List).first as String;
    final probe = jsonDecode(File(probePath).readAsStringSync()) as Map;
    expect(probe['schema_version'],
        'prd_v3_provider_adapter_probe_ai_marketing_skills.v1');
    expect(probe['passed'], isTrue);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);
    expect((probe['checked_assets'] as List), hasLength(4));

    final bindingPath =
        runtimeStatus['provider_capability_binding_manifest_path'] as String;
    final binding = jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    final skillBinding = (binding['bindings'] as List).cast<Map>().firstWhere(
        (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(skillBinding['active_provider_kind'], 'registered_provider');
    expect(skillBinding['selection_allowed'], isTrue);
    expect(skillBinding['runtime_loaded'], isFalse);
    expect(skillBinding['ready_candidate_count'], greaterThanOrEqualTo(2));

    final activated = await controller
        .activateRegisteredProviderCapability('ai_marketing_skills');
    expect(activated, isTrue);
    final activatedBinding =
        jsonDecode(File(bindingPath).readAsStringSync()) as Map;
    expect(activatedBinding['action'], 'activate');
    expect(activatedBinding['selected_provider_ref'], 'ai_marketing_skills');
    expect(activatedBinding['selected_provider_runtime_loaded'], isFalse);
    final selectionLog = File(
            '$configDir${Platform.pathSeparator}registered_provider_selection_log.jsonl')
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(selectionLog.last['status'], '连接成功');
    expect(selectionLog.last['runtime_loaded_after_event'], isFalse);
    expect(selectionLog.last['secret_masked'], isTrue);
    final activatedRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List).cast<Map>();
    final skillAudit = downstreamBindingAudit.firstWhere(
        (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(skillAudit['active_provider_ref'], 'ai_marketing_skills');
    expect(skillAudit['active_provider_kind'], 'registered_provider');
    expect((skillAudit['affected_modules'] as List), contains('skill_factory'));
    expect(skillAudit['runtime_loaded'], isFalse);
    expect(skillAudit['unauthorized_resources_selectable'], isFalse);
    expect(skillAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(3));
  });

  test(
      'skill prompt generator adapter becomes selectable from real skill runtime assets',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(
        readinessEntry(
            readiness, 'skill_prompt_generator')['ready_for_user_selection'],
        isFalse);

    final skillRoot =
        Directory('${workspace.path}${Platform.pathSeparator}skill')
          ..createSync(recursive: true);
    final primaryDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    final localizedDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2')
      ..createSync(recursive: true);
    final fusedDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}fused_product_ops_skill')
      ..createSync(recursive: true);
    final operationsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}operations')
          ..createSync(recursive: true);
    final versionsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}versions')
          ..createSync(recursive: true);
    final v1 = Directory('${versionsDir.path}${Platform.pathSeparator}v1')
      ..createSync(recursive: true);
    final v2 = Directory('${versionsDir.path}${Platform.pathSeparator}v2')
      ..createSync(recursive: true);
    final v1Snapshot = '${v1.path}${Platform.pathSeparator}SKILL.md';
    final v2Snapshot = '${v2.path}${Platform.pathSeparator}SKILL.md';
    File(v1Snapshot).writeAsStringSync('# Skill v1\n');
    File(v2Snapshot).writeAsStringSync('# Skill v2 fused\n');
    File('${primaryDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Knowledge QA Skill\nUse local KB evidence.');
    File('${primaryDir.path}${Platform.pathSeparator}skill_config.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S1',
      'source_mode': 'from_kb',
      'target_platform': 'codex',
      'status': 'validated',
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_generation_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_real_input_skill_generation.v1',
      'source_modes': ['from_kb', 'external_skill_fusion'],
      'selected_generation_config': {
        'skill_type': 'product',
        'target_platform': 'codex',
      },
      'model_route_evidence': {
        'skill_generation': {
          'route_scopes': ['skill_generation', 'skill_validation'],
        },
      },
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_validation_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_factory_validation.v1',
      'status': 'pass',
      'ready_for_agent_binding': true,
      'secret_plaintext_written': false,
    }));
    File('${localizedDir.path}${Platform.pathSeparator}localized_skill_manifest.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S2',
      'source_mode': 'external_skill_fusion',
      'status': 'validated',
    }));
    File('${localizedDir.path}${Platform.pathSeparator}diff_summary.md')
        .writeAsStringSync('# Localized diff\nExternal method fused with KB.');
    File('${fusedDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Fused product ops Skill\n');
    File('${operationsDir.path}${Platform.pathSeparator}skill_version_diff_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_version_diff_report.v1',
      'status': 'pass',
    }));
    File('${operationsDir.path}${Platform.pathSeparator}skill_runtime_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_runtime_manifest.v1',
      'runtime_loaded': true,
      'external_runtime': false,
      'secondary_fusion_runtime_available': true,
      'multi_version_runtime_available': true,
      'version_count': 2,
      'versions': [
        {
          'version_id': 'v1',
          'snapshot_path': v1Snapshot,
        },
        {
          'version_id': 'v2',
          'snapshot_path': v2Snapshot,
        },
      ],
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'external_skill_localization'],
      },
      'secret_plaintext_written': false,
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final status = runtimeStatus();
    readiness = readinessReport(status);
    final skillPrompt = readinessEntry(readiness, 'skill_prompt_generator');
    expect(skillPrompt['status'], '连接成功');
    expect(skillPrompt['ready_for_user_selection'], isTrue);
    expect(skillPrompt['runtime_loaded'], isFalse);
    final probe = jsonDecode(
        File((skillPrompt['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(probe['schema_version'],
        'prd_v3_provider_adapter_probe_skill_prompt_generator.v1');
    expect(probe['passed'], isTrue);
    expect(probe['blocked_reasons'], isEmpty);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);

    final activated = await controller
        .activateRegisteredProviderCapability('skill_prompt_generator');
    expect(activated, isTrue);
    final binding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final activatedBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(activatedBinding['active_provider_ref'], 'skill_prompt_generator');
    expect(activatedBinding['explicit_selection_applied'], isTrue);
    expect(activatedBinding['runtime_loaded'], isFalse);
    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(4));
  });

  test('karpathy teaching skill adapter becomes selectable from skill assets',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    var karpathy = readinessEntry(readiness, 'andrej_karpathy_skills');
    expect(karpathy['ready_for_user_selection'], isTrue);
    expect(karpathy['runtime_loaded'], isFalse);
    var probe = jsonDecode(
        File((karpathy['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(probe['probe_kind'],
        'local_teaching_reasoning_template_asset_manifest');
    final templateAssetManifestPath =
        probe['template_asset_manifest_path'] as String;
    final templateAssetManifest =
        jsonDecode(File(templateAssetManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(templateAssetManifest['schema_version'],
        'prd_v3_skill_template_asset_manifest.v1');
    expect(templateAssetManifest['provider_ref'], 'andrej_karpathy_skills');
    expect(templateAssetManifest['runtime_load_required'], isFalse);
    expect(templateAssetManifest['external_runtime_executed'], isFalse);

    final skillRoot =
        Directory('${workspace.path}${Platform.pathSeparator}skill')
          ..createSync(recursive: true);
    final primaryDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    final operationsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}operations')
          ..createSync(recursive: true);
    final versionsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}versions')
          ..createSync(recursive: true);
    final v1 = Directory('${versionsDir.path}${Platform.pathSeparator}v1')
      ..createSync(recursive: true);
    final v2 = Directory('${versionsDir.path}${Platform.pathSeparator}v2')
      ..createSync(recursive: true);
    final v1Snapshot = '${v1.path}${Platform.pathSeparator}SKILL.md';
    final v2Snapshot = '${v2.path}${Platform.pathSeparator}SKILL.md';
    File(v1Snapshot).writeAsStringSync('# Teaching Skill v1\n');
    File(v2Snapshot).writeAsStringSync('# Teaching Skill v2 reasoning\n');
    File('${primaryDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync(
            '# Knowledge Teaching Skill\n\n用步骤化教学方式讲解知识库证据，并输出推理过程。\n');
    File('${primaryDir.path}${Platform.pathSeparator}skill_config.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S1',
      'type': 'teaching',
      'source_mode': 'from_kb',
      'target_platform': 'codex',
      'status': 'validated',
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_generation_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_real_input_skill_generation.v1',
      'source_modes': ['from_kb'],
      'selected_generation_config': {
        'type': 'teaching',
        'target_platform': 'codex',
      },
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'skill_validation'],
      },
      'secret_plaintext_written': false,
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_validation_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_factory_validation.v1',
      'status': 'pass',
      'ready_for_agent_binding': true,
      'secret_plaintext_written': false,
    }));
    File('${operationsDir.path}${Platform.pathSeparator}skill_version_diff_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_version_diff_report.v1',
      'status': 'pass',
    }));
    File('${operationsDir.path}${Platform.pathSeparator}skill_runtime_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_runtime_manifest.v1',
      'runtime_loaded': true,
      'external_runtime': false,
      'multi_version_runtime_available': true,
      'version_count': 2,
      'versions': [
        {
          'version_id': 'v1',
          'snapshot_path': v1Snapshot,
        },
        {
          'version_id': 'v2',
          'snapshot_path': v2Snapshot,
        },
      ],
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'skill_validation'],
      },
      'secret_plaintext_written': false,
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    readiness = readinessReport(runtimeStatus());
    karpathy = readinessEntry(readiness, 'andrej_karpathy_skills');
    expect(karpathy['status'], '连接成功');
    expect(karpathy['ready_for_user_selection'], isTrue);
    expect(karpathy['runtime_loaded'], isFalse);
    probe = jsonDecode(
        File((karpathy['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(probe['schema_version'],
        'prd_v3_provider_adapter_probe_andrej_karpathy_skills.v1');
    expect(probe['probe_kind'],
        'local_teaching_reasoning_template_asset_manifest');
    expect(probe['passed'], isTrue);
    expect(probe['blocked_reasons'], isEmpty);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);

    final activated = await controller
        .activateRegisteredProviderCapability('andrej_karpathy_skills');
    expect(activated, isTrue);
    final binding = jsonDecode(File(
            runtimeStatus()['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final skillBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(skillBinding['active_provider_ref'], 'andrej_karpathy_skills');
    expect(skillBinding['explicit_selection_applied'], isTrue);
    expect(skillBinding['runtime_loaded'], isFalse);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    final karpathyHealth = (health['health_entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['provider_ref'] == 'andrej_karpathy_skills');
    expect(karpathyHealth['health_status'], '连接成功');
    expect(karpathyHealth['ready_for_user_selection'], isTrue);
    expect(karpathyHealth['runtime_loaded'], isFalse);
  });

  test('mmskills schema package adapter becomes selectable from local assets',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(readinessEntry(readiness, 'mmskills')['ready_for_user_selection'],
        isFalse);

    final skillRoot =
        Directory('${workspace.path}${Platform.pathSeparator}skill')
          ..createSync(recursive: true);
    final primaryDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    final localizedDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2')
      ..createSync(recursive: true);
    final fusedDir = Directory(
        '${skillRoot.path}${Platform.pathSeparator}fused_product_ops_skill')
      ..createSync(recursive: true);
    final operationsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}operations')
          ..createSync(recursive: true);
    final versionsDir =
        Directory('${skillRoot.path}${Platform.pathSeparator}versions')
          ..createSync(recursive: true);
    final v1 = Directory('${versionsDir.path}${Platform.pathSeparator}v1')
      ..createSync(recursive: true);
    final v2 = Directory('${versionsDir.path}${Platform.pathSeparator}v2')
      ..createSync(recursive: true);
    final v1Snapshot = '${v1.path}${Platform.pathSeparator}SKILL.md';
    final v2Snapshot = '${v2.path}${Platform.pathSeparator}SKILL.md';
    File(v1Snapshot).writeAsStringSync('# Skill v1\n');
    File(v2Snapshot).writeAsStringSync('# Skill v2 fused\n');
    File('${primaryDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Knowledge QA Skill\n');
    File('${primaryDir.path}${Platform.pathSeparator}skill_config.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S1',
      'source_mode': 'from_kb',
      'target_platform': 'codex',
      'status': 'validated',
    }));
    File('${localizedDir.path}${Platform.pathSeparator}localized_skill_manifest.json')
        .writeAsStringSync(jsonEncode({
      'skill_config_id': 'S2',
      'source_mode': 'external_skill_fusion',
      'status': 'validated',
    }));
    File('${fusedDir.path}${Platform.pathSeparator}skill_manifest.json')
        .writeAsStringSync(jsonEncode({
      'skill_id': 'S3',
      'source_mode': 'skill_plus_kb_fusion',
      'status': 'validated',
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_package_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_package_manifest.v1',
      'status': 'ready',
      'skill_packages': [
        {'skill_id': 'S1', 'schema_id': 'mmskills_local_schema.v1'}
      ],
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'skill_validation'],
      },
      'secret_plaintext_written': false,
    }));
    File('${skillRoot.path}${Platform.pathSeparator}skill_validation_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_factory_validation.v1',
      'status': 'pass',
      'ready_for_agent_binding': true,
      'secret_plaintext_written': false,
    }));
    File('${operationsDir.path}${Platform.pathSeparator}agent_binding_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_agent_binding_manifest.v1',
      'status': 'bound',
      'agent_id': 'knowledge_qa_agent',
    }));
    File('${operationsDir.path}${Platform.pathSeparator}skill_runtime_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_runtime_manifest.v1',
      'runtime_loaded': true,
      'external_runtime': false,
      'secondary_fusion_runtime_available': true,
      'multi_version_runtime_available': true,
      'version_count': 2,
      'versions': [
        {
          'version_id': 'v1',
          'snapshot_path': v1Snapshot,
        },
        {
          'version_id': 'v2',
          'snapshot_path': v2Snapshot,
        },
      ],
      'model_route_evidence': {
        'route_scopes': ['skill_generation', 'external_skill_localization'],
      },
      'secret_plaintext_written': false,
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    readiness = readinessReport(runtimeStatus());
    final mmskills = readinessEntry(readiness, 'mmskills');
    expect(mmskills['status'], '连接成功');
    expect(mmskills['ready_for_user_selection'], isTrue);
    expect(mmskills['runtime_loaded'], isFalse);
    final probe = jsonDecode(
        File((mmskills['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(
        probe['schema_version'], 'prd_v3_provider_adapter_probe_mmskills.v1');
    expect(probe['passed'], isTrue);
    expect(probe['blocked_reasons'], isEmpty);
    expect(probe['network_used'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(probe['normal_ui_project_name_visible'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);

    final activated =
        await controller.activateRegisteredProviderCapability('mmskills');
    expect(activated, isTrue);
    final binding = jsonDecode(File(
            runtimeStatus()['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final skillBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'skill_template_provider');
    expect(skillBinding['active_provider_ref'], 'mmskills');
    expect(skillBinding['explicit_selection_applied'], isTrue);
    expect(skillBinding['runtime_loaded'], isFalse);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    final mmskillsHealth = (health['health_entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['provider_ref'] == 'mmskills');
    expect(mmskillsHealth['health_status'], '连接成功');
    expect(mmskillsHealth['ready_for_user_selection'], isTrue);
    expect(mmskillsHealth['runtime_loaded'], isFalse);
  });

  test(
      'provider hot swap selection persists across runtime refresh and rollback',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final activated = await controller
        .activateRegisteredProviderCapability('ai_marketing_skills');
    expect(activated, isTrue);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> bindingManifest(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_capability_binding_manifest_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> skillTemplateBinding(Map<String, dynamic> binding) =>
        (binding['bindings'] as List).cast<Map<String, dynamic>>().firstWhere(
            (entry) => entry['capability_id'] == 'skill_template_provider');

    var status = runtimeStatus();
    final selectionPath =
        status['provider_capability_selection_state_path'] as String;
    var selectionState =
        jsonDecode(File(selectionPath).readAsStringSync()) as Map;
    expect(selectionState['schema_version'],
        'prd_v3_provider_capability_selection_state.v1');
    expect(
        (selectionState['selected_providers_by_capability']
            as Map)['skill_template_provider'],
        'ai_marketing_skills');
    expect(selectionState['runtime_loaded_after_change'], isFalse);
    expect(selectionState['secret_plaintext_written'], isFalse);
    var skillBinding = skillTemplateBinding(bindingManifest(status));
    expect(skillBinding['active_provider_ref'], 'ai_marketing_skills');
    expect(skillBinding['explicit_selection_applied'], isTrue);
    expect(skillBinding['explicit_selection_stale'], isFalse);
    expect(skillBinding['runtime_loaded'], isFalse);

    final reloaded = buildController();
    await reloaded.initialize();
    await reloaded.syncRegisteredProviderCapabilities();
    status = runtimeStatus();
    skillBinding = skillTemplateBinding(bindingManifest(status));
    expect(skillBinding['active_provider_ref'], 'ai_marketing_skills');
    expect(
        skillBinding['explicit_selected_provider_ref'], 'ai_marketing_skills');
    expect(skillBinding['explicit_selection_applied'], isTrue);

    final rolledBack = await reloaded
        .rollbackRegisteredProviderCapability('ai_marketing_skills');
    expect(rolledBack, isTrue);
    status = runtimeStatus();
    selectionState = jsonDecode(File(selectionPath).readAsStringSync()) as Map;
    expect(
        (selectionState['selected_providers_by_capability'] as Map)
            .containsKey('skill_template_provider'),
        isFalse);
    expect(selectionState['rollback_suppressed_capability_ids'],
        contains('skill_template_provider'));
    skillBinding = skillTemplateBinding(bindingManifest(status));
    expect(skillBinding['active_provider_ref'], 'local_skill_factory');
    expect(skillBinding['active_provider_kind'], 'local_fallback');
    expect(skillBinding['explicit_selected_provider_ref'], '');
    expect(skillBinding['rollback_suppressed'], isTrue);
    expect(skillBinding['selection_allowed'], isFalse);
  });

  test('exporter adapters become selectable from real export artifacts',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(readinessEntry(readiness, 'jellyfish')['ready_for_user_selection'],
        isFalse);
    expect(
        readinessEntry(readiness, 'story_flicks')['ready_for_user_selection'],
        isFalse);

    final structuredDir = Directory(
        '${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured')
      ..createSync(recursive: true);
    final jsonPath =
        '${structuredDir.path}${Platform.pathSeparator}knowledge_export.json';
    final csvPath =
        '${structuredDir.path}${Platform.pathSeparator}knowledge_export.csv';
    final structuredManifestPath =
        '${structuredDir.path}${Platform.pathSeparator}structured_export_manifest.json';
    File(jsonPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_structured_document_export_payload.v1',
      'status': 'pass',
      'sources': [
        {'source_name': 'source.md', 'relative_path': 'input/source.md'}
      ],
      'retrieval': {
        'results': [
          {
            'title': 'real export evidence',
            'citation': 'input/source.md#chunk=1',
          }
        ],
      },
      'retrieval_results': [
        {
          'title': 'real export evidence',
          'citation': 'input/source.md#chunk=1',
        }
      ],
      'redaction': {'secret_plaintext_written': false},
    }));
    File(csvPath).writeAsStringSync(
        'record_type,title,citation\nretrieval_result,real export evidence,input/source.md#chunk=1\n');
    File(structuredManifestPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_structured_document_export.v1',
      'status': 'pass',
      'json_output': jsonPath,
      'csv_output': csvPath,
    }));

    final videoDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}artifacts${Platform.pathSeparator}video')
      ..createSync(recursive: true);
    final toolDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}tool')
      ..createSync(recursive: true);
    final externalSkillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}external_skills${Platform.pathSeparator}video_generation_skill')
      ..createSync(recursive: true);
    File('${videoDir.path}${Platform.pathSeparator}prompt.txt')
        .writeAsStringSync('产品介绍视频 handoff prompt');
    File('${videoDir.path}${Platform.pathSeparator}cost_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_tool_cost_report.v1',
      'tool_id': 'video.generate',
      'api_call_count': 0,
      'estimated_cost': 0,
    }));
    File('${videoDir.path}${Platform.pathSeparator}video_task_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_video_task_manifest.v1',
      'tool_id': 'video.generate',
      'fake_video_generated': false,
      'api_called': false,
      'prompt_path': '${videoDir.path}${Platform.pathSeparator}prompt.txt',
    }));
    File('${toolDir.path}${Platform.pathSeparator}tool_call_log.jsonl')
        .writeAsStringSync(jsonl([
      {
        'schema_version': 'prd_v3_tool_call_log_record.v1',
        'tool_id': 'video.generate',
        'api_called': false,
        'status': 'Tool 未授权',
      }
    ]));
    File('${externalSkillDir.path}${Platform.pathSeparator}skill_dependency_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_skill_dependency_report.v1',
      'skill_id': 'video_generation_skill',
      'missing_provider_configs': ['video_custom_http_stub'],
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final status = runtimeStatus();
    readiness = readinessReport(status);
    final jellyfish = readinessEntry(readiness, 'jellyfish');
    final storyFlicks = readinessEntry(readiness, 'story_flicks');
    expect(jellyfish['status'], '连接成功');
    expect(jellyfish['ready_for_user_selection'], isTrue);
    expect(jellyfish['runtime_loaded'], isFalse);
    expect(storyFlicks['status'], '连接成功');
    expect(storyFlicks['ready_for_user_selection'], isTrue);
    expect(storyFlicks['runtime_loaded'], isFalse);

    final jellyfishProbe = jsonDecode(
        File((jellyfish['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(jellyfishProbe['schema_version'],
        'prd_v3_provider_adapter_probe_jellyfish.v1');
    expect(jellyfishProbe['passed'], isTrue);
    expect(jellyfishProbe['external_runtime_executed'], isFalse);
    final storyProbe = jsonDecode(
        File((storyFlicks['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(storyProbe['schema_version'],
        'prd_v3_provider_adapter_probe_story_flicks.v1');
    expect(storyProbe['passed'], isTrue);
    expect(storyProbe['fake_video_generated'], isFalse);
    expect(storyProbe['api_called'], isFalse);

    final binding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final exporterBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['capability_id'] == 'document_exporter');
    expect(exporterBinding['active_provider_ref'], 'jellyfish');
    expect(exporterBinding['active_provider_kind'], 'registered_provider');
    expect(exporterBinding['selection_allowed'], isTrue);
    expect(exporterBinding['ready_candidate_count'], greaterThanOrEqualTo(2));

    final activated =
        await controller.activateRegisteredProviderCapability('story_flicks');
    expect(activated, isTrue);
    final activatedBinding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final activatedExporterBinding = (activatedBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['capability_id'] == 'document_exporter');
    expect(activatedExporterBinding['active_provider_ref'], 'story_flicks');
    expect(activatedExporterBinding['explicit_selection_applied'], isTrue);
    expect(activatedExporterBinding['runtime_loaded'], isFalse);
    final activatedRuntimeStatus = runtimeStatus();
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List)
            .cast<Map<String, dynamic>>();
    final exporterAudit = downstreamBindingAudit
        .firstWhere((entry) => entry['capability_id'] == 'document_exporter');
    expect(exporterAudit['active_provider_ref'], 'story_flicks');
    expect(exporterAudit['active_provider_kind'], 'registered_provider');
    expect((exporterAudit['affected_modules'] as List),
        containsAll(['document_generation', 'artifact_center']));
    expect(exporterAudit['runtime_loaded'], isFalse);
    expect(exporterAudit['unauthorized_resources_selectable'], isFalse);
    expect(exporterAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(5));
  });

  test('parser ocr adapters become selectable from real parse artifacts',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(readinessEntry(readiness, 'docling')['ready_for_user_selection'],
        isFalse);
    expect(readinessEntry(readiness, 'paddleocr')['ready_for_user_selection'],
        isFalse);

    final duDir = Directory('${workspace.path}${Platform.pathSeparator}du')
      ..createSync(recursive: true);
    final normalizedDir =
        Directory('${duDir.path}${Platform.pathSeparator}normalized_sources')
          ..createSync(recursive: true);
    final normalizedAlpha =
        '${normalizedDir.path}${Platform.pathSeparator}alpha.md';
    final normalizedImage =
        '${normalizedDir.path}${Platform.pathSeparator}image.md';
    File(normalizedAlpha).writeAsStringSync('normalized real parser text');
    File(normalizedImage).writeAsStringSync('normalized OCR image text');
    File('${duDir.path}${Platform.pathSeparator}document_understanding_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_document_understanding_manifest.v1',
      'status': 'completed',
      'success_count': 2,
      'failed_count': 0,
      'normalized_source_count': 2,
    }));
    File('${duDir.path}${Platform.pathSeparator}document_understanding_records.jsonl')
        .writeAsStringSync(jsonl([
      {
        'relative_path': 'alpha.pdf',
        'normalized_path': normalizedAlpha,
      },
      {
        'relative_path': 'scan.png',
        'normalized_path': normalizedImage,
        'ocr_text': 'normalized OCR image text',
      },
    ]));
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_source_manifest.v1',
      'status': 'imported',
      'source_count': 2,
      'sources': [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.pdf',
          'relative_path': 'alpha.pdf',
          'extension': '.pdf',
          'image_count': 0,
          'structure_status': 'requires_parser',
        },
        {
          'document_id': 'doc_scan',
          'source_name': 'scan.png',
          'relative_path': 'scan.png',
          'extension': '.png',
          'image_count': 1,
          'structure_status': 'requires_parser',
        },
      ],
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final status = runtimeStatus();
    readiness = readinessReport(status);
    final docling = readinessEntry(readiness, 'docling');
    final unstructured = readinessEntry(readiness, 'unstructured');
    final paddleocr = readinessEntry(readiness, 'paddleocr');
    final surya = readinessEntry(readiness, 'surya');
    expect(docling['status'], '连接成功');
    expect(docling['ready_for_user_selection'], isTrue);
    expect(unstructured['ready_for_user_selection'], isTrue);
    expect(paddleocr['status'], '连接成功');
    expect(paddleocr['ready_for_user_selection'], isTrue);
    expect(surya['ready_for_user_selection'], isTrue);
    expect(paddleocr['runtime_loaded'], isFalse);

    final doclingProbe = jsonDecode(
        File((docling['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(doclingProbe['schema_version'],
        'prd_v3_provider_adapter_probe_document_parser_ocr.v1');
    expect(doclingProbe['passed'], isTrue);
    expect(doclingProbe['has_parser_evidence'], isTrue);
    expect(doclingProbe['external_runtime_executed'], isFalse);
    final ocrProbe = jsonDecode(
        File((paddleocr['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(ocrProbe['passed'], isTrue);
    expect(ocrProbe['has_ocr_input_evidence'], isTrue);
    expect(ocrProbe['du_ocr_input_evidence'], isTrue);
    expect(ocrProbe['du_ocr_record_count'], greaterThanOrEqualTo(1));
    expect(ocrProbe['vendor_runtime_loaded'], isFalse);

    final binding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final parserBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['capability_id'] == 'document_parser_ocr');
    expect(parserBinding['active_provider_kind'], 'registered_provider');
    expect(parserBinding['selection_allowed'], isTrue);
    expect(parserBinding['ready_candidate_count'], greaterThanOrEqualTo(4));

    final activated =
        await controller.activateRegisteredProviderCapability('docling');
    expect(activated, isTrue);
    final activatedBinding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final activatedParserBinding = (activatedBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['capability_id'] == 'document_parser_ocr');
    expect(activatedParserBinding['active_provider_ref'], 'docling');
    expect(activatedParserBinding['explicit_selection_applied'], isTrue);
    expect(activatedParserBinding['runtime_loaded'], isFalse);
    final activatedRuntimeStatus = runtimeStatus();
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List)
            .cast<Map<String, dynamic>>();
    final parserAudit = downstreamBindingAudit
        .firstWhere((entry) => entry['capability_id'] == 'document_parser_ocr');
    expect(parserAudit['active_provider_ref'], 'docling');
    expect(parserAudit['active_provider_kind'], 'registered_provider');
    expect((parserAudit['affected_modules'] as List),
        contains('document_library'));
    expect(parserAudit['runtime_loaded'], isFalse);
    expect(parserAudit['unauthorized_resources_selectable'], isFalse);
    expect(parserAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(8));
  });

  test('embedding vector adapters become selectable from real index artifacts',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(
        readinessEntry(readiness, 'rag_anything')['ready_for_user_selection'],
        isFalse);
    expect(readinessEntry(readiness, 'weknora')['ready_for_user_selection'],
        isFalse);
    expect(readinessEntry(readiness, 'llamaindex')['status'], '配置缺失');

    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {
        'chunk_id': 'c_embedding_vector_1',
        'source_path': 'input/vector-source.md',
        'text': 'real kb vector reference evidence',
      },
    ]));
    File('${kbDir.path}${Platform.pathSeparator}index_profile.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_index_profile.v1',
      'status': 'ready',
      'vector_index_enabled': true,
      'vector_store': 'local_vector_reference',
    }));
    File('${kbDir.path}${Platform.pathSeparator}vector_index_reference.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_vector_index_reference.v1',
      'vector_store': 'local_vector_reference',
      'chunk_count': 1,
      'external_vector_db_required': false,
      'secret_plaintext_written': false,
    }));
    File('${kbDir.path}${Platform.pathSeparator}index_build_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_index_build_report.v1',
      'status': 'pass',
      'chunk_count': 1,
    }));
    File('${kbDir.path}${Platform.pathSeparator}index_metadata.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_index_metadata.v1',
      'index_type': 'hybrid_local',
      'chunk_count': 1,
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final status = runtimeStatus();
    readiness = readinessReport(status);
    final ragAnything = readinessEntry(readiness, 'rag_anything');
    final weknora = readinessEntry(readiness, 'weknora');
    final llamaindex = readinessEntry(readiness, 'llamaindex');
    expect(ragAnything['status'], '连接成功');
    expect(ragAnything['ready_for_user_selection'], isTrue);
    expect(ragAnything['runtime_loaded'], isFalse);
    expect(weknora['status'], '连接成功');
    expect(weknora['ready_for_user_selection'], isTrue);
    expect(weknora['runtime_loaded'], isFalse);
    expect(llamaindex['status'], '配置缺失');
    expect(llamaindex['ready_for_user_selection'], isFalse);

    final ragProbe = jsonDecode(
        File((ragAnything['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(ragProbe['schema_version'],
        'prd_v3_provider_adapter_probe_embedding_vector.v1');
    expect(ragProbe['passed'], isTrue);
    expect(ragProbe['has_index_artifacts'], isTrue);
    expect(ragProbe['has_consistent_chunks'], isTrue);
    expect(ragProbe['vector_enabled'], isTrue);
    expect(ragProbe['external_runtime_executed'], isFalse);
    expect(ragProbe['vendor_runtime_loaded'], isFalse);
    expect(ragProbe['secret_plaintext_written'], isFalse);

    final llamaProbe = jsonDecode(
        File((llamaindex['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(llamaProbe['passed'], isFalse);
    expect(llamaProbe['probe_kind'], 'benchmark_only_vector_boundary');
    expect(llamaProbe['vendor_runtime_loaded'], isFalse);

    final binding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final vectorBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'knowledge_embedding_vector');
    expect(vectorBinding['active_provider_ref'], 'rag_anything');
    expect(vectorBinding['active_provider_kind'], 'registered_provider');
    expect(vectorBinding['selection_allowed'], isTrue);
    expect(vectorBinding['ready_candidate_count'], greaterThanOrEqualTo(2));
    expect(vectorBinding['runtime_loaded'], isFalse);

    final activated =
        await controller.activateRegisteredProviderCapability('weknora');
    expect(activated, isTrue);
    final activatedBinding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final activatedVectorBinding = (activatedBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'knowledge_embedding_vector');
    expect(activatedVectorBinding['active_provider_ref'], 'weknora');
    expect(activatedVectorBinding['explicit_selection_applied'], isTrue);
    expect(activatedVectorBinding['runtime_loaded'], isFalse);
    final activatedRuntimeStatus = runtimeStatus();
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List)
            .cast<Map<String, dynamic>>();
    final vectorAudit = downstreamBindingAudit.firstWhere(
        (entry) => entry['capability_id'] == 'knowledge_embedding_vector');
    expect(vectorAudit['active_provider_ref'], 'weknora');
    expect(vectorAudit['active_provider_kind'], 'registered_provider');
    expect(
        (vectorAudit['affected_modules'] as List), contains('knowledge_base'));
    expect(vectorAudit['runtime_loaded'], isFalse);
    expect(vectorAudit['unauthorized_resources_selectable'], isFalse);
    expect(vectorAudit['secret_masked'], isTrue);

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(5));
  });

  test(
      'workflow collaboration adapter becomes selectable from real A2A exports',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    Map<String, dynamic> runtimeStatus() => jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessReport(
            Map<String, dynamic> status) =>
        jsonDecode(
            File(status['provider_adapter_readiness_report_path'] as String)
                .readAsStringSync()) as Map<String, dynamic>;
    Map<String, dynamic> readinessEntry(
            Map<String, dynamic> readiness, String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);

    var readiness = readinessReport(runtimeStatus());
    expect(
        readinessEntry(readiness, 'n8n')['ready_for_user_selection'], isFalse);

    final a2aDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001')
      ..createSync(recursive: true);
    final multiAgentDir =
        Directory('${workspace.path}${Platform.pathSeparator}multi_agent')
          ..createSync(recursive: true);
    final roundLogPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_rounds.jsonl';
    final runtimeAuditPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_runtime_audit.jsonl';
    final conflictPath =
        '${multiAgentDir.path}${Platform.pathSeparator}a2a_conflict_report.json';
    final consensusPath =
        '${multiAgentDir.path}${Platform.pathSeparator}a2a_consensus_report.json';
    final workflowReportPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_collaboration_report.md';
    final discussionManifestPath =
        '${multiAgentDir.path}${Platform.pathSeparator}multi_agent_discussion_manifest.json';
    File(roundLogPath).writeAsStringSync(jsonl([
      {
        'schema_version': 'prd_v3_a2a_round_record.v1',
        'round': 1,
        'agent_id': 'B',
        'output': 'B output',
      },
      {
        'schema_version': 'prd_v3_a2a_round_record.v1',
        'round': 2,
        'agent_id': 'C',
        'output': 'C review',
      },
      {
        'schema_version': 'prd_v3_a2a_round_record.v1',
        'round': 3,
        'agent_id': 'B',
        'output': 'B response',
      },
    ]));
    File(runtimeAuditPath).writeAsStringSync(jsonl([
      {
        'schema_version': 'prd_v3_a2a_runtime_audit_record.v1',
        'round': 1,
        'status': 'completed',
      },
      {
        'schema_version': 'prd_v3_a2a_runtime_audit_record.v1',
        'round': 2,
        'status': 'completed',
      },
      {
        'schema_version': 'prd_v3_a2a_runtime_audit_record.v1',
        'round': 3,
        'status': 'completed',
      },
    ]));
    File(conflictPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_conflict_report.v1',
      'round_count': 3,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
      'conflicts': ['scope_priority'],
      'secret_plaintext_written': false,
    }));
    File(consensusPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_consensus_report.v1',
      'status': 'pass',
      'round_count': 3,
      'ready_for_export': true,
    }));
    File(workflowReportPath)
        .writeAsStringSync('# A2A workflow collaboration export\n');
    File(discussionManifestPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_multi_agent_discussion_manifest.v1',
      'status': 'report_generated',
      'topic': 'workflow export',
      'a2a_conflict_report_path': conflictPath,
      'a2a_consensus_report_path': consensusPath,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
    }));
    File('${a2aDir.path}${Platform.pathSeparator}a2a_session_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_session_manifest.v1',
      'a2a_session_id': 'A2A_001',
      'parent_workspace_id': 'W_M',
      'participant_agent_ids': ['B', 'C'],
      'topic': 'workflow export',
      'rounds': 3,
      'round_limit': 3,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
      'conflict_report_path': conflictPath,
      'consensus_report_path': consensusPath,
      'workspace_output_report_path': workflowReportPath,
      'status': 'report_generated',
    }));

    final healthPath = await controller.testAllRegisteredProviderCapabilities();
    final status = runtimeStatus();
    readiness = readinessReport(status);
    final n8n = readinessEntry(readiness, 'n8n');
    expect(n8n['status'], '连接成功');
    expect(n8n['ready_for_user_selection'], isTrue);
    expect(n8n['runtime_loaded'], isFalse);
    final probe = jsonDecode(
        File((n8n['test_artifacts'] as List).cast<String>().single)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(probe['schema_version'], 'prd_v3_provider_adapter_probe_n8n.v1');
    expect(probe['passed'], isTrue);
    expect(probe['round_limit'], 3);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['vendor_runtime_loaded'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);

    final binding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    final workflowBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(workflowBinding['active_provider_ref'], 'n8n');
    expect(workflowBinding['active_provider_kind'], 'registered_provider');
    expect(workflowBinding['selection_allowed'], isTrue);
    expect(workflowBinding['runtime_loaded'], isFalse);

    final activated =
        await controller.activateRegisteredProviderCapability('n8n');
    expect(activated, isTrue);
    final activatedBinding = jsonDecode(
        File(status['provider_capability_binding_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(activatedBinding['selected_provider_ref'], 'n8n');
    expect(activatedBinding['selected_provider_runtime_loaded'], isFalse);
    final activatedRuntimeStatus = runtimeStatus();
    final lifecycleAudit = jsonDecode(File(
            activatedRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List)
            .cast<Map<String, dynamic>>();
    final workflowAudit = downstreamBindingAudit.firstWhere(
        (entry) => entry['capability_id'] == 'workflow_collaboration_export');
    expect(workflowAudit['active_provider_ref'], 'n8n');
    expect(workflowAudit['active_provider_kind'], 'registered_provider');
    expect((workflowAudit['affected_modules'] as List),
        containsAll(['agent_workbench', 'artifact_center']));
    expect(workflowAudit['runtime_loaded'], isFalse);
    expect(workflowAudit['unauthorized_resources_selectable'], isFalse);
    expect(workflowAudit['secret_masked'], isTrue);
    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(4));
  });

  test('stage3 n8n runtime load degrades when endpoint is missing', () async {
    final workspace = await createWorkspace();
    writeStage2PreflightFixture(workspace);
    writeStage2SkillRuntimeFixture(workspace);
    writeStage2AgentPermissionFixture(workspace);
    writeStage2IndustrialSmokeFixture(workspace);
    writeStage2ExeLaunchSmokeFixture(workspace);
    writeN8nReadinessFixture(workspace);
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final loaded = await controller.loadN8nProviderRuntime();
    expect(loaded, isFalse);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final manifest = jsonDecode(File(
            '$configDir${Platform.pathSeparator}provider_runtime_load_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        manifest['schema_version'], 'prd_v3_provider_runtime_load_manifest.v1');
    expect(manifest['provider_ref'], 'n8n');
    expect(manifest['capability_id'], 'workflow_collaboration_export');
    expect(manifest['eligible_before_load'], isTrue);
    expect(manifest['runtime_loaded'], isFalse);
    expect(manifest['runtime_loaded_count'], 0);
    expect(manifest['status'], '配置缺失');
    expect(manifest['error_code'], 'n8n_endpoint_missing_or_invalid');
    expect(manifest['external_runtime_executed'], isFalse);
    expect(manifest['workflow_executed'], isFalse);
    expect(manifest['normal_ui_project_name_visible'], isFalse);
    expect(manifest['secret_plaintext_written'], isFalse);
    expect(
        (manifest['downstream_binding']
            as Map)['agent_workbench_a2a_workflow_export'],
        contains('降级为本地 A2A'));

    final logRows = readJsonlFile(
        '$configDir${Platform.pathSeparator}provider_runtime_load_log.jsonl');
    expect(logRows, hasLength(1));
    expect(logRows.single['runtime_loaded_after_event'], isFalse);
    expect(logRows.single['fallback'], contains('A2A 本地协作报告导出继续可用'));
    expect(logRows.single['secret_plaintext_written'], isFalse);

    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final loadSummary =
        runtimeStatus['provider_runtime_load_summary'] as Map<String, dynamic>;
    expect(loadSummary['runtime_loaded'], isFalse);
    expect(loadSummary['status'], '配置缺失');
    expect(loadSummary['workflow_executed'], isFalse);
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['external_runtime_loaded_count'],
        0);
    final agentStatus =
        (runtimeStatus['module_status'] as Map)['agent_workbench'] as Map;
    expect(agentStatus['a2a_workflow_runtime_status'], '配置缺失');
    expect(agentStatus['a2a_workflow_runtime_loaded'], isFalse);
    expect(agentStatus['a2a_workflow_external_execution'], isFalse);
    expect(agentStatus['a2a_workflow_fallback'], contains('本地协作报告'));
    expect((runtimeStatus['degradation'] as Map)['n8n_runtime_failure'],
        contains('降级为本地协作报告'));
  });

  test('stage3 n8n runtime load records safe health success only', () async {
    final workspace = await createWorkspace();
    writeStage2PreflightFixture(workspace);
    writeStage2SkillRuntimeFixture(workspace);
    writeStage2AgentPermissionFixture(workspace);
    writeStage2IndustrialSmokeFixture(workspace);
    writeStage2ExeLaunchSmokeFixture(workspace);
    writeN8nReadinessFixture(workspace);
    final previousHttpOverride = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() {
      HttpOverrides.global = previousHttpOverride;
    });
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
    });
    final requests = <String>[];
    unawaited(() async {
      await for (final request in server) {
        requests.add(request.uri.path);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write('{"status":"ok"}');
        await request.response.close();
      }
    }());
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    const sensitiveValue = 'stage3-sensitive-value';
    final endpoint =
        'http://${server.address.host}:${server.port}?credential=redacted';
    final loaded = await controller.loadN8nProviderRuntime(
      endpoint: endpoint,
      apiKey: sensitiveValue,
    );
    expect(loaded, isTrue);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final manifestPath =
        '$configDir${Platform.pathSeparator}provider_runtime_load_manifest.json';
    final manifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['runtime_loaded'], isTrue);
    expect(manifest['runtime_loaded_count'], 1);
    expect(manifest['status'], '连接成功');
    expect(manifest['sanitized_endpoint'],
        'http://${server.address.host}:${server.port}');
    expect(manifest['external_runtime_connected'], isTrue);
    expect(manifest['external_runtime_executed'], isFalse);
    expect(manifest['workflow_executed'], isFalse);
    expect(manifest['secret_plaintext_written'], isFalse);
    final probe =
        jsonDecode(File(manifest['probe_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(
        probe['schema_version'], 'prd_v3_provider_runtime_load_probe_n8n.v1');
    expect(probe['runtime_loaded'], isTrue);
    expect(probe['health_path'], '/healthz');
    expect(probe['workflow_executed'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(requests, ['/healthz']);

    final configLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(configLog, contains('"config_type":"provider_runtime_load"'));
    expect(configLog, isNot(contains(sensitiveValue)));
    expect(configLog, isNot(contains('credential=redacted')));
    expect(
        File(manifestPath).readAsStringSync(), isNot(contains(sensitiveValue)));

    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final loadSummary =
        runtimeStatus['provider_runtime_load_summary'] as Map<String, dynamic>;
    expect(loadSummary['runtime_loaded'], isTrue);
    expect(loadSummary['runtime_loaded_count'], 1);
    expect(loadSummary['external_runtime_executed'], isFalse);
    expect(loadSummary['workflow_executed'], isFalse);
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['external_runtime_loaded_count'],
        1);
    final dashboard =
        (runtimeStatus['module_status'] as Map)['dashboard'] as Map;
    expect((dashboard['external_runtime_health'] as Map)['runtime_loaded'],
        isTrue);
    final agentStatus =
        (runtimeStatus['module_status'] as Map)['agent_workbench'] as Map;
    expect(agentStatus['a2a_workflow_runtime_status'], '连接成功');
    expect(agentStatus['a2a_workflow_runtime_loaded'], isTrue);
    expect(agentStatus['a2a_workflow_external_execution'], isFalse);
    expect(agentStatus['a2a_workflow_fallback'], '');
    expect((runtimeStatus['degradation'] as Map)['n8n_runtime_failure'],
        contains('未执行外部 workflow'));
    final integrationMatrix = jsonDecode(File(
            runtimeStatus['registered_provider_integration_matrix_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final n8nMatrixEntry = (integrationMatrix['provider_entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['provider_ref'] == 'n8n' &&
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(n8nMatrixEntry['runtime_loaded'], isTrue);
    expect(
        (integrationMatrix['registered_project_boundary']
            as Map)['loaded_project_count'],
        1);
    final eligibility = jsonDecode(File(
            runtimeStatus['provider_runtime_load_eligibility_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(eligibility['runtime_loaded_count'], 1);
    final n8nEligibility = (eligibility['entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['provider_ref'] == 'n8n');
    expect(n8nEligibility['runtime_loaded'], isTrue);
    expect(n8nEligibility['load_state'], 'loaded_health_check_only');
    final binding = jsonDecode(File(
            runtimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(binding['registered_provider_loaded_count'], 1);
    final workflowBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(workflowBinding['active_provider_ref'], 'n8n');
    expect(workflowBinding['runtime_loaded'], isTrue);
    expect(workflowBinding['external_runtime_executed'], isFalse);
    expect(workflowBinding['workflow_executed'], isFalse);
    final lifecycleAuditPath =
        runtimeStatus['provider_lifecycle_audit_summary_path'] as String;
    final lifecycleAudit =
        jsonDecode(File(lifecycleAuditPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(lifecycleAudit['schema_version'],
        'prd_v3_provider_lifecycle_audit_summary.v1');
    expect(
        (lifecycleAudit['provider_counts'] as Map)['runtime_loaded_count'], 1);
    expect(
        (lifecycleAudit['event_counts'] as Map)['runtime_load_event_count'], 1);
    expect(
        (lifecycleAudit['event_counts']
            as Map)['runtime_load_success_event_count'],
        1);
    expect(
        ((lifecycleAudit['event_counts'] as Map)['runtime_load_actions']
            as Map)['load'],
        1);
    expect(
        (lifecycleAudit['industrial_boundaries']
            as Map)['external_runtime_executed'],
        isFalse);
    expect(
        (lifecycleAudit['industrial_boundaries'] as Map)['workflow_executed'],
        isFalse);
    expect(
        (lifecycleAudit['industrial_boundaries']
            as Map)['secret_plaintext_written'],
        isFalse);
    final downstreamBindingAudit =
        (lifecycleAudit['downstream_binding_audit'] as List)
            .cast<Map<String, dynamic>>();
    final workflowAudit = downstreamBindingAudit.firstWhere(
        (entry) => entry['capability_id'] == 'workflow_collaboration_export');
    expect(workflowAudit['active_provider_ref'], 'n8n');
    expect(workflowAudit['runtime_loaded'], isTrue);
    expect(workflowAudit['external_runtime_executed'], isFalse);
    expect(workflowAudit['workflow_executed'], isFalse);
    final coverageAudit = jsonDecode(File(
            runtimeStatus['provider_integration_coverage_audit_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(coverageAudit['status'], 'passed');
    expect(coverageAudit['provider_mapping_count'], 29);
    expect(coverageAudit['covered_mapping_count'], 29);
    expect(coverageAudit['failed_mapping_count'], 0);
    expect(coverageAudit['external_runtime_executed'], isFalse);
    expect(coverageAudit['workflow_executed'], isFalse);
    final n8nCoverage = (coverageAudit['coverage_rows'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['provider_ref'] == 'n8n' &&
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(n8nCoverage['runtime_loaded'], isTrue);
    expect(n8nCoverage['coverage_status'], 'passed');
    expect(n8nCoverage['missing_evidence'], isEmpty);
    final userCatalog = jsonDecode(
        File(runtimeStatus['provider_capability_user_catalog_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(userCatalog['runtime_loaded_capability_count'], 1);
    final workflowCatalogEntry = (userCatalog['entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(workflowCatalogEntry['display_name'], 'A2A / 工作流导出');
    expect(workflowCatalogEntry['runtime_loaded'], isTrue);
    expect(workflowCatalogEntry['current_behavior'], contains('健康检查通过'));
    expect(jsonEncode(userCatalog), isNot(contains('n8n')));

    final rolledBack = await controller.rollbackN8nProviderRuntime();
    expect(rolledBack, isTrue);
    final rollbackManifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(rollbackManifest['action'], 'rollback');
    expect(rollbackManifest['runtime_loaded'], isFalse);
    expect(rollbackManifest['runtime_loaded_count'], 0);
    expect(rollbackManifest['status'], '降级为本地模式');
    final rollbackFromManifestPath =
        rollbackManifest['rollback_from_manifest_path'] as String;
    expect(File(rollbackFromManifestPath).existsSync(), isTrue);
    final runtimeLoadLog = readJsonlFile(
        '$configDir${Platform.pathSeparator}provider_runtime_load_log.jsonl');
    expect(runtimeLoadLog.map((row) => row['action']).toList(),
        containsAllInOrder(['load', 'rollback']));
    expect(runtimeLoadLog.last['runtime_loaded_after_event'], isFalse);
    expect(runtimeLoadLog.last['workflow_executed'], isFalse);

    final rollbackRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final rollbackSummary =
        rollbackRuntimeStatus['provider_runtime_load_summary']
            as Map<String, dynamic>;
    expect(rollbackSummary['runtime_loaded'], isFalse);
    expect(rollbackSummary['runtime_loaded_count'], 0);
    expect(
        (rollbackRuntimeStatus['registered_provider_summary']
            as Map)['external_runtime_loaded_count'],
        0);
    final rollbackMatrix = jsonDecode(File(
            rollbackRuntimeStatus['registered_provider_integration_matrix_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final rollbackN8nMatrixEntry = (rollbackMatrix['provider_entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['provider_ref'] == 'n8n' &&
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(rollbackN8nMatrixEntry['runtime_loaded'], isFalse);
    expect(
        (rollbackMatrix['registered_project_boundary']
            as Map)['loaded_project_count'],
        0);
    final rollbackEligibility = jsonDecode(File(rollbackRuntimeStatus[
            'provider_runtime_load_eligibility_manifest_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackEligibility['runtime_loaded_count'], 0);
    final rollbackBinding = jsonDecode(File(
            rollbackRuntimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackBinding['registered_provider_loaded_count'], 0);
    final rollbackWorkflowBinding = (rollbackBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(rollbackWorkflowBinding['runtime_loaded'], isFalse);
    final rollbackCoverageAudit = jsonDecode(File(
            rollbackRuntimeStatus['provider_integration_coverage_audit_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackCoverageAudit['status'], 'passed');
    final rollbackN8nCoverage = (rollbackCoverageAudit['coverage_rows'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['provider_ref'] == 'n8n' &&
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(rollbackN8nCoverage['runtime_loaded'], isFalse);
    final rollbackUserCatalog = jsonDecode(File(
            rollbackRuntimeStatus['provider_capability_user_catalog_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackUserCatalog['runtime_loaded_capability_count'], 0);
    final rollbackWorkflowCatalogEntry =
        (rollbackUserCatalog['entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) =>
                entry['capability_id'] == 'workflow_collaboration_export');
    expect(rollbackWorkflowCatalogEntry['runtime_loaded'], isFalse);
    expect(
        rollbackWorkflowCatalogEntry['current_behavior'], contains('本地协作报告'));
    final rollbackAgentStatus = (rollbackRuntimeStatus['module_status']
        as Map)['agent_workbench'] as Map;
    expect(rollbackAgentStatus['a2a_workflow_runtime_status'], '降级为本地模式');
    expect(rollbackAgentStatus['a2a_workflow_runtime_loaded'], isFalse);
    expect(rollbackAgentStatus['a2a_workflow_fallback'], contains('本地协作报告'));
    final rollbackLifecycleAudit = jsonDecode(File(
            rollbackRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        (rollbackLifecycleAudit['provider_counts']
            as Map)['runtime_loaded_count'],
        0);
    expect(
        (rollbackLifecycleAudit['event_counts']
            as Map)['runtime_load_event_count'],
        2);
    expect(
        (rollbackLifecycleAudit['event_counts'] as Map)['rollback_event_count'],
        1);
    expect(
        ((rollbackLifecycleAudit['event_counts'] as Map)['runtime_load_actions']
            as Map)['rollback'],
        1);
  });

  test('stage3 rtk runtime load uses agent health check only', () async {
    final workspace = await createWorkspace();
    writeStage2PreflightFixture(workspace);
    writeStage2SkillRuntimeFixture(workspace);
    writeStage2AgentPermissionFixture(workspace);
    writeStage2IndustrialSmokeFixture(workspace);
    writeStage2ExeLaunchSmokeFixture(workspace);
    writeN8nReadinessFixture(workspace);
    final previousHttpOverride = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() {
      HttpOverrides.global = previousHttpOverride;
    });
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
    });
    final requests = <String>[];
    unawaited(() async {
      await for (final request in server) {
        requests.add(request.uri.path);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write('{"status":"ok"}');
        await request.response.close();
      }
    }());
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    const sensitiveValue = 'rtk-sensitive-value';
    final loaded = await controller.loadRtkProviderRuntime(
      endpoint: 'http://${server.address.host}:${server.port}?secret=redacted',
      apiKey: sensitiveValue,
    );
    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final manifestPath =
        '$configDir${Platform.pathSeparator}provider_runtime_load_manifest.json';
    final manifestRaw = File(manifestPath).readAsStringSync();
    expect(loaded, isTrue, reason: manifestRaw);
    final manifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['provider_ref'], 'rtk');
    expect(manifest['capability_id'], 'agent_model_tools_memory');
    expect(manifest['runtime_loaded'], isTrue);
    expect(manifest['runtime_loaded_count'], 1);
    expect(manifest['external_runtime_connected'], isTrue);
    expect(manifest['external_runtime_executed'], isFalse);
    expect(manifest['workflow_executed'], isFalse);
    expect(manifest['secret_plaintext_written'], isFalse);
    expect(manifest['sanitized_endpoint'],
        'http://${server.address.host}:${server.port}');
    expect(
        File(manifestPath).readAsStringSync(), isNot(contains(sensitiveValue)));
    final probe =
        jsonDecode(File(manifest['probe_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(
        probe['schema_version'], 'prd_v3_provider_runtime_load_probe_rtk.v1');
    expect(probe['probe_kind'], 'safe_agent_runtime_health_check_only');
    expect(probe['health_path'], '/health');
    expect(probe['runtime_loaded'], isTrue);
    expect(probe['agent_tool_executed'], isFalse);
    expect(probe['external_runtime_executed'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(requests, ['/health']);

    final configLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(configLog, contains('"config_id":"rtk"'));
    expect(configLog, isNot(contains(sensitiveValue)));
    expect(configLog, isNot(contains('secret=redacted')));

    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final loadSummary =
        runtimeStatus['provider_runtime_load_summary'] as Map<String, dynamic>;
    expect(loadSummary['provider_ref'], 'rtk');
    expect(loadSummary['runtime_loaded'], isTrue);
    expect(loadSummary['runtime_loaded_count'], 1);
    expect(loadSummary['external_runtime_executed'], isFalse);
    expect(loadSummary['workflow_executed'], isFalse);
    final binding = jsonDecode(File(
            runtimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final agentBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'agent_model_tools_memory');
    expect(agentBinding['active_provider_ref'], 'rtk');
    expect(agentBinding['runtime_loaded'], isTrue);
    expect(agentBinding['external_runtime_executed'], isFalse);
    expect(agentBinding['workflow_executed'], isFalse);
    final coverageAudit = jsonDecode(File(
            runtimeStatus['provider_integration_coverage_audit_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(coverageAudit['external_runtime_executed'], isFalse);
    expect(coverageAudit['workflow_executed'], isFalse);
    final rtkCoverage = (coverageAudit['coverage_rows'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['provider_ref'] == 'rtk');
    expect(rtkCoverage['runtime_loaded'], isTrue);
    expect(rtkCoverage['coverage_status'], 'passed');

    final rolledBack = await controller.rollbackRtkProviderRuntime();
    expect(rolledBack, isTrue);
    final rollbackManifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(rollbackManifest['provider_ref'], 'rtk');
    expect(rollbackManifest['action'], 'rollback');
    expect(rollbackManifest['runtime_loaded'], isFalse);
    expect(rollbackManifest['runtime_loaded_count'], 0);
    expect(rollbackManifest['external_runtime_executed'], isFalse);
    expect(rollbackManifest['agent_tool_executed'], isFalse);
    final rollbackFromManifestPath =
        rollbackManifest['rollback_from_manifest_path'] as String;
    expect(File(rollbackFromManifestPath).existsSync(), isTrue);
    final runtimeLoadLog = readJsonlFile(
        '$configDir${Platform.pathSeparator}provider_runtime_load_log.jsonl');
    expect(runtimeLoadLog.map((row) => row['action']).toList(),
        containsAllInOrder(['load', 'rollback']));
    expect(runtimeLoadLog.last['runtime_loaded_after_event'], isFalse);
    expect(runtimeLoadLog.last['external_runtime_executed'], isFalse);
    expect(runtimeLoadLog.last['workflow_executed'], isFalse);

    final rollbackRuntimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final rollbackSummary =
        rollbackRuntimeStatus['provider_runtime_load_summary']
            as Map<String, dynamic>;
    expect(rollbackSummary['provider_ref'], 'rtk');
    expect(rollbackSummary['runtime_loaded'], isFalse);
    expect(rollbackSummary['runtime_loaded_count'], 0);
    final rollbackBinding = jsonDecode(File(
            rollbackRuntimeStatus['provider_capability_binding_manifest_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final rollbackAgentBinding = (rollbackBinding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
            (entry) => entry['capability_id'] == 'agent_model_tools_memory');
    expect(rollbackAgentBinding['runtime_loaded'], isFalse);
    expect(rollbackAgentBinding['external_runtime_executed'], isFalse);
    expect(rollbackAgentBinding['workflow_executed'], isFalse);
    final rollbackCoverage = jsonDecode(File(
            rollbackRuntimeStatus['provider_integration_coverage_audit_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    final rollbackRtkCoverage = (rollbackCoverage['coverage_rows'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['provider_ref'] == 'rtk');
    expect(rollbackRtkCoverage['runtime_loaded'], isFalse);
    final rollbackLifecycleAudit = jsonDecode(File(
            rollbackRuntimeStatus['provider_lifecycle_audit_summary_path']
                as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        (rollbackLifecycleAudit['provider_counts']
            as Map)['runtime_loaded_count'],
        0);
    expect(
        ((rollbackLifecycleAudit['event_counts'] as Map)['runtime_load_actions']
            as Map)['rollback'],
        1);
  });

  test('stage3 live n8n endpoint runtime load uses health check only',
      () async {
    final endpoint = (Platform.environment['HEITANG_N8N_ENDPOINT'] ??
            Platform.environment['N8N_ENDPOINT'] ??
            '')
        .trim();
    expect(endpoint, isNotEmpty,
        reason: 'Set HEITANG_N8N_ENDPOINT or N8N_ENDPOINT for live n8n proof.');

    final workspace = await createWorkspace();
    writeStage2PreflightFixture(workspace);
    writeStage2SkillRuntimeFixture(workspace);
    writeStage2AgentPermissionFixture(workspace);
    writeStage2IndustrialSmokeFixture(workspace);
    writeStage2ExeLaunchSmokeFixture(workspace);
    writeN8nReadinessFixture(workspace);

    final previousHttpOverride = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() {
      HttpOverrides.global = previousHttpOverride;
    });

    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.testAllRegisteredProviderCapabilities();
    final loaded = await controller.loadN8nProviderRuntime(endpoint: endpoint);
    expect(loaded, isTrue);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final manifestPath =
        '$configDir${Platform.pathSeparator}provider_runtime_load_manifest.json';
    final manifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['runtime_loaded'], isTrue);
    expect(manifest['runtime_loaded_count'], 1);
    expect(manifest['external_runtime_connected'], isTrue);
    expect(manifest['external_runtime_executed'], isFalse);
    expect(manifest['workflow_executed'], isFalse);
    expect(manifest['secret_plaintext_written'], isFalse);

    final probe =
        jsonDecode(File(manifest['probe_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(probe['probe_kind'], 'safe_health_check_only');
    expect(probe['runtime_loaded'], isTrue);
    expect(probe['workflow_executed'], isFalse);
    expect(probe['secret_plaintext_written'], isFalse);
    expect(['/healthz', '/health', '/rest/settings'],
        contains(probe['health_path']));

    final runtimeStatus = jsonDecode(File(
            '$configDir${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final summary =
        runtimeStatus['provider_runtime_load_summary'] as Map<String, dynamic>;
    expect(summary['runtime_loaded'], isTrue);
    expect(summary['runtime_loaded_count'], 1);
    expect(summary['external_runtime_executed'], isFalse);
    expect(summary['workflow_executed'], isFalse);
    expect(
        (runtimeStatus['registered_provider_summary']
            as Map)['external_runtime_loaded_count'],
        1);
    final userCatalog = jsonDecode(
        File(runtimeStatus['provider_capability_user_catalog_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(userCatalog['runtime_loaded_capability_count'], 1);
    expect(jsonEncode(userCatalog), isNot(contains('n8n')));

    final rolledBack = await controller.rollbackN8nProviderRuntime();
    expect(rolledBack, isTrue);
    final rollbackManifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(rollbackManifest['runtime_loaded'], isFalse);
    expect(rollbackManifest['runtime_loaded_count'], 0);
    expect(rollbackManifest['workflow_executed'], isFalse);
  }, skip: Platform.environment['STAGE3_VERIFY_LIVE_N8N'] != '1');

  test('prd multi knowledge base catalog supports copy merge split delete',
      () async {
    final workspace = await createWorkspace();
    final input = Directory('${workspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha real document');
    File('${input.path}${Platform.pathSeparator}beta.md')
        .writeAsStringSync('beta real document');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'source_path': input.path,
      'sources': [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
        },
        {
          'document_id': 'doc_beta',
          'source_name': 'beta.md',
          'relative_path': 'beta.md',
        },
      ],
    }));
    Directory('${workspace.path}${Platform.pathSeparator}du')
        .createSync(recursive: true);
    writeDuRecords(workspace, ['alpha.md', 'beta.md']);
    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}manifest.json')
              .writeAsStringSync('{"status":"searchable"}');
          final normalizedRoot =
              '${workspace.path}${Platform.pathSeparator}du${Platform.pathSeparator}normalized_sources';
          File('${output.path}${Platform.pathSeparator}chunks.jsonl')
              .writeAsStringSync(jsonl([
            {
              'chunk_id': 'c1',
              'source_path': '$normalizedRoot${Platform.pathSeparator}1.md',
            },
            {
              'chunk_id': 'c2',
              'source_path': '$normalizedRoot${Platform.pathSeparator}2.md',
            },
          ]));
          File('${output.path}${Platform.pathSeparator}cards.jsonl')
              .writeAsStringSync('{"title":"card"}\n');
          File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
              .writeAsStringSync('{"question":"q","answer":"a"}\n');
          File('${output.path}${Platform.pathSeparator}quality_report.json')
              .writeAsStringSync('{"status":"pass"}');
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.buildKnowledgeBase(documentIds: const ['doc_alpha']);
    expect(requests.single.actionId, 'knowledge_base_build');
    expectMainKnowledgeArtifacts(workspace, controller.state);
    expect(controller.state.knowledgeBases, hasLength(1));
    expect(controller.state.knowledgeBases.first.id, 'K1');
    expect(controller.state.knowledgeBases.first.sourceCount, 1);
    final firstCatalogFile = File(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}kb_catalog.json');
    final firstCatalog =
        jsonDecode(firstCatalogFile.readAsStringSync()) as Map<String, dynamic>;
    final firstRecord =
        ((firstCatalog['knowledge_bases'] as List).first as Map);
    final firstSources = (firstRecord['source_documents'] as List).cast<Map>();
    expect(firstSources.map((source) => source['document_id']), ['doc_alpha']);
    await controller.splitKnowledgeBase('K1');
    expect(controller.state.lastError, contains('不能拆分'));

    await controller
        .buildKnowledgeBase(documentIds: const ['doc_alpha', 'doc_beta']);
    expect(controller.state.knowledgeBases.first.sourceCount, 1);
    final fullKb =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K2');
    expect(fullKb.sourceCount, 2);

    await controller.copyKnowledgeBase('K1');
    expectIndustrialIndexArtifacts(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1_COPY1',
        kbId: 'K1_COPY1');
    await controller.mergeKnowledgeBases(['K1', 'K1_COPY1']);
    expectIndustrialIndexArtifacts(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K_MERGED1',
        kbId: 'K_MERGED1');
    await controller.splitKnowledgeBase('K2');
    expectIndustrialIndexArtifacts(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K2_SPLIT1',
        kbId: 'K2_SPLIT1');
    expect(controller.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2', 'K1_COPY1', 'K_MERGED1', 'K2_SPLIT1']));
    expect(controller.state.knowledgeBases.first.versionCount, 1);

    await controller.updateKnowledgeBaseIncremental('K1');
    expectIndustrialIndexArtifacts(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1',
        kbId: 'K1');
    final updatedK1 =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K1');
    expect(updatedK1.operation, 'incremental_update');
    expect(updatedK1.versionCount, 2);

    await controller.compareKnowledgeBaseVersions('K1');
    final comparedK1 =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K1');
    expect(comparedK1.versionComparePath, isNotEmpty);
    expect(File(comparedK1.versionComparePath).existsSync(), isTrue);

    await controller.rollbackKnowledgeBaseVersion('K1');
    expectIndustrialIndexArtifacts(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1',
        kbId: 'K1');
    final rolledBackK1 =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K1');
    expect(rolledBackK1.operation, 'rollback');
    expect(rolledBackK1.versionCount, 1);
    expect(
        File('${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1${Platform.pathSeparator}rollback.log')
            .existsSync(),
        isTrue);

    await controller.rebuildKnowledgeBaseFull('K2');
    expectIndustrialIndexArtifacts(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K2',
        kbId: 'K2');
    final rebuiltK2 =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K2');
    expect(rebuiltK2.operation, 'full_rebuild');

    final catalogFile = File(
        '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}kb_catalog.json');
    final catalog =
        jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
    expect(catalog['schema_version'], 'prd_v2_knowledge_base_catalog.v1');
    expect(catalog['knowledge_bases'], isA<List>());
    expect(
        File('${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K_MERGED1${Platform.pathSeparator}source_map.json')
            .existsSync(),
        isTrue);

    await controller.deleteKnowledgeBaseRecord('K1_COPY1');
    expect(controller.state.knowledgeBases.map((kb) => kb.id),
        isNot(contains('K1_COPY1')));
    expect(
        Directory(
                '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1_COPY1')
            .existsSync(),
        isFalse);
  });

  test('rc10 deleting one imported source removes it and keeps other files',
      () async {
    final workspace = await createWorkspace();
    final input = Directory('${workspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha real document');
    File('${input.path}${Platform.pathSeparator}beta.txt')
        .writeAsStringSync('beta real document');
    Directory('${workspace.path}${Platform.pathSeparator}kb')
        .createSync(recursive: true);
    File('${workspace.path}${Platform.pathSeparator}kb${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{}');
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.importFolderPath(input.path);
    await controller.deleteImportedSource('alpha.md');

    final manifest = jsonDecode(
        File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final sources = (manifest['sources'] as List).cast<Map>();
    expect(sources.map((source) => source['source_name']), ['beta.txt']);
    expect(
        File('${workspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}alpha.md')
            .existsSync(),
        isFalse);
    expect(
        File('${workspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}beta.txt')
            .existsSync(),
        isTrue);
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}kb').existsSync(),
        isFalse);
    expect(controller.state.sourceNames, ['beta.txt']);
    expect(controller.state.hasKnowledgeBase, isFalse);
  });

  test('prd external Skill import localizes real file content into workspace',
      () async {
    final workspace = await createWorkspace();
    final kb = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"kb.v1"}');
    File('${kb.path}${Platform.pathSeparator}chunks.jsonl').writeAsStringSync(
        '{"text":"本地知识库证据：外部 Skill 需要结合真实资料","source_path":"alpha.md","citation":"alpha.md#chunk=1"}\n');
    File('${kb.path}${Platform.pathSeparator}cards.jsonl')
        .writeAsStringSync('{"title":"本地化主题","summary":"真实资料融合"}\n');
    File('${kb.path}${Platform.pathSeparator}qa_pairs.jsonl')
        .writeAsStringSync('{"question":"如何本地化?","answer":"结合 KB 证据"}\n');
    final externalDir = Directory(
        '${workspace.path}${Platform.pathSeparator}external_skill_src')
      ..createSync(recursive: true);
    final externalSkill =
        File('${externalDir.path}${Platform.pathSeparator}SKILL.md')
          ..writeAsStringSync([
            'name: external-writing-skill',
            'version: 1.0.0',
            'description: External transformation writing Skill.',
            'inputs:',
            '  - local KB evidence',
            'outputs:',
            '  - cited Markdown',
            'instructions:',
            '  - 先识别受众，再输出可执行内容。',
            '  - 每个结论要能回到证据。',
            'acceptance:',
            '  - Output includes local evidence citations.',
            '',
            '## 方法论',
            '- 先识别受众，再输出可执行内容。',
            '- 每个结论要能回到证据。',
          ].join('\n'));
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.importExternalSkillPath(externalDir.path);

    final imported = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}external_imported_skill${Platform.pathSeparator}S0${Platform.pathSeparator}source${Platform.pathSeparator}SKILL.md');
    final externalManifest = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}external_imported_skill${Platform.pathSeparator}S0${Platform.pathSeparator}external_skill_manifest.json');
    final localized = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2${Platform.pathSeparator}SKILL.md');
    final localizedManifest = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2${Platform.pathSeparator}localized_skill_manifest.json');
    final diff = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2${Platform.pathSeparator}diff_summary.md');

    expect(imported.readAsStringSync(), contains('外部转化写作 Skill'));
    expect(
        externalManifest.readAsStringSync(),
        allOf(contains('"source_mode": "external_import"'),
            contains(externalSkill.path.replaceAll('\\', '\\\\'))));
    expect(localized.readAsStringSync(), contains('先识别受众'));
    expect(localizedManifest.readAsStringSync(),
        contains('"source_mode": "external_skill_fusion"'));
    expect(diff.readAsStringSync(), contains('不会执行外部代码或系统命令'));
    final history = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_history.json');
    expect(history.readAsStringSync(),
        contains('"action": "import_external_skill"'));
    expect(history.readAsStringSync(), contains('"status": "completed"'));
    expect(controller.state.hasSkill, isTrue);
  });

  test('prd external Skill import rejects dangerous external content',
      () async {
    final workspace = await createWorkspace();
    final kb = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"kb.v1"}');
    final externalDir = Directory(
        '${workspace.path}${Platform.pathSeparator}dangerous_external_skill')
      ..createSync(recursive: true);
    final dangerousSkill =
        File('${externalDir.path}${Platform.pathSeparator}SKILL.md')
          ..writeAsStringSync([
            'name: dangerous',
            'version: 1.0.0',
            'description: bad',
            'inputs: []',
            'outputs: []',
            'instructions: overwrite system C:\\Windows',
            'acceptance: []',
          ].join('\n'));
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.importExternalSkillPath(externalDir.path);

    final history = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_history.json');
    expect(history.readAsStringSync(),
        contains('"action": "import_external_skill"'));
    expect(history.readAsStringSync(), contains('"status": "failed"'));
    expect(history.readAsStringSync(),
        contains('"reason": "dangerous_override_rejected"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2${Platform.pathSeparator}localized_skill_manifest.json')
            .existsSync(),
        isFalse);
    expect(dangerousSkill.existsSync(), isTrue);
  });

  test('rc6 search clears stale query output before reading real results',
      () async {
    final workspace = await createWorkspace();
    final kb = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{}');
    File('${kb.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync('{"text":"heitang-rc6-needle"}\n');
    final stale = Directory('${workspace.path}${Platform.pathSeparator}query')
      ..createSync(recursive: true);
    File('${stale.path}${Platform.pathSeparator}stale.txt')
        .writeAsStringSync('old');

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)..createSync();
          final payload = {
            'selected_count': 1,
            'selected': [
              {
                'source_path': 'rc6_truth_source.md',
                'text': 'contains heitang-rc6-needle from real KB',
                'score': 1.0,
              }
            ],
          };
          File('${output.path}${Platform.pathSeparator}kb_query_result.json')
              .writeAsStringSync(
                  const JsonEncoder.withIndent('  ').convert(payload));
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.search('heitang-rc6-needle');

    expect(requests.single.actionId, 'rag_query');
    expect(requests.single.arguments, contains('kb-query'));
    expect(File('${stale.path}${Platform.pathSeparator}stale.txt').existsSync(),
        isFalse);
    expect(controller.state.searchStatus, Rc6SearchStatus.success);
    expect(controller.state.searchResults.single.excerpt,
        contains('heitang-rc6-needle'));
  });

  test('prd multi knowledge base retrieval merges and attributes results',
      () async {
    final workspace = await createWorkspace();
    final kbRoot =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    for (final id in ['K1', 'K2']) {
      final dir = Directory('${kbRoot.path}${Platform.pathSeparator}$id')
        ..createSync(recursive: true);
      File('${dir.path}${Platform.pathSeparator}manifest.json')
          .writeAsStringSync('{"status":"searchable"}');
      File('${dir.path}${Platform.pathSeparator}chunks.jsonl')
          .writeAsStringSync('{"chunk_id":"$id-c1"}\n');
    }
    File('${kbRoot.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': 'Alpha KB',
          'kb_type': '基础知识库',
          'status': 'searchable',
          'operation': 'build',
          'source_documents': [
            {'source_name': 'alpha.md'}
          ],
          'chunk_count': 1,
        },
        {
          'kb_id': 'K2',
          'kb_name': 'Beta KB',
          'kb_type': '基础知识库',
          'status': 'searchable',
          'operation': 'build',
          'source_documents': [
            {'source_name': 'beta.md'}
          ],
          'chunk_count': 1,
        },
      ],
    }));

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          final kbId = request.outputPath!.split(Platform.pathSeparator).last;
          final score = kbId == 'K2' ? 0.92 : 0.51;
          final payload = {
            'selected_count': 1,
            'selected': [
              {
                'chunk_id': '$kbId-c1',
                'source_path': '$kbId-source.md',
                'text': '$kbId contains multi kb retrieval needle',
                'score': score,
              }
            ],
          };
          File('${output.path}${Platform.pathSeparator}kb_query_result.json')
              .writeAsStringSync(
                  const JsonEncoder.withIndent('  ').convert(payload));
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.searchKnowledgeBases('multi kb retrieval needle', [
      'K1',
      'K2',
    ]);

    expect(requests, hasLength(2));
    expect(
        requests.map((request) => request.arguments),
        everyElement(
          allOf(contains('kb-query'), contains('multi kb retrieval needle')),
        ));
    final resultFile = File(
        '${workspace.path}${Platform.pathSeparator}query${Platform.pathSeparator}multi_kb_query_result.json');
    expect(resultFile.existsSync(), isTrue);
    final result =
        jsonDecode(resultFile.readAsStringSync()) as Map<String, dynamic>;
    expect(result['schema_version'], 'prd_v3_multi_kb_query_result.v1');
    expect(result['selected_kb_ids'], ['K1', 'K2']);
    expect(result['retrieval_plan_path'], contains('retrieval_plan.json'));
    expect(result['rerank_report_path'], contains('rerank_report.json'));
    expect(result['citation_coverage_report_path'],
        contains('citation_coverage_report.json'));
    expect(result['conflict_report_path'], contains('conflict_report.json'));
    expect(result['external_validation_boundary_path'],
        contains('external_validation_boundary.json'));
    final rows = (result['results'] as List).cast<Map>();
    expect(rows.map((row) => row['kb_id']), ['K2', 'K1']);
    expect(rows.first['kb_name'], 'Beta KB');
    expect(controller.state.searchStatus, Rc6SearchStatus.success);
    expect(controller.state.searchResults.map((row) => row.kbName),
        ['Beta KB', 'Alpha KB']);
    expect(controller.state.queryResultPath, resultFile.path);
    expect(controller.state.retrievalPlanPath, isNotEmpty);
    expect(controller.state.retrievalRerankReportPath, isNotEmpty);
    expect(controller.state.retrievalCitationCoveragePath, isNotEmpty);
    expect(controller.state.retrievalConflictReportPath, isNotEmpty);
    expect(controller.state.externalValidationBoundaryPath, isNotEmpty);
    expect(File(controller.state.retrievalPlanPath).readAsStringSync(),
        contains('prd_v3_retrieval_plan.v1'));
    expect(File(controller.state.retrievalRerankReportPath).readAsStringSync(),
        allOf(contains('prd_v3_retrieval_rerank_report.v1'), contains('K2')));
    expect(
        File(controller.state.retrievalCitationCoveragePath).readAsStringSync(),
        contains('prd_v3_retrieval_citation_coverage.v1'));
    expect(
        File(controller.state.retrievalConflictReportPath).readAsStringSync(),
        contains('prd_v3_retrieval_conflict_report.v1'));
    expect(
        File(controller.state.externalValidationBoundaryPath)
            .readAsStringSync(),
        allOf(
          contains('prd_v3_external_validation_boundary.v1'),
          contains('"external_calls_made": false'),
        ));

    final validationPath = await controller.saveRetrievalValidationReport({
      0: 'keep',
      1: 'contradiction',
    });
    final validationFile = File(validationPath);
    expect(validationFile.existsSync(), isTrue);
    final validation =
        jsonDecode(validationFile.readAsStringSync()) as Map<String, dynamic>;
    expect(
        validation['schema_version'], 'prd_v3_retrieval_validation_report.v1');
    expect(validation['result_count'], 2);
    expect(validation['conflict_count'], 1);
    expect(validation['correction_status'], 'reviewed');
    expect(validation['review_mode'], 'manual_correction');
    expect(
        (validation['review_evidence'] as Map)['manual_correction_count'], 2);
    expect((validation['review_evidence'] as Map)['reviewed_result_count'], 2);
    expect(
        (validation['review_evidence'] as Map)['external_calls_made'], isFalse);
    expect((validation['review_evidence'] as Map)['secret_plaintext_written'],
        isFalse);
    expect(
        validation['retrieval_plan_path'], controller.state.retrievalPlanPath);
    expect(validation['rerank_report_path'],
        controller.state.retrievalRerankReportPath);
    expect(validation['citation_coverage_report_path'],
        controller.state.retrievalCitationCoveragePath);
    expect(validation['conflict_report_path'],
        controller.state.retrievalConflictReportPath);
    expect(validation['external_validation_boundary_path'],
        controller.state.externalValidationBoundaryPath);
    expect(controller.state.retrievalValidationReportPath, validationPath);
    final corrections = (validation['manual_corrections'] as List).cast<Map>();
    expect(corrections.last['decision'], 'contradiction');
    expect(corrections.last['normalized_decision'], 'conflict');
    final validationMarkdown = File(
        '${workspace.path}${Platform.pathSeparator}query${Platform.pathSeparator}validation_report.md');
    expect(validationMarkdown.existsSync(), isTrue);
    expect(controller.state.retrievalValidationMarkdownPath,
        validationMarkdown.path);
    expect(
        validationMarkdown.readAsStringSync(),
        allOf(
          contains('# 检索验证报告'),
          contains('Alpha KB'),
          contains('Beta KB'),
          contains('contradiction'),
          contains('K1-source.md'),
        ));
    final validationHistory = File(
        '${workspace.path}${Platform.pathSeparator}query${Platform.pathSeparator}validation_history.jsonl');
    expect(validationHistory.existsSync(), isTrue);
    expect(controller.state.retrievalValidationHistoryPath,
        validationHistory.path);
    final historyLines = validationHistory.readAsLinesSync();
    expect(historyLines, hasLength(1));
    final historyRow = jsonDecode(historyLines.single) as Map<String, dynamic>;
    expect(historyRow['selected_kb_ids'], ['K1', 'K2']);
    expect(historyRow['conflict_count'], 1);
    expect(
        historyRow['retrieval_plan_path'], controller.state.retrievalPlanPath);
    expect(historyRow['markdown_report_path'], validationMarkdown.path);

    final reloadedController = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    await reloadedController.initialize();
    expect(reloadedController.state.queryResultPath, resultFile.path);
    expect(reloadedController.state.retrievalPlanPath,
        controller.state.retrievalPlanPath);
    expect(reloadedController.state.retrievalRerankReportPath,
        controller.state.retrievalRerankReportPath);
    expect(
        reloadedController.state.retrievalValidationReportPath, validationPath);
  });

  test(
      'rc6 real input folder chain uses allowlisted Core actions and artifacts',
      () async {
    final workspace = await createWorkspace();
    final input =
        Directory('${workspace.path}${Platform.pathSeparator}input_src')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.pdf')
        .writeAsStringSync('alpha pdf text 赚钱 小生意');
    File(
        '${input.path}${Platform.pathSeparator}nested${Platform.pathSeparator}beta.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('beta text');

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'batch_import_documents':
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync(
                      const JsonEncoder.withIndent('  ').convert({
                'status': 'completed',
                'imported_count': 2,
              }));
            case 'document_understanding':
              expect(request.arguments, contains('--runtime-config'));
              writeDuRecords(workspace, ['alpha.pdf', 'nested/beta.txt']);
              final duManifest = {
                'status': 'completed',
                'success_count': 2,
                'failed_count': 0,
                'normalized_source_count': 2,
              };
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync(
                      const JsonEncoder.withIndent('  ').convert(duManifest));
              Directory(
                      '${output.path}${Platform.pathSeparator}normalized_sources')
                  .createSync();
            case 'knowledge_base_build':
              File('${output.path}${Platform.pathSeparator}manifest.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}quality_report.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}knowledge_base_build_report.json')
                  .writeAsStringSync('{"source_count":2}');
              final normalizedRoot =
                  '${workspace.path}${Platform.pathSeparator}du${Platform.pathSeparator}normalized_sources';
              File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                  .writeAsStringSync(jsonl([
                {
                  'text': '赚钱 小生意',
                  'source_path': '$normalizedRoot${Platform.pathSeparator}1.md',
                  'citation': 'alpha.pdf#chunk=1',
                },
              ]));
              File('${output.path}${Platform.pathSeparator}cards.jsonl')
                  .writeAsStringSync('{"title":"赚钱小生意","summary":"真实主题"}\n');
              File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                  .writeAsStringSync(
                      '{"question":"主题是什么?","answer":"赚钱小生意"}\n');
            case 'rag_query':
              File('${output.path}${Platform.pathSeparator}kb_query_result.json')
                  .writeAsStringSync(
                      const JsonEncoder.withIndent('  ').convert({
                'query': '赚钱 小生意',
                'selected_count': 1,
                'records': [
                  {
                    'source_path': 'alpha.pdf',
                    'text': '真实输入命中赚钱小生意',
                    'citation': 'alpha.pdf#chunk=1',
                    'score': 2,
                  }
                ],
              }));
            case 'generate_markdown':
              File('${output.path}${Platform.pathSeparator}generated.md')
                  .writeAsStringSync('# generated from real input');
            case 'generate_docx':
              writeGeneratedDocumentExport(output, 'docx');
            case 'generate_pdf':
              writeGeneratedDocumentExport(output, 'pdf');
            case 'generate_pptx':
              writeGeneratedDocumentExport(output, 'pptx');
            case 'package_to_skill':
              File('${output.path}${Platform.pathSeparator}SKILL.md')
                  .writeAsStringSync('# skill');
              File('${output.path}${Platform.pathSeparator}skill_manifest.yaml')
                  .writeAsStringSync('name: skill');
            case 'kb_bound_agent_generation':
              File('${output.path}${Platform.pathSeparator}agent_manifest.json')
                  .writeAsStringSync('{"name":"agent"}');
              File('${output.path}${Platform.pathSeparator}agent_profile.yaml')
                  .writeAsStringSync('name: agent');
          }
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.runRealInputFolderE2E(input.path);

    final smokeReport = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}industrial_exe_smoke_report.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        smokeReport['schema_version'], 'prd_v3_industrial_exe_smoke_report.v1');
    final failedSmokeSteps = (smokeReport['step_results'] as List)
        .cast<Map<String, dynamic>>()
        .where((step) => step['status'] != 'passed')
        .map((step) =>
            '${step['step_id']}: ${step['artifact']} ${step['detail']}')
        .join('\n');
    expect(smokeReport['status'], 'passed', reason: failedSmokeSteps);
    expect(smokeReport['step_count'], 38);
    expect(smokeReport['failed_step_ids'], isEmpty);
    expect(smokeReport['secret_plaintext_written'], isFalse);
    expect(smokeReport['external_runtime_loaded'], isFalse);
    for (final step
        in (smokeReport['step_results'] as List).cast<Map<String, dynamic>>()) {
      expect(step['status'], 'passed', reason: jsonEncode(step));
      final artifact = (step['artifact'] ?? '').toString();
      expect(artifact, isNotEmpty, reason: jsonEncode(step));
      expect(
        File(artifact).existsSync() || Directory(artifact).existsSync(),
        isTrue,
        reason: artifact,
      );
    }
    for (final kbId in ['K1', 'K2', 'K3']) {
      final kbRoot =
          '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$kbId';
      expect(File('$kbRoot${Platform.pathSeparator}manifest.json').existsSync(),
          isTrue);
      expect(
          File('$kbRoot${Platform.pathSeparator}prd_kb_manifest.json')
              .existsSync(),
          isTrue);
      expectIndustrialIndexArtifacts(kbRoot, kbId: kbId);
      expect(readJsonlFile('$kbRoot${Platform.pathSeparator}chunks.jsonl'),
          isNotEmpty);
    }
    final multiKbQuery = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}query${Platform.pathSeparator}multi_kb_query_result.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(multiKbQuery['schema_version'], 'prd_v3_multi_kb_query_result.v1');
    expect(multiKbQuery['selected_kb_ids'], containsAll(['K1', 'K2', 'K3']));
    final multiRows = (multiKbQuery['results'] as List).cast<Map>();
    expect(multiRows.map((row) => row['kb_id']).toSet(),
        containsAll(['K1', 'K2', 'K3']));
    for (final relative in [
      'config${Platform.pathSeparator}provider_runtime_settings.json',
      'config${Platform.pathSeparator}storage_provider_settings.json',
      'config${Platform.pathSeparator}exporter_settings.json',
      'workbooks${Platform.pathSeparator}workbook_manifest.json',
    ]) {
      expect(
          File('${workspace.path}${Platform.pathSeparator}$relative')
              .existsSync(),
          isTrue);
    }

    expect(requests.map((request) => request.actionId), [
      'batch_import_documents',
      'document_understanding',
      'knowledge_base_build',
      'rag_query',
      'generate_markdown',
      'package_to_skill',
      'kb_bound_agent_generation',
    ]);
    expect(controller.state.sourceCount, 2);
    expect(controller.state.chunkCount, 1);
    expect(controller.state.cardsPath, isNotEmpty);
    expect(controller.state.qaPairsPath, isNotEmpty);
    expectMainKnowledgeArtifacts(workspace, controller.state);
    expect(controller.state.hasReadingNotes, isTrue);
    expect(controller.state.hasMultiAgentDiscussion, isTrue);
    expect(controller.state.hasMultiAgentDiscussionManifest, isTrue);
    expect(controller.state.hasA2aSessionManifest, isTrue);
    expect(controller.state.hasA2aConflictReport, isTrue);
    expect(controller.state.hasA2aConsensusReport, isTrue);
    expect(controller.state.hasAgentWorkspacePermissionMatrix, isTrue);
    expect(controller.state.hasAgentValidationReport, isTrue);
    expect(controller.state.a2aSessionId, 'A2A_001');
    expect(controller.state.a2aTopic, '赚钱 小生意');
    expect(controller.state.a2aParticipantAgentIds,
        contains('product_analysis_agent'));
    expect(controller.state.a2aEvidenceCount, greaterThan(0));
    expect(controller.state.a2aStatus, 'report_generated');
    final baseTurnCount = controller.state.agentDialogueTurnCount;
    await controller.runAgentDialogue(prompt: '总结真实输入主题');
    await controller.runAgentDialogue(prompt: '继续追问行动建议');
    expect(controller.state.hasAgentDialogue, isTrue);
    expect(controller.state.hasAgentDialogueManifest, isTrue);
    expect(controller.state.hasAgentDialogueHistory, isTrue);
    expect(controller.state.agentDialogueTurnCount, baseTurnCount + 2);
    expect(controller.state.agentDialogueModelConfigId,
        'local-default-or-configured-provider');
    expect(controller.state.agentDialogueUsedKbIds, contains('K1'));
    expect(controller.state.agentDialogueUsedSkillIds, contains('S1'));
    expect(controller.state.agentDialogueOutputFormat, 'markdown');
    expect(controller.state.agentDialogueEvidenceCount, greaterThan(0));
    expect(controller.state.agentDialogueMemoryWriteStatus,
        'local_session_written');
    expect(controller.state.agentDialogueErrorMessage, isEmpty);
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}agent_dialogue.md')
            .readAsStringSync(),
        contains('总结真实输入主题'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}agent_dialogue.md')
            .readAsStringSync(),
        contains('继续追问行动建议'));
    final chatHistory = File(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}chat_history.jsonl');
    expect(chatHistory.readAsLinesSync(), hasLength(baseTurnCount + 2));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}agent_dialogue_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('"turn_count": ${baseTurnCount + 2}'),
          contains('"memory_write_status": "local_session_written"'),
          contains('"used_skill_ids"'),
        ));
    final dialogueExportPath = await controller.exportAgentDialogue();
    expect(dialogueExportPath, endsWith('agent_dialogue_export.md'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export${Platform.pathSeparator}agent_dialogue_export.md')
            .readAsStringSync(),
        allOf(
          contains('Agent 对话导出'),
          contains('总结真实输入主题'),
          contains('继续追问行动建议'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export${Platform.pathSeparator}agent_dialogue_export_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_agent_dialogue_export.v1'),
          contains('"turn_count": ${baseTurnCount + 2}'),
          contains('"secret_plaintext_written": false'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}run_history.json')
            .readAsStringSync(),
        allOf(
          contains('"action": "run_agent_dialogue"'),
          contains('"action": "export_agent_dialogue"'),
          contains(
              '"artifact": "${dialogueExportPath.replaceAll(r'\', r'\\')}"'),
        ));
    final orchestrationPlanPath =
        '${workspace.path}${Platform.pathSeparator}orchestration${Platform.pathSeparator}orchestration_plan.jsonl';
    final orchestrationRecords = readJsonlFile(orchestrationPlanPath);
    expect(orchestrationRecords, isNotEmpty);
    expect(
        orchestrationRecords.every((record) =>
            record['schema_version'] == 'prd_v3_orchestration_plan_record.v1'),
        isTrue);
    expect(orchestrationRecords.map((record) => record['layer']),
        containsAll(['document', 'skill', 'agent']));
    expect(
        orchestrationRecords.map((record) => record['action']),
        containsAll([
          'generate_document',
          'export_document',
          'generate_skill',
          'generate_agent',
          'run_agent_dialogue',
          'export_agent_dialogue',
        ]));
    expect(
        orchestrationRecords.any((record) =>
            record['action'] == 'export_document' &&
            ((record['resources'] as Map)['format'] == 'json')),
        isTrue);
    expect(
        orchestrationRecords.every((record) =>
            ((record['boundary'] as Map)['okf_runtime_enabled']) == false),
        isTrue);
    final reloadedController = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    await reloadedController.initialize();
    expectMainKnowledgeArtifacts(workspace, reloadedController.state);
    expect(reloadedController.state.hasAgentDialogueHistory, isTrue);
    expect(reloadedController.state.hasAgentDialogueManifest, isTrue);
    expect(reloadedController.state.hasAgentDialogueExport, isTrue);
    expect(reloadedController.state.hasA2aSessionManifest, isTrue);
    expect(reloadedController.state.hasA2aConflictReport, isTrue);
    expect(reloadedController.state.hasA2aConsensusReport, isTrue);
    expect(reloadedController.state.hasAgentWorkspacePermissionMatrix, isTrue);
    expect(reloadedController.state.hasAgentValidationReport, isTrue);
    expect(reloadedController.state.a2aSessionId, 'A2A_001');
    expect(reloadedController.state.a2aParticipantAgentIds,
        contains('knowledge_qa_agent'));
    expect(reloadedController.state.a2aEvidenceCount, greaterThan(0));
    expect(reloadedController.state.agentDialogueExportPath,
        endsWith('agent_dialogue_export.md'));
    expect(reloadedController.state.agentDialogueTurnCount, baseTurnCount + 2);
    expect(reloadedController.state.agentDialogueUsedKbIds, contains('K1'));
    expect(reloadedController.state.agentDialogueUsedSkillIds, contains('S1'));
    expect(reloadedController.state.agentDialogueEvidenceCount, greaterThan(0));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}citation_trace.jsonl')
            .readAsStringSync(),
        contains('prd_v3_agent_citation_trace_record.v1'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}skill_rule_trace.jsonl')
            .readAsStringSync(),
        allOf(
          contains('prd_v3_agent_skill_rule_trace_record.v1'),
          contains('citation_required'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}doc${Platform.pathSeparator}reading_notes.md')
            .readAsStringSync(),
        contains('真实输入文件夹读书笔记'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured${Platform.pathSeparator}knowledge_export.json')
            .readAsStringSync(),
        contains('prd_v2_structured_document_export_payload.v1'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured${Platform.pathSeparator}knowledge_export.csv')
            .readAsStringSync(),
        contains('retrieval_result'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}skill_generation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('rc10_real_input_skill_generation.v1'),
          contains('from_multi_kb'),
          contains('delete_with_confirmation'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_skill_operations.v1'),
          contains('fusion'),
          contains('requires_confirmation'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}exports${Platform.pathSeparator}skills_export.md')
            .readAsStringSync(),
        contains('Skill 导出包'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}fused_product_ops_skill${Platform.pathSeparator}SKILL.md')
            .readAsStringSync(),
        contains('融合产品运营 Skill'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations${Platform.pathSeparator}agent_binding_manifest.json')
            .readAsStringSync(),
        contains('"status": "bound"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}agent_generation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('rc10_real_input_agent_generation.v1'),
          contains('simple_agents'),
          contains('advanced_agents'),
          contains('open_single_agent_chat'),
        ));
    final agentProfile = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}agent_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(agentProfile['schema_version'], 'prd_v3_agent_profile.v1');
    expect(agentProfile['agent_id'], 'knowledge_qa_agent');
    expect(agentProfile['workspace_id'], 'W_A');
    expect(agentProfile['citation_policy'], 'required');
    expect(agentProfile['tool_ids'], contains('video.generate'));
    final agentWorkspace = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspace_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(agentWorkspace['schema_version'], 'prd_v3_agent_workspace.v1');
    expect(agentWorkspace['authorized_kb_ids'], contains('K1'));
    expect(agentWorkspace['authorized_skill_ids'], contains('S1'));
    expect(agentWorkspace['blocked_tool_ids'], contains('video.generate'));
    final dependencyManifest = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dependency_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(dependencyManifest['schema_version'],
        'prd_v3_agent_dependency_manifest.v1');
    expect(dependencyManifest['can_chat_with_kb_skill'], isTrue);
    expect(dependencyManifest['can_call_video_tool'], isFalse);
    expect(dependencyManifest['missing_dependencies'].toString(),
        contains('video_custom_http_stub'));
    final agentStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(agentStatus['schema_version'], 'prd_v3_agent_status.v1');
    expect(agentStatus['status'], 'chat_ready');
    expect(agentStatus['dependency_status'], 'degraded_tool_unavailable');
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}product_config${Platform.pathSeparator}advanced_agent_config.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_agent_advanced_config.v1'),
          contains('"simple_agent"'),
          contains('"advanced_agent"'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}permission_audit.json')
            .readAsStringSync(),
        contains('no_arbitrary_shell'));
    final permissionMatrix = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}workspace_permission_matrix.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(permissionMatrix['schema_version'],
        'prd_v3_agent_workspace_permission_matrix.v1');
    expect(permissionMatrix['status'], 'pass');
    expect(permissionMatrix['violations'], isEmpty);
    expect(permissionMatrix['blocked_capabilities'],
        containsAll(['arbitrary_shell', 'computer_use']));
    final blockReport = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}unauthorized_access_block_report.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(blockReport['schema_version'],
        'prd_v3_agent_unauthorized_access_block_report.v1');
    expect(blockReport['status'], 'pass');
    expect(blockReport['unauthorized_resources_selectable'], isFalse);
    expect(blockReport['blocked_case_count'], greaterThanOrEqualTo(4));
    expect(blockReport['blocked_resource_types'],
        containsAll(['unauthorized_kb', 'non_allowlisted_tool']));
    final authAuditLines = File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}authorization_runtime_audit.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    expect(authAuditLines.length, greaterThanOrEqualTo(5));
    expect(
        authAuditLines.any((line) =>
            line.contains('tool_not_allowlisted') &&
            line.contains('"decision":"deny"')),
        isTrue);
    final agentValidation = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}agent_validation_report.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        agentValidation['schema_version'], 'prd_v3_agent_validation_report.v1');
    expect(agentValidation['status'], 'pass');
    expect(agentValidation['missing_required_artifacts'], isEmpty);
    expect(agentValidation['ready_for_single_agent_dialogue'], isTrue);
    expect(agentValidation['ready_for_a2a'], isTrue);
    expect(
        agentValidation['checks'].toString(),
        allOf(
          contains('unauthorized_access_blocked'),
          contains('unauthorized_access_block_report.json'),
          contains('authorization_runtime_audit.jsonl'),
        ));
    expect(
        agentValidation['checks'].toString(),
        allOf(
          contains('agent_profile_workspace_dependency_persisted'),
          contains('external_skill_tool_dependency_detected'),
          contains('tool_registry_allowlist_and_stub_recorded'),
        ));
    final externalSkillManifest = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}external_skills${Platform.pathSeparator}video_generation_skill${Platform.pathSeparator}external_skill_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(externalSkillManifest['schema_version'],
        'prd_v3_external_skill_manifest.v1');
    expect(externalSkillManifest['required_tools'], contains('video.generate'));
    final toolRegistry = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}tool${Platform.pathSeparator}tool_registry.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(toolRegistry['schema_version'], 'prd_v3_tool_registry.v1');
    expect(toolRegistry['allowlist'],
        containsAll(['kb_retrieval', 'document_export']));
    expect(toolRegistry['blocked_tools'], contains('video.generate'));
    final toolRequirement = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}tool${Platform.pathSeparator}tool_requirement_report.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        toolRequirement['schema_version'], 'prd_v3_tool_requirement_report.v1');
    expect(toolRequirement['api_called'], isFalse);
    expect(toolRequirement['status'], 'Tool 未授权');
    final videoTaskManifest = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}artifacts${Platform.pathSeparator}video${Platform.pathSeparator}video_task_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        videoTaskManifest['schema_version'], 'prd_v3_video_task_manifest.v1');
    expect(videoTaskManifest['fake_video_generated'], isFalse);
    expect(videoTaskManifest['api_called'], isFalse);
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}tool${Platform.pathSeparator}tool_call_log.jsonl')
            .readAsStringSync(),
        allOf(
          contains('prd_v3_tool_call_log_record.v1'),
          contains('video.generate'),
          contains('"api_called":false'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}tool${Platform.pathSeparator}tool_usage_report.json')
            .readAsStringSync(),
        contains('"total_api_calls": 0'));
    final runtimeStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final preflight =
        runtimeStatus['stage_2_industrial_preflight'] as Map<String, dynamic>;
    expect(preflight['failed_checks'],
        isNot(contains('industrial_exe_smoke_38_step')));
    expect(preflight['failed_checks'], contains('industrial_exe_launch_smoke'));
    final exeSmokeCheck = (preflight['checks'] as List).cast<Map>().firstWhere(
        (check) => check['check_id'] == 'industrial_exe_smoke_38_step');
    expect(exeSmokeCheck['status'], 'passed');
    final missingLaunchCheck = (preflight['checks'] as List)
        .cast<Map>()
        .firstWhere(
            (check) => check['check_id'] == 'industrial_exe_launch_smoke');
    expect(missingLaunchCheck['status'], 'failed');
    final acceptanceDir =
        Directory('${workspace.path}${Platform.pathSeparator}acceptance');
    final launchLogPath =
        '${acceptanceDir.path}${Platform.pathSeparator}exe_launch_smoke.log';
    File(launchLogPath)
        .writeAsStringSync('invalid placeholder EXE launch smoke evidence');
    final fakeExePath =
        '${acceptanceDir.path}${Platform.pathSeparator}heitang_workbench.exe';
    File(fakeExePath).writeAsStringSync('windows exe placeholder for smoke');
    File('${acceptanceDir.path}${Platform.pathSeparator}exe_launch_smoke_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_exe_launch_smoke_report.v1',
      'status': 'passed',
      'platform': 'windows',
      'exe_path': fakeExePath,
      'generated_by': 'manual_placeholder',
      'exe_size_bytes': 32,
      'exe_sha256':
          '0000000000000000000000000000000000000000000000000000000000000000',
      'exe_header': 'te',
      'workspace_path': workspace.path,
      'log_path': launchLogPath,
      'launched': true,
      'process_started': true,
      'process_id': 4242,
      'exit_code': null,
      'crashed': false,
      'startup_timeout': false,
      'secret_plaintext_written': false,
    }));
    await controller.testAllRegisteredProviderCapabilities();
    final launchRuntimeStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final launchPreflight = launchRuntimeStatus['stage_2_industrial_preflight']
        as Map<String, dynamic>;
    expect(launchPreflight['failed_checks'],
        contains('industrial_exe_launch_smoke'));
    final exeLaunchCheck = (launchPreflight['checks'] as List)
        .cast<Map>()
        .firstWhere(
            (check) => check['check_id'] == 'industrial_exe_launch_smoke');
    expect(exeLaunchCheck['status'], 'failed');
    expect(
        ((exeLaunchCheck['runtime_evidence'] as Map)['missing'] as List),
        containsAll([
          'generated_by_launch_script',
          'exe_header_mz',
          'exe_size_matches',
        ]));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}exports${Platform.pathSeparator}agent_package_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v3_agent_export_package.v1'),
          contains('agent_validation_report.json'),
          contains('workspace_permission_matrix.json'),
          contains('tool/tool_registry.json'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion.md')
            .readAsStringSync(),
        contains('每个 Agent 的观点'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion.md')
            .readAsStringSync(),
        contains('真实输入命中赚钱小生意'));
    final a2aConflict = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}a2a_conflict_report.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(a2aConflict['schema_version'], 'prd_v3_a2a_conflict_report.v1');
    expect(a2aConflict['round_count'], 3);
    expect(File(a2aConflict['round_log_path'] as String).existsSync(), isTrue);
    expect(
        File(a2aConflict['runtime_audit_path'] as String).existsSync(), isTrue);
    expect(a2aConflict['conflicts'], isA<List>());
    expect(a2aConflict['secret_plaintext_written'], isFalse);
    final a2aConsensus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}a2a_consensus_report.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(a2aConsensus['schema_version'], 'prd_v3_a2a_consensus_report.v1');
    expect(a2aConsensus['status'], 'pass');
    expect(a2aConsensus['round_count'], 3);
    expect(a2aConsensus['ready_for_export'], isTrue);
    final a2aSessionManifest = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001${Platform.pathSeparator}a2a_session_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        a2aSessionManifest['schema_version'], 'prd_v3_a2a_session_manifest.v1');
    expect(a2aSessionManifest['rounds'], 3);
    expect(a2aSessionManifest['round_limit'], 3);
    final roundLog = File(a2aSessionManifest['round_log_path'] as String)
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    final runtimeAudit =
        File(a2aSessionManifest['runtime_audit_path'] as String)
            .readAsLinesSync()
            .where((line) => line.trim().isNotEmpty)
            .toList(growable: false);
    expect(roundLog, hasLength(3));
    expect(runtimeAudit, hasLength(3));
    expect(
        roundLog.every((line) => line.contains('prd_v3_a2a_round_record.v1')),
        isTrue);
    expect(
        runtimeAudit.every(
            (line) => line.contains('prd_v3_a2a_runtime_audit_record.v1')),
        isTrue);
    expect(
        File('${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('a2a_conflict_report.json'),
          contains('a2a_consensus_report.json'),
          contains('a2a_rounds.jsonl'),
          contains('a2a_runtime_audit.jsonl'),
        ));
    await controller.testAllRegisteredProviderCapabilities();
    final a2aRuntimeStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final a2aPreflight =
        a2aRuntimeStatus['stage_2_industrial_preflight'] as Map;
    expect(a2aPreflight['failed_checks'],
        isNot(contains('a2a_multi_round_collaboration')));
    expect(a2aPreflight['failed_checks'],
        isNot(contains('agent_workspace_permission_enforcement')));
    final agentPermissionCheck = (a2aPreflight['checks'] as List)
        .cast<Map>()
        .firstWhere((check) =>
            check['check_id'] == 'agent_workspace_permission_enforcement');
    expect(agentPermissionCheck['status'], 'passed');
    expect(
        ((agentPermissionCheck['runtime_evidence'] as Map)['missing'] as List),
        isEmpty);

    await controller.clearAgentDialogueHistory();
    expect(controller.state.hasAgent, isTrue);
    expect(controller.state.hasAgentDialogue, isFalse);
    expect(controller.state.hasAgentDialogueHistory, isFalse);
    expect(controller.state.hasAgentDialogueExport, isFalse);
    expect(controller.state.hasMultiAgentDiscussion, isTrue);
    expect(
        Directory(
                '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent')
            .existsSync(),
        isTrue);
    expect(
        Directory(
                '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue')
            .existsSync(),
        isFalse);
    expect(
        Directory(
                '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export')
            .existsSync(),
        isFalse);
    await controller.runAgentDialogue(prompt: '清空后重新对话');
    expect(controller.state.hasAgentDialogueHistory, isTrue);
    expect(controller.state.agentDialogueTurnCount, 1);

    await controller.clearAgentArtifacts();
    expect(controller.state.hasAgent, isFalse);
    expect(controller.state.hasAgentDialogue, isFalse);
    expect(controller.state.hasMultiAgentDiscussion, isFalse);
    expect(controller.state.hasAgentValidationReport, isFalse);
    expect(controller.state.hasAgentWorkspacePermissionMatrix, isFalse);
    expect(controller.state.hasA2aConflictReport, isFalse);
    expect(controller.state.hasA2aConsensusReport, isFalse);
    expect(controller.state.hasSkill, isTrue);
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}agent')
            .existsSync(),
        isFalse);

    await controller.generateAgent();
    expect(controller.state.hasAgent, isTrue);
    await controller.clearSkillArtifacts();
    expect(controller.state.hasSkill, isFalse);
    expect(controller.state.hasAgent, isTrue);
    expect(controller.state.hasAgentDialogue, isFalse);
    expect(controller.state.hasMultiAgentDiscussion, isFalse);
    final dependencyMissingStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}status.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(dependencyMissingStatus['status'], 'dependency_missing');
    expect(dependencyMissingStatus['chat_available'], isFalse);
    final dependencyMissingManifest = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dependency_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(dependencyMissingManifest['status'], 'dependency_missing');
    expect(
        dependencyMissingManifest['missing_dependencies'],
        contains(isA<Map>()
            .having(
                (item) => item['dependency_type'], 'dependency_type', 'skill')
            .having((item) => item['dependency_id'], 'dependency_id', 'S1')));
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}skill')
            .existsSync(),
        isFalse);
    expect(
        Directory(
                '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent')
            .existsSync(),
        isTrue);
    await controller.runAgentDialogue(prompt: '缺少 Skill 时不应运行');
    expect(controller.state.hasAgentDialogueHistory, isFalse);
    expect(controller.state.lastError, contains('请先在 Skill 工厂生成 Skill'));
    await controller.runMultiAgentDiscussion(topic: '缺少 Skill 时不应协作');
    expect(controller.state.hasMultiAgentDiscussion, isFalse);
    expect(controller.state.lastError, contains('请先在 Skill 工厂生成 Skill'));
  });

  test('rc8 document flow stops at real Markdown export without Skill or Agent',
      () async {
    final workspace = await createWorkspace();
    final input =
        Directory('${workspace.path}${Platform.pathSeparator}input_src')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.txt')
        .writeAsStringSync('alpha text 赚钱 小生意');

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'batch_import_documents':
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync('{"imported_count":1}');
            case 'document_understanding':
              writeDuRecords(workspace, ['alpha.txt']);
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync('{"status":"completed"}');
            case 'knowledge_base_build':
              File('${output.path}${Platform.pathSeparator}manifest.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}quality_report.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}knowledge_base_build_report.json')
                  .writeAsStringSync('{"source_count":1}');
              final normalizedRoot =
                  '${workspace.path}${Platform.pathSeparator}du${Platform.pathSeparator}normalized_sources';
              File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                  .writeAsStringSync(jsonl([
                {
                  'text': '赚钱 小生意',
                  'source_path': '$normalizedRoot${Platform.pathSeparator}1.md',
                  'citation': 'alpha.txt#chunk=1',
                },
              ]));
              File('${output.path}${Platform.pathSeparator}cards.jsonl')
                  .writeAsStringSync('{"title":"赚钱小生意","summary":"真实主题"}\n');
              File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                  .writeAsStringSync(
                      '{"question":"主题是什么?","answer":"赚钱小生意"}\n');
            case 'rag_query':
              File('${output.path}${Platform.pathSeparator}kb_query_result.json')
                  .writeAsStringSync(
                      '{"query":"赚钱 小生意","selected_count":1,"selected":[{"text":"真实输入命中赚钱小生意","source_path":"alpha.txt","citation":"alpha.txt#chunk=1"}]}');
            case 'generate_markdown':
              File('${output.path}${Platform.pathSeparator}generated.md')
                  .writeAsStringSync('# generated from real input');
            case 'generate_docx':
              writeGeneratedDocumentExport(output, 'docx');
            case 'generate_pdf':
              writeGeneratedDocumentExport(output, 'pdf');
            case 'generate_pptx':
              writeGeneratedDocumentExport(output, 'pptx');
          }
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.runDocumentFlowE2E(input.path);

    expect(requests.map((request) => request.actionId), [
      'batch_import_documents',
      'document_understanding',
      'knowledge_base_build',
      'rag_query',
      'generate_markdown',
    ]);
    expect(controller.state.hasReadingNotes, isTrue);
    expect(controller.state.hasExportedDocument, isTrue);
    expectMainKnowledgeArtifacts(workspace, controller.state);
    expect(controller.state.hasSkill, isFalse);
    expect(controller.state.hasAgent, isFalse);
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}reading_notes_export.md')
            .readAsStringSync(),
        contains('真实输入文件夹读书笔记'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}export_manifest.json')
            .readAsStringSync(),
        contains('rc10_document_export.v1'));
    for (final format in const ['docx', 'pdf', 'pptx']) {
      expect(
          File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}$format${Platform.pathSeparator}generated.$format')
              .existsSync(),
          isFalse);
    }
    await controller.exportDocumentFormat('docx');
    expect(requests.last.actionId, 'generate_docx');
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}docx${Platform.pathSeparator}generated.docx')
            .existsSync(),
        isTrue);
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}docx${Platform.pathSeparator}generated_file_report.json')
            .readAsStringSync(),
        contains('"status":"pass"'));
    for (final format in const ['pdf', 'pptx']) {
      await controller.exportDocumentFormat(format);
      expect(
          File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}$format${Platform.pathSeparator}generated_file_report.json')
              .readAsStringSync(),
          contains('"status":"pass"'));
    }
    await controller.exportDocumentFormat('json');
    await controller.exportDocumentFormat('csv');
    final structuredRoot =
        '${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured';
    expect(
        File('$structuredRoot${Platform.pathSeparator}knowledge_export.json')
            .readAsStringSync(),
        contains('prd_v2_structured_document_export_payload.v1'));
    expect(
        File('$structuredRoot${Platform.pathSeparator}knowledge_export.csv')
            .readAsStringSync(),
        contains('retrieval_result'));
    expect(
        File('$structuredRoot${Platform.pathSeparator}structured_export_manifest.json')
            .readAsStringSync(),
        contains('prd_v2_structured_document_export.v1'));
  });

  test('prd standard knowledge package exports imports and builds KB',
      () async {
    final workspace = await createWorkspace();
    final input =
        Directory('${workspace.path}${Platform.pathSeparator}input_src')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.txt')
        .writeAsStringSync('alpha standard package evidence');

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'batch_import_documents':
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync('{"imported_count":1}');
            case 'document_understanding':
              writeDuRecords(workspace, ['alpha.txt']);
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync('{"status":"completed"}');
          }
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.importFolderPath(input.path);
    await controller.parseAndChunkSources();
    final packagePath = await controller.exportStandardKnowledgePackage();
    expect(packagePath, endsWith('current'));
    expect(controller.state.hasStandardKnowledgePackage, isTrue);
    final standardRoot =
        '${workspace.path}${Platform.pathSeparator}standard_packages${Platform.pathSeparator}current';
    expect(
        File('$standardRoot${Platform.pathSeparator}standard_package_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v3_standard_knowledge_package_manifest.v1'),
          contains('"standard": "okf_candidate"'),
          contains('"okf_runtime_enabled": true'),
          contains('"okf_runtime_mode": "internal_standard_package_runtime"'),
          contains('"independent_agent_runtime": false'),
        ));
    expect(
        File('$standardRoot${Platform.pathSeparator}source_references.json')
            .readAsStringSync(),
        contains('alpha.txt'));
    expect(
        File('$standardRoot${Platform.pathSeparator}content_package.jsonl')
            .readAsStringSync(),
        contains('normalized alpha.txt'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}standard_packages${Platform.pathSeparator}audit_history.jsonl')
            .readAsStringSync(),
        contains('export_standard_knowledge_package'));
    final okfRuntimePath =
        '${workspace.path}${Platform.pathSeparator}standard_packages${Platform.pathSeparator}okf_runtime_manifest.json';
    expect(
        File(okfRuntimePath).readAsStringSync(),
        allOf(
          contains('prd_v3_okf_runtime_manifest.v1'),
          contains('"runtime_loaded": true'),
          contains('"export_import_runtime_available": true'),
          contains('"kb_build_runtime_available": false'),
          contains('"external_runtime": false'),
        ));

    await controller.buildKnowledgeBaseFromStandardPackage();
    expect(controller.state.hasKnowledgeBase, isTrue);
    expect(
        controller.state.knowledgeBases.map((kb) => kb.id), contains('K_OKF1'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}kb${Platform.pathSeparator}manifest.json')
            .readAsStringSync(),
        contains('prd_v3_kb_from_standard_package.v1'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}kb${Platform.pathSeparator}manifest.json')
            .readAsStringSync(),
        contains('"okf_runtime_enabled": true'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}kb_catalog.json')
            .readAsStringSync(),
        allOf(
          contains('build_from_standard_package:K_OKF1'),
          contains('"okf_runtime_enabled": true'),
        ));
    expect(
        File(okfRuntimePath).readAsStringSync(),
        allOf(
          contains('"runtime_loaded": true'),
          contains('"kb_build_runtime_available": true'),
          contains('build_kb_from_standard_package'),
        ));
    final standardRuntimeStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final preflight =
        standardRuntimeStatus['stage_2_industrial_preflight'] as Map;
    expect(preflight['failed_checks'],
        isNot(contains('okf_bundle_runtime_export_import')));
    expect(
        preflight['failed_checks'], isNot(contains('okf_runtime_to_kb_build')));
    final checks = preflight['checks'] as List;
    final okfBundleCheck = checks.cast<Map>().firstWhere(
        (check) => check['check_id'] == 'okf_bundle_runtime_export_import');
    final okfBuildCheck = checks
        .cast<Map>()
        .firstWhere((check) => check['check_id'] == 'okf_runtime_to_kb_build');
    expect(okfBundleCheck['status'], 'passed');
    expect(okfBuildCheck['status'], 'passed');
    expect(((okfBundleCheck['runtime_evidence'] as Map)['missing'] as List),
        isEmpty);
    expect(((okfBuildCheck['runtime_evidence'] as Map)['missing'] as List),
        isEmpty);
    final orchestrationRecords = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}orchestration${Platform.pathSeparator}orchestration_plan.jsonl');
    expect(
        orchestrationRecords.map((record) => record['action']),
        containsAll([
          'export_standard_knowledge_package',
          'build_kb_from_standard_package',
        ]));
    expect(
        orchestrationRecords.any((record) =>
            record['action'] == 'export_standard_knowledge_package' &&
            ((record['boundary'] as Map)['okf_runtime_enabled']) == true),
        isTrue);
    expect(
        orchestrationRecords.any((record) =>
            record['action'] == 'build_kb_from_standard_package' &&
            ((record['boundary'] as Map)['okf_runtime_enabled']) == true),
        isTrue);

    final reloadedController = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    await reloadedController.initialize();
    expect(reloadedController.state.hasStandardKnowledgePackage, isTrue);
    expect(reloadedController.state.hasKnowledgeBase, isTrue);
    expect(reloadedController.state.knowledgeBases.map((kb) => kb.id),
        contains('K_OKF1'));
  });

  test('document generation persists template config into real artifacts',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"test_kb.v1"}');
    File('${kbDir.path}${Platform.pathSeparator}quality_report.json')
        .writeAsStringSync('{"status":"pass"}');
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {
        'text': '真实产品分析证据',
        'source_path': 'alpha.txt',
        'citation': 'alpha.txt#chunk=1',
      },
    ]));
    File('${kbDir.path}${Platform.pathSeparator}cards.jsonl')
        .writeAsStringSync('{"title":"产品分析","summary":"真实主题"}\n');
    File('${kbDir.path}${Platform.pathSeparator}qa_pairs.jsonl')
        .writeAsStringSync('{"question":"主题是什么?","answer":"产品分析"}\n');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'sources': [
        {'source_name': 'alpha.txt', 'relative_path': 'alpha.txt'}
      ],
    }));
    final queryDir =
        Directory('${workspace.path}${Platform.pathSeparator}query')
          ..createSync(recursive: true);
    File('${queryDir.path}${Platform.pathSeparator}multi_kb_query_result.json')
        .writeAsStringSync(jsonEncode({
      'query': '产品分析',
      'selected_count': 1,
      'selected': [
        {
          'text': '真实产品分析证据',
          'source_path': 'alpha.txt',
          'citation': 'alpha.txt#chunk=1',
          'kb_id': 'K1',
          'kb_name': '真实输入知识库',
        }
      ],
    }));

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}generated.md')
              .writeAsStringSync('# generated from real input');
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.generateMarkdown(
      config: const Rc6DocumentGenerationConfig(
        generationType: 'product_analysis',
        outputFormat: 'docx',
        citationStrategy: 'filename_and_chunk',
        templateMode: 'agent',
      ),
    );
    expect(requests.single.actionId, 'generate_markdown');
    expect(requests.single.arguments, contains('真实输入产品分析'));
    final docRoot = '${workspace.path}${Platform.pathSeparator}doc';
    final firstGenerationManifest =
        File('$docRoot${Platform.pathSeparator}generation_manifest.json')
            .readAsStringSync();
    expect(
        firstGenerationManifest,
        allOf(
          contains('prd_v3_template_document_generation.v1'),
          contains('"generation_type": "product_analysis"'),
          contains('"output_format": "docx"'),
          contains('"citation_strategy": "filename_and_chunk"'),
          contains('"template_mode": "agent"'),
        ));
    await controller.generateMarkdown(
      config: const Rc6DocumentGenerationConfig(
        generationType: 'summary',
        outputFormat: 'md',
        citationStrategy: 'filename_and_chunk',
        templateMode: 'built_in',
      ),
    );

    expect(requests, hasLength(2));
    final generationManifest =
        File('$docRoot${Platform.pathSeparator}generation_manifest.json')
            .readAsStringSync();
    expect(
        generationManifest,
        allOf(
          contains('prd_v3_template_document_generation.v1'),
          contains('"citations":'),
          contains('alpha.txt#chunk=1'),
          contains('"kb_name": "真实输入知识库"'),
          contains('"outline_path":'),
        ));
    expect(
        generationManifest,
        allOf(
          contains('"citations_path":'),
          contains('"document_validation_report_path":'),
          contains('"generation_history":'),
          contains('"citation_count": 1'),
          contains('"generation_type": "summary"'),
        ));
    expect(controller.state.documentOutlinePath,
        '$docRoot${Platform.pathSeparator}outline.json');
    expect(controller.state.documentCitationsPath,
        '$docRoot${Platform.pathSeparator}citations.json');
    expect(controller.state.documentValidationReportPath,
        '$docRoot${Platform.pathSeparator}document_validation_report.json');
    expect(
        File(controller.state.documentOutlinePath).readAsStringSync(),
        allOf(
          contains('prd_v3_document_outline.v1'),
          contains('真实输入资料摘要'),
        ));
    expect(
        File(controller.state.documentCitationsPath).readAsStringSync(),
        allOf(
          contains('prd_v3_document_citations.v1'),
          contains('alpha.txt#chunk=1'),
        ));
    expect(
        File(controller.state.documentValidationReportPath).readAsStringSync(),
        allOf(
          contains('prd_v3_document_validation_report.v1'),
          contains('"history_snapshot_status": "written"'),
          contains('"secret_plaintext_written": false'),
        ));
    final generationManifestJson =
        jsonDecode(generationManifest) as Map<String, dynamic>;
    expect(generationManifestJson['generation_history'], hasLength(2));
    final historyEntries =
        (generationManifestJson['generation_history'] as List)
            .whereType<Map>()
            .toList();
    for (final entry in historyEntries) {
      final historyMarkdown = entry['history_markdown'].toString();
      expect(historyMarkdown, endsWith('.md'));
      expect(File(historyMarkdown).existsSync(), isTrue);
    }
    final latestHistoryMarkdown =
        await controller.readLatestDocumentGenerationHistoryMarkdown();
    expect(latestHistoryMarkdown, contains('文档类型：摘要'));
    expect(controller.state.documentGenerationHistoryCount, 2);
    expect(controller.state.hasDocumentGenerationHistory, isTrue);
    await controller.deleteLatestDocumentGenerationHistory();
    final latestDeletedManifest = jsonDecode(
        File('$docRoot${Platform.pathSeparator}generation_manifest.json')
            .readAsStringSync()) as Map<String, dynamic>;
    expect(latestDeletedManifest['generation_history'], hasLength(1));
    expect((latestDeletedManifest['generation_history'] as List).single,
        containsPair('generation_type', 'product_analysis'));
    expect(latestDeletedManifest['latest_history_deleted_event'],
        'generate_document');
    expect(controller.state.documentGenerationHistoryCount, 1);
    expect(controller.state.hasDocumentGenerationHistory, isTrue);
    final firstHistoryMarkdown =
        await controller.readLatestDocumentGenerationHistoryMarkdown();
    expect(firstHistoryMarkdown, contains('文档类型：产品分析'));
    await controller.clearDocumentGenerationHistory();
    final clearedManifest = jsonDecode(
        File('$docRoot${Platform.pathSeparator}generation_manifest.json')
            .readAsStringSync()) as Map<String, dynamic>;
    expect(clearedManifest['generation_history'], isEmpty);
    expect(clearedManifest['history_cleared_at'], isNotEmpty);
    expect(controller.state.documentGenerationHistoryCount, 0);
    expect(controller.state.hasDocumentGenerationHistory, isFalse);
    expect(
        File('$docRoot${Platform.pathSeparator}reading_notes.md').existsSync(),
        isTrue);
    expect(
        File('$docRoot${Platform.pathSeparator}reading_notes.md')
            .readAsStringSync(),
        allOf(
          contains('文档类型：摘要'),
          contains('文件名 + Chunk'),
          contains('通用内置模板'),
        ));

    final editedPath = await controller.saveEditedDocument(
      '# Owner edited product analysis\n\nfinal edited body from real KB',
    );
    expect(editedPath, endsWith('edited_document.md'));
    expect(
        File('$docRoot${Platform.pathSeparator}edited_document.md')
            .readAsStringSync(),
        contains('final edited body from real KB'));
    expect(
        File('$docRoot${Platform.pathSeparator}edit_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_document_edit.v1'),
          contains('edited_document.md'),
          contains('"secret_plaintext_written": false'),
        ));

    await controller.exportMarkdownDocument();
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}export_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('generation_manifest.json'),
          contains('edit_manifest.json'),
          contains('"generation_type": "summary"'),
          contains('"output_format": "md"'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}reading_notes_export.md')
            .readAsStringSync(),
        contains('final edited body from real KB'));

    final reloadedController = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    await reloadedController.initialize();
    expect(reloadedController.state.documentOutlinePath,
        controller.state.documentOutlinePath);
    expect(reloadedController.state.documentCitationsPath,
        controller.state.documentCitationsPath);
    expect(reloadedController.state.documentValidationReportPath,
        controller.state.documentValidationReportPath);
  });

  test('document template registry has artifact lifecycle evidence', () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    final manifestPath = await controller.registerDocumentTemplateLibrary(
      includeTestTemplate: true,
    );
    final templateRoot =
        '${workspace.path}${Platform.pathSeparator}doc${Platform.pathSeparator}templates';
    final manifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['schema_version'], 'prd_v3_document_template_registry.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['template_count'], 5);
    expect(manifest['template_ids'], contains('product_manual_template'));
    expect(manifest['template_ids'],
        contains('test_document_template_registry_entry'));
    expect(manifest['secret_plaintext_written'], isFalse);

    final validationPath =
        '$templateRoot${Platform.pathSeparator}document_template_registry_validation_report.json';
    final validation = jsonDecode(File(validationPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    expect(validation['has_builtin_templates'], isTrue);
    expect(validation['has_output_formats'], isTrue);
    expect(validation['has_required_variables'], isTrue);
    expect(validation['test_marked_entries'],
        contains('test_document_template_registry_entry'));

    final preview = await controller.readDocumentTemplateRegistryPreview();
    expect(preview, contains('prd_v3_document_template_registry.v1'));
    expect(preview, contains('行业分析报告'));

    final exportManifestPath =
        await controller.exportDocumentTemplateRegistry();
    final exportManifest =
        jsonDecode(File(exportManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(exportManifest['schema_version'],
        'prd_v3_document_template_registry_export.v1');
    expect(
        File(exportManifest['exported_manifest_path'] as String).existsSync(),
        isTrue);
    expect(
        File(exportManifest['exported_validation_path'] as String).existsSync(),
        isTrue);

    final testEntryPath =
        '$templateRoot${Platform.pathSeparator}entries${Platform.pathSeparator}test_document_template_registry_entry.json';
    expect(File(testEntryPath).existsSync(), isTrue);
    await controller.deleteTestDocumentTemplateRegistryEntry();
    expect(File(testEntryPath).existsSync(), isFalse);
    final deletedManifest = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(deletedManifest['template_count'], 4);
    expect(deletedManifest['template_ids'],
        isNot(contains('test_document_template_registry_entry')));
    expect(deletedManifest['last_deleted_test_template_id'],
        'test_document_template_registry_entry');

    final reloadedController = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    await reloadedController.initialize();
    final reloadedPreview =
        await reloadedController.readDocumentTemplateRegistryPreview();
    expect(reloadedPreview, contains('product_manual_template'));
    expect(reloadedPreview,
        isNot(contains('test_document_template_registry_entry.json')));

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'document_template_registry_created'),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'document_template_registry_exported'),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['action'] == 'delete_test_document_template_registry_entry'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'document_template_registry_manifest' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'document_template_registry_export' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'test_document_template_registry_entry' &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('skill generation persists type platform and personalization config',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"test_kb.v1"}');
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync('{"text":"产品分析证据","source_path":"alpha.txt"}\n');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'sources': [
        {'source_name': 'alpha.txt', 'relative_path': 'alpha.txt'}
      ],
    }));

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}SKILL.md')
              .writeAsStringSync('# generated skill');
          File('${output.path}${Platform.pathSeparator}skill_manifest.yaml')
              .writeAsStringSync('name: generated skill');
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.generateSkill(
      config: const Rc6SkillGenerationConfig(
        customSkillName: 'Owner 产品方法论 Skill',
        skillType: 'product',
        targetPlatform: 'markdown',
        personalizationGoal: 'agent_specific',
      ),
    );

    expect(requests.single.actionId, 'package_to_skill');
    expect(requests.single.arguments, contains('Owner 产品方法论 Skill'));
    final skillRoot = '${workspace.path}${Platform.pathSeparator}skill';
    expect(
        File('$skillRoot${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}SKILL.md')
            .readAsStringSync(),
        allOf(
          contains('Owner 产品方法论 Skill'),
          contains('产品 Skill'),
          contains('Markdown'),
          contains('Agent 专属化'),
        ));
    expect(
        File('$skillRoot${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}skill_config.json')
            .readAsStringSync(),
        allOf(
          contains('"skill_type": "product"'),
          contains('"target_platform": "markdown"'),
          contains('"personalization_goal": "agent_specific"'),
          contains('"skill_name": "Owner 产品方法论 Skill"'),
        ));
    expect(
        File('$skillRoot${Platform.pathSeparator}skill_generation_manifest.json')
            .readAsStringSync(),
        allOf([
          contains('"selected_generation_config"'),
          contains('"model_route_binding"'),
          contains('"model_route_evidence"'),
          contains('"skill_generation"'),
          contains('"external_skill_localization"'),
          contains('"skill_type": "product"'),
          contains('"target_platform": "markdown"'),
          contains('"personalization_goal": "agent_specific"'),
          contains('"custom_skill_name": "Owner 产品方法论 Skill"'),
        ]));
    final skillGenerationManifest = jsonDecode(File(
            '$skillRoot${Platform.pathSeparator}skill_generation_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final skillRouteBinding =
        skillGenerationManifest['model_route_binding'] as Map;
    expect(skillRouteBinding['module'], 'skill_factory');
    expect(skillRouteBinding['route_scopes'],
        containsAll(['skill_generation', 'external_skill_localization']));
    final skillRouteEvidence =
        skillGenerationManifest['model_route_evidence'] as Map;
    expect((skillRouteEvidence['skill_generation'] as Map)['route_scopes'],
        containsAll(['skill_generation', 'skill_validation']));
    expect(
        (skillRouteEvidence['external_skill_localization']
            as Map)['route_scopes'],
        contains('external_skill_localization'));
    final skillVersionManifestPath =
        '$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_version_manifest.json';
    expect(
        File(skillVersionManifestPath).readAsStringSync(),
        allOf(
          contains('prd_v2_skill_version_manifest.v1'),
          contains('"version_id": "v1"'),
          contains('"event": "generate_skill"'),
        ));
    expect(controller.state.skillVersionCount, 1);
    expect(controller.state.hasSkillVersions, isTrue);
    expect(controller.state.hasPrimarySkill, isTrue);
    expect(controller.state.primarySkillPath, endsWith('SKILL.md'));
    expect(controller.state.hasSkillConfig, isTrue);
    expect(controller.state.hasSkillVerificationReport, isTrue);
    expect(controller.state.hasSkillGenerationManifest, isTrue);
    expect(controller.state.hasSkillPackageManifest, isTrue);
    expect(controller.state.hasSkillValidationReport, isTrue);
    expect(controller.state.hasLocalizedSkillManifest, isTrue);
    expect(controller.state.hasLocalizedSkillDiff, isTrue);
    expect(controller.state.hasSkillVersionManifest, isTrue);
    expect(controller.state.hasSkillOperationManifest, isTrue);
    expect(controller.state.skillFactoryAuditPath,
        endsWith('skill_factory_audit.json'));
    expect(controller.state.hasSkillExport, isTrue);
    expect(controller.state.hasSkillAgentBindingManifest, isTrue);
    expect(controller.state.skillOperationStatus, 'pass');
    expect(controller.state.skillAgentBindingStatus, 'waiting_agent');

    final editedSkillPath = await controller.saveEditedSkill(
      '# Owner edited product Skill\n\nUse product evidence with citations.',
    );
    expect(editedSkillPath, endsWith('SKILL.md'));
    expect(
        File('$skillRoot${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}SKILL.md')
            .readAsStringSync(),
        contains('Owner edited product Skill'));
    expect(
        File('$skillRoot${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}skill_edit_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_skill_draft_edit.v1'),
          contains('SKILL.original.md'),
          contains('"secret_plaintext_written": false'),
        ));
    final editedVersionManifest =
        jsonDecode(File(skillVersionManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(editedVersionManifest['version_count'], 2);
    expect(editedVersionManifest['versions'], hasLength(2));
    expect(File(skillVersionManifestPath).readAsStringSync(),
        contains('"event": "edit_skill"'));
    expect(controller.state.skillVersionCount, 2);

    await controller.completeSkillProductOperations();
    expect(
        File('$skillRoot${Platform.pathSeparator}exports${Platform.pathSeparator}skills_export.md')
            .readAsStringSync(),
        contains('Owner edited product Skill'));
    expect(
        File('$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('"requested_operation": "all"'),
          contains('"history_path"'),
          contains('"operation": "edit"'),
          contains('"operation": "version"'),
          contains('skill_edit_manifest.json'),
          contains('skill_version_manifest.json'),
          contains('"status": "saved"'),
        ));
    await controller.runSkillOperation('fusion');
    final operationManifest = File(
            '$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_manifest.json')
        .readAsStringSync();
    expect(
        operationManifest,
        allOf(
          contains('"requested_operation": "fusion"'),
          contains('"operation": "fusion"'),
          contains('fused_product_ops_skill'),
        ));
    final factoryAuditPath =
        '$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_factory_audit.json';
    final skillPackageManifestPath =
        '$skillRoot${Platform.pathSeparator}skill_package_manifest.json';
    final skillPackageManifest =
        jsonDecode(File(skillPackageManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(skillPackageManifest['schema_version'],
        'prd_v3_skill_package_manifest.v1');
    expect(skillPackageManifest['status'], 'ready');
    expect(skillPackageManifest['skill_packages'], isA<List>());
    expect(skillPackageManifest['missing_required_artifacts'], isEmpty);
    final skillPackageBoundary = skillPackageManifest['tool_boundary'] as Map;
    expect(skillPackageBoundary['local_kb_only'], isTrue);
    expect(skillPackageBoundary['arbitrary_shell_enabled'], isFalse);
    expect(skillPackageBoundary['computer_use_enabled'], isFalse);
    final skillValidationReportPath =
        '$skillRoot${Platform.pathSeparator}skill_validation_report.json';
    final skillValidationReport =
        jsonDecode(File(skillValidationReportPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(skillValidationReport['schema_version'],
        'prd_v3_skill_factory_validation.v1');
    expect(skillValidationReport['status'], 'pass');
    expect(skillValidationReport['missing_required_artifacts'], isEmpty);
    expect(skillValidationReport['ready_for_agent_binding'], isTrue);
    expect(skillValidationReport['ready_for_export'], isTrue);
    final factoryAudit = jsonDecode(File(factoryAuditPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(factoryAudit['schema_version'], 'prd_v3_skill_factory_audit.v1');
    expect(factoryAudit['status'], 'pass');
    expect(factoryAudit['requested_operation'], 'fusion');
    expect(factoryAudit['package_manifest_path'],
        endsWith('skill_package_manifest.json'));
    expect(factoryAudit['validation_report_path'],
        endsWith('skill_validation_report.json'));
    expect(factoryAudit['generation_modes'],
        containsAll(['from_kb', 'external_skill_fusion', 'export']));
    expect((factoryAudit['model_route_binding'] as Map)['module'],
        'skill_factory');
    expect(
        ((factoryAudit['model_route_evidence'] as Map)['skill_generation']
            as Map)['route_scopes'],
        contains('skill_refinement'));
    expect(factoryAudit['artifacts'], isA<List>());
    expect(factoryAudit['artifact_count'], greaterThan(0));
    expect(factoryAudit['missing_required_artifacts'], isEmpty);
    expect(factoryAudit['ready_for_agent_binding'], isTrue);
    expect(factoryAudit['ready_for_export'], isTrue);
    final toolBoundary = factoryAudit['tool_boundary'] as Map;
    expect(toolBoundary['arbitrary_shell_enabled'], isFalse);
    expect(toolBoundary['external_plugin_marketplace_enabled'], isFalse);
    expect(toolBoundary['computer_use_enabled'], isFalse);
    expect(factoryAudit['secret_plaintext_written'], isFalse);
    expect(File(skillVersionManifestPath).readAsStringSync(),
        contains('"event": "skill_operation_fusion"'));
    final skillRuntimeManifestPath =
        '$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_runtime_manifest.json';
    final skillRuntimeManifest =
        jsonDecode(File(skillRuntimeManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(skillRuntimeManifest['schema_version'],
        'prd_v3_skill_runtime_manifest.v1');
    expect(skillRuntimeManifest['runtime_loaded'], isTrue);
    expect(skillRuntimeManifest['secondary_fusion_runtime_available'], isTrue);
    expect(skillRuntimeManifest['multi_version_runtime_available'], isTrue);
    expect((skillRuntimeManifest['model_route_binding'] as Map)['module'],
        'skill_factory');
    expect(
        (skillRuntimeManifest['model_route_evidence'] as Map)['route_scopes'],
        containsAll(['skill_generation', 'external_skill_localization']));
    expect(skillRuntimeManifest['version_count'], greaterThan(1));
    final skillRuntimeVersions =
        skillRuntimeManifest['versions'] as List<dynamic>;
    expect(
        skillRuntimeVersions.every((version) =>
            File((version as Map)['snapshot_path'].toString()).existsSync()),
        isTrue);
    final skillDiffReport = jsonDecode(
        File(skillRuntimeManifest['version_diff_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(skillDiffReport['schema_version'],
        'prd_v3_skill_version_diff_report.v1');
    expect(skillDiffReport['status'], 'pass');
    final skillRollbackManifest = jsonDecode(
        File(skillRuntimeManifest['rollback_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(skillRollbackManifest['schema_version'],
        'prd_v3_skill_rollback_manifest.v1');
    expect(skillRollbackManifest['rollback_supported'], isTrue);
    expect(
        File(skillRollbackManifest['rollback_target_snapshot_path'] as String)
            .existsSync(),
        isTrue);
    expect(
        File(skillRuntimeManifest['runtime_audit_path'] as String)
            .readAsStringSync(),
        allOf(
          contains('prd_v3_skill_runtime_audit_record.v1'),
          contains('"action":"skill_secondary_fusion"'),
          contains('"secondary_fusion_runtime_available":true'),
          contains('"multi_version_runtime_available":true'),
        ));
    final skillRuntimeStatus = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json')
        .readAsStringSync()) as Map;
    final skillPreflight =
        skillRuntimeStatus['stage_2_industrial_preflight'] as Map;
    expect(skillPreflight['failed_checks'],
        isNot(contains('skill_secondary_fusion_version_management')));
    final skillPreflightChecks = skillPreflight['checks'] as List;
    final skillPreflightCheck = skillPreflightChecks.cast<Map>().firstWhere(
        (check) =>
            check['check_id'] == 'skill_secondary_fusion_version_management');
    expect(skillPreflightCheck['status'], 'passed');
    expect(
        ((skillPreflightCheck['runtime_evidence'] as Map)['missing'] as List),
        isEmpty);
    final skillOperationHistoryPath =
        '$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_history.json';
    final skillOperationHistory =
        jsonDecode(File(skillOperationHistoryPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(skillOperationHistory['schema_version'],
        'prd_v2_skill_operation_history.v1');
    expect(skillOperationHistory['status'], 'pass');
    expect(
        skillOperationHistory['records'],
        containsAll([
          isA<Map>()
              .having((record) => record['action'], 'action', 'generate_skill'),
          isA<Map>()
              .having((record) => record['action'], 'action', 'edit_skill'),
          isA<Map>().having((record) => record['action'], 'action',
              'complete_skill_product_operations'),
          isA<Map>().having(
              (record) => record['action'], 'action', 'skill_operation_fusion'),
        ]));
    expect(controller.state.hasSkillOperationHistory, isTrue);
    expect(controller.state.skillOperationHistoryPath,
        endsWith('skill_operation_history.json'));
    final historyPreview =
        await controller.readWorkspaceTextArtifact(skillOperationHistoryPath);
    expect(historyPreview, contains('prd_v2_skill_operation_history.v1'));
    expect(historyPreview, contains('"action": "skill_operation_fusion"'));

    final reloadedController = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    await reloadedController.initialize();
    expect(reloadedController.state.hasSkillOperationHistory, isTrue);
    expect(reloadedController.state.skillOperationHistoryPath,
        endsWith('skill_operation_history.json'));
    expect(reloadedController.state.skillFactoryAuditPath,
        endsWith('skill_factory_audit.json'));
    expect(reloadedController.state.skillPackageManifestPath,
        endsWith('skill_package_manifest.json'));
    expect(reloadedController.state.skillValidationReportPath,
        endsWith('skill_validation_report.json'));
    expect(controller.state.skillExportPath, endsWith('skills_export.md'));
    expect(controller.state.skillOperationManifestPath,
        endsWith('skill_operation_manifest.json'));
    expect(controller.state.skillAgentBindingManifestPath,
        endsWith('agent_binding_manifest.json'));
  });

  test('agent generation persists creation mode type and output config',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"test_kb.v1"}');
    final skillDir =
        Directory('${workspace.path}${Platform.pathSeparator}skill')
          ..createSync(recursive: true);
    final primarySkill =
        Directory('${skillDir.path}${Platform.pathSeparator}knowledge_qa_skill')
          ..createSync(recursive: true);
    File('${primarySkill.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# skill');

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          File('${output.path}${Platform.pathSeparator}agent_manifest.json')
              .writeAsStringSync('{"name":"agent"}');
          File('${output.path}${Platform.pathSeparator}agent_profile.yaml')
              .writeAsStringSync('name: agent');
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.generateAgent(
      config: const Rc6AgentGenerationConfig(
        customAgentName: 'Owner 产品分析 Agent',
        creationMode: 'advanced',
        agentType: 'product_analysis',
        modelConfigId: 'owner-provider-model',
        outputFormat: 'json',
        roleGoal: '以产品经理视角分析证据并输出可执行结论。',
      ),
    );

    expect(requests.single.actionId, 'kb_bound_agent_generation');
    expect(requests.single.arguments, contains('advanced_kb_bound'));
    expect(requests.single.arguments, contains('Owner 产品分析 Agent'));
    final agentRoot = '${workspace.path}${Platform.pathSeparator}agent';
    expect(
        File('$agentRoot${Platform.pathSeparator}knowledge_qa_agent${Platform.pathSeparator}agent_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_selected_agent_manifest.v1'),
          contains('"agent_name": "Owner 产品分析 Agent"'),
          contains('"creation_mode": "advanced"'),
          contains('"agent_type": "product_analysis"'),
          contains('"model_config_id": "owner-provider-model"'),
          contains('"output_format": "json"'),
          contains('"role_goal": "以产品经理视角分析证据并输出可执行结论。"'),
        ));
    expect(
        File('$agentRoot${Platform.pathSeparator}knowledge_qa_agent${Platform.pathSeparator}agent_profile.yaml')
            .readAsStringSync(),
        allOf(
          contains('name: Owner 产品分析 Agent'),
          contains('role_goal: 以产品经理视角分析证据并输出可执行结论。'),
        ));
    expect(
        File('$agentRoot${Platform.pathSeparator}agent_generation_manifest.json')
            .readAsStringSync(),
        allOf([
          contains('"selected_generation_config"'),
          contains('"model_route_binding"'),
          contains('"model_route_evidence"'),
          contains('"agent_chat"'),
          contains('"custom_agent_name": "Owner 产品分析 Agent"'),
          contains('"creation_mode": "advanced"'),
          contains('"agent_type": "product_analysis"'),
          contains('"model_config_id": "owner-provider-model"'),
          contains('"output_format": "json"'),
          contains('"role_goal": "以产品经理视角分析证据并输出可执行结论。"'),
        ]));
    final agentGenerationManifest = jsonDecode(File(
            '$agentRoot${Platform.pathSeparator}agent_generation_manifest.json')
        .readAsStringSync()) as Map;
    expect((agentGenerationManifest['model_route_binding'] as Map)['module'],
        'agent_workbench');
    expect(
        (agentGenerationManifest['model_route_evidence']
            as Map)['route_scopes'],
        containsAll(['agent_chat', 'agent_reasoning']));
    expect(
        File('$agentRoot${Platform.pathSeparator}product_config${Platform.pathSeparator}advanced_agent_config.json')
            .readAsStringSync(),
        allOf(
          contains('"selected_generation_config"'),
          contains('"creation_mode": "advanced"'),
          contains('"model_config_id": "owner-provider-model"'),
          contains('"output_format": "json"'),
          contains('"role_goal": "以产品经理视角分析证据并输出可执行结论。"'),
        ));
    expect(controller.state.hasPrimaryAgentManifest, isTrue);
    expect(controller.state.primaryAgentManifestPath,
        endsWith('agent_manifest.json'));
    expect(controller.state.hasAgentProfile, isTrue);
    expect(controller.state.hasAgentGenerationManifest, isTrue);
    expect(controller.state.agentGenerationManifestPath,
        endsWith('agent_generation_manifest.json'));
    expect(controller.state.hasAgentAdvancedConfig, isTrue);
    expect(controller.state.hasAgentPermissionAudit, isTrue);
    expect(controller.state.hasAgentPackageManifest, isTrue);
    expect(controller.state.hasAgentPackageReadme, isTrue);
    await controller.runAgentDialogue(prompt: '用产品分析 Agent 总结证据');
    expect(controller.state.hasAgentDialogueManifest, isTrue);
    expect(controller.state.agentDialogueModelConfigId, 'owner-provider-model');
    expect(controller.state.agentDialogueUsedKbIds, contains('K1'));
    expect(controller.state.agentDialogueUsedSkillIds, contains('S1'));
    expect(controller.state.agentDialogueOutputFormat, 'json');
    expect(controller.state.agentDialogueEvidenceCount, 0);
    expect(controller.state.agentDialogueMemoryWriteStatus,
        'local_session_written');
    expect(controller.state.agentDialogueErrorMessage, isEmpty);
    final dialogueManifest = File(
            '$agentRoot${Platform.pathSeparator}dialogue${Platform.pathSeparator}agent_dialogue_manifest.json')
        .readAsStringSync();
    expect(
        dialogueManifest,
        allOf([
          contains('"model_config_id": "owner-provider-model"'),
          contains('"model_route_binding"'),
          contains('"model_route_evidence"'),
          contains('"agent_chat"'),
          contains('"role_goal": "以产品经理视角分析证据并输出可执行结论。"'),
          contains('"used_kb_ids"'),
          contains('"K1"'),
          contains('"used_skill_ids"'),
          contains('"S1"'),
        ]));
    expect(
        dialogueManifest,
        allOf(
          contains('"output_format": "json"'),
          contains('"redis_config_id": "settings_redis_optional"'),
          contains(
              '"vector_config_id": "settings_agent_memory_vector_optional"'),
        ));
    final dialogueManifestJson = jsonDecode(dialogueManifest) as Map;
    expect((dialogueManifestJson['model_route_binding'] as Map)['module'],
        'agent_workbench');
    expect(
        (dialogueManifestJson['model_route_evidence'] as Map)['route_scopes'],
        containsAll(['agent_chat', 'agent_reasoning']));
    expect(
        File('$agentRoot${Platform.pathSeparator}dialogue${Platform.pathSeparator}chat_history.jsonl')
            .readAsStringSync(),
        allOf(
          contains('"output_format":"json"'),
          contains('"role_goal":"以产品经理视角分析证据并输出可执行结论。"'),
          contains('"redis_config_id":"settings_redis_optional"'),
          contains(
              '"vector_config_id":"settings_agent_memory_vector_optional"'),
        ));
    await controller.runMultiAgentDiscussion(
      topic: 'Owner 自定义 A2A 议题',
      participantAgentIds: const [
        'operation_conversion_agent',
        'product_analysis_agent',
      ],
    );
    expect(controller.state.a2aTopic, 'Owner 自定义 A2A 议题');
    expect(controller.state.a2aParticipantAgentIds,
        ['operation_conversion_agent', 'product_analysis_agent']);
    final discussion = File(
            '${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion.md')
        .readAsStringSync();
    expect(
        discussion,
        allOf(
          contains('Owner 自定义 A2A 议题'),
          contains('operation_conversion_agent / product_analysis_agent'),
        ));
    final a2aManifest = File(
            '$agentRoot${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001${Platform.pathSeparator}a2a_session_manifest.json')
        .readAsStringSync();
    expect(
        a2aManifest,
        allOf(
          contains('"topic": "Owner 自定义 A2A 议题"'),
          contains('"model_route_binding"'),
          contains('"model_route_evidence"'),
          contains('"a2a_consensus"'),
          contains('"operation_conversion_agent"'),
          contains('"product_analysis_agent"'),
        ));
    final a2aManifestJson = jsonDecode(a2aManifest) as Map;
    expect(a2aManifestJson['schema_version'], 'prd_v3_a2a_session_manifest.v1');
    expect((a2aManifestJson['model_route_binding'] as Map)['module'], 'a2a');
    expect((a2aManifestJson['model_route_evidence'] as Map)['route_scopes'],
        containsAll(['a2a_conflict_detection', 'a2a_consensus']));
    expect(
        File('$agentRoot${Platform.pathSeparator}audit${Platform.pathSeparator}run_history.json')
            .readAsStringSync(),
        allOf(
          contains('"action": "run_agent_dialogue"'),
          contains('"action": "run_a2a_discussion"'),
          contains('"model_route_evidence_recorded": true'),
          contains('"model_route_evidence"'),
          contains('Owner 自定义 A2A 议题'),
        ));
    final orchestrationRecords = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}orchestration${Platform.pathSeparator}orchestration_plan.jsonl');
    expect(orchestrationRecords.map((record) => record['layer']),
        containsAll(['agent', 'a2a']));
    expect(
        orchestrationRecords.map((record) => record['action']),
        containsAll(
            ['generate_agent', 'run_agent_dialogue', 'run_a2a_discussion']));
    expect(
        orchestrationRecords.any((record) =>
            record['action'] == 'run_a2a_discussion' &&
            ((record['resources'] as Map)['topic'] == 'Owner 自定义 A2A 议题')),
        isTrue);
  });

  test('rc6 owner input folder chain uses the fixed Owner input directory',
      () async {
    final workspace = await createWorkspace();
    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'batch_import_documents':
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync('{"imported_count":6}');
            case 'document_understanding':
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync('{"status":"completed"}');
            case 'knowledge_base_build':
              File('${output.path}${Platform.pathSeparator}manifest.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}quality_report.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                  .writeAsStringSync(
                      '{"text":"赚钱 小生意","source_path":"owner.pdf"}\n');
              File('${output.path}${Platform.pathSeparator}cards.jsonl')
                  .writeAsStringSync('{"title":"Owner input"}\n');
              File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                  .writeAsStringSync('{"question":"q","answer":"a"}\n');
            case 'rag_query':
              File('${output.path}${Platform.pathSeparator}kb_query_result.json')
                  .writeAsStringSync(
                      '{"query":"赚钱 小生意","selected_count":1,"selected":[{"text":"owner hit","source_path":"owner.pdf"}]}');
            case 'generate_markdown':
              File('${output.path}${Platform.pathSeparator}generated.md')
                  .writeAsStringSync('# owner input');
            case 'generate_docx':
              writeGeneratedDocumentExport(output, 'docx');
            case 'generate_pdf':
              writeGeneratedDocumentExport(output, 'pdf');
            case 'generate_pptx':
              writeGeneratedDocumentExport(output, 'pptx');
            case 'package_to_skill':
              File('${output.path}${Platform.pathSeparator}SKILL.md')
                  .writeAsStringSync('# skill');
              File('${output.path}${Platform.pathSeparator}skill_manifest.yaml')
                  .writeAsStringSync('name: skill');
            case 'kb_bound_agent_generation':
              File('${output.path}${Platform.pathSeparator}agent_manifest.json')
                  .writeAsStringSync('{"name":"agent"}');
              File('${output.path}${Platform.pathSeparator}agent_profile.yaml')
                  .writeAsStringSync('name: agent');
          }
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.runOwnerInputFolderE2E();

    final ownerInput = Directory(r'D:\HeiTang-Codex-WorkSpace\input');
    if (ownerInput.existsSync()) {
      expect(requests.first.actionId, 'batch_import_documents');
      expect(controller.state.sourceCount, greaterThan(0));
      expect(controller.state.selectedFilePath,
          '${workspace.path}${Platform.pathSeparator}input');
    } else {
      expect(controller.state.lastError,
          contains(r'D:\HeiTang-Codex-WorkSpace\input'));
    }
  });

  test('prd p0 product smoke writes multiple KBs, localized skill, and A2A',
      () async {
    final workspace = await createWorkspace();
    final input =
        Directory('${workspace.path}${Platform.pathSeparator}input_src')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.pdf')
        .writeAsStringSync('alpha real source 赚钱 小生意');
    File('${input.path}${Platform.pathSeparator}beta.txt')
        .writeAsStringSync('beta real source product ops');

    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'batch_import_documents':
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync('{"imported_count":2}');
            case 'document_understanding':
              writeDuRecords(workspace, ['alpha.pdf', 'beta.txt']);
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync(
                      '{"status":"completed","success_count":2,"failed_count":0}');
            case 'knowledge_base_build':
              File('${output.path}${Platform.pathSeparator}manifest.json')
                  .writeAsStringSync('{"schema_version":"kb.v1"}');
              File('${output.path}${Platform.pathSeparator}quality_report.json')
                  .writeAsStringSync('{"status":"pass"}');
              File('${output.path}${Platform.pathSeparator}knowledge_base_build_report.json')
                  .writeAsStringSync('{"source_count":2}');
              final normalizedRoot =
                  '${workspace.path}${Platform.pathSeparator}du${Platform.pathSeparator}normalized_sources';
              File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                  .writeAsStringSync(jsonl([
                {
                  'text': '赚钱 小生意 alpha',
                  'source_path': '$normalizedRoot${Platform.pathSeparator}1.md',
                  'citation': 'alpha.pdf#chunk=1',
                },
                {
                  'text': 'product ops beta',
                  'source_path': '$normalizedRoot${Platform.pathSeparator}2.md',
                  'citation': 'beta.txt#chunk=1',
                },
              ]));
              File('${output.path}${Platform.pathSeparator}cards.jsonl')
                  .writeAsStringSync('{"title":"alpha","summary":"赚钱"}\n');
              File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                  .writeAsStringSync('{"question":"q","answer":"a"}\n');
            case 'rag_query':
              File('${output.path}${Platform.pathSeparator}kb_query_result.json')
                  .writeAsStringSync(
                      '{"query":"赚钱 小生意","selected_count":1,"selected":[{"text":"真实命中","source_path":"alpha.pdf","citation":"alpha.pdf#chunk=1"}]}');
            case 'generate_markdown':
              File('${output.path}${Platform.pathSeparator}generated.md')
                  .writeAsStringSync('# generated from real input');
            case 'generate_docx':
              writeGeneratedDocumentExport(output, 'docx');
            case 'generate_pdf':
              writeGeneratedDocumentExport(output, 'pdf');
            case 'generate_pptx':
              writeGeneratedDocumentExport(output, 'pptx');
            case 'package_to_skill':
              File('${output.path}${Platform.pathSeparator}SKILL.md')
                  .writeAsStringSync('# skill');
              File('${output.path}${Platform.pathSeparator}skill_manifest.yaml')
                  .writeAsStringSync('name: skill');
            case 'kb_bound_agent_generation':
              File('${output.path}${Platform.pathSeparator}agent_manifest.json')
                  .writeAsStringSync('{"name":"agent"}');
              File('${output.path}${Platform.pathSeparator}agent_profile.yaml')
                  .writeAsStringSync('name: agent');
          }
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.runPrdP0ProductE2E(input.path);

    expect(
        requests.map((request) => request.actionId),
        containsAll([
          'batch_import_documents',
          'document_understanding',
          'knowledge_base_build',
          'rag_query',
          'generate_markdown',
          'package_to_skill',
          'kb_bound_agent_generation',
        ]));
    expect(requests.map((request) => request.actionId),
        isNot(contains('generate_docx')));
    expect(requests.map((request) => request.actionId),
        isNot(contains('generate_pdf')));
    expect(requests.map((request) => request.actionId),
        isNot(contains('generate_pptx')));
    expect(controller.state.hasPrdP0Evidence, isTrue);
    expectMainKnowledgeArtifacts(workspace, controller.state);
    final evidence = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}prd_p0${Platform.pathSeparator}prd_p0_e2e_evidence.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(evidence['status'], 'pass');
    expect(evidence['knowledge_bases'], hasLength(3));
    expect((evidence['generated_documents'] as List),
        containsAll(['D1', 'D2', 'D3']));
    expect(evidence['external_skill_imported'], isTrue);
    expect(
        File('${workspace.path}${Platform.pathSeparator}prd_p0${Platform.pathSeparator}localized_skills${Platform.pathSeparator}S2${Platform.pathSeparator}SKILL.md')
            .readAsStringSync(),
        contains('本地化写作 Skill S2'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}localized_writing_skill${Platform.pathSeparator}S2${Platform.pathSeparator}localized_skill_manifest.json')
            .readAsStringSync(),
        contains('"source_mode": "external_skill_fusion"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}external_imported_skill${Platform.pathSeparator}S0${Platform.pathSeparator}external_skill_manifest.json')
            .readAsStringSync(),
        contains('"source_mode": "external_import"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}agent_generation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('"parent_multi_agent"'),
          contains('"simple_agents"'),
          contains('"advanced_agents"'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}children${Platform.pathSeparator}W_B${Platform.pathSeparator}agent_manifest.json')
            .readAsStringSync(),
        contains('"parent_workspace_id": "W_M"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001${Platform.pathSeparator}a2a_session_manifest.json')
            .readAsStringSync(),
        contains('"conflict_detection_enabled": true'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_manifest.json')
            .readAsStringSync(),
        contains('"operation": "copy"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations${Platform.pathSeparator}agent_binding_manifest.json')
            .readAsStringSync(),
        contains('"status": "bound"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}product_config${Platform.pathSeparator}advanced_agent_config.json')
            .readAsStringSync(),
        allOf(
          contains('"secret_source": "env_only"'),
          contains('"simple_agent"'),
          contains('"advanced_agent"'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}permission_audit.json')
            .readAsStringSync(),
        contains('"computer_use_disabled"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}exports${Platform.pathSeparator}agent_package_README.md')
            .readAsStringSync(),
        contains('Agent 导出包'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}prd_p0${Platform.pathSeparator}agent_workspaces${Platform.pathSeparator}W_A${Platform.pathSeparator}agent_manifest.json')
            .readAsStringSync(),
        contains('"workspace_id": "W_A"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}prd_p0${Platform.pathSeparator}agent_workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}children${Platform.pathSeparator}W_B${Platform.pathSeparator}agent_manifest.json')
            .readAsStringSync(),
        contains('"parent_workspace_id": "W_M"'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}prd_p0${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001${Platform.pathSeparator}a2a_collaboration_report.md')
            .readAsStringSync(),
        contains('A2A 协作摘要'));
  });

  test('workspace artifact preview reads only bounded text artifacts',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    final artifact = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}SKILL.md');
    artifact.parent.createSync(recursive: true);
    artifact.writeAsStringSync('# Real Skill\n${'body ' * 200}');

    final preview = await controller.readWorkspaceTextArtifact(artifact.path,
        maxCharacters: 40);
    expect(preview, contains('# Real Skill'));
    expect(preview, contains('预览已截断'));

    final outside = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}outside_skill.md');
    outside.writeAsStringSync('# outside');
    addTearDown(() {
      if (outside.existsSync()) outside.deleteSync();
    });
    final blocked = await controller.readWorkspaceTextArtifact(outside.path);
    expect(blocked, contains('不在当前工作区'));

    final binary = File(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}asset.bin');
    binary.writeAsBytesSync([1, 2, 3]);
    final unsupported = await controller.readWorkspaceTextArtifact(binary.path);
    expect(unsupported, contains('仅支持文本产物'));
  });

  testWidgets('prd artifact center lists exported Agent dialogue',
      (tester) async {
    await pumpWorkbench(tester, setupWorkspace: (workspace) async {
      final dialogueExportDir = Directory(
          '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export')
        ..createSync(recursive: true);
      File('${dialogueExportDir.path}${Platform.pathSeparator}agent_dialogue_export.md')
          .writeAsStringSync('# Agent dialogue export');
    });

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-artifact-center')));
    await tester.tap(find.byKey(const Key('sidebar-artifact-center')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('artifact-center-catalog')), findsOneWidget);
    expect(find.text('助手对话导出'), findsOneWidget);
    expect(find.textContaining('chat export'), findsOneWidget);
    expect(find.byKey(const Key('artifact-center-export-selected')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('prd artifact center exports bounded file and directory artifacts',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    final skillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    final skillFile = File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
      ..writeAsStringSync('# Real Skill');
    final fileManifestPath = await controller.exportWorkspaceArtifact(
      artifactPath: skillFile.path,
      artifactLabel: 'SKILL.md 草稿',
    );
    final fileManifest =
        jsonDecode(File(fileManifestPath).readAsStringSync()) as Map;
    expect(fileManifest['schema_version'], 'prd_v3_artifact_center_export.v1');
    expect(fileManifest['artifact_kind'], 'file');
    expect(fileManifest['bounded_to_workspace'], isTrue);
    expect(File(fileManifest['exported_path'] as String).readAsStringSync(),
        contains('# Real Skill'));

    final directoryManifestPath = await controller.exportWorkspaceArtifact(
      artifactPath: skillDir.path,
      artifactLabel: 'Skill 目录导出',
    );
    final directoryManifest =
        jsonDecode(File(directoryManifestPath).readAsStringSync()) as Map;
    expect(directoryManifest['artifact_kind'], 'directory');
    expect(
        File('${directoryManifest['exported_path']}${Platform.pathSeparator}SKILL.md')
            .existsSync(),
        isTrue);
    expect(
        File('${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}artifact_export_history.jsonl')
            .readAsStringSync(),
        contains('prd_v3_artifact_center_export.v1'));

    final outside = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}outside_artifact.md')
      ..writeAsStringSync('# outside');
    addTearDown(() {
      if (outside.existsSync()) outside.deleteSync();
    });
    final rejected = await controller.exportWorkspaceArtifact(
      artifactPath: outside.path,
      artifactLabel: 'outside',
    );
    expect(rejected, isEmpty);
    expect(controller.state.lastError, contains('不在当前工作区'));
  });

  test('prd artifact center deletion uses owned generated document scope',
      () async {
    final workspace = await createWorkspace();
    final doc = Directory('${workspace.path}${Platform.pathSeparator}doc')
      ..createSync(recursive: true);
    final export = Directory('${workspace.path}${Platform.pathSeparator}export')
      ..createSync(recursive: true);
    File('${doc.path}${Platform.pathSeparator}generated.md')
        .writeAsStringSync('# generated from product flow');
    File('${doc.path}${Platform.pathSeparator}reading_notes.md')
        .writeAsStringSync('# reading notes from product flow');
    File('${export.path}${Platform.pathSeparator}reading_notes_export.md')
        .writeAsStringSync('# exported reading notes');
    File('${export.path}${Platform.pathSeparator}export_manifest.json')
        .writeAsStringSync('{"schema_version":"test_export_manifest.v1"}');
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    expect(controller.state.hasMarkdown, isTrue);
    expect(controller.state.hasExportedDocument, isTrue);

    await controller.clearRecentTaskArtifacts('doc');

    expect(
        Directory('${workspace.path}${Platform.pathSeparator}doc').existsSync(),
        isFalse);
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}export')
            .existsSync(),
        isFalse);
    expect(controller.state.hasMarkdown, isFalse);
    expect(controller.state.hasExportedDocument, isFalse);
  });

  test('prd workbook creation and switching persists across restart', () async {
    final workspace = await createWorkspace();
    final input = Directory('${workspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha workbook source');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_source_manifest.v1',
      'source_path': input.path,
      'sources': [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
          'workspace_path': '${input.path}${Platform.pathSeparator}alpha.md',
          'extension': '.md',
        }
      ]
    }));
    final kbCatalogDir =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    File('${kbCatalogDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': '产品研究知识库',
          'source_documents': [
            {'document_id': 'doc_alpha'}
          ],
        }
      ],
    }));
    final skillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Skill');
    final agentDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agent_manifest.json')
        .writeAsStringSync('{"agent_id":"A"}');
    final auditDir =
        Directory('${workspace.path}${Platform.pathSeparator}audit')
          ..createSync(recursive: true);
    File('${auditDir.path}${Platform.pathSeparator}audit_report.json')
        .writeAsStringSync('{"status":"pass"}');
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    await controller.createOrSwitchWorkbook('产品研究工作本');
    await controller.createOrSwitchWorkbook('运营复盘工作本');

    final manifest = File(
        '${workspace.path}${Platform.pathSeparator}workbooks${Platform.pathSeparator}workbook_manifest.json');
    expect(manifest.existsSync(), isTrue);
    final payload = jsonDecode(manifest.readAsStringSync()) as Map;
    expect(payload['schema_version'], 'prd_v2_workbook_manifest.v1');
    expect(payload['current_workbook'], '运营复盘工作本');
    final activeWorkbook = (payload['workbooks'] as List)
        .whereType<Map>()
        .firstWhere((row) => row['name'] == '运营复盘工作本');
    final assetIndex =
        (activeWorkbook['asset_index'] as Map).cast<String, dynamic>();
    expect(assetIndex['schema_version'], 'prd_v2_workbook_asset_index.v1');
    expect(assetIndex['workspace_boundary'], workspace.path);
    expect(assetIndex['source_manifest_path'],
        '${workspace.path}${Platform.pathSeparator}source_manifest.json');
    expect(assetIndex['document_ids'], contains('doc_alpha'));
    expect(assetIndex['knowledge_base_ids'], contains('K1'));
    expect(assetIndex['knowledge_index_artifacts'], isA<List>());
    expect(assetIndex['skill_artifacts'], isNotEmpty);
    expect(assetIndex['agent_artifacts'], isNotEmpty);
    expect(assetIndex['audit_artifacts'], isNotEmpty);
    expect(assetIndex['secret_plaintext_written'], isFalse);
    expect(assetIndex['directory_isolation'], 'single_workspace_asset_index');
    expect(controller.state.currentWorkbookName, '运营复盘工作本');
    expect(controller.state.workbookNames,
        containsAll(['默认工作本', '产品研究工作本', '运营复盘工作本']));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.currentWorkbookName, '运营复盘工作本');
    expect(reloaded.state.workbookManifestPath, manifest.path);
    expect(reloaded.state.workbookNames, containsAll(['产品研究工作本', '运营复盘工作本']));
  });

  test('prd workbook deletion persists across restart', () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    await controller.createOrSwitchWorkbook('产品研究工作本');
    await controller.createOrSwitchWorkbook('运营复盘工作本');
    await controller.deleteWorkbook('产品研究工作本');

    final manifest = File(
        '${workspace.path}${Platform.pathSeparator}workbooks${Platform.pathSeparator}workbook_manifest.json');
    var payload =
        jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
    var workbookNames = (payload['workbooks'] as List)
        .whereType<Map>()
        .map((row) => row['name'])
        .toList();
    expect(workbookNames, isNot(contains('产品研究工作本')));
    expect(workbookNames, containsAll(['默认工作本', '运营复盘工作本']));
    expect(payload['current_workbook'], '运营复盘工作本');
    expect(controller.state.workbookNames, isNot(contains('产品研究工作本')));
    expect(controller.state.currentWorkbookName, '运营复盘工作本');

    await controller.deleteWorkbook('运营复盘工作本');
    payload = jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
    workbookNames = (payload['workbooks'] as List)
        .whereType<Map>()
        .map((row) => row['name'])
        .toList();
    expect(workbookNames, ['默认工作本']);
    expect(payload['current_workbook'], '默认工作本');
    expect(controller.state.workbookNames, ['默认工作本']);
    expect(controller.state.currentWorkbookName, '默认工作本');

    await controller.deleteWorkbook('默认工作本');
    expect(controller.state.lastError, contains('至少保留一个工作本'));
    expect(controller.state.workbookNames, ['默认工作本']);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.currentWorkbookName, '默认工作本');
    expect(reloaded.state.workbookNames, ['默认工作本']);
    expect(reloaded.state.workbookNames, isNot(contains('产品研究工作本')));
    expect(reloaded.state.workbookNames, isNot(contains('运营复盘工作本')));
  });

  test('prd workbook asset index refreshes after product artifacts are added',
      () async {
    final workspace = await createWorkspace();
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (_) async => const CoreBridgeProcessResult(
                exitCode: 0, stdout: 'ok', stderr: ''),
          ),
          coreCli: 'heitang-kb-forge',
          coreWorkingDirectory: Directory.current.path,
          configuredWorkspace: workspace.path,
          isWebRuntime: false,
        );

    final controller = buildController();
    await controller.initialize();
    await controller.createOrSwitchWorkbook('产品研究工作本');
    final manifestPath =
        '${workspace.path}${Platform.pathSeparator}workbooks${Platform.pathSeparator}workbook_manifest.json';
    var payload = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    var activeWorkbook = (payload['workbooks'] as List)
        .whereType<Map>()
        .firstWhere((row) => row['name'] == '产品研究工作本');
    expect((activeWorkbook['asset_index'] as Map)['document_ids'], isEmpty);

    final input = Directory('${workspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha workbook source');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_source_manifest.v1',
      'source_path': input.path,
      'sources': [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
          'workspace_path': '${input.path}${Platform.pathSeparator}alpha.md',
          'extension': '.md',
        }
      ]
    }));
    final kbCatalogDir =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    File('${kbCatalogDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {'kb_id': 'K1', 'kb_name': '产品研究知识库'}
      ],
    }));
    final skillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Skill');
    final skillOps = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations')
      ..createSync(recursive: true);
    final skillBindingPath =
        '${skillOps.path}${Platform.pathSeparator}agent_binding_manifest.json';
    File(skillBindingPath).writeAsStringSync('{"status":"bound"}');
    final skillExportDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}exports')
      ..createSync(recursive: true);
    final skillExportPath =
        '${skillExportDir.path}${Platform.pathSeparator}skills_export.md';
    File(skillExportPath).writeAsStringSync('# exported Skill');
    final agentDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agent_manifest.json')
        .writeAsStringSync('{"agent_id":"A"}');
    final dialogueExportDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export')
      ..createSync(recursive: true);
    final dialogueExportPath =
        '${dialogueExportDir.path}${Platform.pathSeparator}agent_dialogue_export.md';
    File(dialogueExportPath).writeAsStringSync('# dialogue export');
    final multiAgentDir =
        Directory('${workspace.path}${Platform.pathSeparator}multi_agent')
          ..createSync(recursive: true);
    final discussionPath =
        '${multiAgentDir.path}${Platform.pathSeparator}multi_agent_discussion.md';
    File(discussionPath).writeAsStringSync('# A2A discussion');
    final a2aDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001')
      ..createSync(recursive: true);
    final a2aSessionManifestPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_session_manifest.json';
    File(a2aSessionManifestPath).writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_a2a_session_manifest.v1',
      'a2a_session_id': 'A2A_001',
      'topic': 'industrial collaboration',
      'participant_agent_ids': ['B', 'C'],
      'status': 'completed',
    }));
    final a2aReportPath =
        '${a2aDir.path}${Platform.pathSeparator}a2a_collaboration_report.md';
    File(a2aReportPath).writeAsStringSync('# A2A report');

    final reloaded = buildController();
    await reloaded.initialize();
    payload = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    activeWorkbook = (payload['workbooks'] as List)
        .whereType<Map>()
        .firstWhere((row) => row['name'] == '产品研究工作本');
    final refreshedIndex =
        (activeWorkbook['asset_index'] as Map).cast<String, dynamic>();
    expect(activeWorkbook['document_count'], 1);
    expect(activeWorkbook['knowledge_base_count'], 1);
    expect(refreshedIndex['document_ids'], contains('doc_alpha'));
    expect(refreshedIndex['knowledge_base_ids'], contains('K1'));
    expect(refreshedIndex['skill_artifacts'], isNotEmpty);
    expect(refreshedIndex['agent_artifacts'], isNotEmpty);
    expect(refreshedIndex['skill_artifacts'], contains(skillBindingPath));
    expect(refreshedIndex['skill_artifacts'], contains(skillExportPath));
    expect(refreshedIndex['agent_artifacts'], contains(dialogueExportPath));
    expect(refreshedIndex['agent_artifacts'], contains(discussionPath));
    expect(refreshedIndex['agent_artifacts'], contains(a2aSessionManifestPath));
    expect(refreshedIndex['agent_artifacts'], contains(a2aReportPath));
    expect(reloaded.state.a2aSessionManifestPath, a2aSessionManifestPath);
    expect(reloaded.state.a2aWorkspaceReportPath, a2aReportPath);
    expect(reloaded.state.a2aTopic, 'industrial collaboration');
    expect(activeWorkbook['updated_at'], isNotNull);
  });
}
