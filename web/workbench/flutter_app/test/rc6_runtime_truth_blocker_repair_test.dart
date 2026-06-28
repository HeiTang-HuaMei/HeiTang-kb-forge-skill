import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/features/knowledge_base/services/okf_semantic_chunk_service.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller_io.dart';
import 'package:heitang_workbench/workbench/task_model.dart';
import 'package:heitang_workbench/workbench/task_workbench.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Directory> createWorkspace() async {
    final dir = Directory.systemTemp.createTempSync('kb_forge_rc6_widget_');
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

  Future<void> pumpWorkbench(
    WidgetTester tester, {
    Future<void> Function(Directory workspace)? setupWorkspace,
    LocalCoreBridge coreBridge = const LocalCoreBridge(),
    int initialSelectedIndex = 0,
    Size surfaceSize = const Size(1366, 768),
    void Function(Directory workspace)? captureWorkspace,
    bool waitForRuntimeReady = false,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    final workspace = await createWorkspace();
    captureWorkspace?.call(workspace);
    if (setupWorkspace != null) {
      await setupWorkspace(workspace);
    }
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        campaign6AgentRuntimeStatus: sampleCampaign6AgentRuntimeStatus,
        campaign7ConfigurationStatus: sampleCampaign7ConfigurationStatus,
        campaign9DesktopDeliveryStatus: sampleCampaign9DesktopDeliveryStatus,
        coreBridge: coreBridge,
        isWebRuntime: false,
        enableLocalCoreActions: false,
        coreWorkspace: workspace.path,
        initialSelectedIndex: initialSelectedIndex,
      ),
    );
    if (waitForRuntimeReady) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 1000)));
    }
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

  void writeWorkgroupAgentSkillFixture(
    Directory workspace, {
    String agentId = 'test_workgroup_agent',
    String agentName = '工作小组测试助手',
    String description = '用于工作小组黑盒验收。',
    String role = '处理当前工作区任务',
  }) {
    final skillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Knowledge QA Skill\n');
    final now = DateTime.now().toUtc().toIso8601String();
    final agentDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}catalog')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agents.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'heitang_agent_catalog.v1',
      'status': 'saved',
      'agents': [
        {
          'id': agentId,
          'name': agentName,
          'description': description,
          'role': role,
          'status': 'available',
          'created_at': now,
          'updated_at': now,
          'workspace_id': '默认工作本',
          'primary_knowledge_base_id': 'K1',
          'allowed_reference_kb_ids': [],
          'kb_scope_mode': 'single',
          'answer_policy_id': 'strict_evidence',
          'ai_profile_id': 'ai_profile_default_local',
          'bound_knowledge_base_ids': ['K1'],
          'bound_skill_ids': ['primary_skill'],
          'settings': {'reply_mode': 'local_fallback_until_configured'},
        }
      ],
      'updated_at': now,
    }));
    final conversationDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}conversations${Platform.pathSeparator}$agentId')
      ..createSync(recursive: true);
    File('${conversationDir.path}${Platform.pathSeparator}conversation.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'heitang_agent_conversation.v1',
      'conversation_id': 'conv_$agentId',
      'agent_id': agentId,
      'messages': [],
      'created_at': now,
      'updated_at': now,
    }));
  }

  void writeResearchAnalysisQueryFixture(Directory workspace) {
    final queryDir =
        Directory('${workspace.path}${Platform.pathSeparator}query')
          ..createSync(recursive: true);
    File('${queryDir.path}${Platform.pathSeparator}kb_query_result.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_kb_query_result.v1',
      'query': '研究分析：跨文档比较证据、风险和行动建议',
      'selected_count': 3,
      'selected': [
        {
          'chunk_id': 'research_chunk_1',
          'text': '第一份资料说明市场需求增长，但需要验证数据来源。',
          'source_path': 'research/source_a.md',
          'citation': 'research/source_a.md#chunk=1',
          'score': 0.91,
        },
        {
          'chunk_id': 'research_chunk_2',
          'text': '第二份资料指出供应链风险，需要在结论中单独标注。',
          'source_path': 'research/source_b.md',
          'citation': 'research/source_b.md#chunk=2',
          'score': 0.86,
        },
        {
          'chunk_id': 'research_chunk_3',
          'text': '第三份资料给出行动建议，但缺少成本假设。',
          'source_path': 'research/source_c.md',
          'citation': 'research/source_c.md#chunk=3',
          'score': 0.79,
        },
      ],
    }));
  }

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

  void writeKnowledgeCanvasFixture(Directory workspace) {
    final input = Directory('${workspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha source for knowledge canvas');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'rc10_source_manifest.v1',
      'status': 'imported',
      'source_path': input.path,
      'source_name': 'input',
      'source_count': 1,
      'sources': [
        {
          'document_id': 'doc_alpha',
          'source_path': '${input.path}${Platform.pathSeparator}alpha.md',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
          'source_type': 'local_file',
          'size_bytes': 33,
        },
      ],
      'workspace': workspace.path,
    }));
    final kb = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'test_kb_manifest.v1',
      'status': 'searchable',
      'kb_id': 'current_kb',
      'name': 'Canvas Test KB',
    }));
    File('${kb.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {
        'chunk_id': 'chunk_alpha_001',
        'source_path': '${input.path}${Platform.pathSeparator}alpha.md',
        'text': 'alpha source for knowledge canvas',
      },
    ]));
    File('${kb.path}${Platform.pathSeparator}quality_report.json')
        .writeAsStringSync('{"status":"pass"}');
    final catalogRoot =
        Directory('${workspace.path}${Platform.pathSeparator}knowledge_bases')
          ..createSync(recursive: true);
    final catalogKb =
        Directory('${catalogRoot.path}${Platform.pathSeparator}K_CANVAS_TEST')
          ..createSync(recursive: true);
    File('${catalogKb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"status":"searchable"}');
    File('${catalogKb.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(jsonl([
      {
        'chunk_id': 'chunk_alpha_001',
        'source_path': 'alpha.md',
        'text': 'alpha source for knowledge canvas',
      },
    ]));
    File('${catalogRoot.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K_CANVAS_TEST',
          'kb_name': 'Canvas Test KB',
          'status': 'searchable',
          'current_version': 'v1',
          'source_documents': [
            {'document_id': 'doc_alpha', 'source_name': 'alpha.md'}
          ],
          'chunk_count': 1,
        },
      ],
    }));
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

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), '没有这个对象');
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const Key('topbar-search-option-retrieval-verification')),
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
    expect(find.byKey(const Key('agent-primary-entry-switch')), findsOneWidget);
    expect(find.text('助手对话'), findsOneWidget);
    await tester.tap(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('助手配置'),
        ),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('创建助手并进入对话'), findsWidgets);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('运行 Owner input 链路'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);
    await tester.tap(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('工作小组'),
        ),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('multi-agent-discussion-product-flow')),
        findsOneWidget);
    expect(find.text('启动工作小组'), findsOneWidget);
    expect(find.textContaining('arbitrary shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('p2 workgroup basic runtime button creates local evidence',
      (tester) async {
    late Directory workspace;
    await pumpWorkbench(
      tester,
      initialSelectedIndex: 7,
      surfaceSize: const Size(1440, 900),
      captureWorkspace: (dir) => workspace = dir,
      setupWorkspace: (workspace) async {
        final skillDir = Directory(
            '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
          ..createSync(recursive: true);
        File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
            .writeAsStringSync('# Knowledge QA Skill\n');
        final now = DateTime.now().toUtc().toIso8601String();
        final agentDir = Directory(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}catalog')
          ..createSync(recursive: true);
        File('${agentDir.path}${Platform.pathSeparator}agents.json')
            .writeAsStringSync(jsonEncode({
          'schema_version': 'heitang_agent_catalog.v1',
          'status': 'saved',
          'agents': [
            {
              'id': 'test_workgroup_agent',
              'name': '工作小组测试助手',
              'description': '用于 P2-1 工作小组黑盒验收。',
              'role': '处理当前工作区任务',
              'status': 'available',
              'created_at': now,
              'updated_at': now,
              'workspace_id': '默认工作本',
              'primary_knowledge_base_id': 'K1',
              'allowed_reference_kb_ids': [],
              'kb_scope_mode': 'single',
              'answer_policy_id': 'strict_evidence',
              'ai_profile_id': 'ai_profile_default_local',
              'bound_knowledge_base_ids': ['K1'],
              'bound_skill_ids': ['primary_skill'],
              'settings': {'reply_mode': 'local_fallback_until_configured'},
            }
          ],
          'updated_at': now,
        }));
        final conversationDir = Directory(
            '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}conversations${Platform.pathSeparator}test_workgroup_agent')
          ..createSync(recursive: true);
        File('${conversationDir.path}${Platform.pathSeparator}conversation.json')
            .writeAsStringSync(jsonEncode({
          'schema_version': 'heitang_agent_conversation.v1',
          'conversation_id': 'conv_test_workgroup_agent',
          'agent_id': 'test_workgroup_agent',
          'messages': [],
          'created_at': now,
          'updated_at': now,
        }));
      },
      waitForRuntimeReady: true,
    );

    expect(find.byKey(const Key('agent-primary-entry-switch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-primary-entry-工作小组')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    final button =
        find.byKey(const Key('workgroup-basic-runtime-evidence-button'));
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (button.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(button).onPressed != null) {
        break;
      }
    }
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester.widget<FilledButton>(button).onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    final summaryPath =
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}workgroup_basic_runtime_summary.json';
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (File(summaryPath).existsSync()) {
        break;
      }
    }
    expect(tester.takeException(), isNull);
    expect(File(summaryPath).existsSync(), isTrue);
    final summary = jsonDecode(File(summaryPath).readAsStringSync()) as Map;
    expect(summary['status'], 'pass');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['black_box_status'], 'passed');
    expect(
        summary['ui_blackbox_path'], 'Agent -> Work Group -> Start Work Group');
    expect(
        File('${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion.md')
            .existsSync(),
        isTrue);
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'workgroup_basic_runtime_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    expect(find.textContaining('Provider'), findsNothing);
    expect(find.textContaining('Adapter'), findsNothing);
    expect(find.textContaining('Parser'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('p2 research analysis workgroup button creates research evidence',
      (tester) async {
    late Directory workspace;
    await pumpWorkbench(
      tester,
      initialSelectedIndex: 7,
      surfaceSize: const Size(1440, 900),
      captureWorkspace: (dir) => workspace = dir,
      setupWorkspace: (workspace) async {
        writeWorkgroupAgentSkillFixture(
          workspace,
          agentId: 'test_research_workgroup_agent',
          agentName: '研究分析测试助手',
          description: '用于 P2-3 研究分析工作组黑盒验收。',
          role: '处理当前研究分析任务',
        );
        writeResearchAnalysisQueryFixture(workspace);
      },
      waitForRuntimeReady: true,
    );

    expect(find.byKey(const Key('agent-primary-entry-switch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-primary-entry-工作小组')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    final input = find.byKey(const Key('a2a-topic-input'));
    expect(input, findsOneWidget);
    final editable = find.descendant(
      of: input,
      matching: find.byType(EditableText),
    );
    expect(editable, findsOneWidget);
    final editableText = tester.widget<EditableText>(editable);
    editableText.controller.text = 'P2-3 研究分析：比较资料证据、风险和建议。';
    editableText.controller.selection = TextSelection.collapsed(
      offset: editableText.controller.text.length,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(input).controller?.text,
      contains('P2-3'),
    );

    final button =
        find.byKey(const Key('workgroup-basic-runtime-evidence-button'));
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (button.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(button).onPressed != null) {
        break;
      }
    }
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester.widget<FilledButton>(button).onPressed?.call();
      await Future<void>.delayed(const Duration(seconds: 1));
    });

    final workgroupSummaryPath =
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}workgroup_basic_runtime_summary.json';
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (File(workgroupSummaryPath).existsSync()) {
        break;
      }
    }
    expect(File(workgroupSummaryPath).existsSync(), isTrue);
    final workgroupSummary =
        jsonDecode(File(workgroupSummaryPath).readAsStringSync()) as Map;
    expect(workgroupSummary['topic'].toString(), contains('P2-3'));

    final summaryPath =
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}research_analysis_workgroup_summary.json';
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (File(summaryPath).existsSync()) {
        break;
      }
    }
    expect(tester.takeException(), isNull);
    expect(File(summaryPath).existsSync(), isTrue);
    final summary = jsonDecode(File(summaryPath).readAsStringSync()) as Map;
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'research_analysis_workgroup');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['black_box_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['p2_4_status'], 'not_closed_by_p2_3');
    expect(summary['ui_blackbox_path'],
        'Agent -> Work Group -> Collaboration task input -> Start Work Group');
    expect(File(summary['source_trace_path'] as String).existsSync(), isTrue);
    expect(readJsonlFile(summary['source_trace_path'] as String).length,
        greaterThan(1));
    expect(
        File(summary['validation_report_path'] as String).existsSync(), isTrue);
    expect(File(summary['research_brief_path'] as String).existsSync(), isTrue);
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'research_analysis_workgroup_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'research_analysis_workgroup_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(find.textContaining('Provider'), findsNothing);
    expect(find.textContaining('Adapter'), findsNothing);
    expect(find.textContaining('Parser'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('p2 workgroup fixture loads agent profile and skill', () async {
    final workspace = await createWorkspace();
    final skillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Knowledge QA Skill\n');
    final now = DateTime.now().toUtc().toIso8601String();
    final agentDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}catalog')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agents.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'heitang_agent_catalog.v1',
      'status': 'saved',
      'agents': [
        {
          'id': 'test_workgroup_agent',
          'name': '工作小组测试助手',
          'description': '用于 P2-1 工作小组黑盒验收。',
          'role': '处理当前工作区任务',
          'status': 'available',
          'created_at': now,
          'updated_at': now,
          'workspace_id': '默认工作本',
          'primary_knowledge_base_id': 'K1',
          'allowed_reference_kb_ids': [],
          'kb_scope_mode': 'single',
          'answer_policy_id': 'strict_evidence',
          'ai_profile_id': 'ai_profile_default_local',
          'bound_knowledge_base_ids': ['K1'],
          'bound_skill_ids': ['primary_skill'],
          'settings': {'reply_mode': 'local_fallback_until_configured'},
        }
      ],
      'updated_at': now,
    }));
    final conversationDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}conversations${Platform.pathSeparator}test_workgroup_agent')
      ..createSync(recursive: true);
    File('${conversationDir.path}${Platform.pathSeparator}conversation.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'heitang_agent_conversation.v1',
      'conversation_id': 'conv_test_workgroup_agent',
      'agent_id': 'test_workgroup_agent',
      'messages': [],
      'created_at': now,
      'updated_at': now,
    }));

    final controller = Rc6RuntimeController(
      coreBridge: const LocalCoreBridge(),
      coreCli: 'heitang-kb-forge',
      coreWorkingDirectory: Directory.current.path,
      configuredWorkspace: workspace.path,
      isWebRuntime: false,
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state.hasSkill, isTrue);
    expect(controller.state.hasAgentProfiles, isTrue);
    expect(controller.state.agentProfiles.single.name, '工作小组测试助手');
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    await controller.importFilePath(first.path);
    await controller.importFilePath(second.path);

    final manifestFile = File(
        '${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json');
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
        File('${activeWorkspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}alpha.md')
            .existsSync(),
        isTrue);
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}beta.txt')
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

  test('module4 UI008 duplicate content import records content hash and dedupes',
      () async {
    final workspace = await createWorkspace();
    final sampleRoot = Directory([
      Directory.current.path,
      '..',
      '..',
      '..',
      'docs',
      'design_source',
      'test_samples',
    ].join(Platform.pathSeparator));
    expect(sampleRoot.existsSync(), isTrue);
    final sourceDir =
        Directory('${workspace.path}${Platform.pathSeparator}ui008_sources')
          ..createSync(recursive: true);
    for (final name in const [
      'UI008_TXT_A.txt',
      'UI008_DUPLICATE_A_COPY.txt',
      'UI008_TXT_B.txt',
    ]) {
      File('${sampleRoot.path}${Platform.pathSeparator}$name')
          .copySync('${sourceDir.path}${Platform.pathSeparator}$name');
    }
    final requests = <CoreBridgeRequest>[];
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (request) async {
              requests.add(request);
              final output = Directory(request.outputPath!)
                ..createSync(recursive: true);
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync(
                      '{"status":"completed","imported_count":2,"duplicate_count":1}');
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    await controller.importFolderPath(sourceDir.path);

    final manifest = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final sources = (manifest['sources'] as List).cast<Map>();
    final duplicates =
        ((manifest['duplicate_sources'] as List?) ?? const []).cast<Map>();
    expect(manifest['source_count'], 2);
    expect(manifest['duplicate_count'], 1);
    expect(sources, hasLength(2));
    expect(duplicates, hasLength(1));
    expect(sources.map((source) => source['content_hash']),
        everyElement(isNotEmpty));
    expect(
        sources.map((source) => source['content_hash']).toSet(), hasLength(2));
    expect(sources.map((source) => source['content_hash']),
        contains(duplicates.single['content_hash']));
    expect(duplicates.single['duplicate_of'], isNotEmpty);
    expect(controller.state.sourceCount, 2);
    expect(controller.state.sourceRecords, hasLength(2));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.sourceRecords, hasLength(2));
    expect(requests.map((request) => request.actionId),
        everyElement('batch_import_documents'));
  });

  test('module4 UI008 parse partial failure reports failed sources', () async {
    final workspace = await createWorkspace();
    final sampleRoot = Directory([
      Directory.current.path,
      '..',
      '..',
      '..',
      'docs',
      'design_source',
      'test_samples',
    ].join(Platform.pathSeparator));
    expect(sampleRoot.existsSync(), isTrue);
    final sourceDir =
        Directory('${workspace.path}${Platform.pathSeparator}ui008_parse')
          ..createSync(recursive: true);
    for (final name in const [
      'UI008_TXT_A.txt',
      'UI008_BAD_EMPTY.txt',
    ]) {
      File('${sampleRoot.path}${Platform.pathSeparator}$name')
          .copySync('${sourceDir.path}${Platform.pathSeparator}$name');
    }
    final requests = <CoreBridgeRequest>[];
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (request) async {
              requests.add(request);
              final output = Directory(request.outputPath!)
                ..createSync(recursive: true);
              switch (request.actionId) {
                case 'batch_import_documents':
                  File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                      .writeAsStringSync(
                          '{"status":"completed","imported_count":2}');
                case 'document_understanding':
                  writeDuRecords(workspace, ['UI008_TXT_A.txt']);
                  File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                      .writeAsStringSync(jsonEncode({
                    'status': 'completed',
                    'normalized_source_count': 1,
                    'success_count': 1,
                    'failed_count': 1,
                    'skipped_count': 0,
                    'items': [
                      {
                        'relative_path': 'UI008_TXT_A.txt',
                        'status': 'success',
                      },
                      {
                        'relative_path': 'UI008_BAD_EMPTY.txt',
                        'status': 'failed',
                        'error_message': '文件无法解析：文档为空。',
                      },
                    ],
                  }));
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

    final controller = buildController();
    await controller.initialize();
    await controller.importFolderPath(sourceDir.path);
    expect(controller.state.sourceRecords, hasLength(2));

    await controller.parseAndChunkSources();

    expect(controller.state.parseReportPath, isNotEmpty);
    expect(controller.state.lastMessage, contains('1 个来源可用'));
    expect(controller.state.lastError, contains('1 个失败'));
    expect(controller.state.sourceRecords, hasLength(2));
    expect(requests.map((request) => request.actionId),
        containsAll(['batch_import_documents', 'document_understanding']));
  });

  test('module4 unsupported import fails explainably without source manifest',
      () async {
    final workspace = await createWorkspace();
    final unsupported =
        File('${workspace.path}${Platform.pathSeparator}UI008_BAD.exe')
          ..writeAsBytesSync([0, 1, 2, 3]);
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    await controller.importFilePath(unsupported.path);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(requests, isEmpty);
    expect(controller.state.phase, Rc6RuntimePhase.failed);
    expect(controller.state.lastError, contains('暂不支持该文件格式'));
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
            .existsSync(),
        isFalse);
    final ledger = readJsonlFile(
        '${activeWorkspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(ledger.map((row) => row['event_type']), contains('failure_event'));
    expect(ledger.map((row) => row['error_message']).join('\n'),
        contains('暂不支持该文件格式'));
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
        containsPair('button_enabled', true));
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
        isTrue);
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
              '${output.parent.path}${Platform.pathSeparator}du${Platform.pathSeparator}normalized_sources';
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final input =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}input')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha real document');
    File('${input.path}${Platform.pathSeparator}beta.md')
        .writeAsStringSync('beta real document');
    File('${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
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
    Directory('${activeWorkspace.path}${Platform.pathSeparator}du')
        .createSync(recursive: true);
    writeDuRecords(activeWorkspace, ['alpha.md', 'beta.md']);

    await controller.buildKnowledgeBase(documentIds: const ['doc_alpha']);
    expect(requests.single.actionId, 'knowledge_base_build');
    expectMainKnowledgeArtifacts(activeWorkspace, controller.state);
    expect(controller.state.knowledgeBases, hasLength(1));
    expect(controller.state.knowledgeBases.first.id, 'K1');
    expect(controller.state.knowledgeBases.first.sourceCount, 1);
    final firstCatalogFile = File(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}kb_catalog.json');
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
    final alphaKb =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K1');
    expect(alphaKb.sourceCount, 1);
    final fullKb = controller.state.knowledgeBases
        .firstWhere((kb) => kb.id != 'K1' && kb.sourceCount == 2);
    final fullKbId = fullKb.id;
    expect(fullKb.sourceCount, 2);

    await controller.copyKnowledgeBase(fullKbId);
    final copyId = '${fullKbId}_COPY1';
    expectIndustrialIndexArtifacts(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$copyId',
        kbId: copyId);
    await controller.mergeKnowledgeBases([fullKbId, copyId]);
    expectIndustrialIndexArtifacts(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K_MERGED1',
        kbId: 'K_MERGED1');
    await controller.splitKnowledgeBase(fullKbId);
    final splitId = '${fullKbId}_SPLIT1';
    expectIndustrialIndexArtifacts(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$splitId',
        kbId: splitId);
    expect(controller.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', fullKbId, copyId, 'K_MERGED1', splitId]));
    expect(fullKb.versionCount, 1);

    await controller.updateKnowledgeBaseIncremental(fullKbId);
    expectIndustrialIndexArtifacts(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$fullKbId',
        kbId: fullKbId);
    final updatedFullKb =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == fullKbId);
    expect(updatedFullKb.operation, 'incremental_update');
    expect(updatedFullKb.versionCount, 2);

    await controller.compareKnowledgeBaseVersions(fullKbId);
    final comparedFullKb =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == fullKbId);
    expect(comparedFullKb.versionComparePath, isNotEmpty);
    expect(File(comparedFullKb.versionComparePath).existsSync(), isTrue);

    await controller.rollbackKnowledgeBaseVersion(fullKbId);
    expectIndustrialIndexArtifacts(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$fullKbId',
        kbId: fullKbId);
    final rolledBackFullKb =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == fullKbId);
    expect(rolledBackFullKb.operation, 'rollback');
    expect(rolledBackFullKb.versionCount, 1);
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$fullKbId${Platform.pathSeparator}rollback.log')
            .existsSync(),
        isTrue);

    await controller.rebuildKnowledgeBaseFull(fullKbId);
    expectIndustrialIndexArtifacts(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$fullKbId',
        kbId: fullKbId);
    final rebuiltFullKb =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == fullKbId);
    expect(rebuiltFullKb.operation, 'full_rebuild');

    final catalogFile = File(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}kb_catalog.json');
    final catalog =
        jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
    expect(catalog['schema_version'], 'prd_v2_knowledge_base_catalog.v1');
    expect(catalog['knowledge_bases'], isA<List>());
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K_MERGED1${Platform.pathSeparator}source_map.json')
            .existsSync(),
        isTrue);

    await controller.deleteKnowledgeBaseRecord(copyId);
    expect(controller.state.knowledgeBases.map((kb) => kb.id),
        isNot(contains(copyId)));
    expect(
        Directory(
                '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$copyId')
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final staleKb =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
          ..createSync(recursive: true);
    File('${staleKb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{}');
    await controller.importFolderPath(input.path);
    await controller.deleteImportedSource('alpha.md');

    final manifest = jsonDecode(
        File('${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final sources = (manifest['sources'] as List).cast<Map>();
    expect(sources.map((source) => source['source_name']), ['beta.txt']);
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}alpha.md')
            .existsSync(),
        isFalse);
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}input${Platform.pathSeparator}beta.txt')
            .existsSync(),
        isTrue);
    expect(
        Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
            .existsSync(),
        isFalse);
    expect(controller.state.sourceNames, ['beta.txt']);
    expect(controller.state.hasKnowledgeBase, isFalse);
  });

  test('agent dialogue preserves empty binding truth without fallback ids',
      () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'package_to_skill':
              File('${output.path}${Platform.pathSeparator}SKILL.md')
                  .writeAsStringSync('# Skill');
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final kb = Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"kb.v1"}');
    File('${kb.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync('{"text":"local evidence","source_path":"a.md"}\n');
    File('${kb.path}${Platform.pathSeparator}cards.jsonl')
        .writeAsStringSync('{"title":"card"}\n');
    File('${kb.path}${Platform.pathSeparator}qa_pairs.jsonl')
        .writeAsStringSync('{"question":"q","answer":"a"}\n');

    await controller.generateSkill();
    await controller.generateAgent();

    final manifestFile = File(
        '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent${Platform.pathSeparator}agent_manifest.json');
    final manifest = jsonDecode(manifestFile.readAsStringSync())
        as Map<String, dynamic>;
    manifest
      ..remove('kb_ids')
      ..remove('skill_ids')
      ..remove('bound_knowledge_base_ids')
      ..remove('bound_skill_ids');
    manifestFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest));

    await controller.runAgentDialogue(prompt: '无绑定时不要伪造绑定');
    expect(controller.state.agentDialogueUsedKbIds, isEmpty);
    expect(controller.state.agentDialogueUsedSkillIds, isEmpty);
    final dialogueManifestPath =
        '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}agent_dialogue_manifest.json';
    final dialogueManifest = jsonDecode(
        File(dialogueManifestPath).readAsStringSync()) as Map<String, dynamic>;
    expect(dialogueManifest['used_kb_ids'], isEmpty);
    expect(dialogueManifest['used_skill_ids'], isEmpty);
    expect(dialogueManifest['binding_truth_status'], 'unbound');
    expect(dialogueManifest['missing_binding_reasons'],
        containsAll(['missing_kb_binding', 'missing_skill_binding']));

    final chatHistory = File(
            '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}chat_history.jsonl')
        .readAsStringSync();
    expect(chatHistory, isNot(contains('"K1"')));
    expect(chatHistory, isNot(contains('"S1"')));
    expect(chatHistory, isNot(contains('reading_summary_skill')));
    expect(chatHistory, isNot(contains('local evidence')));
    expect(chatHistory, contains('未绑定知识库'));

    final exportPath = await controller.exportAgentDialogue();
    expect(File(exportPath).existsSync(), isTrue);
    final exportManifest = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export${Platform.pathSeparator}agent_dialogue_export_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(exportManifest['used_kb_ids'], isEmpty);
    expect(exportManifest['used_skill_ids'], isEmpty);
    expect(exportManifest['binding_truth_status'], 'unbound');
    expect(exportManifest['missing_binding_reasons'],
        containsAll(['missing_kb_binding', 'missing_skill_binding']));

    final runHistory = File(
            '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}audit${Platform.pathSeparator}run_history.json')
        .readAsStringSync();
    expect(runHistory, isNot(contains('"K1"')));
    expect(runHistory, isNot(contains('"S1"')));
    expect(runHistory, isNot(contains('reading_summary_skill')));
    expect(runHistory, contains('"binding_truth_status": "unbound"'));
  });

  test('agent dialogue uses real skill ids from binding manifest', () async {
    final workspace = await createWorkspace();
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'package_to_skill':
              File('${output.path}${Platform.pathSeparator}SKILL.md')
                  .writeAsStringSync('# Skill');
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final kb = Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    File('${kb.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"kb.v1"}');
    File('${kb.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync('{"text":"local evidence","source_path":"a.md"}\n');
    File('${kb.path}${Platform.pathSeparator}cards.jsonl')
        .writeAsStringSync('{"title":"card"}\n');
    File('${kb.path}${Platform.pathSeparator}qa_pairs.jsonl')
        .writeAsStringSync('{"question":"q","answer":"a"}\n');

    await controller.generateSkill();
    await controller.generateAgent();
    await controller.runAgentDialogue(prompt: '绑定 Skill 必须使用真实 id');

    expect(controller.state.agentDialogueUsedSkillIds,
        contains('knowledge_qa_skill'));
    expect(controller.state.agentDialogueUsedSkillIds, isNot(contains('S1')));
    final dialogueManifestPath =
        '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}agent_dialogue_manifest.json';
    final dialogueManifest = jsonDecode(
        File(dialogueManifestPath).readAsStringSync()) as Map<String, dynamic>;
    expect(dialogueManifest['used_skill_ids'], contains('knowledge_qa_skill'));
    expect(dialogueManifest['used_skill_ids'], isNot(contains('S1')));
    expect(dialogueManifest['binding_truth_status'], 'bound');

    final citationTrace =
        readJsonlFile(dialogueManifest['citation_trace_path'].toString());
    expect(citationTrace, isNotEmpty);
    expect(citationTrace.first['skill_ids'], contains('knowledge_qa_skill'));
    expect(citationTrace.first['skill_ids'], isNot(contains('S1')));

    final chatHistory = File(
            '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue${Platform.pathSeparator}chat_history.jsonl')
        .readAsStringSync();
    expect(chatHistory, contains('"knowledge_qa_skill"'));
    expect(chatHistory, isNot(contains('"S1"')));
  });

  test('okf semantic chunking prefers ParsedDocument canonical blocks',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    final duDir = Directory('${workspace.path}${Platform.pathSeparator}du')
      ..createSync(recursive: true);
    final normalizedPath = '${duDir.path}${Platform.pathSeparator}alpha.md';
    File(normalizedPath)
        .writeAsStringSync('# Wrong fallback\nfallback-only text');
    File('${duDir.path}${Platform.pathSeparator}document_understanding_records.jsonl')
        .writeAsStringSync('${jsonEncode({
              'relative_path': 'alpha.md',
              'normalized_path': normalizedPath,
              'parsed_document': {
                'schema_version': 'parsed_document.v1',
                'blocks': [
                  {
                    'block_id': 'doc_alpha_intro',
                    'block_type': 'paragraph',
                    'heading_path': ['Canonical'],
                    'source_path': 'materials/alpha.md#section=intro',
                    'page_or_section': 'p.7 / Intro',
                    'page_number': 7,
                    'section_id': 'sec-intro',
                    'source_span': {'start': 11, 'end': 47},
                    'text': 'canonical parsed document evidence',
                  },
                ],
              },
            })}\n');

    final result = await const OkfSemanticChunkService().materialize(
      workspace: workspace,
      kbDir: kbDir,
      kbId: 'K_OKF_CANONICAL',
      sourceDocs: [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
          'source_path': 'materials/alpha.md',
        },
        {
          'document_id': 'doc_beta',
          'source_name': 'beta.md',
          'relative_path': 'beta.md',
        },
      ],
      inputChunks: const [
        {
          'source_doc_id': 'doc_beta',
          'relative_path': 'beta.md',
          'text': 'beta fallback evidence',
          'heading_path': ['Beta'],
          'block_ids': ['doc_beta_block_001'],
        },
      ],
    );

    expect(result.chunks, hasLength(2));
    final alphaChunk = result.chunks
        .firstWhere((chunk) => chunk['source_doc_id'] == 'doc_alpha');
    final betaChunk = result.chunks
        .firstWhere((chunk) => chunk['source_doc_id'] == 'doc_beta');
    expect(alphaChunk['text'], 'canonical parsed document evidence');
    expect(alphaChunk['block_ids'], ['doc_alpha_intro']);
    expect(alphaChunk['heading_path'], ['Canonical']);
    expect(alphaChunk['source_path'], 'materials/alpha.md#section=intro');
    expect(alphaChunk['page_or_section'], 'p.7 / Intro');
    expect((alphaChunk['lineage'] as Map)['source_path'],
        'materials/alpha.md#section=intro');
    expect((alphaChunk['lineage'] as Map)['page_or_section'], 'p.7 / Intro');
    expect((alphaChunk['lineage'] as Map)['normalized_path'],
        normalizedPath);
    expect(alphaChunk['page_number'], 7);
    expect(alphaChunk['section_id'], 'sec-intro');
    expect(alphaChunk['source_span'], {'start': 11, 'end': 47});
    expect((alphaChunk['lineage'] as Map)['parsed_document_source'],
        'canonical_blocks');
    expect((alphaChunk['lineage'] as Map)['page_number'], 7);
    expect((alphaChunk['lineage'] as Map)['section_id'], 'sec-intro');
    expect((alphaChunk['lineage'] as Map)['source_span'],
        {'start': 11, 'end': 47});
    expect(alphaChunk['text'], isNot(contains('fallback-only')));
    expect(betaChunk['text'], 'beta fallback evidence');
    expect(betaChunk['block_ids'], ['doc_beta_block_001']);
    expect(betaChunk['heading_path'], ['Beta']);

    final writtenChunks = readJsonlFile(
        '${kbDir.path}${Platform.pathSeparator}chunks.jsonl');
    final writtenTrace = readJsonlFile(
        '${kbDir.path}${Platform.pathSeparator}source_trace.jsonl');
    expect(writtenChunks.map((chunk) => chunk['source_doc_id']).toSet(),
        {'doc_alpha', 'doc_beta'});
    expect(writtenTrace.map((trace) => trace['source_doc_id']).toSet(),
        {'doc_alpha', 'doc_beta'});
    expect(writtenChunks.map((chunk) => chunk['chunk_id']).toSet(),
        hasLength(writtenChunks.length));
    expect(writtenTrace.map((trace) => trace['chunk_id']).toSet(),
        hasLength(writtenTrace.length));
    final alphaTrace = writtenTrace
        .firstWhere((trace) => trace['source_doc_id'] == 'doc_alpha');
    expect(alphaTrace['source_path'], 'materials/alpha.md#section=intro');
    expect(alphaTrace['page_or_section'], 'p.7 / Intro');
    expect(alphaTrace['page_number'], 7);
    expect(alphaTrace['section_id'], 'sec-intro');
    expect(alphaTrace['source_span'], {'start': 11, 'end': 47});
    expect((alphaTrace['lineage'] as Map)['source_path'],
        'materials/alpha.md#section=intro');
    expect((alphaTrace['lineage'] as Map)['page_or_section'], 'p.7 / Intro');
    expect((alphaTrace['lineage'] as Map)['parsed_document_source'],
        'canonical_blocks');
  });

  test('okf missing-source fallback keeps chunk ids unique after parsed blocks',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    final duDir = Directory('${workspace.path}${Platform.pathSeparator}du')
      ..createSync(recursive: true);
    final normalizedPath = '${duDir.path}${Platform.pathSeparator}alpha.md';
    File(normalizedPath).writeAsStringSync('# Alpha\ncanonical alpha evidence');
    File('${duDir.path}${Platform.pathSeparator}document_understanding_records.jsonl')
        .writeAsStringSync('${jsonEncode({
              'relative_path': 'alpha.md',
              'normalized_path': normalizedPath,
              'parsed_document': {
                'schema_version': 'parsed_document.v1',
                'blocks': [
                  {
                    'block_id': 'doc_alpha_intro',
                    'block_type': 'paragraph',
                    'heading_path': ['Alpha'],
                    'text': 'canonical alpha evidence',
                  },
                ],
              },
            })}\n');

    final result = await const OkfSemanticChunkService().materialize(
      workspace: workspace,
      kbDir: kbDir,
      kbId: 'K_OKF_MISSING_FALLBACK',
      sourceDocs: const [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
        },
        {
          'document_id': 'doc_beta',
          'source_name': 'beta.md',
          'relative_path': 'beta.md',
          'summary': 'beta source summary fallback',
          'source_path': 'materials/beta.md',
          'page_or_section': 'p.9 / Beta',
          'page_number': 9,
          'section_id': 'beta-sec',
          'source_span': {'start': 12, 'end': 48},
        },
      ],
      inputChunks: const [],
    );

    expect(result.chunks, hasLength(2));
    expect(result.chunks.map((chunk) => chunk['chunk_id']).toSet(),
        hasLength(result.chunks.length));
    expect(result.sourceTraceRows.map((trace) => trace['chunk_id']).toSet(),
        hasLength(result.sourceTraceRows.length));
    final betaChunk = result.chunks
        .firstWhere((chunk) => chunk['source_doc_id'] == 'doc_beta');
    expect(betaChunk['text'], 'beta source summary fallback');
    expect(betaChunk['source_path'], 'materials/beta.md');
    expect(betaChunk['page_number'], 9);
    expect(betaChunk['section_id'], 'beta-sec');
    expect(betaChunk['source_span'], {'start': 12, 'end': 48});
    expect((betaChunk['lineage'] as Map)['fallback_reason'],
        'no_core_chunk_matched_source_doc');
    expect((betaChunk['lineage'] as Map)['chunking_strategy'],
        'okf_fallback_from_source_manifest');
    expect((betaChunk['lineage'] as Map)['source_path'], 'materials/beta.md');
    expect((betaChunk['lineage'] as Map)['page_or_section'], 'p.9 / Beta');
    expect((betaChunk['lineage'] as Map)['page_number'], 9);
    expect((betaChunk['lineage'] as Map)['section_id'], 'beta-sec');
    expect((betaChunk['lineage'] as Map)['source_span'],
        {'start': 12, 'end': 48});
    final betaTrace = result.sourceTraceRows
        .firstWhere((trace) => trace['source_doc_id'] == 'doc_beta');
    expect(betaTrace['source_path'], 'materials/beta.md');
    expect((betaTrace['lineage'] as Map)['page_or_section'], 'p.9 / Beta');
    expect(betaTrace['page_number'], 9);
    expect(betaTrace['section_id'], 'beta-sec');
    expect(betaTrace['source_span'], {'start': 12, 'end': 48});
  });

  test('okf normalized text fallback is explicitly marked as fallback',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);
    final duDir = Directory('${workspace.path}${Platform.pathSeparator}du')
      ..createSync(recursive: true);
    final normalizedPath = '${duDir.path}${Platform.pathSeparator}alpha.md';
    File(normalizedPath).writeAsStringSync(
      '# Alpha\nnormalized fallback evidence from text only',
    );
    File('${duDir.path}${Platform.pathSeparator}document_understanding_records.jsonl')
        .writeAsStringSync('${jsonEncode({
              'relative_path': 'alpha.md',
              'normalized_path': normalizedPath,
              'parsed_document': {
                'schema_version': 'parsed_document.v1',
              },
            })}\n');

    final result = await const OkfSemanticChunkService().materialize(
      workspace: workspace,
      kbDir: kbDir,
      kbId: 'K_OKF_NORMALIZED_FALLBACK',
      sourceDocs: const [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
        },
      ],
      inputChunks: const [],
    );

    expect(result.chunks, isNotEmpty);
    for (final chunk in result.chunks) {
      final lineage = chunk['lineage'] as Map;
      expect(lineage['parsed_document_source'], 'normalized_text');
      expect(lineage['chunking_strategy'], 'okf_fallback_from_normalized_text');
      expect(
        lineage['fallback_reason'],
        'parsed_document_blocks_unavailable',
      );
      expect(lineage['page_or_section'], chunk['page_or_section']);
    }
    for (final trace in result.sourceTraceRows) {
      expect(trace['lineage'], containsPair(
        'chunking_strategy',
        'okf_fallback_from_normalized_text',
      ));
    }
  });

  test('okf input chunk fallback is explicitly marked as fallback', () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);

    final result = await const OkfSemanticChunkService().materialize(
      workspace: workspace,
      kbDir: kbDir,
      kbId: 'K_OKF_INPUT_FALLBACK',
      sourceDocs: const [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
        },
      ],
      inputChunks: const [
        {
          'source_doc_id': 'doc_alpha',
          'relative_path': 'alpha.md',
          'text': 'legacy window chunk evidence',
          'block_ids': ['doc_alpha_window_001'],
          'heading_path': ['Legacy'],
          'page_number': 5,
          'section_id': 'legacy-sec',
          'source_span': {'start': 3, 'end': 31},
        },
      ],
    );

    expect(result.chunks, hasLength(1));
    final chunk = result.chunks.single;
    final lineage = chunk['lineage'] as Map;
    expect(chunk['semantic_unit_type'], 'okf_semantic_chunk');
    expect(chunk['page_number'], 5);
    expect(chunk['section_id'], 'legacy-sec');
    expect(chunk['source_span'], {'start': 3, 'end': 31});
    expect(lineage['chunking_strategy'], 'okf_fallback_from_input_chunk');
    expect(lineage['fallback_reason'], 'parsed_document_unavailable');
    expect(lineage['page_or_section'], 'Legacy');
    expect(lineage['page_number'], 5);
    expect(lineage['section_id'], 'legacy-sec');
    expect(lineage['source_span'], {'start': 3, 'end': 31});
    final trace = result.sourceTraceRows.single;
    expect(trace['page_number'], 5);
    expect(trace['section_id'], 'legacy-sec');
    expect(trace['source_span'], {'start': 3, 'end': 31});
    expect(trace['lineage'], containsPair(
      'chunking_strategy',
      'okf_fallback_from_input_chunk',
    ));
  });

  test('okf materialize writes source map linked to chunks and trace',
      () async {
    final workspace = await createWorkspace();
    final kbDir = Directory('${workspace.path}${Platform.pathSeparator}kb')
      ..createSync(recursive: true);

    final result = await const OkfSemanticChunkService().materialize(
      workspace: workspace,
      kbDir: kbDir,
      kbId: 'K_OKF_SOURCE_MAP',
      sourceDocs: const [
        {
          'document_id': 'doc_alpha',
          'source_name': 'alpha.md',
          'relative_path': 'alpha.md',
          'source_path': 'materials/alpha.md',
          'page_or_section': 'p.3 / Alpha',
        },
      ],
      inputChunks: const [
        {
          'source_doc_id': 'doc_alpha',
          'relative_path': 'alpha.md',
          'source_path': 'materials/alpha.md',
          'text': 'source map evidence',
          'block_ids': ['doc_alpha_block_001'],
          'heading_path': ['Alpha'],
          'page_or_section': 'p.3 / Alpha',
          'page_number': 3,
          'section_id': 'sec-alpha',
          'source_span': {'start': 8, 'end': 27},
        },
        {
          'source_doc_id': 'doc_alpha',
          'relative_path': 'alpha.md',
          'source_path': 'materials/alpha.md',
          'text': 'second source map evidence',
          'block_ids': ['doc_alpha_block_002'],
          'heading_path': ['Alpha', 'Detail'],
          'page_or_section': 'p.4 / Alpha Detail',
          'page_number': 4,
          'section_id': 'sec-alpha-detail',
          'source_span': {'start': 28, 'end': 61},
        },
      ],
    );

    final sourceMap = jsonDecode(File(
      '${kbDir.path}${Platform.pathSeparator}source_map.json',
    ).readAsStringSync()) as Map<String, dynamic>;
    expect(sourceMap['schema_version'], 'prd_v3_okf_source_map.v1');
    expect(sourceMap['kb_id'], 'K_OKF_SOURCE_MAP');
    expect(sourceMap['chunks_path'],
        '${kbDir.path}${Platform.pathSeparator}chunks.jsonl');
    expect(sourceMap['source_trace_path'],
        '${kbDir.path}${Platform.pathSeparator}source_trace.jsonl');
    expect(sourceMap['chunk_count'], result.chunks.length);
    expect(sourceMap['source_trace_count'], result.sourceTraceRows.length);

    final documents = sourceMap['documents'] as List;
    expect(documents, hasLength(1));
    final alphaMap = documents.single as Map;
    expect(alphaMap['source_doc_id'], 'doc_alpha');
    expect(alphaMap['source_document'], 'alpha.md');
    expect(alphaMap['source_path'], 'materials/alpha.md');
    expect(alphaMap['chunk_ids'], result.chunks
        .map((chunk) => chunk['chunk_id'])
        .toList(growable: false));
    expect(alphaMap['source_trace_ids'], result.sourceTraceRows
        .map((trace) => trace['source_trace_id'])
        .toList(growable: false));
    expect(alphaMap['block_ids'],
        ['doc_alpha_block_001', 'doc_alpha_block_002']);
    expect(alphaMap['page_or_sections'],
        ['p.3 / Alpha', 'p.4 / Alpha Detail']);
    expect(alphaMap['page_numbers'], [3, 4]);
    expect(alphaMap['section_ids'], ['sec-alpha', 'sec-alpha-detail']);
    expect(alphaMap['source_spans'], [
      {'start': 8, 'end': 27},
      {'start': 28, 'end': 61},
    ]);
    expect(alphaMap['chunk_mappings'], [
      {
        'chunk_id': result.chunks[0]['chunk_id'],
        'source_trace_id': result.sourceTraceRows[0]['source_trace_id'],
        'block_ids': ['doc_alpha_block_001'],
        'page_or_section': 'p.3 / Alpha',
        'page_number': 3,
        'section_id': 'sec-alpha',
        'source_span': {'start': 8, 'end': 27},
      },
      {
        'chunk_id': result.chunks[1]['chunk_id'],
        'source_trace_id': result.sourceTraceRows[1]['source_trace_id'],
        'block_ids': ['doc_alpha_block_002'],
        'page_or_section': 'p.4 / Alpha Detail',
        'page_number': 4,
        'section_id': 'sec-alpha-detail',
        'source_span': {'start': 28, 'end': 61},
      },
    ]);
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

    expect(imported.readAsStringSync(),
        contains('External transformation writing Skill'));
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
    final releaseGateExternalRoot =
        '${workspace.path}${Platform.pathSeparator}p2_release_gate${Platform.pathSeparator}external_source';
    final releaseGateSourceTrace = File(
        '$releaseGateExternalRoot${Platform.pathSeparator}source_trace.jsonl');
    final releaseGateEvidenceMap = File(
        '$releaseGateExternalRoot${Platform.pathSeparator}evidence_map.json');
    final releaseGateValidation = File(
        '$releaseGateExternalRoot${Platform.pathSeparator}validation_report.json');
    final releaseGateUiReport = File(
        '$releaseGateExternalRoot${Platform.pathSeparator}ordinary_ui_external_source_verification_report.json');
    expect(releaseGateSourceTrace.existsSync(), isTrue);
    expect(readJsonlFile(releaseGateSourceTrace.path), hasLength(2));
    expect(releaseGateEvidenceMap.existsSync(), isTrue);
    expect(releaseGateValidation.existsSync(), isTrue);
    expect(releaseGateUiReport.existsSync(), isTrue);
    final releaseGateUi =
        jsonDecode(releaseGateUiReport.readAsStringSync()) as Map;
    expect(releaseGateUi['status'], 'passed');
    expect(releaseGateUi['ordinary_ui_path_verified'], isTrue);
    expect(releaseGateUi['implementation_name_leakage'], isFalse);
    expect(releaseGateUi['provider_adapter_parser_user_visible'], isFalse);

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

  testWidgets(
      'ordinary UI retrieval verification creates external source evidence',
      (tester) async {
    late Directory workspace;
    await pumpWorkbench(
      tester,
      initialSelectedIndex: 4,
      surfaceSize: const Size(1440, 900),
      captureWorkspace: (dir) => workspace = dir,
      setupWorkspace: (workspace) async {
        final kbRoot = Directory(
            '${workspace.path}${Platform.pathSeparator}knowledge_bases')
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
              'kb_name': 'Release Gate KB',
              'kb_type': '基础知识库',
              'status': 'searchable',
              'operation': 'build',
              'source_documents': [
                {'source_name': 'release_gate.md'}
              ],
              'chunk_count': 1,
            }
          ],
        }));
      },
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
                  'chunk_id': 'K1-release-c1',
                  'source_path': 'release_gate.md',
                  'citation': 'release_gate.md#chunk=1',
                  'text': '普通用户路径外部来源核对测试证据',
                  'score': 0.93,
                }
              ],
            }),
          );
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      waitForRuntimeReady: true,
    );

    final verifyButton =
        find.byKey(const Key('workbench.retrieval.test_kb_button'));
    expect(verifyButton, findsOneWidget);
    await tester.ensureVisible(verifyButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester.widget<FilledButton>(verifyButton).onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    final saveButton =
        find.byKey(const Key('workbench.retrieval.save_report_button'));
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (saveButton.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(saveButton).onPressed != null) {
        break;
      }
    }
    expect(saveButton, findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester.widget<FilledButton>(saveButton).onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    final externalRoot =
        '${workspace.path}${Platform.pathSeparator}p2_release_gate${Platform.pathSeparator}external_source';
    final sourceTrace =
        File('$externalRoot${Platform.pathSeparator}source_trace.jsonl');
    final evidenceMap =
        File('$externalRoot${Platform.pathSeparator}evidence_map.json');
    final validation =
        File('$externalRoot${Platform.pathSeparator}validation_report.json');
    final uiReport = File(
        '$externalRoot${Platform.pathSeparator}ordinary_ui_external_source_verification_report.json');
    expect(sourceTrace.existsSync(), isTrue);
    expect(evidenceMap.existsSync(), isTrue);
    expect(validation.existsSync(), isTrue);
    expect(uiReport.existsSync(), isTrue);
    final ui = jsonDecode(uiReport.readAsStringSync()) as Map;
    expect(ui['status'], 'passed');
    expect(ui['ordinary_ui_path_verified'], isTrue);
    expect(ui['visible_capability'], '知识库问答能力');
    expect(ui['implementation_name_leakage'], isFalse);
    expect(ui['ordinary_ui_project_names_visible'], isFalse);
    expect(find.textContaining('Provider'), findsNothing);
    expect(find.textContaining('Adapter'), findsNothing);
    expect(find.textContaining('Parser'), findsNothing);
    expect(tester.takeException(), isNull);
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
    expect(controller.state.hasSkill, isFalse);
    expect(controller.state.hasAgent, isFalse);
    for (final format in const ['docx', 'pdf', 'pptx']) {
      expect(
          File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}$format${Platform.pathSeparator}generated.$format')
              .existsSync(),
          isTrue);
      final fileReport = jsonDecode(File(
              '${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}$format${Platform.pathSeparator}generated_file_report.json')
          .readAsStringSync()) as Map<String, dynamic>;
      expect(fileReport['status'], 'pass');
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

  test('strict citation document generation blocks missing source evidence',
      () async {
    final workspace = await createWorkspace();
    final requests = <CoreBridgeRequest>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request);
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final kbDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
          ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"test_kb.v1"}');
    final queryDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}query')
          ..createSync(recursive: true);
    File('${queryDir.path}${Platform.pathSeparator}multi_kb_query_result.json')
        .writeAsStringSync(jsonEncode({
      'query': '缺少引用',
      'selected_kb_ids': ['K_STRICT'],
      'selected_count': 1,
      'selected': [
        {
          'text': '这条结果没有可用引用和追溯字段。',
          'kb_id': 'K_STRICT',
          'kb_name': '严格引用知识库',
        }
      ],
    }));

    await controller.generateMarkdown(
      config: const Rc6DocumentGenerationConfig(
        generationType: 'structured_report',
        citationStrategy: 'strict_citation',
      ),
    );

    expect(requests, isEmpty);
    expect(controller.state.lastError, contains('严格引用模式需要至少一条可追溯来源证据'));
    expect(controller.state.phase, Rc6RuntimePhase.failed);
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}doc${Platform.pathSeparator}generation_manifest.json')
            .existsSync(),
        isFalse);
  });

  test('document generation persists template config into real artifacts',
      () async {
    final workspace = await createWorkspace();
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final kbDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
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
    final kbCatalogDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases')
      ..createSync(recursive: true);
    File('${kbCatalogDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'K1',
          'kb_name': '未选择知识库',
          'source_documents': [
            {'document_id': 'doc_unselected'}
          ],
        },
        {
          'kb_id': 'K2',
          'kb_name': '真实输入知识库',
          'source_documents': [
            {'document_id': 'doc_alpha'}
          ],
        },
      ],
    }));
    File('${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'sources': [
        {'source_name': 'alpha.txt', 'relative_path': 'alpha.txt'}
      ],
    }));
    final queryDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}query')
          ..createSync(recursive: true);
    File('${queryDir.path}${Platform.pathSeparator}multi_kb_query_result.json')
        .writeAsStringSync(jsonEncode({
      'query': '产品分析',
      'selected_kb_ids': ['K2'],
      'selected_count': 1,
      'selected': [
        {
          'text': '真实产品分析证据',
          'source_path': 'alpha.txt',
          'citation': 'alpha.txt#chunk=1',
          'kb_id': 'K2',
          'kb_name': '真实输入知识库',
          'chunk_id': 'K2_chunk_001',
          'source_trace_id': 'trace_K2_alpha_001',
          'source_doc_id': 'doc_alpha',
          'source_document': 'alpha.txt',
          'page_number': 3,
          'section_id': 'sec-product',
          'block_ids': ['doc_alpha_block_001'],
          'heading_path': ['产品分析'],
          'lineage': {
            'parsed_document_source': 'canonical_blocks',
          },
        }
      ],
    }));
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
    final docRoot = '${activeWorkspace.path}${Platform.pathSeparator}doc';
    final firstGenerationManifest =
        File('$docRoot${Platform.pathSeparator}generation_manifest.json')
            .readAsStringSync();
    final firstOutline =
        File('$docRoot${Platform.pathSeparator}outline.json').readAsStringSync();
    final firstReadingNotes =
        File('$docRoot${Platform.pathSeparator}reading_notes.md')
            .readAsStringSync();
    final firstValidation =
        File('$docRoot${Platform.pathSeparator}document_validation_report.json')
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
    expect(
        firstGenerationManifest,
        allOf(
          contains('"product_problem"'),
          contains('"agent_use_scaffold"'),
          contains('"agent_use_boundary"'),
        ));
    expect(
        firstOutline,
        allOf(
          contains('"type_structure_status": "type_specific_sections_applied"'),
          contains('"template_effect_status": "template_mode_applied"'),
          contains('"title": "产品问题"'),
          contains('"title": "用户 / 场景证据"'),
        ));
    expect(
        firstReadingNotes,
        allOf(
          contains('## 产品问题'),
          contains('## 用户 / 场景证据'),
          contains('agent_use_scaffold'),
          contains('agent_use_boundary'),
        ));
    expect(
        firstValidation,
        allOf(
          contains('"outline_status": "generated_from_type_specific_template"'),
          contains('"has_required_variables": true'),
          contains('"template_effect_status": "template_mode_applied"'),
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
          contains('"selected_kb_id": "K2"'),
          contains('"source_kb_ids":'),
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
    expect(
        generationManifest,
        allOf(
          contains('"summary_points"'),
          contains('"built_in_document_scaffold"'),
          contains('"source_summary"'),
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
            contains('"title": "摘要重点"'),
            contains('"title": "来源覆盖"'),
            contains('"type_structure_status": "type_specific_sections_applied"'),
          ));
    expect(
        File(controller.state.documentCitationsPath).readAsStringSync(),
        allOf(
          contains('prd_v3_document_citations.v1'),
          contains('alpha.txt#chunk=1'),
          contains('trace_K2_alpha_001'),
          contains('K2_chunk_001'),
          contains('doc_alpha'),
        ));
    final citationsJson = jsonDecode(
            File(controller.state.documentCitationsPath).readAsStringSync())
        as Map<String, dynamic>;
    final citation = (citationsJson['citations'] as List).single as Map;
    expect(citation['source_trace_id'], 'trace_K2_alpha_001');
    expect(citation['chunk_id'], 'K2_chunk_001');
    expect(citation['source_doc_id'], 'doc_alpha');
    expect(citation['source_document'], 'alpha.txt');
    expect(citation['page_number'], 3);
    expect(citation['section_id'], 'sec-product');
    expect(citation['block_ids'], ['doc_alpha_block_001']);
    expect(citation['heading_path'], ['产品分析']);
    expect(citation['trace_complete'], isTrue);
    expect(
        File(controller.state.documentValidationReportPath).readAsStringSync(),
          allOf(
            contains('prd_v3_document_validation_report.v1'),
            contains('"outline_status": "generated_from_type_specific_template"'),
            contains('"has_required_variables": true'),
            contains('"history_snapshot_status": "written"'),
            contains('"secret_plaintext_written": false'),
          ));
    final generationManifestJson =
        jsonDecode(generationManifest) as Map<String, dynamic>;
    expect(generationManifestJson['selected_kb_id'], 'K2');
    expect(generationManifestJson['selected_kb_ids'], ['K2']);
    expect(generationManifestJson['source_kb_ids'], ['K2']);
    expect(
        ((generationManifestJson['citations'] as List).single
            as Map)['source_trace_id'],
        'trace_K2_alpha_001');
    expect(generationManifestJson['generation_history'], hasLength(2));
    final historyEntries =
        (generationManifestJson['generation_history'] as List)
            .whereType<Map>()
            .toList();
    for (final entry in historyEntries) {
      expect(entry['selected_kb_id'], 'K2');
      expect(entry['source_kb_ids'], ['K2']);
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
    expect((latestDeletedManifest['generation_history'] as List).single,
        containsPair('selected_kb_id', 'K2'));
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
            contains('## 摘要重点'),
            contains('## 来源覆盖'),
            contains('built_in_document_scaffold'),
            contains('source_summary'),
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
          contains('"selected_kb_id": "K2"'),
          contains('"secret_plaintext_written": false'),
        ));

    await controller.exportMarkdownDocument();
    final exportManifest = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}export_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(exportManifest['selected_kb_id'], 'K2');
    expect(exportManifest['source_kb_ids'], ['K2']);
    expect((exportManifest['source_body_used'] as Map)['kind'],
        'edited_document');
    expect((exportManifest['source_body_used'] as Map)['path'], editedPath);
    expect(exportManifest['source_body_priority'],
        ['edited_document', 'reading_notes', 'generated_markdown']);
    expect(
        const JsonEncoder.withIndent('  ').convert(exportManifest),
        allOf(
          contains('generation_manifest.json'),
          contains('edit_manifest.json'),
          contains('"generation_type": "summary"'),
          contains('"output_format": "md"'),
        ));
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}reading_notes_export.md')
            .readAsStringSync(),
        contains('final edited body from real KB'));
    await controller.exportDocumentFormat('json');
    final structuredManifest = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured${Platform.pathSeparator}structured_export_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(structuredManifest['selected_kb_id'], 'K2');
    expect(structuredManifest['source_kb_ids'], ['K2']);
    expect((structuredManifest['source_body_used'] as Map)['kind'],
        'edited_document');
    expect((structuredManifest['source_body_used'] as Map)['path'], editedPath);
    expect(structuredManifest['source_body_priority'],
        ['edited_document', 'reading_notes', 'generated_markdown']);
    final structuredPayload = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}structured${Platform.pathSeparator}knowledge_export.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        (structuredPayload['knowledge_base'] as Map)['selected_kb_id'], 'K2');
    expect(
        (structuredPayload['knowledge_base'] as Map)['source_kb_ids'], ['K2']);
    expect((structuredPayload['document'] as Map)['path'], editedPath);
    expect((structuredPayload['document'] as Map)['source_kind'],
        'edited_document');
    expect((structuredPayload['source_body_used'] as Map)['kind'],
        'edited_document');
    expect((structuredPayload['document'] as Map)['preview'],
        contains('final edited body from real KB'));
    final eventRows = readJsonlFile(
        '${activeWorkspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    final documentLifecycleActions =
        eventRows.map((row) => row['action']).toList(growable: false);
    expect(
        documentLifecycleActions,
        containsAll([
          'generate_markdown',
          'generate_document',
          'delete_latest_document_generation_history',
          'clear_document_generation_history',
          'save_edited_document',
          'export_document_md',
          'export_document_json',
        ]));
    expect(
        eventRows.any((row) =>
            row['action'] == 'generate_document' &&
            row['artifact_path'] ==
                '$docRoot${Platform.pathSeparator}reading_notes.md' &&
            ((row['metadata'] as Map)['manifest_path'] as String)
                .endsWith('generation_manifest.json')),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['action'] == 'delete_latest_document_generation_history' &&
            ((row['metadata'] as Map)['preserved_body']) == true &&
            ((row['metadata'] as Map)['history_count_after']) == 1),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['action'] == 'clear_document_generation_history' &&
            ((row['metadata'] as Map)['preserved_exports']) == true &&
            ((row['metadata'] as Map)['history_count_after']) == 0),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['action'] == 'save_edited_document' &&
            row['artifact_path'] == editedPath &&
            ((row['metadata'] as Map)['generation_manifest'] as String)
                .endsWith('generation_manifest.json')),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifactRows = (artifactCatalog['artifacts'] as List)
        .whereType<Map>()
        .toList(growable: false);
    final artifactIds =
        artifactRows.map((row) => row['artifact_id']).toList(growable: false);
    expect(
        artifactIds,
        containsAll([
          'generated_document_current',
          'edited_document_current',
          'generated_document_export_md',
          'generated_document_export_json',
        ]));
    expect(
        artifactRows.any((row) =>
            row['artifact_id'] == 'generated_document_current' &&
            row['file_path'] ==
                '$docRoot${Platform.pathSeparator}reading_notes.md' &&
            ((row['metadata'] as Map)['manifest_path'] as String)
                .endsWith('generation_manifest.json')),
        isTrue);
    expect(
        artifactRows.any((row) =>
            row['artifact_id'] == 'edited_document_current' &&
            row['file_path'] == editedPath &&
            row['source_id'] == 'save_edited_document'),
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
    expect(reloadedController.state.documentOutlinePath,
        controller.state.documentOutlinePath);
    expect(reloadedController.state.documentCitationsPath,
        controller.state.documentCitationsPath);
    expect(reloadedController.state.documentValidationReportPath,
        controller.state.documentValidationReportPath);
    expect(
        reloadedController.state.eventLedgerRecords
            .map((record) => record.action),
        contains('save_edited_document'));
    expect(
        reloadedController.state.artifactRecords
            .map((record) => record.artifactId),
        contains('edited_document_current'));
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

  test('office artifact adapter docx basic has lifecycle evidence', () async {
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
    final summaryPath = await controller.runOfficeArtifactAdapterAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_office_artifact_adapter_docx_basic_acceptance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['external_office_adapter_executed'], isFalse);
    expect(summary['officecli_integrated'], isFalse);
    expect(summary['redis_vector_service_packaged'], isFalse);
    expect(summary['real_user_data_deleted'], isFalse);
    expect(summary['secret_plaintext_written'], isFalse);
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'real_user_data_deleted' ||
          entry.key == 'external_office_adapter_executed' ||
          entry.key == 'redis_vector_service_packaged' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final docxPath = summary['docx_output_path'] as String;
    final docx = File(docxPath);
    expect(docx.existsSync(), isTrue);
    final docxBytes = docx.readAsBytesSync();
    expect(docxBytes.take(4).toList(), [0x50, 0x4b, 0x03, 0x04]);
    final docxPayload = latin1.decode(docxBytes, allowInvalid: true);
    expect(docxPayload, contains('[Content_Types].xml'));
    expect(docxPayload, contains('_rels/.rels'));
    expect(docxPayload, contains('word/document.xml'));
    expect(
        docxPayload,
        contains(
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml'));

    final manifest = jsonDecode(
            File(summary['adapter_manifest_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['schema_version'],
        'prd_v3_office_docx_basic_adapter_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['adapter'], 'builtin_local_docx_adapter');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_office_docx_basic_adapter_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['missing_docx_parts'], isEmpty);

    final testArtifact = File(summary['test_artifact_path'] as String);
    expect(testArtifact.existsSync(), isFalse);

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
    expect(File(docxPath).existsSync(), isTrue);
    expect(reloadedController.state.hasExportedDocument, isTrue);
    expect(reloadedController.state.exportedDocumentPath, docxPath);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows
            .any((row) => row['event_type'] == 'office_docx_adapter_exported'),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['action'] == 'delete_test_office_docx_adapter_artifact'),
        isTrue);
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'office_artifact_adapter_acceptance'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'office_docx_basic_export' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'test_office_docx_adapter_artifact' &&
            row['status'] == 'deleted'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'office_artifact_adapter_acceptance_summary' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 office collaboration workgroup has office and workgroup evidence',
      () async {
    final workspace = await createWorkspace();
    final now = DateTime.now().toUtc().toIso8601String();
    final skillDir = Directory(
        '${workspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Knowledge QA Skill\n');
    final agentDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}catalog')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agents.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'heitang_agent_catalog.v1',
      'status': 'saved',
      'agents': [
        {
          'id': 'test_office_workgroup_agent',
          'name': '办公协作测试助手',
          'description': '用于 P2-2 办公协作黑盒验收。',
          'role': '处理当前办公协作任务',
          'status': 'available',
          'created_at': now,
          'updated_at': now,
          'workspace_id': '默认工作本',
          'primary_knowledge_base_id': 'K1',
          'allowed_reference_kb_ids': [],
          'kb_scope_mode': 'single',
          'answer_policy_id': 'strict_evidence',
          'ai_profile_id': 'ai_profile_default_local',
          'bound_knowledge_base_ids': ['K1'],
          'bound_skill_ids': ['primary_skill'],
          'settings': {'reply_mode': 'local_fallback_until_configured'},
        }
      ],
      'updated_at': now,
    }));
    final conversationDir = Directory(
        '${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}conversations${Platform.pathSeparator}test_office_workgroup_agent')
      ..createSync(recursive: true);
    File('${conversationDir.path}${Platform.pathSeparator}conversation.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'heitang_agent_conversation.v1',
      'conversation_id': 'conv_test_office_workgroup_agent',
      'agent_id': 'test_office_workgroup_agent',
      'messages': [],
      'created_at': now,
      'updated_at': now,
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
    await controller.runOfficeArtifactAdapterAcceptance();
    final summaryPath =
        await controller.runOfficeCollaborationWorkgroupAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_office_collaboration_workgroup_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'office_collaboration_workgroup');
    expect(summary['capability_gate'], 'P2-2 Office Collaboration Workgroup');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['p2_4_status'], 'not_closed_by_p2_2');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'p2_4_ten_agent_gate_closed') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }
    expect(summary['missing_docx_parts'], isEmpty);
    final officeDocument = File(summary['office_document_path'] as String);
    expect(officeDocument.existsSync(), isTrue);
    expect(officeDocument.readAsBytesSync().take(4).toList(),
        [0x50, 0x4b, 0x03, 0x04]);
    expect(
        File(summary['workgroup_summary_path'] as String).existsSync(), isTrue);
    expect(File(summary['discussion_path'] as String).existsSync(), isTrue);

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
    expect(reloadedController.state.hasExportedDocument, isTrue);
    expect(reloadedController.state.hasA2aSessionManifest, isTrue);

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'office_collaboration_workgroup_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'office_collaboration_workgroup_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
  });

  test(
      'p2 research analysis workgroup has source trace and validation evidence',
      () async {
    final workspace = await createWorkspace();
    writeWorkgroupAgentSkillFixture(
      workspace,
      agentId: 'test_research_workgroup_agent',
      agentName: '研究分析测试助手',
      description: '用于 P2-3 研究分析工作组验收。',
      role: '处理当前研究分析任务',
    );
    writeResearchAnalysisQueryFixture(workspace);
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
    final summaryPath =
        await controller.runResearchAnalysisWorkgroupAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_research_analysis_workgroup_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'research_analysis_workgroup');
    expect(summary['capability_gate'], 'P2-3 Research Analysis Workgroup');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['p2_4_status'], 'not_closed_by_p2_3');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'p2_4_ten_agent_gate_closed') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }
    expect(
        File(summary['workgroup_summary_path'] as String).existsSync(), isTrue);
    expect(File(summary['discussion_path'] as String).existsSync(), isTrue);
    final sourceTracePath = summary['source_trace_path'] as String;
    expect(File(sourceTracePath).existsSync(), isTrue);
    expect(readJsonlFile(sourceTracePath).length, 3);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_research_analysis_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(File(summary['evidence_map_path'] as String).existsSync(), isTrue);
    expect(File(summary['research_brief_path'] as String).existsSync(), isTrue);

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
    expect(reloadedController.state.hasA2aSessionManifest, isTrue);

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'research_analysis_workgroup_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'research_analysis_workgroup_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'research_analysis_brief' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 role-based workgroup creates role evidence package', () async {
    final workspace = await createWorkspace();
    writeWorkgroupAgentSkillFixture(
      workspace,
      agentId: 'test_role_workgroup_agent',
      agentName: '角色分工测试助手',
      description: '用于 P2-10 角色分工工作组验收。',
      role: '处理当前角色分工任务',
    );
    writeResearchAnalysisQueryFixture(workspace);
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
    final summaryPath = await controller.runRoleBasedWorkgroupAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'], 'prd_v3_role_based_workgroup_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'role_based_workgroup');
    expect(summary['capability_gate'], 'P2-10 Role-based Workgroup');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-11 ReAct Tool Runtime Industrialization');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final roleManifest = jsonDecode(
        File(summary['role_assignment_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(roleManifest['schema_version'],
        'prd_v3_role_based_workgroup_assignment.v1');
    expect(roleManifest['role_count'], greaterThanOrEqualTo(4));
    final assignments =
        (roleManifest['assignments'] as List).cast<Map<String, dynamic>>();
    expect(assignments.map((row) => row['display_name']),
        containsAll(['任务负责人', '证据复核', '风险复核', '文档整理']));
    expect(
        assignments.every((row) =>
            row['agent_id'].toString().isNotEmpty &&
            row['external_runtime_loaded'] == false),
        isTrue);

    final roleOutputs = readJsonlFile(summary['role_outputs_path'] as String);
    expect(roleOutputs, hasLength(assignments.length));
    expect(
        roleOutputs.every((row) =>
            row['status'] == 'completed' &&
            (row['evidence_refs'] as List).length >= 3),
        isTrue);
    final validation = jsonDecode(
        File(summary['role_validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_role_based_workgroup_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(File(summary['role_review_report_path'] as String).existsSync(),
        isTrue);
    expect(
        File(summary['workgroup_summary_path'] as String).existsSync(), isTrue);

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
    expect(reloadedController.state.hasA2aSessionManifest, isTrue);

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'role_based_workgroup_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'role_based_workgroup_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'role_based_workgroup_review' &&
            row['status'] == 'completed'),
        isTrue);
  });

  testWidgets('p2 role-based workgroup button creates role evidence',
      (tester) async {
    late Directory workspace;
    await pumpWorkbench(
      tester,
      initialSelectedIndex: 7,
      surfaceSize: const Size(1440, 900),
      captureWorkspace: (dir) => workspace = dir,
      setupWorkspace: (workspace) async {
        writeWorkgroupAgentSkillFixture(
          workspace,
          agentId: 'test_role_workgroup_agent',
          agentName: '角色分工测试助手',
          description: '用于 P2-10 角色分工工作组黑盒验收。',
          role: '处理当前角色分工任务',
        );
        writeResearchAnalysisQueryFixture(workspace);
      },
      waitForRuntimeReady: true,
    );

    expect(find.byKey(const Key('agent-primary-entry-switch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-primary-entry-工作小组')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    final input = find.byKey(const Key('a2a-topic-input'));
    expect(input, findsOneWidget);
    final editable = find.descendant(
      of: input,
      matching: find.byType(EditableText),
    );
    expect(editable, findsOneWidget);
    final editableText = tester.widget<EditableText>(editable);
    editableText.controller.text = 'P2-10 角色分工：按负责人、证据、风险、文档整理协作。';
    editableText.controller.selection = TextSelection.collapsed(
      offset: editableText.controller.text.length,
    );
    await tester.pumpAndSettle();

    final button =
        find.byKey(const Key('workgroup-basic-runtime-evidence-button'));
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (button.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(button).onPressed != null) {
        break;
      }
    }
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester.widget<FilledButton>(button).onPressed?.call();
      await Future<void>.delayed(const Duration(seconds: 1));
    });

    final summaryPath =
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}role_based_workgroup_summary.json';
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (File(summaryPath).existsSync()) {
        break;
      }
    }
    expect(tester.takeException(), isNull);
    expect(File(summaryPath).existsSync(), isTrue);
    final summary = jsonDecode(File(summaryPath).readAsStringSync()) as Map;
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'role_based_workgroup');
    expect(summary['black_box_status'], 'passed');
    expect(summary['ui_blackbox_path'],
        'Agent -> Work Group -> Collaboration task input -> Start Work Group');
    expect(
        File(summary['role_assignment_manifest_path'] as String).existsSync(),
        isTrue);
    expect(File(summary['role_outputs_path'] as String).existsSync(), isTrue);
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'role_based_workgroup_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    expect(find.textContaining('Provider'), findsNothing);
    expect(find.textContaining('Adapter'), findsNothing);
    expect(find.textContaining('Parser'), findsNothing);
    expect(find.textContaining('0/'), findsNothing);
  });

  testWidgets('p2 a2a ten-agent template button creates user-path evidence',
      (tester) async {
    late Directory workspace;
    await pumpWorkbench(
      tester,
      initialSelectedIndex: 7,
      surfaceSize: const Size(1440, 900),
      captureWorkspace: (dir) => workspace = dir,
      setupWorkspace: (workspace) async {
        writeWorkgroupAgentSkillFixture(
          workspace,
          agentId: 'test_a2a_template_entry_agent',
          agentName: '十助手模板入口测试助手',
          description: '用于 P2-4 常用助手模板黑盒验收。',
          role: '保留在工作区内的既有助手。',
        );
        writeResearchAnalysisQueryFixture(workspace);
      },
      waitForRuntimeReady: true,
    );

    await tester.tap(find.byKey(const Key('agent-primary-entry-工作小组')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('常用助手模板'), findsOneWidget);
    expect(find.textContaining('Provider'), findsNothing);
    expect(find.textContaining('Adapter'), findsNothing);
    expect(find.textContaining('Parser'), findsNothing);
    expect(find.textContaining('0/'), findsNothing);

    final button =
        find.byKey(const Key('a2a-ten-agent-template-evidence-button'));
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (button.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(button).onPressed != null) {
        break;
      }
    }
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester.widget<FilledButton>(button).onPressed?.call();
      await Future<void>.delayed(const Duration(seconds: 1));
    });

    final summaryPath =
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}a2a_ten_agent_template_summary.json';
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();
      if (File(summaryPath).existsSync()) {
        break;
      }
    }
    expect(tester.takeException(), isNull);
    expect(File(summaryPath).existsSync(), isTrue);
    final summary = jsonDecode(File(summaryPath).readAsStringSync()) as Map;
    expect(summary['status'], 'pass');
    expect(summary['capability_gate'], 'P2-4 A2A >= 10 Agents');
    expect(summary['product_facing_entry'], '常用助手模板');
    expect(summary['participant_count'], 10);
    expect(summary['black_box_status'], 'passed');
  });

  test('p2 a2a ten-agent templates create workgroup and tombstone test data',
      () async {
    final workspace = await createWorkspace();
    writeWorkgroupAgentSkillFixture(
      workspace,
      agentId: 'test_existing_workgroup_agent',
      agentName: '既有工作小组测试助手',
      description: '用于确认 P2-4 只删除本次 test 标记助手。',
      role: '保留在工作区内的既有助手。',
    );
    writeResearchAnalysisQueryFixture(workspace);
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
    final summaryPath = await controller.runA2aTenAgentTemplateAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_a2a_ten_agent_template_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'a2a_workgroup');
    expect(summary['capability_gate'], 'P2-4 A2A >= 10 Agents');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['participant_count'], 10);
    expect(summary['product_facing_entry'], '常用助手模板');
    expect(summary['create_action'], '创建工作小组');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'real_user_data_deleted' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final templateManifest = jsonDecode(
        File(summary['template_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(templateManifest['schema_version'],
        'prd_v3_common_assistant_templates_manifest.v1');
    expect(templateManifest['template_count'], 10);
    expect(templateManifest['product_facing_entry'], '常用助手模板');
    final templates =
        (templateManifest['templates'] as List).cast<Map<String, dynamic>>();
    expect(
        templates.map((row) => row['required_name']),
        containsAll([
          'Material organizing assistant',
          'Knowledge base QA assistant',
          'Evidence verification assistant',
          'Document writing assistant',
          'Quality review assistant',
          'Risk review assistant',
          'Skill generation assistant',
          'Task coordination assistant',
          'Planning assistant',
          'Delivery check assistant',
        ]));
    expect(
        templates.any((row) =>
            row.values.join(' ').contains('Provider') ||
            row.values.join(' ').contains('Adapter') ||
            row.values.join(' ').contains('Parser') ||
            row.values.join(' ').contains('0/')),
        isFalse);

    final creation = jsonDecode(
        File(summary['creation_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(creation['assistant_count'], 10);
    final createdAssistants =
        (creation['assistants'] as List).cast<Map<String, dynamic>>();
    expect(
        createdAssistants.every((row) =>
            (row['settings'] as Map)['test_marker'] ==
            'p2_4_a2a_ten_agent_template'),
        isTrue);

    final workgroupSummary = jsonDecode(
        File(summary['workgroup_summary_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(workgroupSummary['status'], 'pass');
    expect(workgroupSummary['participant_count'], 10);
    final a2aManifest = jsonDecode(
        File(summary['a2a_session_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(a2aManifest['participant_count'], 10);
    final taskRecords = readJsonlFile(summary['task_records_path'] as String);
    expect(taskRecords, hasLength(10));
    expect(
        taskRecords.every((row) =>
            row['status'] == 'completed' &&
            row['output'].toString().trim().isNotEmpty),
        isTrue);
    expect(
        File(summary['conflict_report_path'] as String).existsSync(), isTrue);
    expect(
        File(summary['consensus_report_path'] as String).existsSync(), isTrue);

    final tombstone =
        jsonDecode(File(summary['tombstone_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(tombstone['schema_version'],
        'prd_v3_p2_4_test_assistant_tombstone_report.v1');
    expect(tombstone['status'], 'pass');
    expect(tombstone['deleted_assistant_count'], 10);
    expect(tombstone['only_test_marked_assistants_deleted'], isTrue);
    expect(tombstone['real_user_data_deleted'], isFalse);

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
    expect(reloadedController.state.hasA2aSessionManifest, isTrue);
    expect(
        reloadedController.state.agentProfiles
            .any((profile) => profile.id.startsWith('test_p2_4_')),
        isFalse);
    expect(
        reloadedController.state.agentProfiles
            .any((profile) => profile.id == 'test_existing_workgroup_agent'),
        isTrue);

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'a2a_ten_agent_templates_created'),
        isTrue);
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'a2a_ten_agent_templates_tombstoned'),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'a2a_ten_agent_template_workgroup_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'a2a_ten_agent_template_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'a2a_ten_agent_template_tombstones' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 multi-agent rag deepening creates core evidence package', () async {
    final workspace = await createWorkspace();
    writeWorkgroupAgentSkillFixture(
      workspace,
      agentId: 'test_multi_agent_rag_agent',
      agentName: '多助手检索深化测试助手',
      description: '用于 P2-5 多助手检索深化验收。',
      role: '处理当前检索深化任务',
    );
    writeResearchAnalysisQueryFixture(workspace);
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
    final summaryPath = await controller.runMultiAgentRagDeepeningAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_multi_agent_rag_deepening_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'multi_agent_rag_deepening');
    expect(summary['capability_gate'], 'P2-5 Multi-Agent RAG Deepening');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'],
        'P2-6 Hot-Pluggable Project Config Industrial Isolation');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(3));
    expect(
        sourceTraceRows.every((row) =>
            row['trace_id'].toString().isNotEmpty &&
            row['citation'].toString().isNotEmpty),
        isTrue);
    final agentViews =
        readJsonlFile(summary['agent_retrieval_views_path'] as String);
    expect(agentViews, hasLength(4));
    expect(
        agentViews.every((row) =>
            row['status'] == 'completed' &&
            (row['evidence_refs'] as List).length == 3),
        isTrue);
    final evidenceGraph = jsonDecode(
            File(summary['evidence_graph_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(evidenceGraph['schema_version'],
        'prd_v3_multi_agent_rag_evidence_graph.v1');
    expect(evidenceGraph['anchor'], 'rag_trace_01');
    expect((evidenceGraph['entities'] as List), hasLength(3));
    expect(
        (evidenceGraph['answer_contract'] as Map)['requires_answer'], isTrue);
    expect(
        (evidenceGraph['answer_contract']
            as Map)['missing_evidence_blocks_answer'],
        isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_multi_agent_rag_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(File(summary['retrieval_plan_path'] as String).existsSync(), isTrue);
    expect(File(summary['synthesis_path'] as String).existsSync(), isTrue);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'multi_agent_rag_deepening_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'multi_agent_rag_deepening_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'multi_agent_rag_synthesis' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 react tool runtime industrialization creates core evidence package',
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
    final summaryPath =
        await controller.runReactToolRuntimeIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_react_tool_runtime_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'react_tool_runtime_industrial');
    expect(summary['capability_gate'],
        'P2-11 ReAct Tool Runtime Industrialization');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-12 Long Context Evaluation');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'external_runtime_executed' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy =
        jsonDecode(File(summary['policy_path'] as String).readAsStringSync())
            as Map;
    expect(policy['schema_version'], 'prd_v3_react_tool_runtime_policy.v1');
    expect(policy['allowlist'], contains('kb_retrieval'));
    expect(policy['blocked_tools'], contains('arbitrary_shell'));
    final loopRecords = readJsonlFile(summary['loop_records_path'] as String);
    expect(loopRecords, hasLength(5));
    expect(loopRecords.any((row) => row['phase'] == 'thought'), isTrue);
    expect(loopRecords.any((row) => row['phase'] == 'observation'), isTrue);
    expect(
        loopRecords.any((row) =>
            row['tool_id'] == 'arbitrary_shell' &&
            row['decision'] == 'deny' &&
            row['executed'] == false),
        isTrue);
    final toolCalls = readJsonlFile(summary['tool_call_log_path'] as String);
    expect(
        toolCalls.any((row) =>
            row['tool_id'] == 'kb_retrieval' &&
            row['decision'] == 'allow' &&
            row['executed'] == true),
        isTrue);
    expect(
        toolCalls.any((row) =>
            row['tool_id'] == 'arbitrary_shell' &&
            row['decision'] == 'deny' &&
            row['executed'] == false &&
            row['error_code'] == 'tool_not_allowlisted'),
        isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_react_tool_runtime_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(File(summary['error_report_path'] as String).existsSync(), isTrue);
    expect(File(summary['answer_path'] as String).existsSync(), isTrue);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'react_tool_runtime_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'react_tool_runtime_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'react_tool_runtime_answer' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 long context evaluation creates core evidence package', () async {
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
    final summaryPath = await controller.runLongContextEvaluationAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_long_context_evaluation_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'long_context_evaluation');
    expect(summary['capability_gate'], 'P2-12 Long Context Evaluation');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-13 Official Sample Project Library');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final chunkIndex = jsonDecode(
        File(summary['chunk_index_path'] as String).readAsStringSync()) as Map;
    expect(chunkIndex['schema_version'], 'prd_v3_long_context_chunk_index.v1');
    expect((chunkIndex['chunks'] as List), hasLength(6));
    final windowPlan = jsonDecode(
        File(summary['window_plan_path'] as String).readAsStringSync()) as Map;
    expect(windowPlan['schema_version'], 'prd_v3_long_context_window_plan.v1');
    expect(windowPlan['window_count'], 2);
    expect(windowPlan['missing_evidence_blocks_answer'], isTrue);
    final traceRows = readJsonlFile(summary['retrieval_trace_path'] as String);
    expect(traceRows, hasLength(6));
    expect(
        traceRows.every((row) =>
            row['trace_id'].toString().isNotEmpty &&
            row['citation'].toString().isNotEmpty &&
            row['selected'] == true),
        isTrue);
    final evidenceGraph = jsonDecode(
            File(summary['evidence_graph_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(evidenceGraph['schema_version'],
        'prd_v3_long_context_evidence_graph.v1');
    expect((evidenceGraph['entities'] as List), hasLength(6));
    expect(
        (evidenceGraph['answer_contract']
            as Map)['missing_evidence_blocks_answer'],
        isTrue);
    final missingEvidence = jsonDecode(
        File(summary['missing_evidence_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(missingEvidence['schema_version'],
        'prd_v3_long_context_missing_evidence_report.v1');
    expect(missingEvidence['answer_blocked'], isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_long_context_evaluation_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(File(summary['answer_path'] as String).existsSync(), isTrue);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'long_context_evaluation_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'long_context_evaluation_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'long_context_evaluation_answer' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 official sample project library has artifact lifecycle evidence',
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
    final summaryPath =
        await controller.runOfficialSampleProjectLibraryAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_official_sample_project_library_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'official_sample_project_library');
    expect(summary['capability_gate'], 'P2-13 Official Sample Project Library');
    expect(summary['acceptance_type'], 'artifact');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-14 Polly-style Lead Orchestrator');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final manifest =
        jsonDecode(File(summary['manifest_path'] as String).readAsStringSync())
            as Map;
    expect(manifest['schema_version'],
        'prd_v3_official_sample_project_library_manifest.v1');
    expect(manifest['knowledge_base_sample_count'], 3);
    expect(manifest['document_template_sample_count'], 3);
    expect(manifest['implementation_names_user_visible'], isFalse);
    expect(manifest['provider_adapter_parser_user_visible'], isFalse);
    final kbSamples = jsonDecode(
        File(summary['knowledge_base_samples_path'] as String)
            .readAsStringSync()) as Map;
    expect((kbSamples['samples'] as List), hasLength(3));
    final documentSamples = jsonDecode(
        File(summary['document_template_samples_path'] as String)
            .readAsStringSync()) as Map;
    expect((documentSamples['samples'] as List), hasLength(3));
    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(2));
    expect(
        sourceTraceRows.every((row) =>
            row['trace_id'].toString().isNotEmpty &&
            row['citation'].toString().isNotEmpty &&
            row['test_marked_source'] == true),
        isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_official_sample_project_library_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(
        File(summary['export_manifest_path'] as String).existsSync(), isTrue);
    expect(
        File(summary['exported_document_path'] as String).existsSync(), isTrue);
    expect(
        File(summary['deleted_test_knowledge_base_path'] as String)
            .existsSync(),
        isFalse);
    expect(File(summary['deleted_test_document_path'] as String).existsSync(),
        isFalse);
    final tombstone =
        jsonDecode(File(summary['tombstone_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(tombstone['schema_version'],
        'prd_v3_official_sample_project_library_tombstone.v1');
    expect(tombstone['status'], 'pass');
    expect(tombstone['only_test_marked_objects_deleted'], isTrue);
    expect(tombstone['real_user_data_deleted'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'official_sample_project_library_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] ==
            'official_sample_project_library_test_objects_deleted'),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'official_sample_project_library_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'official_sample_project_library_manifest' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'official_sample_project_library_tombstones' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 polly-style lead orchestrator creates core evidence package',
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
    final summaryPath =
        await controller.runPollyStyleLeadOrchestratorAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_polly_style_lead_orchestrator_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'polly_style_lead_orchestrator');
    expect(summary['capability_gate'], 'P2-14 Polly-style Lead Orchestrator');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'],
        'P2-15 Sandbox and Tool Permission Industrialization');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final plan =
        jsonDecode(File(summary['plan_path'] as String).readAsStringSync())
            as Map;
    expect(
        plan['schema_version'], 'prd_v3_polly_style_lead_orchestrator_plan.v1');
    expect((plan['subtasks'] as List), hasLength(4));
    final delegations = readJsonlFile(summary['delegation_path'] as String);
    expect(delegations, hasLength(4));
    expect(
        delegations.every((row) =>
            row['decision'] == 'assigned' &&
            row['required_evidence'] is List &&
            (row['required_evidence'] as List).isNotEmpty),
        isTrue);
    final traceRows = readJsonlFile(summary['execution_trace_path'] as String);
    expect(traceRows, hasLength(4));
    expect(traceRows.first['owner_role'], 'lead_orchestrator');
    expect(traceRows.last['owner_role'], 'verifier');
    expect(
        traceRows
            .where((row) => row['owner_role'].toString().contains('worker'))
            .every((row) =>
                row['status'] == 'completed' &&
                (row['evidence_refs'] as List).isNotEmpty),
        isTrue);
    final blockedBranch = jsonDecode(
            File(summary['blocked_branch_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(blockedBranch['schema_version'],
        'prd_v3_polly_style_blocked_branch.v1');
    expect(blockedBranch['completion_blocked'], isTrue);
    expect(blockedBranch['missing_evidence'], contains('source_trace'));
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_polly_style_lead_orchestrator_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(File(summary['handoff_path'] as String).existsSync(), isTrue);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'polly_style_lead_orchestrator_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'polly_style_lead_orchestrator_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'polly_style_lead_orchestrator_handoff' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 sandbox tool permission creates governance evidence package',
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
    final summaryPath = await controller.runSandboxToolPermissionAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_sandbox_tool_permission_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'sandbox_tool_permission');
    expect(summary['capability_gate'],
        'P2-15 Sandbox and Tool Permission Industrialization');
    expect(summary['acceptance_type'], 'governance');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['governance_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-16 Session Share / Fork / Replay');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final permissionMatrix = jsonDecode(
        File(summary['workspace_permission_matrix_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(permissionMatrix['schema_version'],
        'prd_v3_agent_workspace_permission_matrix.v1');
    expect(permissionMatrix['status'], 'pass');
    expect(permissionMatrix['violations'], isEmpty);
    expect(permissionMatrix['blocked_capabilities'],
        containsAll(['arbitrary_shell', 'computer_use']));
    final permissionAudit = jsonDecode(
            File(summary['permission_audit_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        permissionAudit['schema_version'], 'prd_v2_agent_permission_audit.v1');
    expect(permissionAudit['status'], 'pass');
    expect(permissionAudit['secret_display'], 'masked');
    expect(
        permissionAudit['checks'],
        containsAll(
            ['tool_allowlist_enforced', 'no_cross_agent_secret_access']));
    final authRows =
        readJsonlFile(summary['authorization_runtime_audit_path'] as String);
    expect(authRows, hasLength(greaterThanOrEqualTo(5)));
    expect(
        authRows.every((row) =>
            row['expected_decision'] == row['decision'] &&
            row['secret_plaintext_written'] == false),
        isTrue);
    expect(
        authRows.any((row) =>
            row['error_code'] == 'tool_not_allowlisted' &&
            row['decision'] == 'deny'),
        isTrue);
    expect(
        authRows.any((row) =>
            row['error_code'] == 'plaintext_secret_access_denied' &&
            row['decision'] == 'deny'),
        isTrue);
    final blockReport = jsonDecode(
        File(summary['unauthorized_access_block_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(blockReport['schema_version'],
        'prd_v3_agent_unauthorized_access_block_report.v1');
    expect(blockReport['status'], 'pass');
    expect(blockReport['unauthorized_resources_selectable'], isFalse);
    expect(blockReport['blocked_resource_types'],
        containsAll(['unauthorized_kb', 'non_allowlisted_tool']));
    final toolRegistry = jsonDecode(
            File(summary['tool_registry_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(toolRegistry['schema_version'], 'prd_v3_tool_registry.v1');
    expect(toolRegistry['allowlist'],
        containsAll(['kb_retrieval', 'document_export']));
    expect(toolRegistry['blocked_tools'],
        containsAll(['video.generate', 'arbitrary_shell', 'computer_use']));
    final governanceReport = jsonDecode(
        File(summary['governance_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(governanceReport['schema_version'],
        'prd_v3_sandbox_tool_permission_governance_report.v1');
    expect(governanceReport['status'], 'pass');
    expect(governanceReport['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_sandbox_tool_permission_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['secret_plaintext_written'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'sandbox_tool_permission_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'sandbox_tool_permission_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'sandbox_tool_permission_governance_report' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 session share fork replay creates core evidence package', () async {
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
    final summaryPath = await controller.runSessionShareForkReplayAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_session_share_fork_replay_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'session_share_fork_replay');
    expect(summary['capability_gate'], 'P2-16 Session Share / Fork / Replay');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-17 Cloud Disposable Sandbox Evaluation');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final snapshot = jsonDecode(
            File(summary['session_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(snapshot['schema_version'], 'prd_v3_session_share_snapshot.v1');
    expect(snapshot['status'], 'pass');
    expect(snapshot['turns'], hasLength(2));
    expect(snapshot['contains_secret_plaintext'], isFalse);
    expect(snapshot['external_network_required'], isFalse);
    final sharePackage = jsonDecode(
            File(summary['share_package_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(sharePackage['schema_version'], 'prd_v3_session_share_package.v1');
    expect((sharePackage['permissions'] as Map)['read_only'], isTrue);
    expect((sharePackage['permissions'] as Map)['fork_allowed'], isTrue);
    expect((sharePackage['permissions'] as Map)['external_network_required'],
        isFalse);
    final forkManifest = jsonDecode(
            File(summary['fork_manifest_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(forkManifest['schema_version'], 'prd_v3_session_fork_manifest.v1');
    expect(forkManifest['parent_session_modified'], isFalse);
    expect(forkManifest['parent_source_hash'], summary['source_hash']);
    expect(forkManifest['secret_plaintext_written'], isFalse);
    final replayRows = readJsonlFile(summary['replay_log_path'] as String);
    expect(replayRows, hasLength(2));
    expect(
        replayRows.every((row) =>
            row['schema_version'] == 'prd_v3_session_replay_record.v1' &&
            row['replay_status'] == 'matched' &&
            row['content_hash'] == row['expected_hash'] &&
            row['external_call_made'] == false &&
            row['tool_call_made'] == false),
        isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_session_replay_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['parent_hash_preserved'], isTrue);
    expect(validation['replay_matched'], isTrue);
    final errorReport = jsonDecode(
            File(summary['error_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        errorReport['schema_version'], 'prd_v3_session_replay_error_report.v1');
    expect(errorReport['status'], 'pass');
    expect(errorReport['all_error_paths_blocked'], isTrue);
    expect(
        (errorReport['error_cases'] as List).any((row) =>
            (row as Map)['case_id'] == 'missing_snapshot_blocks_replay' &&
            row['decision'] == 'blocked'),
        isTrue);
    expect(
        (errorReport['error_cases'] as List).any((row) =>
            (row as Map)['case_id'] == 'tampered_hash_blocks_replay' &&
            row['decision'] == 'blocked'),
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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'session_share_fork_replay_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'session_share_fork_replay_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'session_share_package' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 cloud disposable sandbox creates core evidence package', () async {
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
    final summaryPath = await controller.runCloudDisposableSandboxAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_cloud_disposable_sandbox_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'cloud_disposable_sandbox');
    expect(summary['capability_gate'],
        'P2-17 Cloud Disposable Sandbox Evaluation');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-18 Fugu-style Multi-Model Orchestration');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final profile =
        jsonDecode(File(summary['profile_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(profile['schema_version'],
        'prd_v3_cloud_disposable_sandbox_profile.v1');
    expect(profile['status'], 'evaluation_contract_only');
    expect(profile['remote_resource_created'], isFalse);
    expect(profile['network_call_made'], isFalse);
    expect(profile['contains_secret_plaintext'], isFalse);
    expect(profile['blocked_mounts'],
        containsAll(['user_home', 'system_paths', 'credential_store']));
    final lifecyclePlan = jsonDecode(
            File(summary['lifecycle_plan_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecyclePlan['schema_version'],
        'prd_v3_cloud_disposable_sandbox_lifecycle_plan.v1');
    expect(lifecyclePlan['status'], 'pass');
    expect(lifecyclePlan['ttl_enforced'], isTrue);
    expect(lifecyclePlan['destroy_required'], isTrue);
    expect(lifecyclePlan['rollback_required'], isTrue);
    final permissionEnvelope = jsonDecode(
        File(summary['permission_envelope_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(permissionEnvelope['schema_version'],
        'prd_v3_cloud_sandbox_permission_envelope.v1');
    expect(permissionEnvelope['status'], 'pass');
    expect(permissionEnvelope['network_default'], 'deny');
    expect(permissionEnvelope['secret_plaintext_access'], isFalse);
    expect(permissionEnvelope['blocked_tools'],
        containsAll(['arbitrary_shell', 'computer_use']));
    final traceRows = readJsonlFile(summary['execution_trace_path'] as String);
    expect(traceRows, hasLength(4));
    expect(
        traceRows.any((row) =>
            row['tool_id'] == 'arbitrary_shell' &&
            row['tool_decision'] == 'deny' &&
            row['executed'] == false),
        isTrue);
    expect(
        traceRows.any((row) =>
            row['action'] == 'destroy_disposable_state' &&
            row['status'] == 'completed'),
        isTrue);
    expect(traceRows.every((row) => row['network_call_made'] != true), isTrue);
    final destroyProof = jsonDecode(
            File(summary['destroy_proof_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(destroyProof['schema_version'],
        'prd_v3_cloud_sandbox_destroy_proof.v1');
    expect(destroyProof['status'], 'pass');
    expect(destroyProof['ttl_expired_or_destroyed'], isTrue);
    expect(destroyProof['real_user_data_deleted'], isFalse);
    expect(destroyProof['secret_plaintext_written'], isFalse);
    final rollbackReport = jsonDecode(
            File(summary['rollback_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(rollbackReport['schema_version'],
        'prd_v3_cloud_sandbox_rollback_report.v1');
    expect(rollbackReport['status'], 'pass');
    expect(rollbackReport['service_binary_packaged_into_exe'], isFalse);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_cloud_disposable_sandbox_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_cloud_sandbox_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['no_cloud_resource_created'], isTrue);
    expect(boundaryReport['no_network_call_made'], isTrue);
    expect(boundaryReport['no_new_dependency'], isTrue);
    expect(boundaryReport['no_packaging_architecture_change'], isTrue);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundaryReport['local_model_training_used'], isFalse);
    expect(boundaryReport['gpu_training_used'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'cloud_disposable_sandbox_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cloud_disposable_sandbox_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cloud_disposable_sandbox_validation' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 fugu multi model orchestration creates core evidence package',
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
    final summaryPath =
        await controller.runFuguMultiModelOrchestrationAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_fugu_multi_model_orchestration_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'fugu_multi_model_orchestration');
    expect(summary['capability_gate'],
        'P2-18 Fugu-style Multi-Model Orchestration');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-19 Loop Orchestrator Industrial');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final taskProfile = jsonDecode(
            File(summary['task_profile_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(taskProfile['schema_version'],
        'prd_v3_multi_model_orchestration_task_profile.v1');
    expect(taskProfile['status'], 'pass');
    expect(taskProfile['execution_mode'], 'local_contract_evaluation');
    expect(taskProfile['external_model_call_made'], isFalse);
    expect(taskProfile['network_call_made'], isFalse);
    expect(taskProfile['contains_secret_plaintext'], isFalse);
    final candidatePool = jsonDecode(
            File(summary['candidate_pool_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(candidatePool['schema_version'],
        'prd_v3_multi_model_candidate_pool.v1');
    expect(candidatePool['status'], 'pass');
    expect(candidatePool['user_visible_project_or_provider_names'], isFalse);
    expect(candidatePool['lanes'], hasLength(3));
    final routerContract = jsonDecode(
            File(summary['router_contract_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(routerContract['schema_version'],
        'prd_v3_multi_model_router_contract.v1');
    expect(routerContract['status'], 'pass');
    expect(routerContract['default_network_policy'], 'deny');
    expect(routerContract['fallback_policy'], 'same_process_local_contract');
    expect(routerContract['user_visible_label_policy'],
        'show_capability_result_not_implementation');
    final routingRows =
        readJsonlFile(summary['routing_decisions_path'] as String);
    expect(routingRows, hasLength(3));
    expect(
        ['draft', 'review', 'verify'].every((segment) =>
            routingRows.any((row) => row['segment_id'] == segment)),
        isTrue);
    expect(
        routingRows.every((row) =>
            row['schema_version'] == 'prd_v3_multi_model_routing_decision.v1' &&
            row['decision'] == 'selected' &&
            row['external_model_call_made'] == false &&
            row['network_call_made'] == false),
        isTrue);
    final fallbackRows =
        readJsonlFile(summary['fallback_trace_path'] as String);
    expect(fallbackRows, hasLength(2));
    expect(
        fallbackRows.any((row) =>
            row['case_id'] == 'missing_citation_check_primary' &&
            row['status'] == 'fallback_succeeded' &&
            row['fallback_lane'] == 'verification_lane'),
        isTrue);
    expect(
        fallbackRows.any((row) =>
            row['case_id'] == 'secret_bearing_request' &&
            row['status'] == 'blocked_by_secret_boundary' &&
            row['secret_plaintext_written'] == false),
        isTrue);
    final evaluatorReport = jsonDecode(
            File(summary['evaluator_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(evaluatorReport['schema_version'],
        'prd_v3_multi_model_evaluator_report.v1');
    expect(evaluatorReport['status'], 'pass');
    expect(evaluatorReport['consensus_status'], 'verified');
    expect(evaluatorReport['conflict_count'], 0);
    expect(evaluatorReport['external_model_call_made'], isFalse);
    final errorReport = jsonDecode(
            File(summary['error_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(errorReport['schema_version'], 'prd_v3_multi_model_error_report.v1');
    expect(errorReport['status'], 'pass');
    expect(errorReport['all_error_paths_blocked'], isTrue);
    expect(errorReport['secret_plaintext_written'], isFalse);
    expect(
        (errorReport['error_cases'] as List).any((row) =>
            (row as Map)['case_id'] == 'empty_candidate_pool_blocks_routing' &&
            row['decision'] == 'blocked'),
        isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_multi_model_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_multi_model_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['external_model_call_made'], isFalse);
    expect(boundaryReport['network_call_made'], isFalse);
    expect(boundaryReport['no_new_dependency'], isTrue);
    expect(boundaryReport['no_packaging_architecture_change'], isTrue);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundaryReport['local_model_training_used'], isFalse);
    expect(boundaryReport['gpu_training_used'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);
    expect(boundaryReport['provider_adapter_parser_user_visible'], isFalse);
    expect(boundaryReport['capability_matrix_user_visible'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'fugu_multi_model_orchestration_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'fugu_multi_model_orchestration_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'fugu_multi_model_orchestration_validation' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 loop orchestrator industrial creates core evidence package',
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
    final summaryPath =
        await controller.runLoopOrchestratorIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_loop_orchestrator_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'loop_orchestrator_industrial');
    expect(summary['capability_gate'], 'P2-19 Loop Orchestrator Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-20 Human Brake and Judgment Gate');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'stage_chain_mutated' ||
          entry.key == 'release_gate_skipped' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final loopPlan =
        jsonDecode(File(summary['loop_plan_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(loopPlan['schema_version'], 'prd_v3_loop_orchestrator_plan.v1');
    expect(loopPlan['status'], 'pass');
    expect(loopPlan['max_auto_repair_rounds'], 3);
    expect(loopPlan['max_network_retry_rounds'], 5);
    expect(loopPlan['stage_chain_locked'], isTrue);
    final traceRows = readJsonlFile(summary['iteration_trace_path'] as String);
    expect(traceRows, hasLength(6));
    expect(
        traceRows.any((row) =>
            row['step'] == 'white_box_gate' &&
            row['status'] == 'soft_blocker_detected' &&
            row['hard_blocker'] == false),
        isTrue);
    expect(
        traceRows.any((row) =>
            row['step'] == 'implementation_repair' &&
            row['status'] == 'completed' &&
            row['retry_count'] == 1),
        isTrue);
    expect(
        traceRows.any((row) =>
            row['step'] == 'automatic_retest' && row['status'] == 'passed'),
        isTrue);
    expect(
        traceRows.any((row) =>
            row['step'] == 'reviewer_gate' && row['status'] == 'passed'),
        isTrue);
    final repairBudget = jsonDecode(
            File(summary['repair_budget_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(repairBudget['schema_version'],
        'prd_v3_loop_orchestrator_repair_budget.v1');
    expect(repairBudget['status'], 'pass');
    expect(repairBudget['max_auto_repair_rounds'], 3);
    expect(repairBudget['repair_rounds_used'], 1);
    expect(repairBudget['repair_budget_exhausted'], isFalse);
    expect(repairBudget['hard_blocker_triggered'], isFalse);
    final networkPolicy = jsonDecode(
        File(summary['network_retry_policy_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(networkPolicy['schema_version'],
        'prd_v3_loop_orchestrator_network_retry_policy.v1');
    expect(networkPolicy['status'], 'pass');
    expect(networkPolicy['max_network_retry_rounds'], 5);
    expect(networkPolicy['retry_wait_seconds'], [10, 30, 60, 120, 300]);
    expect(networkPolicy['network_call_made'], isFalse);
    final checkpoint = jsonDecode(
            File(summary['checkpoint_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(checkpoint['schema_version'],
        'prd_v3_loop_orchestrator_checkpoint_report.v1');
    expect(checkpoint['status'], 'pass');
    expect(checkpoint['checkpoint_required_for_hard_blocker'], isTrue);
    expect(checkpoint['checkpoint_fields'], contains('resume_prompt'));
    final resumePrompt = jsonDecode(
            File(summary['resume_prompt_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(resumePrompt['schema_version'],
        'prd_v3_loop_orchestrator_resume_prompt_report.v1');
    expect(resumePrompt['status'], 'pass');
    expect(resumePrompt['resume_prompt_required'], isTrue);
    expect(resumePrompt['global_goal_complete_must_remain_false'], isTrue);
    final exhaustionReport = jsonDecode(
        File(summary['exhaustion_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(exhaustionReport['schema_version'],
        'prd_v3_loop_orchestrator_exhaustion_report.v1');
    expect(exhaustionReport['status'], 'pass');
    expect(exhaustionReport['auto_repair_exhaustion_turns'], 3);
    expect(exhaustionReport['network_retry_exhaustion_turns'], 5);
    expect(exhaustionReport['hard_blocker_after_exhaustion_only'], isTrue);
    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_loop_orchestrator_state_snapshot.v1');
    expect(stateSnapshot['status'], 'pass');
    expect(stateSnapshot['current_gate'], 'P2-19 Loop Orchestrator Industrial');
    expect(stateSnapshot['next_gate'], 'P2-20 Human Brake and Judgment Gate');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['remaining_gates_non_empty'], isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_loop_orchestrator_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_loop_orchestrator_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['stage_chain_mutated'], isFalse);
    expect(boundaryReport['release_gate_skipped'], isFalse);
    expect(boundaryReport['external_runtime_executed'], isFalse);
    expect(boundaryReport['network_call_made'], isFalse);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundaryReport['local_model_training_used'], isFalse);
    expect(boundaryReport['gpu_training_used'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'loop_orchestrator_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'loop_orchestrator_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'loop_orchestrator_industrial_validation' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 human brake judgment gate creates governance evidence package',
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
    final summaryPath = await controller.runHumanBrakeJudgmentGateAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_human_brake_judgment_gate_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'human_brake_judgment_gate');
    expect(summary['capability_gate'], 'P2-20 Human Brake and Judgment Gate');
    expect(summary['acceptance_type'], 'governance');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['governance_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-21 DataAgent Foundation Industrial');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'stage_chain_mutated' ||
          entry.key == 'release_gate_skipped' ||
          entry.key == 'soft_blocker_stops_execution' ||
          entry.key == 'hard_blocker_without_checkpoint_allowed' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy =
        jsonDecode(File(summary['policy_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(policy['schema_version'], 'prd_v3_human_brake_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['soft_blockers_continue_automatically'], isTrue);
    expect(policy['hard_blockers_stop_execution'], isTrue);
    expect(policy['final_owner_review_remains_queued'], isTrue);
    final decisionMatrix = jsonDecode(
            File(summary['decision_matrix_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(decisionMatrix['schema_version'],
        'prd_v3_human_brake_judgment_matrix.v1');
    expect(decisionMatrix['status'], 'pass');
    expect(decisionMatrix['soft_blocker_cases'], hasLength(3));
    expect(decisionMatrix['hard_blocker_cases'], hasLength(5));
    final softRows =
        readJsonlFile(summary['soft_blocker_routing_path'] as String);
    expect(softRows, hasLength(3));
    expect(
        softRows.every((row) =>
            row['stops_execution'] == false &&
            (row['decision'] == 'auto_repair' ||
                row['decision'] == 'auto_retry')),
        isTrue);
    final hardBlockerReport = jsonDecode(
        File(summary['hard_blocker_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(hardBlockerReport['schema_version'],
        'prd_v3_human_brake_hard_blocker_report.v1');
    expect(hardBlockerReport['status'], 'pass');
    expect(hardBlockerReport['all_hard_blockers_require_stop'], isTrue);
    expect(hardBlockerReport['checkpoint_required'], isTrue);
    expect(hardBlockerReport['failure_report_required'], isTrue);
    expect(hardBlockerReport['resume_prompt_required'], isTrue);
    expect(hardBlockerReport['hard_blocker_cases'],
        contains('secret_exposure_required'));
    final checkpoint = jsonDecode(
        File(summary['checkpoint_contract_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(checkpoint['schema_version'],
        'prd_v3_human_brake_checkpoint_contract.v1');
    expect(checkpoint['status'], 'pass');
    expect(checkpoint['required_fields'], contains('blocked_reason'));
    expect(checkpoint['required_fields'], contains('failure_report'));
    expect(checkpoint['required_fields'], contains('resume_prompt'));
    final ownerReview = jsonDecode(
        File(summary['owner_review_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(ownerReview['schema_version'],
        'prd_v3_human_brake_owner_review_manifest.v1');
    expect(ownerReview['status'], 'pass');
    expect(ownerReview['p2_release_gate_remains_before_final_owner_review'],
        isTrue);
    expect(ownerReview['final_owner_review_gate_remains_queued'], isTrue);
    expect(ownerReview['owner_review_claim_written'], isFalse);
    final queueInvariant = jsonDecode(
        File(summary['queue_invariant_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(queueInvariant['schema_version'],
        'prd_v3_human_brake_queue_invariant_report.v1');
    expect(queueInvariant['status'], 'pass');
    expect(queueInvariant['global_goal_complete'], isFalse);
    expect(queueInvariant['remaining_gates_non_empty'], isTrue);
    expect(queueInvariant['stage_chain_preserved'], isTrue);
    final statusVocabulary = jsonDecode(
        File(summary['status_vocabulary_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(statusVocabulary['schema_version'],
        'prd_v3_human_brake_status_vocabulary_report.v1');
    expect(statusVocabulary['status'], 'pass');
    expect(statusVocabulary['forbidden_positive_claims_present'], isFalse);
    expect(
        statusVocabulary['forbidden_decisions'], contains('skip_release_gate'));
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_human_brake_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_human_brake_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['stage_chain_mutated'], isFalse);
    expect(boundaryReport['release_gate_skipped'], isFalse);
    expect(boundaryReport['soft_blocker_stops_execution'], isFalse);
    expect(boundaryReport['hard_blocker_without_checkpoint_allowed'], isFalse);
    expect(boundaryReport['external_runtime_executed'], isFalse);
    expect(boundaryReport['network_call_made'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'human_brake_judgment_gate_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'human_brake_judgment_gate_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'human_brake_judgment_gate_validation' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 dataagent foundation industrial creates core evidence package',
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
    final summaryPath =
        await controller.runDataAgentFoundationIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_dataagent_foundation_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'dataagent_foundation_industrial');
    expect(summary['capability_gate'], 'P2-21 DataAgent Foundation Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-22 Workbench Native Skills Library');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_database_connected' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final schema =
        jsonDecode(File(summary['schema_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(schema['schema_version'], 'prd_v3_dataagent_record_schema.v1');
    expect(schema['status'], 'pass');
    expect(schema['required_fields'], contains('source_trace_id'));
    expect(schema['required_fields'], contains('quality_score'));
    expect(schema['external_database_required'], isFalse);
    final manifest = jsonDecode(
            File(summary['dataset_manifest_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['schema_version'], 'prd_v3_dataagent_dataset_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['record_count'], 3);
    expect(manifest['test_marker'], isTrue);
    expect(manifest['network_call_made'], isFalse);
    final records = readJsonlFile(summary['task_records_path'] as String);
    expect(records, hasLength(3));
    expect(
        records.every((row) =>
            row['schema_version'] == 'prd_v3_dataagent_task_record.v1' &&
            row['test_marker'] == true &&
            (row['source_trace_id'] as String).isNotEmpty &&
            (row['evidence_refs'] as List).isNotEmpty &&
            (row['quality_score'] as num) >= 0.95),
        isTrue);
    final traceRows = readJsonlFile(summary['source_trace_path'] as String);
    expect(traceRows, hasLength(3));
    final traceIds = traceRows.map((row) => row['source_trace_id']).toSet();
    expect(records.every((row) => traceIds.contains(row['source_trace_id'])),
        isTrue);
    expect(
        traceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_dataagent_source_trace_record.v1' &&
            row['validation_status'] == 'linked'),
        isTrue);
    final quality = jsonDecode(
            File(summary['quality_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(quality['schema_version'], 'prd_v3_dataagent_quality_report.v1');
    expect(quality['status'], 'pass');
    expect(quality['all_records_have_source_trace'], isTrue);
    expect(quality['all_records_have_evidence_refs'], isTrue);
    expect(quality['duplicate_record_count'], 0);
    expect(quality['missing_required_field_count'], 0);
    final errorReport = jsonDecode(
            File(summary['error_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(errorReport['schema_version'], 'prd_v3_dataagent_error_report.v1');
    expect(errorReport['status'], 'pass');
    expect(errorReport['all_error_paths_blocked'], isTrue);
    expect(errorReport['external_database_required'], isFalse);
    expect(errorReport['external_model_called'], isFalse);
    expect(
        (errorReport['error_cases'] as List).any((row) =>
            (row as Map)['case_id'] == 'missing_source_trace_blocks_close' &&
            row['decision'] == 'blocked'),
        isTrue);
    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        stateSnapshot['schema_version'], 'prd_v3_dataagent_state_snapshot.v1');
    expect(stateSnapshot['status'], 'pass');
    expect(stateSnapshot['record_count'], 3);
    expect(stateSnapshot['source_trace_count'], 3);
    expect(stateSnapshot['global_goal_complete'], isFalse);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(
        validation['schema_version'], 'prd_v3_dataagent_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_dataagent_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['external_database_connected'], isFalse);
    expect(boundaryReport['external_runtime_executed'], isFalse);
    expect(boundaryReport['network_call_made'], isFalse);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundaryReport['local_model_training_used'], isFalse);
    expect(boundaryReport['gpu_training_used'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'dataagent_foundation_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'dataagent_foundation_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'dataagent_foundation_industrial_validation' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 native skills library creates artifact lifecycle evidence',
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
    final summaryPath = await controller.runNativeSkillsLibraryAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'], 'prd_v3_native_skill_library_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'native_skills_library');
    expect(summary['capability_gate'], 'P2-22 Workbench Native Skills Library');
    expect(summary['acceptance_type'], 'artifact');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-23 CLI Agent Hub Evaluation');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_skill_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final templateManifest = jsonDecode(
        File(summary['template_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(templateManifest['schema_version'],
        'prd_v3_native_skill_template_manifest.v1');
    expect(templateManifest['status'], 'pass');
    expect(templateManifest['template_count'], greaterThanOrEqualTo(5));
    expect(templateManifest['external_project_names_user_visible'], isFalse);
    expect(templateManifest['provider_adapter_parser_user_visible'], isFalse);
    final templateRows =
        readJsonlFile(summary['template_catalog_path'] as String);
    expect(templateRows, hasLength(greaterThanOrEqualTo(5)));
    expect(
        templateRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_native_skill_template_catalog_row.v1' &&
            row['test_marker'] == true &&
            (row['user_capability'] as String).isNotEmpty),
        isTrue);
    final createdSnapshot = jsonDecode(
        File(summary['created_skill_snapshot_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(createdSnapshot['schema_version'],
        'prd_v3_native_skill_created_snapshot.v1');
    expect(createdSnapshot['status'], 'pass');
    expect(createdSnapshot['skill_id'], 'test_native_skill_review');
    expect(createdSnapshot['test_marker'], isTrue);
    final testKb =
        jsonDecode(File(summary['test_kb_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(testKb['schema_version'], 'prd_v3_native_skill_test_kb_manifest.v1');
    expect(testKb['knowledge_base_id'], 'test_kb_native_skill_library');
    expect(testKb['test_marker'], isTrue);
    final binding = jsonDecode(
            File(summary['binding_manifest_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        binding['schema_version'], 'prd_v3_native_skill_binding_manifest.v1');
    expect(binding['skill_id'], 'test_native_skill_review');
    expect(binding['knowledge_base_id'], 'test_kb_native_skill_library');
    expect(binding['external_runtime_required'], isFalse);
    final historyRows =
        readJsonlFile(summary['operation_history_path'] as String);
    final operations = historyRows.map((row) => row['operation']).toSet();
    expect(
        operations,
        containsAll([
          'create_skill',
          'bind_knowledge_base',
          'validate_skill',
          'export_skill',
          'open_skill_export',
          'delete_skill',
        ]));
    expect(historyRows.every((row) => row['test_marker'] == true), isTrue);
    final traceRows = readJsonlFile(summary['source_trace_path'] as String);
    expect(traceRows, hasLength(1));
    expect(traceRows.single['validation_status'], 'linked');
    expect(traceRows.single['test_marker'], isTrue);
    final exportManifest = jsonDecode(
            File(summary['export_manifest_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(exportManifest['schema_version'],
        'prd_v3_native_skill_export_manifest.v1');
    expect(exportManifest['export_openable'], isTrue);
    final exportPackage = jsonDecode(
            File(summary['export_file_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(exportPackage['schema_version'],
        'prd_v3_native_skill_export_package.v1');
    expect(exportPackage['skill_id'], 'test_native_skill_review');
    expect(exportPackage['test_marker'], isTrue);
    final openReport = jsonDecode(
            File(summary['open_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(openReport['schema_version'], 'prd_v3_native_skill_open_report.v1');
    expect(openReport['status'], 'pass');
    expect(openReport['opened_skill_id'], 'test_native_skill_review');
    final deleteReport = jsonDecode(
            File(summary['delete_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        deleteReport['schema_version'], 'prd_v3_native_skill_delete_report.v1');
    expect(deleteReport['status'], 'pass');
    expect(deleteReport['skill_existed_before_delete'], isTrue);
    expect(deleteReport['skill_exists_after_delete'], isFalse);
    expect(deleteReport['only_test_marked_object_deleted'], isTrue);
    expect(deleteReport['real_user_data_deleted'], isFalse);
    final tombstone =
        jsonDecode(File(summary['tombstone_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(tombstone['schema_version'], 'prd_v3_native_skill_tombstone.v1');
    expect(tombstone['status'], 'deleted');
    expect(tombstone['test_marker'], isTrue);
    expect(tombstone['real_user_data_deleted'], isFalse);
    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_native_skill_library_state_snapshot.v1');
    expect(stateSnapshot['test_skill_deleted'], isTrue);
    expect(stateSnapshot['global_goal_complete'], isFalse);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_native_skill_library_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_native_skill_library_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['external_project_runtime_loaded'], isFalse);
    expect(boundaryReport['external_skill_runtime_loaded'], isFalse);
    expect(boundaryReport['external_model_called'], isFalse);
    expect(boundaryReport['network_call_made'], isFalse);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundaryReport['local_model_training_used'], isFalse);
    expect(boundaryReport['gpu_training_used'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'native_skill_created' &&
            row['target_id'] == 'test_native_skill_review'),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'native_skill_exported' &&
            row['artifact_path'] == summary['export_file_path']),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'native_skill_deleted' &&
            row['artifact_path'] == summary['tombstone_path']),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'native_skills_library_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'native_skills_library_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'native_skills_library_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'native_skill_test_export' &&
            row['file_path'] == summary['export_file_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'native_skill_test_tombstone' &&
            row['file_path'] == summary['tombstone_path'] &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('p2 cli agent hub evaluation creates core evidence package', () async {
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
    final summaryPath = await controller.runCliAgentHubEvaluationAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_cli_agent_hub_evaluation_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'cli_agent_hub_evaluation');
    expect(summary['capability_gate'], 'P2-23 CLI Agent Hub Evaluation');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-24 Remote Task Control');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_cli_agent_executed' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final registry =
        jsonDecode(File(summary['registry_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(registry['schema_version'], 'prd_v3_cli_agent_hub_registry.v1');
    expect(registry['status'], 'pass');
    expect(registry['agents'], hasLength(3));
    expect(registry['external_project_runtime_loaded'], isFalse);
    final taskPlan =
        jsonDecode(File(summary['task_plan_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(taskPlan['schema_version'], 'prd_v3_cli_agent_hub_task_plan.v1');
    expect(taskPlan['checkpoint_required'], isTrue);
    expect(taskPlan['resume_prompt_required'], isTrue);
    expect(taskPlan['steps'], hasLength(3));
    final envelope = jsonDecode(
        File(summary['permission_envelope_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(envelope['schema_version'],
        'prd_v3_cli_agent_hub_permission_envelope.v1');
    expect(envelope['status'], 'pass');
    expect(envelope['blocked_actions'],
        containsAll(['read_secret', 'network_fetch', 'delete_user_data']));
    expect(envelope['secret_plaintext_access'], isFalse);
    expect(envelope['network_default'], 'deny');
    final traceRows = readJsonlFile(summary['execution_trace_path'] as String);
    expect(traceRows, hasLength(5));
    expect(traceRows.where((row) => row['decision'] == 'allow'), hasLength(3));
    expect(traceRows.where((row) => row['decision'] == 'deny'),
        hasLength(greaterThanOrEqualTo(2)));
    expect(
        traceRows.every((row) =>
            row['schema_version'] == 'prd_v3_cli_agent_hub_trace_record.v1' &&
            row['external_runtime_executed'] == false &&
            row['test_marker'] == true),
        isTrue);
    expect(
        traceRows.any((row) =>
            row['action'] == 'read_secret' &&
            row['decision'] == 'deny' &&
            row['executed'] == false),
        isTrue);
    expect(
        traceRows.any((row) =>
            row['action'] == 'network_fetch' &&
            row['decision'] == 'deny' &&
            row['executed'] == false),
        isTrue);
    final reviewReport = jsonDecode(
            File(summary['review_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(reviewReport['schema_version'],
        'prd_v3_cli_agent_hub_review_report.v1');
    expect(reviewReport['status'], 'pass');
    expect(reviewReport['requires_external_agent_runtime'], isFalse);
    final checkpoint = jsonDecode(
            File(summary['checkpoint_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(checkpoint['schema_version'],
        'prd_v3_cli_agent_hub_checkpoint_report.v1');
    expect(checkpoint['status'], 'pass');
    expect(checkpoint['blocked_reason'], 'secret_access_denied');
    expect(checkpoint['resume_allowed_after_boundary_fix'], isTrue);
    final resume = jsonDecode(
            File(summary['resume_prompt_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(resume['schema_version'],
        'prd_v3_cli_agent_hub_resume_prompt_report.v1');
    expect(resume['status'], 'pass');
    expect(resume['contains_secret_plaintext'], isFalse);
    final failurePolicy = jsonDecode(
            File(summary['failure_policy_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(failurePolicy['schema_version'],
        'prd_v3_cli_agent_hub_failure_policy.v1');
    expect(failurePolicy['max_repair_rounds'], 3);
    expect(failurePolicy['max_network_retry_rounds'], 5);
    expect(failurePolicy['hard_failures'], hasLength(3));
    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_cli_agent_hub_state_snapshot.v1');
    expect(stateSnapshot['agent_count'], 3);
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-24 Remote Task Control');
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_cli_agent_hub_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_cli_agent_hub_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['external_project_runtime_loaded'], isFalse);
    expect(boundaryReport['external_cli_agent_executed'], isFalse);
    expect(boundaryReport['external_model_called'], isFalse);
    expect(boundaryReport['network_call_made'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);
    expect(boundaryReport['stage_chain_mutated'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'cli_agent_hub_evaluation_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cli_agent_hub_evaluation_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cli_agent_hub_evaluation_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cli_agent_hub_checkpoint' &&
            row['file_path'] == summary['checkpoint_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  testWidgets('p2 remote task control exposes cancel and retry user controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final events = <String>[];
    final tasks = [
      WorkbenchTaskSnapshot(
        stage: WorkbenchTaskStage.validation,
        status: WorkbenchTaskStatus.running,
        progress: 0.4,
        currentStep: 'remote_task_running',
        inputRequired: 'test_remote_task_request',
        outputTarget: r'C:\workspace\remote_task_control\result.md',
        nextSafeAction: 'Cancel if the remote task is no longer needed.',
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TaskWorkbenchSurface(
            localeCode: 'zh-CN',
            workspace: r'C:\workspace',
            tasks: tasks,
            onCancel: (task) => events.add('cancel:${task.stage.id}'),
            onRetry: (task) => events.add('retry:${task.stage.id}'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-control-actions')), findsOneWidget);
    expect(find.byKey(const Key('task-control-cancel-validation')),
        findsOneWidget);
    expect(find.text('取消任务'), findsOneWidget);
    expect(find.textContaining('Provider'), findsNothing);
    expect(find.textContaining('Adapter'), findsNothing);
    expect(find.textContaining('Parser'), findsNothing);
    expect(find.textContaining('0/'), findsNothing);
    await tester.tap(find.byKey(const Key('task-control-cancel-validation')));
    await tester.pumpAndSettle();
    expect(events, ['cancel:validation']);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TaskWorkbenchSurface(
            localeCode: 'zh-CN',
            workspace: r'C:\workspace',
            tasks: [
              WorkbenchTaskSnapshot(
                stage: WorkbenchTaskStage.validation,
                status: WorkbenchTaskStatus.retryable,
                progress: 0.6,
                currentStep: 'remote_task_retryable',
                inputRequired: 'test_remote_task_request',
                outputTarget: r'C:\workspace\remote_task_control\result.md',
                nextSafeAction: 'Retry the controlled test task.',
              ),
            ],
            onCancel: (task) => events.add('cancel:${task.stage.id}'),
            onRetry: (task) => events.add('retry:${task.stage.id}'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-control-actions')), findsOneWidget);
    expect(
        find.byKey(const Key('task-control-retry-validation')), findsOneWidget);
    expect(find.text('重试任务'), findsOneWidget);
    await tester.tap(find.byKey(const Key('task-control-retry-validation')));
    await tester.pumpAndSettle();
    expect(events, ['cancel:validation', 'retry:validation']);
  });

  test('p2 remote task control creates user blackbox evidence package',
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
    final summaryPath = await controller.runRemoteTaskControlAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'], 'prd_v3_remote_task_control_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'remote_task_control');
    expect(summary['capability_gate'], 'P2-24 Remote Task Control');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-25 Office Agent Industrialization');
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_remote_service_called' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'network_call_made' ||
          entry.key == 'new_dependency_added' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final queue =
        jsonDecode(File(summary['queue_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(queue['schema_version'], 'prd_v3_remote_task_control_queue.v1');
    expect(queue['status'], 'completed_after_retry');
    expect(queue['tasks'], hasLength(1));
    final controlRows = readJsonlFile(summary['control_log_path'] as String);
    expect(controlRows, hasLength(5));
    expect(controlRows.map((row) => row['action']),
        containsAll(['submit', 'start', 'cancel', 'retry', 'complete']));
    expect(
        controlRows.every((row) =>
            row['schema_version'] == 'prd_v3_remote_task_control_event.v1' &&
            row['test_marker'] == true),
        isTrue);
    final uiBinding = jsonDecode(
        File(summary['ui_binding_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(uiBinding['schema_version'],
        'prd_v3_remote_task_control_ui_binding_report.v1');
    expect(uiBinding['status'], 'pass');
    expect(uiBinding['visible_labels'], containsAll(['取消任务', '重试任务']));
    expect(uiBinding['provider_adapter_parser_visible'], isFalse);
    expect(uiBinding['capability_matrix_visible'], isFalse);
    final permission = jsonDecode(
        File(summary['permission_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(permission['schema_version'],
        'prd_v3_remote_task_control_permission_report.v1');
    expect(permission['status'], 'pass');
    expect(permission['blocked_actions'],
        containsAll(['read_secret', 'delete_real_user_data']));
    expect(permission['secret_plaintext_written'], isFalse);
    expect(permission['external_runtime_started'], isFalse);
    final openReport = jsonDecode(
            File(summary['open_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(openReport['status'], 'pass');
    final exportPackage = jsonDecode(
            File(summary['export_package_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(exportPackage['schema_version'],
        'prd_v3_remote_task_control_export_package.v1');
    expect(exportPackage['test_marker'], isTrue);
    final deleteReport = jsonDecode(
            File(summary['delete_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(deleteReport['status'], 'pass');
    expect(deleteReport['active_task_exists_before_delete'], isTrue);
    expect(deleteReport['active_task_exists_after_delete'], isFalse);
    expect(deleteReport['real_user_data_deleted'], isFalse);
    expect(File(summary['tombstone_path'] as String).existsSync(), isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_remote_task_control_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundaryReport = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_remote_task_control_boundary_report.v1');
    expect(boundaryReport['status'], 'pass');
    expect(boundaryReport['external_remote_service_called'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);
    expect(boundaryReport['stage_chain_mutated'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'remote_task_control_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'remote_task_control_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'remote_task_control_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'remote_task_control_export_package' &&
            row['file_path'] == summary['export_package_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'remote_task_control_tombstone' &&
            row['file_path'] == summary['tombstone_path'] &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('p2 office agent industrialization creates template document evidence',
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
    final summaryPath =
        await controller.runOfficeAgentIndustrializationAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_office_agent_industrialization_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'office_agent_industrialization');
    expect(summary['capability_gate'], 'P2-25 Office Agent Industrialization');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-26 Multi-KB Governance Industrial');

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_office_runtime_called' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'network_call_made' ||
          entry.key == 'new_dependency_added' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final templateManifest = jsonDecode(
        File(summary['template_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(templateManifest['schema_version'],
        'prd_v3_office_agent_template_manifest.v1');
    expect(templateManifest['user_visible_entry'], '常用文档模板');
    expect(templateManifest['user_visible_action'], '生成文档');
    expect(templateManifest['template_count'], 5);
    final templateText = jsonEncode(templateManifest);
    for (final token in [
      'OpenDataLoader',
      'Composio',
      'Provider Matrix',
      'Capability Matrix',
      'dependency_gated',
      'ready_for_user_selection',
      '0/',
    ]) {
      expect(templateText.contains(token), isFalse, reason: token);
    }

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(2));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] == 'prd_v3_office_agent_source_trace.v1' &&
            row['test_marker'] == true),
        isTrue);
    final citation = jsonDecode(
        File(summary['citation_binding_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(citation['schema_version'],
        'prd_v3_office_agent_citation_binding_report.v1');
    expect(citation['status'], 'pass');
    expect(citation['citation_count'], sourceTraceRows.length);
    expect((citation['bindings'] as List), hasLength(sourceTraceRows.length));

    final generatedDocument =
        File(summary['generated_document_path'] as String);
    expect(generatedDocument.existsSync(), isTrue);
    expect(generatedDocument.readAsBytesSync().take(4).toList(),
        [0x50, 0x4b, 0x03, 0x04]);
    final openReport = jsonDecode(
            File(summary['open_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(openReport['status'], 'pass');
    expect(openReport['missing_docx_parts'], isEmpty);
    final exportManifest = jsonDecode(
            File(summary['export_manifest_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(exportManifest['schema_version'],
        'prd_v3_office_agent_export_manifest.v1');
    expect(exportManifest['status'], 'pass');
    expect(
        File(summary['exported_document_path'] as String).existsSync(), isTrue);
    final deleteReport = jsonDecode(
            File(summary['delete_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(deleteReport['status'], 'pass');
    expect(deleteReport['active_document_exists_before_delete'], isTrue);
    expect(deleteReport['active_document_exists_after_delete'], isFalse);
    expect(deleteReport['real_user_data_deleted'], isFalse);
    expect(File(summary['tombstone_path'] as String).existsSync(), isTrue);
    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_office_agent_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        boundary['schema_version'], 'prd_v3_office_agent_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_office_runtime_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'office_agent_industrialization_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'office_agent_document_deleted' &&
            row['metadata']['real_user_data_deleted'] == false),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'office_agent_industrialization_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'office_agent_generated_test_document' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'office_agent_validation_report' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'office_agent_test_document_tombstone' &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('p2 multi kb governance industrial creates core evidence package',
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
    final summaryPath =
        await controller.runMultiKbGovernanceIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_multi_kb_governance_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'multi_kb_governance_industrial');
    expect(summary['capability_gate'], 'P2-26 Multi-KB Governance Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-27 Versioned Knowledge Governance');

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_database_connected' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'network_call_made' ||
          entry.key == 'new_dependency_added' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final templateManifest = jsonDecode(
        File(summary['template_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(templateManifest['schema_version'],
        'prd_v3_multi_kb_template_manifest.v1');
    expect(templateManifest['user_visible_entry'], '常用知识库模板');
    expect(templateManifest['user_visible_action'], '创建知识库');
    expect(templateManifest['template_count'], 5);
    final templateText = jsonEncode(templateManifest);
    for (final token in [
      'OpenDataLoader',
      'Composio',
      'Provider Matrix',
      'Capability Matrix',
      'dependency_gated',
      'ready_for_user_selection',
      '0/',
    ]) {
      expect(templateText.contains(token), isFalse, reason: token);
    }

    final manifest = jsonDecode(
        File(summary['multi_kb_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(
        manifest['schema_version'], 'prd_v3_multi_kb_governance_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['knowledge_base_count'], 3);
    final knowledgeBases =
        (manifest['knowledge_bases'] as List).cast<Map<String, dynamic>>();
    expect(knowledgeBases.every((row) => row['test_marker'] == true), isTrue);

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(3));
    expect(
        sourceTraceRows.map((row) => row['knowledge_base_id']).toSet().length,
        3);
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] == 'prd_v3_multi_kb_source_trace.v1' &&
            row['test_marker'] == true &&
            (row['version_id'] as String).isNotEmpty &&
            (row['citation'] as String).isNotEmpty),
        isTrue);

    final scope = jsonDecode(
            File(summary['scope_matrix_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(scope['schema_version'], 'prd_v3_multi_kb_scope_matrix.v1');
    expect(scope['status'], 'pass');
    expect(scope['primary_knowledge_base_id'], 'test_kb_company_p2_26');
    expect(scope['allowed_reference_kb_ids'],
        containsAll(['test_kb_project_p2_26', 'test_kb_research_p2_26']));
    expect(scope['denied_kb_ids'], contains('real_user_kb_not_test_marked'));

    final permission = jsonDecode(
        File(summary['permission_matrix_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(
        permission['schema_version'], 'prd_v3_multi_kb_permission_matrix.v1');
    expect(permission['status'], 'pass');
    expect(permission['blocked_actions'],
        contains('delete_real_user_knowledge_base'));
    expect(permission['real_user_data_deleted'], isFalse);
    expect(permission['secret_plaintext_written'], isFalse);

    final versionMetadata = jsonDecode(
            File(summary['version_metadata_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(versionMetadata['schema_version'],
        'prd_v3_multi_kb_version_scope_metadata.v1');
    expect(versionMetadata['status'], 'pass');
    expect(
        versionMetadata['versioned_knowledge_governance_closed_by_this_gate'],
        isFalse);
    expect((versionMetadata['versions'] as List), hasLength(3));

    final queryRoute = jsonDecode(
        File(summary['query_answer_route_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(queryRoute['schema_version'],
        'prd_v3_multi_kb_query_answer_route_report.v1');
    expect(queryRoute['status'], 'pass');
    expect(queryRoute['route'], 'Anchor -> Entity -> Evidence -> Answer');
    expect(queryRoute['used_knowledge_base_ids'],
        containsAll(['test_kb_company_p2_26', 'test_kb_project_p2_26']));
    expect(queryRoute['blocked_knowledge_base_ids'],
        contains('real_user_kb_not_test_marked'));

    final deleteReport = jsonDecode(
            File(summary['delete_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(deleteReport['schema_version'],
        'prd_v3_multi_kb_governance_delete_report.v1');
    expect(deleteReport['status'], 'pass');
    expect(deleteReport['active_record_exists_before_delete'], isTrue);
    expect(deleteReport['active_record_exists_after_delete'], isFalse);
    expect(deleteReport['real_user_data_deleted'], isFalse);
    expect(File(summary['tombstone_path'] as String).existsSync(), isTrue);

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_multi_kb_governance_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_multi_kb_governance_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);
    expect(boundary['versioned_knowledge_governance_closed_by_this_gate'],
        isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'multi_kb_governance_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'multi_kb_governance_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'multi_kb_governance_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'multi_kb_governance_source_trace' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'multi_kb_governance_tombstone' &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('p2 versioned knowledge governance creates core evidence package',
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
    final summaryPath =
        await controller.runVersionedKnowledgeGovernanceAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_versioned_knowledge_governance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'versioned_knowledge_governance');
    expect(summary['capability_gate'], 'P2-27 Versioned Knowledge Governance');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-28 Jurisdiction / Domain Scope');

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_database_connected' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'network_call_made' ||
          entry.key == 'new_dependency_added' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final registry = jsonDecode(
            File(summary['version_registry_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        registry['schema_version'], 'prd_v3_versioned_knowledge_registry.v1');
    expect(registry['status'], 'pass');
    expect(registry['user_visible_entry'], '知识库版本记录');
    expect(registry['current_version_id'], 'test_kb_versioned_p2_27_v3');
    expect(
        registry['rollback_target_version_id'], 'test_kb_versioned_p2_27_v2');
    final versions =
        (registry['versions'] as List).cast<Map<String, dynamic>>();
    expect(versions, hasLength(3));
    expect(versions.every((row) => row['test_marker'] == true), isTrue);
    expect(versions[1]['parent_version_id'], 'test_kb_versioned_p2_27_v1');
    expect(versions[2]['parent_version_id'], 'test_kb_versioned_p2_27_v2');
    final userVisibleText = jsonEncode({
      'entry': registry['user_visible_entry'],
      'actions': registry['user_visible_actions'],
    });
    for (final token in [
      'OpenDataLoader',
      'Composio',
      'Provider Matrix',
      'Capability Matrix',
      'dependency_gated',
      'ready_for_user_selection',
      '0/',
    ]) {
      expect(userVisibleText.contains(token), isFalse, reason: token);
    }

    final manifest = jsonDecode(
        File(summary['test_knowledge_base_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(manifest['schema_version'],
        'prd_v3_versioned_knowledge_base_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['knowledge_base_id'], 'test_kb_versioned_p2_27');
    expect(manifest['test_marker'], isTrue);
    expect((manifest['documents'] as List), hasLength(3));

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(3));
    expect(
        sourceTraceRows.map((row) => row['version_id']).toSet(),
        containsAll([
          'test_kb_versioned_p2_27_v1',
          'test_kb_versioned_p2_27_v2',
          'test_kb_versioned_p2_27_v3',
        ]));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_versioned_knowledge_source_trace.v1' &&
            row['test_marker'] == true &&
            (row['citation'] as String).isNotEmpty),
        isTrue);

    final diff = jsonDecode(File(summary['version_diff_report_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(diff['schema_version'], 'prd_v3_versioned_knowledge_diff_report.v1');
    expect(diff['status'], 'pass');
    expect(diff['from_version_id'], 'test_kb_versioned_p2_27_v2');
    expect(diff['to_version_id'], 'test_kb_versioned_p2_27_v3');
    expect(diff['added_chunks'], contains('test_chunk_version_revision_001'));

    final rollback = jsonDecode(
            File(summary['rollback_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(rollback['schema_version'],
        'prd_v3_versioned_knowledge_rollback_report.v1');
    expect(rollback['status'], 'pass');
    expect(rollback['active_version_before_rollback'],
        'test_kb_versioned_p2_27_v3');
    expect(
        rollback['rollback_target_version_id'], 'test_kb_versioned_p2_27_v2');
    expect(rollback['active_version_after_rollback'],
        'test_kb_versioned_p2_27_v2');
    expect(rollback['real_user_data_deleted'], isFalse);

    final queryRoute = jsonDecode(
        File(summary['query_answer_route_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(queryRoute['schema_version'],
        'prd_v3_versioned_knowledge_query_answer_route_report.v1');
    expect(queryRoute['status'], 'pass');
    expect(queryRoute['route'], 'Anchor -> Entity -> Evidence -> Answer');
    expect(queryRoute['active_version_id'], 'test_kb_versioned_p2_27_v2');
    expect(queryRoute['excluded_version_ids'],
        contains('test_kb_versioned_p2_27_v3'));

    final deleteReport = jsonDecode(
            File(summary['delete_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(deleteReport['schema_version'],
        'prd_v3_versioned_knowledge_delete_report.v1');
    expect(deleteReport['status'], 'pass');
    expect(deleteReport['active_record_exists_before_delete'], isTrue);
    expect(deleteReport['active_record_exists_after_delete'], isFalse);
    expect(deleteReport['real_user_data_deleted'], isFalse);
    expect(File(summary['tombstone_path'] as String).existsSync(), isTrue);

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_versioned_knowledge_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_versioned_knowledge_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'versioned_knowledge_governance_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'versioned_knowledge_governance_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'versioned_knowledge_governance_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'versioned_knowledge_governance_source_trace' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'versioned_knowledge_governance_tombstone' &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('p2 jurisdiction domain scope creates core evidence package', () async {
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
    final summaryPath = await controller.runJurisdictionDomainScopeAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_jurisdiction_domain_scope_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'jurisdiction_domain_scope');
    expect(summary['capability_gate'], 'P2-28 Jurisdiction / Domain Scope');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-29 Human Review Console');

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_database_connected' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'network_call_made' ||
          entry.key == 'new_dependency_added' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy = jsonDecode(
        File(summary['jurisdiction_policy_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(policy['schema_version'], 'prd_v3_jurisdiction_domain_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['user_visible_entry'], '知识范围规则');
    final rules = (policy['rules'] as List).cast<Map<String, dynamic>>();
    expect(rules.any((row) => row['decision'] == 'allow'), isTrue);
    expect(rules.any((row) => row['decision'] == 'block'), isTrue);
    final userVisibleText = jsonEncode({
      'entry': policy['user_visible_entry'],
      'actions': policy['user_visible_actions'],
    });
    for (final token in [
      'OpenDataLoader',
      'Composio',
      'Provider Matrix',
      'Capability Matrix',
      'dependency_gated',
      'ready_for_user_selection',
      '0/',
    ]) {
      expect(userVisibleText.contains(token), isFalse, reason: token);
    }

    final scope = jsonDecode(File(summary['domain_scope_matrix_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(
        scope['schema_version'], 'prd_v3_jurisdiction_domain_scope_matrix.v1');
    expect(scope['status'], 'pass');
    expect(scope['active_jurisdiction'], 'cn_mainland');
    expect(scope['active_domain'], 'company_policy');
    expect(
        scope['allowed_knowledge_base_ids'],
        containsAll(
            ['test_kb_policy_cn_p2_28', 'test_kb_research_public_p2_28']));
    expect(scope['blocked_knowledge_base_ids'],
        contains('real_user_finance_kb_not_test'));

    final manifest = jsonDecode(
        File(summary['test_knowledge_base_manifest_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(manifest['schema_version'],
        'prd_v3_jurisdiction_domain_kb_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['test_knowledge_base_count'], 2);
    expect(manifest['blocked_non_test_knowledge_base_count'], 1);

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(2));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_jurisdiction_domain_source_trace.v1' &&
            row['test_marker'] == true &&
            (row['jurisdiction'] as String).isNotEmpty &&
            (row['domain'] as String).isNotEmpty &&
            (row['citation'] as String).isNotEmpty),
        isTrue);

    final queryRoute = jsonDecode(
        File(summary['query_answer_route_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(queryRoute['schema_version'],
        'prd_v3_jurisdiction_domain_query_answer_route_report.v1');
    expect(queryRoute['status'], 'pass');
    expect(queryRoute['route'], 'Anchor -> Entity -> Evidence -> Answer');
    expect(
        queryRoute['used_knowledge_base_ids'],
        containsAll(
            ['test_kb_policy_cn_p2_28', 'test_kb_research_public_p2_28']));
    expect(queryRoute['blocked_knowledge_base_ids'],
        contains('real_user_finance_kb_not_test'));

    final denied = jsonDecode(
        File(summary['denied_scope_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(denied['schema_version'],
        'prd_v3_jurisdiction_domain_denied_scope_report.v1');
    expect(denied['status'], 'pass');
    expect(denied['blocked_actions'],
        contains('read_out_of_scope_knowledge_base'));
    expect(denied['real_user_data_deleted'], isFalse);

    final permission = jsonDecode(
        File(summary['permission_matrix_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(permission['schema_version'],
        'prd_v3_jurisdiction_domain_permission_matrix.v1');
    expect(permission['status'], 'pass');
    final deniedActions =
        (permission['denied_actions'] as Map).cast<String, dynamic>();
    expect(deniedActions['test_scope_reviewer'],
        contains('delete_real_user_finance_kb_not_test'));
    expect(permission['real_user_data_deleted'], isFalse);
    expect(permission['secret_plaintext_written'], isFalse);

    final deleteReport = jsonDecode(
            File(summary['delete_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(deleteReport['schema_version'],
        'prd_v3_jurisdiction_domain_delete_report.v1');
    expect(deleteReport['status'], 'pass');
    expect(deleteReport['active_record_exists_before_delete'], isTrue);
    expect(deleteReport['active_record_exists_after_delete'], isFalse);
    expect(deleteReport['real_user_data_deleted'], isFalse);
    expect(File(summary['tombstone_path'] as String).existsSync(), isTrue);

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_jurisdiction_domain_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_jurisdiction_domain_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'jurisdiction_domain_scope_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'jurisdiction_domain_scope_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'jurisdiction_domain_scope_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'jurisdiction_domain_scope_source_trace' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'jurisdiction_domain_scope_tombstone' &&
            row['status'] == 'deleted'),
        isTrue);
  });

  test('p2 human review console creates governance evidence package', () async {
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
    final summaryPath = await controller.runHumanReviewConsoleAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'], 'prd_v3_human_review_console_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'human_review_console');
    expect(summary['capability_gate'], 'P2-29 Human Review Console');
    expect(summary['acceptance_type'], 'governance');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['governance_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-30 Reliability Score Industrial');

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'ui_modified' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final queue = jsonDecode(
            File(summary['review_queue_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(queue['schema_version'], 'prd_v3_human_review_console_queue.v1');
    expect(queue['status'], 'pass');
    expect(queue['current_gate'], 'P2-29 Human Review Console');
    expect(queue['next_gate'], 'P2-30 Reliability Score Industrial');
    final queueItems =
        (queue['queue_items'] as List).cast<Map<String, dynamic>>();
    expect(queueItems, hasLength(3));
    expect(
        queueItems.map((row) => row['required_action']),
        containsAll([
          'accept_evidence',
          'request_fix_and_retest',
          'stop_with_checkpoint',
        ]));
    expect(queueItems.every((row) => row['test_marker'] == true), isTrue);

    final decisionRows = readJsonlFile(summary['decision_log_path'] as String);
    expect(decisionRows, hasLength(3));
    expect(decisionRows.map((row) => row['decision']),
        containsAll(['accepted', 'fix_requested', 'hard_blocker_escalated']));
    expect(
        decisionRows.any((row) =>
            row['requires_checkpoint'] == true &&
            row['decision'] == 'hard_blocker_escalated'),
        isTrue);
    expect(
        decisionRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_human_review_console_decision.v1' &&
            row['contains_secret_plaintext'] == false),
        isTrue);

    final checklist = jsonDecode(
        File(summary['reviewer_checklist_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(checklist['schema_version'],
        'prd_v3_human_review_console_checklist.v1');
    expect(checklist['status'], 'pass');
    expect(checklist['all_required_checks_present'], isTrue);
    expect(
        checklist['required_checks'],
        containsAll(
            ['release_gate_not_skipped', 'close_allowed_not_overclaimed']));

    final evidence = jsonDecode(
            File(summary['evidence_packet_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(evidence['schema_version'],
        'prd_v3_human_review_console_evidence_packet.v1');
    expect(evidence['status'], 'pass');
    expect(evidence['validation_report_required'], isTrue);

    final handoff = jsonDecode(
            File(summary['owner_handoff_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(handoff['schema_version'],
        'prd_v3_human_review_console_owner_handoff.v1');
    expect(handoff['status'], 'pass');
    expect(handoff['p2_release_gate_still_required'], isTrue);
    expect(handoff['final_owner_review_still_queued'], isTrue);
    expect(handoff['handoff_status'], 'owner_review_not_current_gate');

    final vocabulary = jsonDecode(
        File(summary['status_vocabulary_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(vocabulary['schema_version'],
        'prd_v3_human_review_console_status_vocabulary.v1');
    expect(vocabulary['status'], 'pass');
    expect(vocabulary['unknown_status_count'], 0);
    expect(vocabulary['allowed_statuses'],
        containsAll(['queued_for_review', 'fix_requested']));

    final invariant = jsonDecode(
            File(summary['queue_invariant_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(invariant['schema_version'],
        'prd_v3_human_review_console_queue_invariant.v1');
    expect(invariant['status'], 'pass');
    expect(invariant['global_goal_complete'], isFalse);
    expect(invariant['remaining_gates_non_empty'], isTrue);
    expect(invariant['p2_release_gate_still_queued'], isTrue);
    expect(invariant['final_owner_review_still_queued'], isTrue);

    final forbidden = jsonDecode(
            File(summary['forbidden_claims_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(forbidden['schema_version'],
        'prd_v3_human_review_console_forbidden_claims.v1');
    expect(forbidden['status'], 'pass');
    expect(forbidden['final_readiness_claims_absent'], isTrue);
    expect(forbidden['single_gate_not_treated_as_global_completion'], isTrue);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_human_review_console_state_snapshot.v1');
    expect(stateSnapshot['queue_item_count'], 3);
    expect(stateSnapshot['decision_count'], 3);
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-30 Reliability Score Industrial');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_human_review_console_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_human_review_console_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['ui_modified'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);
    expect(boundary['stage_chain_mutated'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'human_review_console_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'human_review_console_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'human_review_console_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'human_review_console_decision_log' &&
            row['file_path'] == summary['decision_log_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 reliability score industrial creates core evidence package',
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
    final summaryPath =
        await controller.runReliabilityScoreIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_reliability_score_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'reliability_score_industrial');
    expect(summary['capability_gate'], 'P2-30 Reliability Score Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-31 Night Knowledge Maintenance Loop');

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'sag_runtime_loaded' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy = jsonDecode(
            File(summary['scoring_policy_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(policy['schema_version'], 'prd_v3_reliability_score_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['low_score_threshold'], 0.8);
    expect(policy['score_components'], hasLength(4));

    final entityIndex = jsonDecode(
            File(summary['entity_index_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(entityIndex['schema_version'], 'prd_v3_reliability_entity_index.v1');
    expect(entityIndex['status'], 'pass');
    expect(entityIndex['entities'], hasLength(2));
    expect(entityIndex['relations'], hasLength(1));
    expect(
        (entityIndex['entities'] as List)
            .cast<Map<String, dynamic>>()
            .every((row) => row['test_marker'] == true),
        isTrue);

    final semanticEvents =
        readJsonlFile(summary['semantic_events_path'] as String);
    expect(semanticEvents, hasLength(3));
    expect(
        semanticEvents.map((row) => row['event_type']),
        containsAll(
            ['source_trace_linked', 'conflict_detected', 'repair_routed']));
    expect(
        semanticEvents.every((row) =>
            row['schema_version'] == 'prd_v3_reliability_semantic_event.v1' &&
            row['test_marker'] == true),
        isTrue);

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(3));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_reliability_score_source_trace.v1' &&
            row['test_marker'] == true &&
            (row['citation'] as String).isNotEmpty &&
            (row['entity_ids'] as List).isNotEmpty),
        isTrue);

    final scoreMatrix = jsonDecode(
            File(summary['score_matrix_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(scoreMatrix['schema_version'], 'prd_v3_reliability_score_matrix.v1');
    expect(scoreMatrix['status'], 'pass');
    final scoreRows =
        (scoreMatrix['score_rows'] as List).cast<Map<String, dynamic>>();
    expect(scoreRows, hasLength(2));
    expect(scoreRows.map((row) => row['decision']),
        containsAll(['pass', 'repair_required']));
    expect(
        scoreRows.every((row) =>
            (row['final_score'] as num) >= 0 &&
            (row['final_score'] as num) <= 1),
        isTrue);

    final reliability = jsonDecode(
        File(summary['reliability_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(reliability['schema_version'], 'prd_v3_reliability_score_report.v1');
    expect(reliability['status'], 'pass');
    expect(reliability['source_trace_count'], 3);
    expect(reliability['entity_count'], 2);
    expect(reliability['relation_count'], 1);
    expect(reliability['repair_required_case_count'], 1);

    final repair = jsonDecode(
            File(summary['repair_routing_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        repair['schema_version'], 'prd_v3_reliability_score_repair_routing.v1');
    expect(repair['status'], 'pass');
    expect(repair['network_retry_required'], isFalse);
    expect((repair['repair_items'] as List).first['blocked_reason'],
        'score_below_threshold');

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_reliability_score_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(
        stateSnapshot['next_gate'], 'P2-31 Night Knowledge Maintenance Loop');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_reliability_score_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_reliability_score_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['sag_runtime_loaded'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'reliability_score_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'reliability_score_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'reliability_score_industrial_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'reliability_score_industrial_source_trace' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'reliability_score_industrial_score_matrix' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 night knowledge maintenance creates core evidence package',
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
    final summaryPath =
        await controller.runNightKnowledgeMaintenanceAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_night_knowledge_maintenance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'night_knowledge_maintenance');
    expect(
        summary['capability_gate'], 'P2-31 Night Knowledge Maintenance Loop');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-32 Citation Auto-Repair Industrial');
    expect(summary['task_count'], 4);
    expect(summary['queue_item_count'], 4);
    expect(summary['journal_event_count'], 4);
    expect(summary['repair_candidate_count'], 1);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'background_daemon_started' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy =
        jsonDecode(File(summary['policy_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(policy['schema_version'],
        'prd_v3_night_knowledge_maintenance_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['max_auto_repair_rounds'], 3);
    expect(policy['network_retry_rounds'], 5);
    expect(policy['requires_test_marker_for_delete'], isTrue);
    expect(policy['disallowed_actions'],
        containsAll(['real_user_data_deletion', 'local_model_training']));

    final plan =
        jsonDecode(File(summary['plan_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(
        plan['schema_version'], 'prd_v3_night_knowledge_maintenance_plan.v1');
    expect(plan['status'], 'pass');
    expect(plan['background_daemon_started'], isFalse);
    final tasks = (plan['tasks'] as List).cast<Map<String, dynamic>>();
    expect(tasks, hasLength(4));
    expect(tasks.map((row) => row['task_type']),
        containsAll(['source_trace_validation', 'repair_candidate_routing']));
    expect(tasks.every((row) => row['test_marker'] == true), isTrue);

    final queueRows = readJsonlFile(summary['queue_path'] as String);
    expect(queueRows, hasLength(4));
    expect(queueRows.map((row) => row['status']),
        containsAll(['completed', 'queued_for_retest', 'checkpointed']));
    expect(
        queueRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_night_knowledge_maintenance_queue.v1' &&
            row['test_marker'] == true),
        isTrue);
    expect(
        queueRows.any((row) =>
            row['required_action'] == 'auto_fix_then_retest' &&
            row['source_trace_required'] == true),
        isTrue);

    final journalRows = readJsonlFile(summary['journal_path'] as String);
    expect(journalRows, hasLength(4));
    expect(journalRows.map((row) => row['event_type']),
        containsAll(['maintenance_started', 'next_window_checkpointed']));
    expect(
        journalRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_night_knowledge_maintenance_journal.v1' &&
            row['test_marker'] == true),
        isTrue);

    final repair = jsonDecode(File(summary['repair_candidates_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(repair['schema_version'],
        'prd_v3_night_knowledge_maintenance_repair_candidates.v1');
    expect(repair['status'], 'pass');
    final repairCandidates =
        (repair['repair_candidates'] as List).cast<Map<String, dynamic>>();
    expect(repairCandidates, hasLength(1));
    expect(repairCandidates.first['recommended_action'],
        'add_source_trace_and_retest');
    expect(repairCandidates.first['auto_fix_allowed'], isTrue);
    expect(repairCandidates.first['max_retry_rounds'], 3);

    final schedule =
        jsonDecode(File(summary['schedule_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(schedule['schema_version'],
        'prd_v3_night_knowledge_maintenance_schedule.v1');
    expect(schedule['status'], 'pass');
    expect(schedule['p2_release_gate_rerun_required'], isTrue);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_night_knowledge_maintenance_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-32 Citation Auto-Repair Industrial');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_night_knowledge_maintenance_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_night_knowledge_maintenance_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['background_daemon_started'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'night_knowledge_maintenance_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'night_knowledge_maintenance_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'night_knowledge_maintenance_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'night_knowledge_maintenance_queue' &&
            row['file_path'] == summary['queue_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'night_knowledge_maintenance_journal' &&
            row['file_path'] == summary['journal_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 citation auto repair creates core evidence package', () async {
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
    final summaryPath = await controller.runCitationAutoRepairAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'], 'prd_v3_citation_auto_repair_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'citation_auto_repair');
    expect(summary['capability_gate'], 'P2-32 Citation Auto-Repair Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-33 Memory Consolidation Industrial');
    expect(summary['issue_count'], 1);
    expect(summary['repair_action_count'], 2);
    expect(summary['patched_trace_count'], 2);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final beforeRows =
        readJsonlFile(summary['source_trace_before_path'] as String);
    expect(beforeRows, hasLength(2));
    expect(
        beforeRows.any((row) =>
            row['validation_status'] == 'missing_citation' &&
            row['citation'] == ''),
        isTrue);

    final issues = jsonDecode(
            File(summary['citation_issues_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(issues['schema_version'], 'prd_v3_citation_auto_repair_issues.v1');
    expect(issues['status'], 'pass');
    final issueRows = (issues['issues'] as List).cast<Map<String, dynamic>>();
    expect(issueRows, hasLength(1));
    expect(issueRows.first['issue_type'], 'missing_citation');
    expect(issueRows.first['auto_fix_allowed'], isTrue);
    expect(issueRows.first['max_retry_rounds'], 3);

    final plan = jsonDecode(
            File(summary['repair_plan_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(plan['schema_version'], 'prd_v3_citation_auto_repair_plan.v1');
    expect(plan['status'], 'pass');
    expect(plan['max_auto_repair_rounds'], 3);
    expect(plan['network_retry_required'], isFalse);
    final actions = (plan['actions'] as List).cast<Map<String, dynamic>>();
    expect(
        actions.map((row) => row['action_type']),
        containsAll(
            ['patch_source_trace_citation', 'retest_source_trace_validation']));
    expect(actions.every((row) => row['requires_external_model'] == false),
        isTrue);

    final diff = jsonDecode(
            File(summary['repair_diff_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(diff['schema_version'], 'prd_v3_citation_auto_repair_diff.v1');
    expect(diff['status'], 'pass');
    final changes = (diff['changes'] as List).cast<Map<String, dynamic>>();
    expect(changes, hasLength(1));
    expect(changes.first['field'], 'citation');
    expect(changes.first['before'], '');
    expect(changes.first['after'], 'citation_policy.md#chunk=2');
    expect(diff['real_user_data_deleted'], isFalse);

    final afterRows =
        readJsonlFile(summary['patched_source_trace_path'] as String);
    expect(afterRows, hasLength(2));
    expect(
        afterRows.every((row) =>
            row['validation_status'] == 'valid' &&
            (row['citation'] as String).isNotEmpty &&
            row['test_marker'] == true),
        isTrue);
    expect(
        afterRows.any((row) =>
            row['repair_status'] == 'patched_and_retested' &&
            row['repair_issue_id'] == 'test_issue_missing_citation_001'),
        isTrue);

    final retest = jsonDecode(
            File(summary['retest_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(retest['schema_version'],
        'prd_v3_citation_auto_repair_retest_report.v1');
    expect(retest['status'], 'pass');
    expect(retest['before_issue_count'], 1);
    expect(retest['after_issue_count'], 0);
    expect(retest['citation_coverage'], 1.0);
    expect(retest['all_repaired_rows_have_citations'], isTrue);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_citation_auto_repair_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-33 Memory Consolidation Industrial');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_citation_auto_repair_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_citation_auto_repair_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'citation_auto_repair_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'citation_auto_repair_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'citation_auto_repair_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'citation_auto_repair_source_trace' &&
            row['file_path'] == summary['patched_source_trace_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'citation_auto_repair_retest_report' &&
            row['file_path'] == summary['retest_report_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 memory consolidation industrial creates core evidence package',
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
    final summaryPath =
        await controller.runMemoryConsolidationIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_memory_consolidation_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'memory_consolidation_industrial');
    expect(summary['capability_gate'], 'P2-33 Memory Consolidation Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-34 Permission-Scoped Company Brain');
    expect(summary['entry_count'], 3);
    expect(summary['relation_count'], 2);
    expect(summary['memory_card_count'], 1);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_memory_service_connected' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(3));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_memory_consolidation_source_trace.v1' &&
            (row['citation'] as String).isNotEmpty &&
            row['test_marker'] == true),
        isTrue);

    final memoryEntries =
        readJsonlFile(summary['memory_entries_path'] as String);
    expect(memoryEntries, hasLength(3));
    expect(memoryEntries.map((row) => row['status']),
        containsAll(['active', 'superseded']));
    expect(
        memoryEntries.every((row) =>
            row['schema_version'] == 'prd_v3_memory_consolidation_entry.v1' &&
            row['test_marker'] == true &&
            (row['source_trace_ids'] as List).isNotEmpty),
        isTrue);

    final relations = jsonDecode(
            File(summary['memory_relations_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(relations['schema_version'],
        'prd_v3_memory_consolidation_relations.v1');
    expect(relations['status'], 'pass');
    final relationRows =
        (relations['relations'] as List).cast<Map<String, dynamic>>();
    expect(relationRows, hasLength(2));
    expect(relationRows.map((row) => row['relation_type']),
        containsAll(['supports', 'superseded_by']));

    final plan = jsonDecode(File(summary['consolidation_plan_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(plan['schema_version'], 'prd_v3_memory_consolidation_plan.v1');
    expect(plan['status'], 'pass');
    final mergeGroups =
        (plan['merge_groups'] as List).cast<Map<String, dynamic>>();
    expect(mergeGroups, hasLength(1));
    expect(mergeGroups.first['requires_external_model'], isFalse);
    expect(mergeGroups.first['requires_training'], isFalse);
    expect(plan['tombstone_memory_ids'],
        contains('test_memory_outdated_preference'));

    final cards = jsonDecode(
            File(summary['memory_cards_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(cards['schema_version'], 'prd_v3_memory_consolidation_cards.v1');
    expect(cards['status'], 'pass');
    final memoryCards =
        (cards['memory_cards'] as List).cast<Map<String, dynamic>>();
    expect(memoryCards, hasLength(1));
    expect(memoryCards.first['retrievable'], isTrue);
    expect(memoryCards.first['updatable'], isTrue);
    expect(memoryCards.first['forgettable'], isTrue);
    expect((memoryCards.first['source_trace_ids'] as List), hasLength(2));

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecycle['schema_version'],
        'prd_v3_memory_consolidation_lifecycle.v1');
    expect(lifecycle['status'], 'pass');
    expect(lifecycle['tombstoned_memory_ids'],
        contains('test_memory_outdated_preference'));
    expect(lifecycle['forget_requires_test_marker'], isTrue);
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final observability = jsonDecode(
        File(summary['observability_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(observability['schema_version'],
        'prd_v3_memory_consolidation_observability.v1');
    expect(observability['status'], 'pass');
    expect(observability['entry_count'], 3);
    expect(observability['relation_count'], 2);
    expect(observability['memory_card_count'], 1);
    expect(observability['tombstone_count'], 1);
    expect(observability['external_memory_service_used'], isFalse);
    expect(observability['training_used'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_memory_consolidation_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-34 Permission-Scoped Company Brain');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_memory_consolidation_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);
    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_memory_consolidation_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_memory_service_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['local_model_training_used'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'memory_consolidation_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'memory_consolidation_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'memory_consolidation_industrial_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'memory_consolidation_industrial_cards' &&
            row['file_path'] == summary['memory_cards_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'memory_consolidation_industrial_lifecycle' &&
            row['file_path'] == summary['lifecycle_report_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 permission scoped company brain creates core evidence package',
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
    final summaryPath =
        await controller.runPermissionScopedCompanyBrainAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_permission_scoped_company_brain_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'permission_scoped_company_brain');
    expect(summary['capability_gate'], 'P2-34 Permission-Scoped Company Brain');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'],
        'P2-35 Retrieval Regression Benchmark Industrial');
    expect(summary['source_trace_count'], 2);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy =
        jsonDecode(File(summary['policy_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(policy['schema_version'],
        'prd_v3_permission_scoped_company_brain_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['user_visible_capability_name'], '企业知识权限');
    final rules = (policy['rules'] as List).cast<Map<String, dynamic>>();
    expect(rules.map((row) => row['decision']),
        containsAll(['allow', 'allow_reference', 'block']));

    final manifest =
        jsonDecode(File(summary['manifest_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['schema_version'],
        'prd_v3_permission_scoped_company_brain_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['test_knowledge_base_count'], 2);
    expect(manifest['blocked_non_test_knowledge_base_count'], 1);

    final permissionMatrix = jsonDecode(
        File(summary['permission_matrix_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(permissionMatrix['schema_version'],
        'prd_v3_permission_scoped_company_brain_permission_matrix.v1');
    expect(permissionMatrix['status'], 'pass');
    final roles =
        (permissionMatrix['roles'] as List).cast<Map<String, dynamic>>();
    expect((roles.first['allowed_knowledge_base_ids'] as List),
        containsAll(['test_kb_company_policy', 'test_kb_product_reference']));
    expect((roles.first['blocked_knowledge_base_ids'] as List),
        contains('real_user_finance_kb_not_test'));
    expect((roles.first['blocked_actions'] as List),
        contains('delete_real_user_finance_kb_not_test'));

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(2));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_permission_scoped_company_brain_source_trace.v1' &&
            (row['citation'] as String).isNotEmpty &&
            row['test_marker'] == true),
        isTrue);

    final retrievalPlan = jsonDecode(
        File(summary['scoped_retrieval_plan_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(retrievalPlan['schema_version'],
        'prd_v3_permission_scoped_company_brain_retrieval_plan.v1');
    expect(retrievalPlan['status'], 'pass');
    expect(retrievalPlan['route'], 'Anchor -> Entity -> Evidence -> Answer');
    expect((retrievalPlan['blocked_knowledge_base_ids'] as List),
        contains('real_user_finance_kb_not_test'));

    final allowedAnswer = jsonDecode(
        File(summary['allowed_answer_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(allowedAnswer['schema_version'],
        'prd_v3_permission_scoped_company_brain_allowed_answer.v1');
    expect(allowedAnswer['status'], 'pass');
    expect((allowedAnswer['used_knowledge_base_ids'] as List),
        containsAll(['test_kb_company_policy', 'test_kb_product_reference']));
    expect((allowedAnswer['evidence_refs'] as List), hasLength(2));

    final deniedAccess = jsonDecode(
        File(summary['denied_access_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(deniedAccess['schema_version'],
        'prd_v3_permission_scoped_company_brain_denied_access.v1');
    expect(deniedAccess['status'], 'pass');
    expect(
        (deniedAccess['denied_request']
            as Map<String, dynamic>)['knowledge_base_id'],
        'real_user_finance_kb_not_test');
    expect(deniedAccess['user_visible_status'], '需要处理');
    expect(deniedAccess['real_user_data_deleted'], isFalse);

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecycle['schema_version'],
        'prd_v3_permission_scoped_company_brain_lifecycle.v1');
    expect(lifecycle['status'], 'pass');
    expect((lifecycle['exportable_paths'] as List), hasLength(greaterThan(3)));
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_permission_scoped_company_brain_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'],
        'P2-35 Retrieval Regression Benchmark Industrial');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_permission_scoped_company_brain_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_permission_scoped_company_brain_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'permission_scoped_company_brain_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'permission_scoped_company_brain_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'permission_scoped_company_brain_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'permission_scoped_company_brain_source_trace' &&
            row['file_path'] == summary['source_trace_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'permission_scoped_company_brain_denied_access' &&
            row['file_path'] == summary['denied_access_report_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 retrieval regression benchmark creates core evidence package',
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
    final summaryPath =
        await controller.runRetrievalRegressionBenchmarkIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_retrieval_regression_benchmark_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(
        summary['capability_id'], 'retrieval_regression_benchmark_industrial');
    expect(summary['capability_gate'],
        'P2-35 Retrieval Regression Benchmark Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-36 Self-Improving Knowledge Maintenance');
    expect(summary['benchmark_case_count'], 3);
    expect(summary['external_trace_count'], 2);
    expect(summary['baseline_pass_rate'], 0.33);
    expect(summary['improved_pass_rate'], 1.0);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_network_call_made' ||
          entry.key == 'local_kb_evidence_replaced' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final dataset =
        jsonDecode(File(summary['dataset_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(dataset['schema_version'],
        'prd_v3_retrieval_regression_benchmark_dataset.v1');
    expect(dataset['status'], 'pass');
    expect((dataset['cases'] as List), hasLength(3));

    final baseline =
        jsonDecode(File(summary['baseline_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(baseline['schema_version'],
        'prd_v3_retrieval_regression_baseline_report.v1');
    expect(baseline['status'], 'partial');
    expect(baseline['local_kb_evidence_retained'], isTrue);
    expect(baseline['baseline_pass_rate'], 0.33);

    final externalTraceRows = readJsonlFile(
        summary['external_verification_source_trace_path'] as String);
    expect(externalTraceRows, hasLength(2));
    expect(
        externalTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_retrieval_external_verification_source_trace.v1' &&
            (row['citation'] as String).isNotEmpty &&
            row['validation_status'] == 'linked' &&
            row['network_call_made'] == false &&
            row['test_marker'] == true),
        isTrue);

    final freshness = jsonDecode(
            File(summary['freshness_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(freshness['schema_version'],
        'prd_v3_retrieval_freshness_regression_report.v1');
    expect(freshness['status'], 'pass');
    expect(freshness['freshness_improved_count'], 2);

    final conflict = jsonDecode(
            File(summary['conflict_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(conflict['schema_version'],
        'prd_v3_retrieval_conflict_regression_report.v1');
    expect(conflict['status'], 'pass');
    expect(conflict['conflict_count'], 1);
    expect(conflict['missed_conflict_count_after'], 0);

    final citationValidation = jsonDecode(
        File(summary['citation_validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(citationValidation['schema_version'],
        'prd_v3_retrieval_citation_validation_regression_report.v1');
    expect(citationValidation['status'], 'pass');
    expect(citationValidation['local_citation_coverage'], 1.0);
    expect(citationValidation['external_trace_coverage'], 1.0);
    expect(citationValidation['local_kb_evidence_replaced'], isFalse);

    final improved = jsonDecode(
        File(summary['improved_retrieval_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(improved['schema_version'],
        'prd_v3_retrieval_regression_improved_report.v1');
    expect(improved['status'], 'pass');
    expect(improved['improved_pass_rate'], 1.0);
    expect(improved['local_kb_evidence_retained'], isTrue);
    expect(improved['external_verification_is_additive'], isTrue);

    final matrix = jsonDecode(File(summary['regression_matrix_path'] as String)
        .readAsStringSync()) as Map<String, dynamic>;
    expect(matrix['schema_version'],
        'prd_v3_retrieval_regression_benchmark_matrix.v1');
    expect(matrix['status'], 'pass');
    expect(matrix['freshness_regression_passed'], isTrue);
    expect(matrix['conflict_regression_passed'], isTrue);
    expect(matrix['citation_validation_passed'], isTrue);
    expect(matrix['source_trace_regression_passed'], isTrue);
    expect(matrix['local_kb_evidence_replaced'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_retrieval_regression_benchmark_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'],
        'P2-36 Self-Improving Knowledge Maintenance');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_retrieval_regression_benchmark_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_retrieval_regression_benchmark_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_verification_used'], isTrue);
    expect(boundary['external_network_call_made'], isFalse);
    expect(boundary['local_kb_evidence_replaced'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'retrieval_regression_benchmark_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'retrieval_regression_benchmark_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'retrieval_regression_benchmark_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'retrieval_regression_benchmark_external_trace' &&
            row['file_path'] ==
                summary['external_verification_source_trace_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'retrieval_regression_benchmark_matrix' &&
            row['file_path'] == summary['regression_matrix_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 self improving knowledge maintenance creates core evidence package',
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
    final summaryPath =
        await controller.runSelfImprovingKnowledgeMaintenanceAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_self_improving_knowledge_maintenance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'self_improving_knowledge_maintenance');
    expect(summary['capability_gate'],
        'P2-36 Self-Improving Knowledge Maintenance');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-37 Agent Memory Industrial');
    expect(summary['signal_count'], 3);
    expect(summary['candidate_count'], 3);
    expect(summary['patch_preview_count'], 2);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'auto_apply_knowledge_patch' ||
          entry.key == 'real_knowledge_base_modified' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'background_daemon_started' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final policy =
        jsonDecode(File(summary['policy_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(policy['schema_version'],
        'prd_v3_self_improving_knowledge_maintenance_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['auto_apply_knowledge_patch'], isFalse);
    expect(policy['requires_owner_review_for_real_data'], isTrue);

    final signals = readJsonlFile(summary['signal_ledger_path'] as String);
    expect(signals, hasLength(3));
    expect(
        signals.every((row) =>
            row['schema_version'] ==
                'prd_v3_self_improving_maintenance_signal.v1' &&
            (row['source_trace_id'] as String).isNotEmpty &&
            row['test_marker'] == true),
        isTrue);
    expect(
        signals.map((row) => row['source_capability']),
        containsAll([
          'retrieval_regression_benchmark_industrial',
          'citation_auto_repair',
          'memory_consolidation_industrial',
        ]));

    final candidatePlan = jsonDecode(
            File(summary['candidate_plan_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(candidatePlan['schema_version'],
        'prd_v3_self_improving_knowledge_candidate_plan.v1');
    expect(candidatePlan['status'], 'pass');
    final candidates =
        (candidatePlan['candidates'] as List).cast<Map<String, dynamic>>();
    expect(candidates, hasLength(3));
    expect(
        candidates.every((row) => row['auto_apply_allowed'] == false), isTrue);
    expect(candidates.every((row) => row['requires_human_review'] == true),
        isTrue);

    final patchPreview = jsonDecode(
            File(summary['patch_preview_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(patchPreview['schema_version'],
        'prd_v3_self_improving_knowledge_patch_preview.v1');
    expect(patchPreview['status'], 'pass');
    expect(patchPreview['patch_mode'], 'preview_only');
    expect(patchPreview['real_knowledge_base_modified'], isFalse);
    final patches =
        (patchPreview['patches'] as List).cast<Map<String, dynamic>>();
    expect(patches, hasLength(2));
    expect(patches.every((row) => row['applied'] == false), isTrue);

    final validationQueue =
        readJsonlFile(summary['validation_queue_path'] as String);
    expect(validationQueue, hasLength(2));
    expect(
        validationQueue.every((row) =>
            (row['required_checks'] as List).contains('human_review_required')),
        isTrue);

    final humanReview = jsonDecode(
        File(summary['human_review_required_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(humanReview['schema_version'],
        'prd_v3_self_improving_human_review_required.v1');
    expect(humanReview['status'], 'pass');
    expect(humanReview['review_required'], isTrue);
    expect(humanReview['auto_apply_blocked'], isTrue);

    final learning = jsonDecode(
            File(summary['learning_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(learning['schema_version'],
        'prd_v3_self_improving_knowledge_learning_report.v1');
    expect(learning['status'], 'pass');
    expect(learning['learning_note_only'], isFalse);
    expect(learning['auto_apply_knowledge_patch'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_self_improving_knowledge_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-37 Agent Memory Industrial');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_self_improving_knowledge_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_self_improving_knowledge_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['auto_apply_knowledge_patch'], isFalse);
    expect(boundary['real_knowledge_base_modified'], isFalse);
    expect(boundary['background_daemon_started'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] ==
                'self_improving_knowledge_maintenance_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'self_improving_knowledge_maintenance_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'self_improving_knowledge_maintenance_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'self_improving_knowledge_maintenance_signals' &&
            row['file_path'] == summary['signal_ledger_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'self_improving_knowledge_maintenance_patch_preview' &&
            row['file_path'] == summary['patch_preview_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 agent memory industrial creates core evidence package', () async {
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
    final summaryPath = await controller.runAgentMemoryIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_agent_memory_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'agent_memory_industrial');
    expect(summary['capability_gate'], 'P2-37 Agent Memory Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-38 Mermaid Symbolic Memory Industrial');
    expect(summary['card_count'], 3);
    expect(summary['active_card_count'], 2);
    expect(summary['tombstone_count'], 1);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_memory_service_connected' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final sourceTraceRows =
        readJsonlFile(summary['source_trace_path'] as String);
    expect(sourceTraceRows, hasLength(3));
    expect(
        sourceTraceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_agent_memory_industrial_source_trace.v1' &&
            (row['citation'] as String).isNotEmpty &&
            row['test_marker'] == true),
        isTrue);

    final cards = jsonDecode(
            File(summary['memory_cards_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(cards['schema_version'], 'prd_v3_agent_memory_industrial_cards.v1');
    expect(cards['status'], 'pass');
    final memoryCards =
        (cards['memory_cards'] as List).cast<Map<String, dynamic>>();
    expect(memoryCards, hasLength(3));
    expect(memoryCards.map((row) => row['status']),
        containsAll(['active', 'tombstoned']));
    expect(
        memoryCards.every((row) =>
            row['test_marker'] == true &&
            row['forgettable'] == true &&
            (row['source_trace_ids'] as List).isNotEmpty),
        isTrue);

    final index = jsonDecode(
            File(summary['memory_index_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(index['schema_version'], 'prd_v3_agent_memory_industrial_index.v1');
    expect(index['status'], 'pass');
    expect(
        (index['active_card_ids'] as List),
        containsAll([
          'test_agent_memory_goal_context',
          'test_agent_memory_update_policy'
        ]));
    expect((index['tombstoned_card_ids'] as List),
        contains('test_agent_memory_obsolete_context'));

    final retrieval = jsonDecode(
            File(summary['retrieval_probe_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(retrieval['schema_version'],
        'prd_v3_agent_memory_industrial_retrieval_probe.v1');
    expect(retrieval['status'], 'pass');
    expect(retrieval['route'], 'Anchor -> Entity -> Evidence -> Answer');
    expect((retrieval['matched_card_ids'] as List),
        contains('test_agent_memory_goal_context'));

    final updatePatch = jsonDecode(
            File(summary['update_patch_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(updatePatch['schema_version'],
        'prd_v3_agent_memory_industrial_update_patch.v1');
    expect(updatePatch['status'], 'pass');
    expect(updatePatch['validation_report_required'], isTrue);
    expect(updatePatch['auto_applied_to_real_memory'], isFalse);

    final tombstone = jsonDecode(
            File(summary['forget_tombstone_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(tombstone['schema_version'],
        'prd_v3_agent_memory_industrial_forget_tombstone.v1');
    expect(tombstone['status'], 'pass');
    expect(tombstone['delete_scope'], 'test_marked_memory_only');
    expect(tombstone['real_user_data_deleted'], isFalse);

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecycle['schema_version'],
        'prd_v3_agent_memory_industrial_lifecycle.v1');
    expect(lifecycle['status'], 'pass');
    expect((lifecycle['created_card_ids'] as List), isNotEmpty);
    expect((lifecycle['retrieved_card_ids'] as List), isNotEmpty);
    expect((lifecycle['updated_card_ids'] as List), isNotEmpty);
    expect((lifecycle['tombstoned_card_ids'] as List),
        contains('test_agent_memory_obsolete_context'));
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final observability = jsonDecode(
        File(summary['observability_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(observability['schema_version'],
        'prd_v3_agent_memory_industrial_observability.v1');
    expect(observability['status'], 'pass');
    expect(observability['card_count'], 3);
    expect(observability['active_card_count'], 2);
    expect(observability['tombstone_count'], 1);
    expect(observability['external_memory_service_connected'], isFalse);
    expect(observability['training_used'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_agent_memory_industrial_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(
        stateSnapshot['next_gate'], 'P2-38 Mermaid Symbolic Memory Industrial');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_agent_memory_industrial_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_agent_memory_industrial_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_memory_service_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'agent_memory_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'agent_memory_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'agent_memory_industrial_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'agent_memory_industrial_cards' &&
            row['file_path'] == summary['memory_cards_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'agent_memory_industrial_retrieval_probe' &&
            row['file_path'] == summary['retrieval_probe_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'agent_memory_industrial_lifecycle' &&
            row['file_path'] == summary['lifecycle_report_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('assistant backend separation persists profile and provider refs',
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
    final summaryPath =
        await controller.runAssistantBackendSeparationAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_assistant_backend_separation_acceptance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'assistant_backend_separation');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['backend_executor_executed'], isFalse);
    expect(summary['multi_model_orchestration_executed'], isFalse);
    expect(summary['external_calls_made'], isFalse);
    expect(summary['secret_plaintext_written'], isFalse);
    expect(summary['redis_vector_service_packaged_into_exe'], isFalse);
    expect(summary['failed_checks'], isEmpty);
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'secret_plaintext_written' ||
          entry.key == 'redis_vector_service_packaged_into_exe') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final agentSettings =
        (summary['agent_backend_binding'] as Map).cast<String, dynamic>();
    expect(agentSettings['backend_binding_status'],
        'separated_provider_profile_binding');
    expect(agentSettings['active_profile_id'], summary['active_profile_id']);
    expect(agentSettings['model_config_id'], summary['active_model_config_id']);
    expect(agentSettings['model_gateway_config_id'],
        summary['active_model_gateway_config_id']);
    expect(agentSettings['secret_plaintext_written'], 'false');

    final agentCatalogPath = summary['agent_catalog_path'] as String;
    final providerPath = summary['provider_runtime_settings_path'] as String;
    final profilesPath = summary['project_config_profiles_path'] as String;
    expect(agentCatalogPath, isNot(providerPath));
    expect(File(agentCatalogPath).existsSync(), isTrue);
    expect(File(providerPath).existsSync(), isTrue);
    expect(File(profilesPath).existsSync(), isTrue);
    expect(File(agentCatalogPath).readAsStringSync(),
        contains('test_assistant_backend_separation'));
    expect(File(providerPath).readAsStringSync(),
        isNot(contains('runtime-input-token')));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.agentProfiles.any((profile) =>
            profile.id == summary['agent_id'] &&
            profile.settings['backend_binding_status'] ==
                'separated_provider_profile_binding'),
        isTrue);
    expect(reloaded.state.hasProviderRuntimeSettings, isTrue);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'assistant_backend_separation_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'assistant_backend_separation_summary' &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('ui taste gate writes audit evidence and reloads catalog', () async {
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
    final summaryPath = await controller.runUiTasteGateAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_ui_taste_gate_acceptance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'ui_taste_gate');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['ui_blackbox_path'],
        contains('Operation Records -> Record Export'));
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'redis_vector_service_packaged_into_exe') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final buttonBindings =
        (summary['button_bindings'] as List).cast<Map<String, dynamic>>();
    expect(
        buttonBindings.any((row) =>
            row['automation_key'] == 'ui-taste-gate-evidence-button' &&
            row['action'] == 'runUiTasteGateAcceptance'),
        isTrue);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) => row['event_type'] == 'ui_taste_gate_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'ui_taste_gate_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords
            .any((record) => record.eventType == 'ui_taste_gate_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'ui_taste_gate_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('full route responsive review writes audit evidence and reloads catalog',
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
    final summaryPath =
        await controller.runFullRouteResponsiveReviewAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_full_route_responsive_review_acceptance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'full_route_responsive_review');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['ui_blackbox_path'],
        contains('Operation Records -> Record Export'));
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'redis_vector_service_packaged_into_exe') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final routeMatrix =
        (summary['route_matrix'] as List).cast<Map<String, dynamic>>();
    expect(routeMatrix.any((row) => row['page_id'] == 'reports-audit'), isTrue);
    expect(routeMatrix.any((row) => row['page_id'] == 'workspace'), isTrue);
    expect(routeMatrix.length, greaterThanOrEqualTo(9));

    final buttonBindings =
        (summary['button_bindings'] as List).cast<Map<String, dynamic>>();
    expect(
        buttonBindings.any((row) =>
            row['automation_key'] ==
                'full-route-responsive-review-evidence-button' &&
            row['action'] == 'runFullRouteResponsiveReviewAcceptance'),
        isTrue);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'full_route_responsive_review_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'full_route_responsive_review_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'full_route_responsive_review_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'full_route_responsive_review_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('connection configuration writes audit evidence and reloads catalog',
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
    await controller.saveProviderRuntimeSettings(
      llmProvider: 'env_configured',
      modelId: 'connection-test-model',
      embeddingProvider: 'local_keyword_embedding',
      searchProvider: 'local_index',
      parserProvider: 'local_parser',
      ocrProvider: 'optional_ocr',
      apiKey: 'connection-test-input',
    );
    await controller.saveStorageProviderSettings(
      redisHost: '127.0.0.1',
      redisPort: 6379,
      redisKeyPrefix: 'heitang:test:',
      redisPassword: 'redis-test-input',
      qdrantEndpoint: 'http://127.0.0.1:6333',
      qdrantCollection: 'heitang_test_collection',
      qdrantDimension: 1536,
      qdrantApiKey: 'qdrant-test-input',
    );

    final summaryPath = await controller.runConnectionConfigurationAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('connection-test-input')));
    expect(summaryText, isNot(contains('redis-test-input')));
    expect(summaryText, isNot(contains('qdrant-test-input')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_connection_configuration_acceptance_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'connection_configuration');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['ui_blackbox_path'], contains('Settings -> Model Service'));
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'redis_vector_service_packaged_into_exe') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final buttonBindings =
        (summary['button_bindings'] as List).cast<Map<String, dynamic>>();
    expect(
        buttonBindings.any((row) =>
            row['automation_key'] ==
                'connection-configuration-evidence-button' &&
            row['action'] == 'runConnectionConfigurationAcceptance'),
        isTrue);
    final connectionRows =
        (summary['connection_rows'] as List).cast<Map<String, dynamic>>();
    expect(
        connectionRows.any((row) =>
            row['connection_id'] == 'redis_short_term_memory' &&
            row['secret_masked'] == true),
        isTrue);
    expect(
        connectionRows.any((row) =>
            row['connection_id'] == 'qdrant_knowledge_memory' &&
            row['dimension'] == 1536),
        isTrue);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'connection_configuration_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'connection_configuration_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'connection_configuration_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'connection_configuration_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('knowledge canvas basic writes user blackbox evidence and reloads',
      () async {
    final workspace = await createWorkspace();
    writeKnowledgeCanvasFixture(workspace);
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
    final summaryPath = await controller.runKnowledgeCanvasBasicAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_knowledge_canvas_basic_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'knowledge_canvas_basic');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['ui_blackbox_path'], contains('Knowledge Base'));
    expect(summary['anchor_entity_evidence_answer_path'],
        ['Anchor', 'Entity', 'Evidence', 'Answer']);
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }
    final blackBox =
        (summary['black_box_evidence'] as Map).cast<String, dynamic>();
    expect(
        blackBox['automation_key'], 'knowledge-canvas-basic-evidence-button');
    expect((summary['canvas_nodes'] as List), hasLength(4));
    expect((summary['canvas_edges'] as List), hasLength(3));

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'knowledge_canvas_basic_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'knowledge_canvas_basic_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any(
            (record) => record.eventType == 'knowledge_canvas_basic_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'knowledge_canvas_basic_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  testWidgets('knowledge canvas basic button creates visible canvas evidence',
      (tester) async {
    await pumpWorkbench(
      tester,
      setupWorkspace: (workspace) async {
        writeKnowledgeCanvasFixture(workspace);
      },
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          if (request.actionId == 'knowledge_base_build') {
            final output = Directory(request.outputPath!)
              ..createSync(recursive: true);
            File('${output.path}${Platform.pathSeparator}manifest.json')
                .writeAsStringSync('{"status":"searchable"}');
            File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                .writeAsStringSync(jsonl([
              {
                'chunk_id': 'chunk_alpha_001',
                'source_path': 'alpha.md',
                'text': 'alpha source for knowledge canvas',
              },
            ]));
            File('${output.path}${Platform.pathSeparator}cards.jsonl')
                .writeAsStringSync('{"title":"canvas"}\n');
            File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                .writeAsStringSync('{"question":"q","answer":"a"}\n');
            File('${output.path}${Platform.pathSeparator}quality_report.json')
                .writeAsStringSync('{"status":"pass"}');
          }
          return const CoreBridgeProcessResult(
              exitCode: 0, stdout: 'ok', stderr: '');
        },
      ),
      initialSelectedIndex: 3,
      surfaceSize: const Size(1440, 1000),
      waitForRuntimeReady: true,
    );

    expect(find.text('关系画布'), findsOneWidget);
    expect(find.byKey(const Key('knowledge-canvas-basic-evidence-button')),
        findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const Key('knowledge-canvas-basic-evidence-button')));
    final canvasButton = tester.widget<FilledButton>(
      find.byKey(const Key('knowledge-canvas-basic-evidence-button')),
    );
    expect(canvasButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  test('knowledge base table view writes user blackbox evidence and reloads',
      () async {
    final workspace = await createWorkspace();
    writeKnowledgeCanvasFixture(workspace);
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
    final summaryPath = await controller.runKnowledgeBaseTableViewAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_knowledge_base_table_view_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'knowledge_base_table_view');
    expect(summary['acceptance_type'], 'user_blackbox');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'passed');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['runtime_row_count'], 1);
    final rows = (summary['table_rows'] as List).cast<Map<String, dynamic>>();
    expect(rows.single['kb_id'], 'K_CANVAS_TEST');
    expect(rows.single['name'], 'Canvas Test KB');
    expect(rows.single['source_count'], 1);
    expect(rows.single['chunk_count'], 1);
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'knowledge_base_table_view_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'knowledge_base_table_view_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'knowledge_base_table_view_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'knowledge_base_table_view_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('clean markdown import writes core evidence and reloads', () async {
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
    final summaryPath = await controller.runCleanMarkdownImportAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_clean_markdown_import_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'clean_markdown_import');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['block_count'], greaterThanOrEqualTo(4));

    final cleanedPath = summary['cleaned_markdown_path'].toString();
    final cleaned = File(cleanedPath).readAsStringSync();
    expect(cleaned, startsWith('# Test Knowledge Import'));
    expect(cleaned, contains('```'));
    expect(cleaned, isNot(contains(String.fromCharCode(7))));
    expect(cleaned, isNot(contains('   \n')));

    final blocks = readJsonlFile(summary['blocks_path'].toString());
    expect(blocks.map((row) => row['block_type']), contains('heading'));
    expect(blocks.map((row) => row['block_type']), contains('list_item'));
    expect(blocks.map((row) => row['block_type']), contains('code'));

    final traces = readJsonlFile(summary['source_trace_path'].toString());
    expect(traces.single['source_trace_status'], 'linked');
    expect((traces.single['block_ids'] as List), isNotEmpty);

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['unsupported_extension_rejected'], isTrue);
    expect(validationChecks['empty_markdown_rejected'], isTrue);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'clean_markdown_import_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'clean_markdown_import_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any(
            (record) => record.eventType == 'clean_markdown_import_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'clean_markdown_import_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('engineering learning samples writes core evidence and reloads',
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
    final summaryPath =
        await controller.runEngineeringLearningSamplesAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_engineering_learning_samples_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'engineering_learning_samples');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['sample_count'], greaterThanOrEqualTo(3));

    final manifest =
        jsonDecode(File(summary['manifest_path'].toString()).readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['status'], 'pass');
    expect(manifest['external_project_runtime_loaded'], isFalse);
    expect(manifest['external_dependency_added'], isFalse);
    expect(manifest['user_visible_project_names'], isFalse);

    final sampleCards = readJsonlFile(summary['sample_cards_path'].toString());
    expect(sampleCards.map((row) => row['sample_id']),
        contains('sample_clean_markdown_to_knowledge_package'));
    expect(sampleCards.map((row) => row['user_visible_capability']),
        contains('文档解析能力'));
    expect(sampleCards.map((row) => row['user_visible_capability']),
        isNot(contains('Provider')));

    final traces = readJsonlFile(summary['source_trace_path'].toString());
    expect(traces, hasLength(sampleCards.length));
    expect(
        traces.every((row) => row['source_trace_status'] == 'linked'), isTrue);

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['all_samples_accepted'], isTrue);
    expect(validationChecks['missing_sample_id_rejected'], isTrue);
    expect(validationChecks['missing_expected_output_rejected'], isTrue);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'external_project_runtime_loaded',
        'external_dependency_added',
        'user_visible_project_names',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'engineering_learning_samples_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'engineering_learning_samples_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'engineering_learning_samples_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'engineering_learning_samples_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('agent memory layer basic writes core evidence and reloads', () async {
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
    final summaryPath = await controller.runAgentMemoryLayerBasicAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_agent_memory_layer_basic_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'agent_memory_layer_basic');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['memory_count'], greaterThanOrEqualTo(4));

    final entries = readJsonlFile(summary['memory_entries_path'].toString());
    expect(entries.map((row) => row['memory_id']), contains('mem_task_goal'));
    expect(entries.map((row) => row['status']), contains('active'));
    expect(entries.map((row) => row['status']), contains('expired'));
    expect(
        entries.every((row) =>
            ((row['source_trace_ids'] as List?) ?? const []).isNotEmpty),
        isTrue);

    final relations =
        readJsonlFile(summary['memory_relations_path'].toString());
    expect(relations.map((row) => row['relation_type']), contains('replaces'));
    expect(relations.map((row) => row['relation_type']), contains('guards'));

    final index = jsonDecode(
            File(summary['memory_index_path'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(index['status'], 'pass');
    expect(index['active_count'], greaterThanOrEqualTo(3));
    expect(index['expired_count'], 1);

    final offload = jsonDecode(
        File(summary['context_offload_pointer_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(offload['status'], 'pass');
    expect(
        (offload['restorable_memory_ids'] as List), contains('mem_task_goal'));

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['all_entries_accepted'], isTrue);
    expect(validationChecks['missing_memory_id_rejected'], isTrue);
    expect(validationChecks['missing_source_trace_rejected'], isTrue);
    expect(validationChecks['relation_targets_resolve'], isTrue);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'tencentdb_agent_memory_integrated',
        'node_22_dependency_added',
        'local_model_training_used',
        'external_memory_runtime_loaded',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'agent_memory_layer_basic_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'agent_memory_layer_basic_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'agent_memory_layer_basic_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'agent_memory_layer_basic_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('context offload basic writes core evidence and reloads', () async {
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
    final summaryPath = await controller.runContextOffloadBasicAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_context_offload_basic_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'context_offload_basic');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['fragment_count'], greaterThanOrEqualTo(3));

    final package =
        jsonDecode(File(summary['package_path'].toString()).readAsStringSync())
            as Map<String, dynamic>;
    expect(package['status'], 'pass');
    expect(package['compressed_context']['compression_strategy'],
        'extractive_summary_with_source_trace');

    final pointer =
        jsonDecode(File(summary['pointer_path'].toString()).readAsStringSync())
            as Map<String, dynamic>;
    expect(pointer['status'], 'pass');
    expect(pointer['package_path'], summary['package_path']);

    final restoreIndex = jsonDecode(
            File(summary['restore_index_path'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(restoreIndex['status'], 'pass');
    final restoreOrder =
        (restoreIndex['restore_order'] as List).cast<Map<String, dynamic>>();
    expect(restoreOrder.first['fragment_id'], 'ctx_current_gate');

    final resumeSummary =
        File(summary['resume_summary_path'].toString()).readAsStringSync();
    expect(resumeSummary, contains('Context Resume Summary'));
    expect(resumeSummary, contains('ctx_current_gate'));

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['all_fragments_accepted'], isTrue);
    expect(validationChecks['missing_fragment_id_rejected'], isTrue);
    expect(validationChecks['missing_restore_priority_rejected'], isTrue);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'external_memory_runtime_loaded',
        'external_llm_used_for_compression',
        'vector_db_used_for_offload',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'context_offload_basic_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'context_offload_basic_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any(
            (record) => record.eventType == 'context_offload_basic_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'context_offload_basic_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('mermaid task map basic writes core evidence and reloads', () async {
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
    final summaryPath = await controller.runMermaidTaskMapBasicAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_mermaid_task_map_basic_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'mermaid_task_map_basic');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['node_count'], greaterThanOrEqualTo(4));
    expect(summary['edge_count'], greaterThanOrEqualTo(3));

    final mermaid = File(summary['mermaid_path'].toString()).readAsStringSync();
    expect(mermaid.trimLeft(), startsWith('flowchart TD'));
    expect(mermaid, contains('task_start'));
    expect(mermaid, contains('-->|records|'));

    final nodes = readJsonlFile(summary['node_index_path'].toString());
    final edges = readJsonlFile(summary['edge_index_path'].toString());
    expect(nodes.map((row) => row['node_id']), contains('task_start'));
    expect(
        edges.map((row) => row['edge_id']), contains('edge_start_to_memory'));

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['valid_map_passed'], isTrue);
    expect(validationChecks['missing_node_rejected'], isTrue);
    expect(validationChecks['duplicate_node_rejected'], isTrue);
    expect(validationChecks['mermaid_starts_with_flowchart'], isTrue);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'external_renderer_used',
        'figma_or_browser_render_required',
        'p2_symbolic_memory_claimed',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'mermaid_task_map_basic_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'mermaid_task_map_basic_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any(
            (record) => record.eventType == 'mermaid_task_map_basic_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'mermaid_task_map_basic_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('p2 mermaid symbolic memory industrial creates core evidence package',
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
    final summaryPath =
        await controller.runMermaidSymbolicMemoryIndustrialAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_mermaid_symbolic_memory_industrial_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'mermaid_symbolic_memory_industrial');
    expect(
        summary['capability_gate'], 'P2-38 Mermaid Symbolic Memory Industrial');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-39 Cross-Agent Memory Migration');
    expect(summary['node_count'], 4);
    expect(summary['edge_count'], 3);

    final mermaid = File(summary['mermaid_path'] as String).readAsStringSync();
    expect(mermaid.trimLeft(), startsWith('flowchart TD'));
    expect(mermaid, contains('sym_agent_goal'));
    expect(mermaid, contains('-->|grounds|'));

    final nodes = readJsonlFile(summary['symbol_nodes_path'] as String);
    final edges = readJsonlFile(summary['symbol_edges_path'] as String);
    expect(nodes, hasLength(4));
    expect(edges, hasLength(3));
    expect(nodes.map((row) => row['node_id']), contains('sym_agent_goal'));
    expect(edges.map((row) => row['relation_type']),
        containsAll(['grounds', 'updates', 'superseded_by']));
    expect(
        nodes.every((row) =>
            row['schema_version'] == 'prd_v3_mermaid_symbolic_memory_node.v1' &&
            row['test_marker'] == true &&
            (row['source_trace_ids'] as List).isNotEmpty),
        isTrue);

    final bindings = jsonDecode(
            File(summary['memory_bindings_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(bindings['schema_version'],
        'prd_v3_mermaid_symbolic_memory_bindings.v1');
    expect(bindings['status'], 'pass');
    final bindingRows =
        (bindings['bindings'] as List).cast<Map<String, dynamic>>();
    expect(bindingRows.map((row) => row['memory_card_id']),
        contains('test_agent_memory_goal_context'));

    final graphIndex = jsonDecode(
            File(summary['graph_index_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(graphIndex['schema_version'],
        'prd_v3_mermaid_symbolic_memory_index.v1');
    expect(graphIndex['status'], 'pass');
    expect(graphIndex['node_count'], 4);
    expect(graphIndex['edge_count'], 3);

    final queryTrace = jsonDecode(
            File(summary['query_trace_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(queryTrace['schema_version'],
        'prd_v3_mermaid_symbolic_memory_query_trace.v1');
    expect(queryTrace['status'], 'pass');
    expect(
        queryTrace['route'], 'Symbol -> Memory Card -> Source Trace -> Answer');
    expect(
        (queryTrace['matched_symbol_ids'] as List), contains('sym_agent_goal'));
    expect((queryTrace['source_trace_ids'] as List),
        contains('trace_test_agent_memory_goal_001'));

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecycle['schema_version'],
        'prd_v3_mermaid_symbolic_memory_lifecycle.v1');
    expect(lifecycle['status'], 'pass');
    expect(lifecycle['bound_memory_card_count'], 3);
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final observability = jsonDecode(
        File(summary['observability_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(observability['schema_version'],
        'prd_v3_mermaid_symbolic_memory_observability.v1');
    expect(observability['status'], 'pass');
    expect(observability['node_count'], 4);
    expect(observability['edge_count'], 3);
    expect(observability['external_renderer_used'], isFalse);
    expect(observability['vector_db_used'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_mermaid_symbolic_memory_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-39 Cross-Agent Memory Migration');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_mermaid_symbolic_memory_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_mermaid_symbolic_memory_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_renderer_used'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_memory_service_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_renderer_used' ||
          entry.key == 'figma_or_browser_render_required' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_memory_service_connected' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] ==
                'mermaid_symbolic_memory_industrial_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'mermaid_symbolic_memory_industrial_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'mermaid_symbolic_memory_industrial_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'mermaid_symbolic_memory_industrial_graph' &&
            row['file_path'] == summary['mermaid_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'mermaid_symbolic_memory_industrial_query_trace' &&
            row['file_path'] == summary['query_trace_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 cross agent memory migration creates core evidence package',
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
    final summaryPath =
        await controller.runCrossAgentMemoryMigrationAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_cross_agent_memory_migration_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'cross_agent_memory_migration');
    expect(summary['capability_gate'], 'P2-39 Cross-Agent Memory Migration');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-40 Night Memory Consolidation Loop');
    expect(summary['source_memory_count'], 3);
    expect(summary['mapping_count'], 3);
    expect(summary['preview_card_count'], 3);
    expect(summary['conflict_count'], 1);

    final manifest =
        jsonDecode(File(summary['manifest_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['schema_version'],
        'prd_v3_cross_agent_memory_migration_manifest.v1');
    expect(manifest['status'], 'pass');
    expect(manifest['preview_only'], isTrue);
    expect(manifest['real_user_data_migrated'], isFalse);

    final sourceRows = readJsonlFile(summary['source_export_path'] as String);
    expect(sourceRows, hasLength(3));
    expect(sourceRows.map((row) => row['source_memory_id']),
        containsAll(['src_test_goal_context', 'src_test_update_policy']));
    expect(
        sourceRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_cross_agent_memory_source_export.v1' &&
            row['test_marker'] == true &&
            (row['source_trace_ids'] as List).isNotEmpty &&
            row['permission_scope'] == 'test_marked_memory_only'),
        isTrue);

    final mappingTable = jsonDecode(
            File(summary['mapping_table_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(mappingTable['schema_version'],
        'prd_v3_cross_agent_memory_mapping_table.v1');
    expect(mappingTable['status'], 'pass');
    final mappings =
        (mappingTable['mappings'] as List).cast<Map<String, dynamic>>();
    expect(mappings, hasLength(3));
    expect(mappings.map((row) => row['mapping_status']),
        containsAll(['ready_for_preview_import', 'conflict_preview_only']));
    expect(
        mappings.every((row) =>
            row['test_marker'] == true &&
            (row['source_trace_ids'] as List).isNotEmpty &&
            (row['target_memory_id'] as String).isNotEmpty),
        isTrue);

    final preview = jsonDecode(
            File(summary['import_preview_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(preview['schema_version'],
        'prd_v3_cross_agent_memory_import_preview.v1');
    expect(preview['status'], 'pass');
    expect(preview['preview_only'], isTrue);
    expect(preview['auto_applied_to_runtime'], isFalse);
    expect(preview['real_user_data_migrated'], isFalse);
    final previewCards =
        (preview['preview_memory_cards'] as List).cast<Map<String, dynamic>>();
    expect(previewCards, hasLength(3));
    expect(previewCards.map((row) => row['status']),
        contains('preview_tombstone'));

    final conflict = jsonDecode(
            File(summary['conflict_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(conflict['schema_version'],
        'prd_v3_cross_agent_memory_conflict_report.v1');
    expect(conflict['status'], 'pass');
    expect(conflict['unresolved_conflict_count'], 0);
    expect(conflict['requires_owner_confirmation_before_apply'], isTrue);
    final conflicts =
        (conflict['conflicts'] as List).cast<Map<String, dynamic>>();
    expect(
        conflicts.single['resolution'], 'preview_as_tombstone_requires_review');
    expect(conflicts.single['real_user_data_deleted'], isFalse);

    final permission = jsonDecode(
        File(summary['permission_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(permission['schema_version'],
        'prd_v3_cross_agent_memory_permission_boundary.v1');
    expect(permission['status'], 'pass');
    expect(permission['allowed_scope'], 'test_marked_memory_only');
    expect(permission['permission_escalation'], isFalse);
    expect(permission['secret_plaintext_written'], isFalse);
    expect(permission['real_user_data_migrated'], isFalse);

    final rollback = jsonDecode(
            File(summary['rollback_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(rollback['schema_version'],
        'prd_v3_cross_agent_memory_rollback_tombstone.v1');
    expect(rollback['status'], 'pass');
    expect(rollback['delete_scope'], 'test_marked_migration_preview_only');
    expect(rollback['preview_import_can_be_discarded'], isTrue);
    expect(rollback['real_user_data_deleted'], isFalse);

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(
        lifecycle['schema_version'], 'prd_v3_cross_agent_memory_lifecycle.v1');
    expect(lifecycle['status'], 'pass');
    expect((lifecycle['created_paths'] as List), isNotEmpty);
    expect((lifecycle['exportable_paths'] as List), isNotEmpty);
    expect(lifecycle['restart_recoverable_from_files'], isTrue);
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final observability = jsonDecode(
        File(summary['observability_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(observability['schema_version'],
        'prd_v3_cross_agent_memory_observability.v1');
    expect(observability['status'], 'pass');
    expect(observability['source_memory_count'], 3);
    expect(observability['mapping_count'], 3);
    expect(observability['preview_card_count'], 3);
    expect(observability['external_multi_agent_runtime_initialized'], isFalse);
    expect(observability['external_memory_service_connected'], isFalse);
    expect(observability['external_model_called'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_cross_agent_memory_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-40 Night Memory Consolidation Loop');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_cross_agent_memory_migration_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_cross_agent_memory_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['external_multi_agent_runtime_initialized'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_memory_service_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_memory_migration_applied'], isFalse);
    expect(boundary['real_user_data_migrated'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'external_multi_agent_runtime_initialized' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_memory_service_connected' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_memory_migration_applied' ||
          entry.key == 'real_user_data_migrated' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'cross_agent_memory_migration_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cross_agent_memory_migration_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cross_agent_memory_migration_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'cross_agent_memory_migration_manifest' &&
            row['file_path'] == summary['manifest_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'cross_agent_memory_migration_source_export' &&
            row['file_path'] == summary['source_export_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'cross_agent_memory_migration_import_preview' &&
            row['file_path'] == summary['import_preview_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('p2 night memory consolidation loop creates core evidence package',
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
    final summaryPath =
        await controller.runNightMemoryConsolidationLoopAcceptance();
    final summary = jsonDecode(File(summaryPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_night_memory_consolidation_loop_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'night_memory_consolidation_loop');
    expect(summary['capability_gate'], 'P2-40 Night Memory Consolidation Loop');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['linked_black_box_status'], 'not_required');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2-41 Memory Observability Panel');
    expect(summary['input_memory_count'], 3);
    expect(summary['queue_item_count'], 4);
    expect(summary['journal_event_count'], 5);
    expect(summary['output_card_count'], 1);
    expect(summary['carryover_count'], 1);

    final policy =
        jsonDecode(File(summary['policy_path'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(policy['schema_version'],
        'prd_v3_night_memory_consolidation_policy.v1');
    expect(policy['status'], 'pass');
    expect(policy['execution_mode'], 'local_test_marked_loop_simulation');
    expect(policy['max_auto_repair_rounds'], 3);
    expect(policy['network_retry_rounds'], 5);
    expect(policy['p2_release_gate_rerun_required'], isTrue);
    expect(policy['disallowed_actions'],
        containsAll(['start_background_daemon', 'train_local_model']));

    final windowPlan = jsonDecode(
            File(summary['window_plan_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(windowPlan['schema_version'],
        'prd_v3_night_memory_consolidation_window_plan.v1');
    expect(windowPlan['status'], 'pass');
    expect(windowPlan['background_daemon_started'], isFalse);
    expect(windowPlan['scheduled_runtime_started'], isFalse);
    final tasks = (windowPlan['tasks'] as List).cast<Map<String, dynamic>>();
    expect(tasks, hasLength(4));
    expect(
        tasks.map((row) => row['task_type']),
        containsAll([
          'merge_source_traced_memory_cards',
          'checkpoint_next_night_window'
        ]));
    expect(tasks.every((row) => row['test_marker'] == true), isTrue);

    final inputs = readJsonlFile(summary['input_snapshot_path'] as String);
    expect(inputs, hasLength(3));
    expect(inputs.map((row) => row['status']),
        containsAll(['active', 'conflict_requires_review']));
    expect(
        inputs.every((row) =>
            row['schema_version'] ==
                'prd_v3_night_memory_consolidation_input.v1' &&
            row['test_marker'] == true &&
            (row['source_trace_ids'] as List).isNotEmpty),
        isTrue);

    final queueRows = readJsonlFile(summary['queue_path'] as String);
    expect(queueRows, hasLength(4));
    expect(queueRows.map((row) => row['status']),
        containsAll(['completed', 'queued_for_owner_review', 'checkpointed']));
    expect(
        queueRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_night_memory_consolidation_queue.v1' &&
            row['test_marker'] == true),
        isTrue);
    expect(
        queueRows.any((row) =>
            row['required_action'] == 'review_conflict_before_apply' &&
            row['source_trace_required'] == true),
        isTrue);

    final journalRows = readJsonlFile(summary['journal_path'] as String);
    expect(journalRows, hasLength(5));
    expect(
        journalRows.map((row) => row['event_type']),
        containsAll([
          'loop_started',
          'memory_cards_consolidated',
          'next_window_checkpointed'
        ]));
    expect(
        journalRows.every((row) =>
            row['schema_version'] ==
                'prd_v3_night_memory_consolidation_journal.v1' &&
            row['test_marker'] == true),
        isTrue);

    final outputCards = jsonDecode(
            File(summary['output_cards_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(outputCards['schema_version'],
        'prd_v3_night_memory_consolidation_output_cards.v1');
    expect(outputCards['status'], 'pass');
    expect(outputCards['real_memory_applied'], isFalse);
    final cards =
        (outputCards['memory_cards'] as List).cast<Map<String, dynamic>>();
    expect(cards, hasLength(1));
    expect(cards.single['retrievable'], isTrue);
    expect(cards.single['updatable'], isTrue);
    expect(cards.single['forgettable'], isTrue);
    expect((cards.single['source_trace_ids'] as List), hasLength(2));

    final checkpoint = jsonDecode(
        File(summary['carryover_checkpoint_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(checkpoint['schema_version'],
        'prd_v3_night_memory_consolidation_checkpoint.v1');
    expect(checkpoint['status'], 'pass');
    expect((checkpoint['carryover_queue_item_ids'] as List),
        contains('night_queue_review_conflict'));
    expect((checkpoint['resume_prompt'] as String), isNotEmpty);
    expect(checkpoint['global_goal_complete'], isFalse);

    final lifecycle = jsonDecode(
            File(summary['lifecycle_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(lifecycle['schema_version'],
        'prd_v3_night_memory_consolidation_lifecycle.v1');
    expect(lifecycle['status'], 'pass');
    expect(lifecycle['restart_recoverable_from_files'], isTrue);
    expect(lifecycle['background_daemon_started'], isFalse);
    expect(lifecycle['real_memory_applied'], isFalse);
    expect(lifecycle['real_user_data_deleted'], isFalse);

    final observability = jsonDecode(
        File(summary['observability_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(observability['schema_version'],
        'prd_v3_night_memory_consolidation_observability.v1');
    expect(observability['status'], 'pass');
    expect(observability['input_memory_count'], 3);
    expect(observability['queue_item_count'], 4);
    expect(observability['journal_event_count'], 5);
    expect(observability['output_card_count'], 1);
    expect(observability['carryover_count'], 1);
    expect(observability['background_daemon_started'], isFalse);
    expect(observability['external_memory_service_connected'], isFalse);
    expect(observability['local_model_training_used'], isFalse);

    final stateSnapshot = jsonDecode(
            File(summary['state_snapshot_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(stateSnapshot['schema_version'],
        'prd_v3_night_memory_consolidation_state_snapshot.v1');
    expect(stateSnapshot['global_goal_complete'], isFalse);
    expect(stateSnapshot['next_gate'], 'P2-41 Memory Observability Panel');

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_night_memory_consolidation_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_night_memory_consolidation_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['background_daemon_started'], isFalse);
    expect(boundary['scheduled_runtime_started'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_memory_service_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);
    expect(boundary['real_memory_applied'], isFalse);
    expect(boundary['real_user_data_migrated'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'background_daemon_started' ||
          entry.key == 'scheduled_runtime_started' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_memory_service_connected' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_memory_applied' ||
          entry.key == 'real_user_data_migrated' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed' ||
          entry.key == 'network_call_made' ||
          entry.key == 'ui_modified' ||
          entry.key == 'new_dependency_added') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

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
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'night_memory_consolidation_loop_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'night_memory_consolidation_loop_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'night_memory_consolidation_loop_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'night_memory_consolidation_loop_queue' &&
            row['file_path'] == summary['queue_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'night_memory_consolidation_loop_output_cards' &&
            row['file_path'] == summary['output_cards_path'] &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'night_memory_consolidation_loop_checkpoint' &&
            row['file_path'] == summary['carryover_checkpoint_path'] &&
            row['status'] == 'completed'),
        isTrue);
  });

  test('task experience reuse basic writes core evidence and reloads',
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
    final summaryPath =
        await controller.runTaskExperienceReuseBasicAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_task_experience_reuse_basic_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'task_experience_reuse_basic');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['experience_count'], greaterThanOrEqualTo(3));
    expect(summary['match_count'], greaterThanOrEqualTo(1));

    final cards = readJsonlFile(summary['experience_cards_path'].toString());
    expect(cards.map((row) => row['experience_id']),
        contains('exp_agent_memory_restart'));
    expect(
        cards.every(
            (row) => ((row['evidence_paths'] as List?) ?? const []).isNotEmpty),
        isTrue);

    final index = jsonDecode(
            File(summary['reuse_index_path'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(index['status'], 'pass');
    expect((index['tag_index'] as Map).containsKey('restart_recovery'), isTrue);

    final matchReport = jsonDecode(
            File(summary['match_report_path'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(matchReport['status'], 'pass');
    final matches =
        (matchReport['matches'] as List).cast<Map<String, dynamic>>();
    expect(matches.first['experience_id'], 'exp_agent_memory_restart');
    expect(matches.first['score'], greaterThan(0));

    final recommendations =
        File(summary['recommendation_report_path'].toString())
            .readAsStringSync();
    expect(recommendations, contains('Task Experience Reuse Recommendations'));
    expect(recommendations, contains('exp_agent_memory_restart'));

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['all_cards_accepted'], isTrue);
    expect(validationChecks['missing_experience_id_rejected'], isTrue);
    expect(validationChecks['missing_evidence_rejected'], isTrue);
    expect(validationChecks['query_returns_match'], isTrue);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'external_llm_used_for_matching',
        'vector_db_used_for_matching',
        'external_project_runtime_loaded',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'task_experience_reuse_basic_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'task_experience_reuse_basic_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'task_experience_reuse_basic_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'task_experience_reuse_basic_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test(
      'p2 tencentdb agent memory adapter evaluation creates governance evidence package',
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
    final summaryPath =
        await controller.runTencentDbAgentMemoryAdapterEvaluationAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_tencentdb_agent_memory_adapter_evaluation_summary.v1');
    expect(summary['status'], 'pass');
    expect(
        summary['capability_id'], 'tencentdb_agent_memory_adapter_evaluation');
    expect(summary['acceptance_type'], 'governance');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['governance_status'], 'passed');
    expect(summary['artifact_status'], 'passed');
    expect(summary['event_status'], 'passed');
    expect(summary['lifecycle_status'], 'passed');
    expect(summary['regression_status'], 'passed');
    expect(summary['boundary_status'], 'passed');
    expect(summary['close_allowed'], isTrue);
    expect(summary['next_gate'], 'P2 Release Gate');
    expect(
        summary['optional_integration_status'], 'deferred_until_owner_review');
    expect(summary['runtime_integration_done'], isFalse);
    expect(summary['failed_checks'], isEmpty);

    final evaluation = jsonDecode(
        File(summary['evaluation_matrix_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(evaluation['schema_version'],
        'prd_v3_tencentdb_agent_memory_adapter_evaluation_matrix.v1');
    expect(evaluation['status'], 'pass');
    expect(evaluation['external_project_classification'], 'absorb');
    expect(
        evaluation['current_action'], 'evaluate_only_no_runtime_integration');
    expect(evaluation['optional_integration_status'],
        'deferred_until_owner_review');
    expect(evaluation['user_facing_capability_label'], '记忆与证据能力');
    expect((evaluation['disallowed_actions'] as List),
        contains('runtime_integration_in_current_gate'));

    final nativeContract = jsonDecode(
            File(summary['native_contract_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(nativeContract['schema_version'],
        'prd_v3_tencentdb_agent_memory_native_contract_mapping.v1');
    expect(nativeContract['status'], 'pass');
    expect((nativeContract['native_contract'] as Map)['event'],
        'HeiTang Event Ledger');
    expect(
        (nativeContract['adapter_boundary'] as Map)['adapter_runtime_loaded'],
        isFalse);
    expect(
        (nativeContract['adapter_boundary']
            as Map)['external_database_connected'],
        isFalse);

    final dependencyRisk = jsonDecode(
            File(summary['dependency_risk_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(dependencyRisk['schema_version'],
        'prd_v3_tencentdb_agent_memory_dependency_risk_report.v1');
    expect(dependencyRisk['status'], 'pass');
    expect(dependencyRisk['node_22_dependency_added'], isFalse);
    expect(dependencyRisk['new_dependency_added'], isFalse);
    expect(dependencyRisk['external_memory_runtime_loaded'], isFalse);
    expect(dependencyRisk['requires_owner_approval_before_real_integration'],
        isTrue);

    final queueInvariant = jsonDecode(
            File(summary['queue_invariant_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(queueInvariant['schema_version'],
        'prd_v3_tencentdb_agent_memory_queue_invariant_report.v1');
    expect(queueInvariant['status'], 'pass');
    expect(queueInvariant['next_gate_after_closure'], 'P2 Release Gate');
    expect(queueInvariant['p2_release_gate_still_queued'], isTrue);
    expect(queueInvariant['final_owner_review_still_queued'], isTrue);
    expect(queueInvariant['global_goal_complete'], isFalse);

    final decision = jsonDecode(
            File(summary['decision_record_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(decision['schema_version'],
        'prd_v3_tencentdb_agent_memory_optional_integration_decision.v1');
    expect(decision['decision'], 'do_not_integrate_in_current_gate');
    expect(decision['optional_integration_allowed_now'], isFalse);
    expect(decision['runtime_now'], isFalse);

    final validation = jsonDecode(
        File(summary['validation_report_path'] as String)
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['schema_version'],
        'prd_v3_tencentdb_agent_memory_adapter_evaluation_validation_report.v1');
    expect(validation['status'], 'pass');
    expect(validation['failed_checks'], isEmpty);

    final boundary = jsonDecode(
            File(summary['boundary_report_path'] as String).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['schema_version'],
        'prd_v3_tencentdb_agent_memory_adapter_evaluation_boundary_report.v1');
    expect(boundary['status'], 'pass');
    expect(boundary['runtime_integration_done'], isFalse);
    expect(boundary['external_project_runtime_loaded'], isFalse);
    expect(boundary['external_memory_service_connected'], isFalse);
    expect(boundary['external_database_connected'], isFalse);
    expect(boundary['external_model_called'], isFalse);
    expect(boundary['network_call_made'], isFalse);
    expect(boundary['new_dependency_added'], isFalse);
    expect(boundary['node_22_dependency_added'], isFalse);
    expect(boundary['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundary['local_model_training_used'], isFalse);
    expect(boundary['gpu_training_used'], isFalse);
    expect(boundary['real_memory_applied'], isFalse);
    expect(boundary['real_user_data_deleted'], isFalse);
    expect(boundary['secret_plaintext_written'], isFalse);
    expect(boundary['external_project_name_user_visible'], isFalse);
    expect(boundary['provider_adapter_parser_user_visible'], isFalse);
    expect(boundary['capability_matrix_user_visible'], isFalse);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if (entry.key == 'runtime_integration_done' ||
          entry.key == 'external_project_runtime_loaded' ||
          entry.key == 'external_memory_service_connected' ||
          entry.key == 'external_database_connected' ||
          entry.key == 'external_model_called' ||
          entry.key == 'network_call_made' ||
          entry.key == 'new_dependency_added' ||
          entry.key == 'node_22_dependency_added' ||
          entry.key == 'package_manifest_changed' ||
          entry.key == 'redis_vector_service_packaged_into_exe' ||
          entry.key == 'local_model_training_used' ||
          entry.key == 'gpu_training_used' ||
          entry.key == 'real_memory_applied' ||
          entry.key == 'real_user_data_deleted' ||
          entry.key == 'secret_plaintext_written' ||
          entry.key == 'external_project_name_user_visible' ||
          entry.key == 'provider_adapter_parser_user_visible' ||
          entry.key == 'capability_matrix_user_visible' ||
          entry.key == 'ui_modified' ||
          entry.key == 'stage_chain_mutated' ||
          entry.key == 'packaging_architecture_changed') {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] ==
                'tencentdb_agent_memory_adapter_evaluation_validated' &&
            row['artifact_path'] == summaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'tencentdb_agent_memory_adapter_evaluation_summary' &&
            row['file_path'] == summaryPath &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'tencentdb_agent_memory_adapter_evaluation_validation' &&
            row['status'] == 'completed'),
        isTrue);
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'tencentdb_agent_memory_adapter_evaluation_boundary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType ==
            'tencentdb_agent_memory_adapter_evaluation_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId ==
                'tencentdb_agent_memory_adapter_evaluation_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('memory adapter research writes core evidence and reloads', () async {
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
    final summaryPath = await controller.runMemoryAdapterResearchAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Bearer ')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(
        summary['schema_version'], 'prd_v3_memory_adapter_research_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'memory_adapter_research');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    expect(summary['candidate_count'], 2);

    final candidates = readJsonlFile(summary['candidates_path'].toString());
    expect(candidates.map((row) => row['project_key']),
        containsAll(['openclaw', 'hermes']));
    expect(candidates.every((row) => row['runtime_now'] == false), isTrue);
    expect(
        candidates.every((row) => row['dependencies_added'] == false), isTrue);
    expect(candidates.every((row) => row['user_visible_project_name'] == false),
        isTrue);

    final boundary = jsonDecode(
            File(summary['boundary_matrix_path'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(boundary['status'], 'pass');
    expect(boundary['p1_decision'], 'research_only_no_runtime_integration');
    final rules = (boundary['rules'] as List).cast<Map<String, dynamic>>();
    expect(rules.every((rule) => rule['passed'] == true), isTrue);

    final contract = jsonDecode(
            File(summary['native_contract_path'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(contract['status'], 'research_contract_only');
    final userFacingPolicy =
        (contract['user_facing_policy'] as Map).cast<String, dynamic>();
    expect(userFacingPolicy['show_external_project_names'], isFalse);
    expect(userFacingPolicy['show_adapter_or_provider_names'], isFalse);

    final validation = jsonDecode(
        File(summary['validation_report_path'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(validation['status'], 'pass');
    final validationChecks =
        (validation['checks'] as Map).cast<String, dynamic>();
    expect(validationChecks['all_candidates_classified'], isTrue);
    expect(validationChecks['missing_classification_rejected'], isTrue);
    expect(validationChecks['p1_runtime_integration_rejected'], isTrue);
    expect(validationChecks['user_visible_project_name_rejected'], isTrue);

    final recommendations =
        File(summary['recommendation_report_path'].toString())
            .readAsStringSync();
    expect(
        recommendations, contains('Memory Adapter Research Recommendations'));
    expect(recommendations, contains('research_only_no_runtime_integration'));

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'runtime_integration_done',
        'dependencies_added',
        'external_project_runtime_loaded',
        'project_names_added_to_user_ui',
        'external_llm_used_for_research',
        'vector_db_used_for_research',
        'redis_vector_service_packaged_into_exe',
        'local_model_training_used',
        'gpu_training_used',
        'real_user_data_deleted',
        'secret_plaintext_written',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'memory_adapter_research_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'memory_adapter_research_summary' &&
            row['status'] == 'completed' &&
            (row['metadata'] as Map)['test_marked_artifact'] == true),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'memory_adapter_research_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'memory_adapter_research_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  testWidgets('knowledge base table view button refreshes catalog rows',
      (tester) async {
    await pumpWorkbench(
      tester,
      setupWorkspace: (workspace) async {
        writeKnowledgeCanvasFixture(workspace);
      },
      coreBridge: LocalCoreBridge(
        runner: (_) async => const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'ok', stderr: ''),
      ),
      initialSelectedIndex: 3,
      surfaceSize: const Size(1440, 1000),
      waitForRuntimeReady: true,
    );

    expect(find.byKey(const Key('knowledge-base-table-view-evidence-button')),
        findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const Key('knowledge-base-table-view-evidence-button')));
    final tableButton = tester.widget<FilledButton>(
      find.byKey(const Key('knowledge-base-table-view-evidence-button')),
    );
    expect(tableButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  test('hot pluggable project config basic writes core evidence and reloads',
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
    final summaryPath =
        await controller.runHotPluggableProjectConfigBasicAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('super-secret-password')));
    expect(summaryText, isNot(contains('qdrant-secret-key')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_hot_pluggable_project_config_basic_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'hot_pluggable_project_config_basic');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'redis_vector_service_packaged_into_exe',
        'secret_plaintext_written',
        'real_user_data_deleted',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final profiles = (jsonDecode(
        File('$configDir${Platform.pathSeparator}project_config_profiles.json')
            .readAsStringSync()) as Map<String, dynamic>)['profiles'] as List;
    expect(
        profiles
            .cast<Map>()
            .where((profile) => profile['is_active'] == true)
            .length,
        1);
    expect(
        profiles.cast<Map>().any((profile) => (profile['display_name'] ?? '')
            .toString()
            .contains('test_project_config_profile_p1_25')),
        isFalse);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] ==
            'hot_pluggable_project_config_basic_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'hot_pluggable_project_config_basic_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'hot_pluggable_project_config_basic_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'hot_pluggable_project_config_basic_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('project config industrial isolation writes core evidence and reloads',
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
    final summaryPath =
        await controller.runProjectConfigIndustrialIsolationAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('super-secret-password')));
    expect(summaryText, isNot(contains('qdrant-secret-key')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_project_config_industrial_isolation_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'project_config_industrial_isolation');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'secret_plaintext_written',
        'external_runtime_executed',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'ui_blackbox_required',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final evidencePaths =
        (summary['evidence_paths'] as Map).cast<String, dynamic>();
    for (final path in [
      evidencePaths['schema'],
      evidencePaths['runtime_status'],
      evidencePaths['fallback_report'],
      evidencePaths['rollback_manifest'],
    ]) {
      expect(File(path.toString()).existsSync(), isTrue, reason: path);
    }

    final statusReport = jsonDecode(
            File(evidencePaths['runtime_status'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    final localProfile =
        (statusReport['local_profile'] as Map).cast<String, dynamic>();
    final hybridProfile =
        (statusReport['hybrid_profile'] as Map).cast<String, dynamic>();
    expect(localProfile['network_enabled'], isFalse);
    expect(hybridProfile['network_enabled'], isTrue);
    expect(localProfile['memory_policy_id'], 'agent_memory_local_file');
    expect(hybridProfile['memory_policy_id'],
        'agent_memory_redis_vector_optional');
    expect(statusReport['secret_plaintext_written'], isFalse);

    final fallbackReport = jsonDecode(
        File(evidencePaths['fallback_report'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(fallbackReport['fallback_preserves_local_import'], isTrue);
    expect(fallbackReport['external_runtime_executed'], isFalse);
    expect(fallbackReport['redis_vector_service_packaged_into_exe'], isFalse);

    final rollbackManifest = jsonDecode(
        File(evidencePaths['rollback_manifest'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackManifest['test_profiles_cleaned_up'], isTrue);
    expect(rollbackManifest['single_active_profile_after_cleanup'], isTrue);
    expect(rollbackManifest['final_active_profile_id'],
        rollbackManifest['initial_active_profile_id']);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final profiles = (jsonDecode(
        File('$configDir${Platform.pathSeparator}project_config_profiles.json')
            .readAsStringSync()) as Map<String, dynamic>)['profiles'] as List;
    expect(
        profiles
            .cast<Map>()
            .where((profile) => profile['is_active'] == true)
            .length,
        1);
    expect(
        profiles.cast<Map>().any((profile) => (profile['display_name'] ?? '')
            .toString()
            .contains('test_project_config_industrial')),
        isFalse);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] ==
            'project_config_industrial_isolation_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] ==
                'project_config_industrial_isolation_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType ==
            'project_config_industrial_isolation_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId ==
                'project_config_industrial_isolation_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('connector industrialization writes core evidence and reloads',
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
    final summaryPath =
        await controller.runConnectorIndustrializationAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('super-secret-password')));
    expect(summaryText, isNot(contains('qdrant-secret-key')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_connector_industrialization_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'connector_industrialization');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'normal_ui_project_names_visible',
        'hot_swap_project_concept_visible',
        'secret_plaintext_written',
        'external_runtime_executed',
        'workflow_executed',
        'redis_vector_service_packaged_into_exe',
        'real_user_data_deleted',
        'ui_blackbox_required',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final counts = (summary['connector_counts'] as Map).cast<String, dynamic>();
    expect(counts['provider_mapping_count'], 29);
    expect(counts['unique_provider_ref_count'], 26);
    expect(counts['contract_count'], 26);
    expect(counts['readiness_entry_count'], 26);
    expect(counts['health_entry_count'], 29);
    expect(counts['binding_count'], 8);
    expect(counts['runtime_loaded_count'], 0);

    final evidencePaths =
        (summary['evidence_paths'] as Map).cast<String, dynamic>();
    for (final path in evidencePaths.values) {
      expect(File(path.toString()).existsSync(), isTrue, reason: path);
    }

    final healthMatrix = jsonDecode(
            File(evidencePaths['health_matrix'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(healthMatrix['schema_version'],
        'prd_v3_connector_industrialization_health_matrix.v1');
    expect(healthMatrix['provider_mapping_count'], 29);
    expect(healthMatrix['unique_provider_ref_count'], 26);
    expect(healthMatrix['runtime_loaded_count'], 0);
    expect(healthMatrix['normal_ui_project_names_visible'], isFalse);
    expect(healthMatrix['secret_plaintext_written'], isFalse);

    final failureMatrix = jsonDecode(
            File(evidencePaths['failure_matrix'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(failureMatrix['schema_version'],
        'prd_v3_connector_industrialization_failure_matrix.v1');
    expect(
        (failureMatrix['model_api_failure_modes'] as List)
            .map((entry) => (entry as Map)['scenario'])
            .toSet(),
        containsAll([
          'auth_failed',
          'timeout',
          'rate_limited',
          'upstream_unavailable',
          'missing_config',
        ]));
    expect(failureMatrix['fallback_preserves_local_chain'], isTrue);
    expect(failureMatrix['network_call_attempted'], isFalse);
    expect(failureMatrix['external_runtime_executed'], isFalse);
    final highRiskEntries =
        (failureMatrix['high_risk_gate_entries'] as List).cast<Map>();
    expect(highRiskEntries.length, greaterThanOrEqualTo(4));
    expect(
        highRiskEntries.every((entry) =>
            entry['runtime_loaded'] == false &&
            entry['runtime_load_allowed'] == false &&
            entry['fallback_preserves_local_chain'] == true &&
            entry['external_runtime_executed'] == false),
        isTrue);

    final auditReport = jsonDecode(
            File(evidencePaths['audit_report'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(auditReport['schema_version'],
        'prd_v3_connector_industrialization_audit_report.v1');
    expect(auditReport['coverage_status'], 'passed');
    expect(auditReport['failed_mapping_count'], 0);
    expect(auditReport['ordinary_ui_abstracted'], isTrue);
    expect(auditReport['external_runtime_executed'], isFalse);
    expect(auditReport['secret_plaintext_written'], isFalse);

    final rollbackReport = jsonDecode(
        File(evidencePaths['rollback_report'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(rollbackReport['schema_version'],
        'prd_v3_connector_industrialization_rollback_report.v1');
    expect(rollbackReport['registered_rollback_supported'], isTrue);
    expect(rollbackReport['registered_rollback_target_count'], 29);
    expect(rollbackReport['blocked_activation_audited'], isTrue);
    expect(rollbackReport['rollback_audited'], isTrue);
    expect(rollbackReport['high_risk_activation_blocked'], isTrue);
    expect(rollbackReport['runtime_loaded_after_rollback'], isFalse);

    final userCatalog = jsonDecode(
        File(evidencePaths['provider_capability_user_catalog'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    final userCatalogText = jsonEncode(userCatalog);
    expect(userCatalog['normal_ui_project_names_visible'], isFalse);
    expect(userCatalog['hot_swap_project_concept_visible'], isFalse);
    expect(userCatalogText, isNot(contains('n8n')));
    expect(userCatalogText, isNot(contains('docling')));
    expect(userCatalogText, isNot(contains('Provider')));
    expect(userCatalogText, isNot(contains('Adapter')));

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'connector_industrialization_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'connector_industrialization_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'connector_industrialization_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'connector_industrialization_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('blackbox automation baseline writes core evidence and reloads',
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
    final summaryPath =
        await controller.runBlackboxAutomationBaselineAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('Authorization')));
    expect(summaryText, isNot(contains('Cookie:')));
    expect(summaryText, isNot(contains('super-secret-password')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_blackbox_automation_baseline_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'blackbox_automation_baseline');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);

    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'ui_blackbox_required',
        'fake_ui_blackbox_created',
        'final_full_matrix_claimed',
        'final_packaging_claimed',
        'release_gate_bypassed',
        'secret_plaintext_written',
        'authorization_header_written',
        'redis_vector_service_packaged_into_exe',
        'local_model_training',
        'gpu_video_generation',
        'external_runtime_executed',
        'real_user_data_deleted',
        'ordinary_ui_project_names_visible',
        'provider_adapter_parser_names_visible_in_product_ui',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final counts = (summary['coverage_counts'] as Map).cast<String, dynamic>();
    expect(counts['p0_closed_gate_count'], greaterThan(10));
    expect(counts['p1_closed_gate_count'], greaterThan(40));
    expect(counts['p2_closed_gate_count'], 7);
    expect(counts['baseline_case_count'], 9);
    expect(counts['runner_hook_count'], 4);

    final evidencePaths =
        (summary['evidence_paths'] as Map).cast<String, dynamic>();
    for (final path in evidencePaths.values) {
      expect(File(path.toString()).existsSync(), isTrue, reason: path);
    }

    final matrix = jsonDecode(File(evidencePaths['baseline_matrix'].toString())
        .readAsStringSync()) as Map<String, dynamic>;
    expect(matrix['schema_version'],
        'prd_v3_blackbox_automation_baseline_matrix.v1');
    expect(matrix['baseline_only'], isTrue);
    expect(matrix['final_full_matrix_claimed'], isFalse);
    expect(matrix['p2_release_gate_owns_final_full_matrix'], isTrue);
    expect(matrix['covered_until_gate'], 'P2-7 Connector Industrialization');
    expect(matrix['future_append_starts_at'], 'P2-10 Role-based Workgroup');
    final caseInventory =
        (matrix['case_inventory'] as List).cast<Map<String, dynamic>>();
    expect(caseInventory.length, 9);
    expect(
        caseInventory.any((entry) =>
            entry['phase'] == 'P0' &&
            (entry['covered_gate_ids'] as List).contains('P0 Release Gate')),
        isTrue);
    expect(
        caseInventory.any((entry) =>
            entry['phase'] == 'P1' &&
            (entry['covered_gate_ids'] as List).contains('P1 Release Gate')),
        isTrue);
    for (final gate in [
      'P2-1 Workgroup Basic Runtime',
      'P2-2 Office Collaboration Workgroup',
      'P2-3 Research Analysis Workgroup',
      'P2-4 A2A >= 10 Agents',
      'P2-5 Multi-Agent RAG Deepening',
      'P2-6 Hot-Pluggable Project Config Industrial Isolation',
      'P2-7 Connector Industrialization',
    ]) {
      expect(
          caseInventory.any(
              (entry) => (entry['covered_gate_ids'] as List).contains(gate)),
          isTrue,
          reason: gate);
    }
    final appendContract =
        (matrix['append_contract'] as Map).cast<String, dynamic>();
    expect(appendContract['future_p2_gate_policy'],
        contains('P2-10 through P2-42'));
    expect(appendContract['release_gate_policy'], contains('P2 Release Gate'));
    expect(appendContract['allowed_delete_scope'],
        contains('test-marked temporary objects only'));

    final gapMatrix = jsonDecode(
            File(evidencePaths['gap_matrix'].toString()).readAsStringSync())
        as Map<String, dynamic>;
    expect(gapMatrix['schema_version'],
        'prd_v3_blackbox_automation_gap_matrix.v1');
    expect(gapMatrix['baseline_status'], 'built');
    expect(gapMatrix['missing_current_baseline_cases'], isEmpty);
    expect(gapMatrix['soft_blockers'], isEmpty);
    expect(gapMatrix['hard_blockers'], isEmpty);
    expect(
        (gapMatrix['known_gaps'] as List)
            .every((entry) => (entry as Map)['blocking_current_gate'] == false),
        isTrue);

    final regressionPlan = jsonDecode(
        File(evidencePaths['regression_plan'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(regressionPlan['schema_version'],
        'prd_v3_blackbox_automation_regression_plan.v1');
    expect(regressionPlan['release_gate_rerun_required'], isTrue);
    expect(
        regressionPlan['release_gate_scope'], contains('P2-1 through P2-42'));

    final boundaryReport = jsonDecode(
        File(evidencePaths['boundary_report'].toString())
            .readAsStringSync()) as Map<String, dynamic>;
    expect(boundaryReport['schema_version'],
        'prd_v3_blackbox_automation_boundary_report.v1');
    expect(boundaryReport['acceptance_type'], 'core_only');
    expect(boundaryReport['ui_blackbox_required'], isFalse);
    expect(boundaryReport['fake_ui_blackbox_created'], isFalse);
    expect(boundaryReport['final_full_matrix_claimed'], isFalse);
    expect(boundaryReport['final_packaging_claimed'], isFalse);
    expect(boundaryReport['release_gate_bypassed'], isFalse);
    expect(boundaryReport['secret_plaintext_written'], isFalse);
    expect(boundaryReport['redis_vector_service_packaged_into_exe'], isFalse);
    expect(boundaryReport['local_model_training'], isFalse);
    expect(boundaryReport['gpu_video_generation'], isFalse);
    expect(boundaryReport['real_user_data_deleted'], isFalse);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'blackbox_automation_baseline_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'blackbox_automation_baseline_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'blackbox_automation_baseline_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'blackbox_automation_baseline_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('audit report enhancement writes core evidence and reloads', () async {
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
    final artifactPath =
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}test_audit_report_input.json';
    File(artifactPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('{"status":"pass"}');
    await controller.exportWorkspaceArtifact(
      artifactPath: artifactPath,
      artifactLabel: 'test audit report input',
    );

    final summaryPath = await controller.runAuditReportEnhancementAcceptance();
    final summaryText = File(summaryPath).readAsStringSync();
    expect(summaryText, isNot(contains('super-secret-password')));
    expect(summaryText, isNot(contains('qdrant-secret-key')));
    final summary = jsonDecode(summaryText) as Map<String, dynamic>;
    expect(summary['schema_version'],
        'prd_v3_audit_report_enhancement_summary.v1');
    expect(summary['status'], 'pass');
    expect(summary['capability_id'], 'audit_report_enhancement');
    expect(summary['acceptance_type'], 'core_only');
    expect(summary['white_box_status'], 'passed');
    expect(summary['black_box_status'], 'not_required');
    expect(summary['failed_checks'], isEmpty);
    final checks = (summary['checks'] as Map).cast<String, dynamic>();
    for (final entry in checks.entries) {
      if ({
        'redis_vector_service_packaged_into_exe',
        'secret_plaintext_written',
        'real_user_data_deleted',
      }.contains(entry.key)) {
        expect(entry.value, isFalse, reason: entry.key);
      } else {
        expect(entry.value, isTrue, reason: entry.key);
      }
    }

    final auditReportPath = summary['audit_report_path'] as String;
    final auditReport =
        jsonDecode(File(auditReportPath).readAsStringSync()) as Map;
    expect(auditReport['schema_version'], 'heitang_workbench_audit_report.v1');
    expect(auditReport['enhancement_schema_version'],
        'prd_v3_audit_report_enhancement.v1');
    expect(auditReport['record_count'], greaterThanOrEqualTo(14));
    expect((auditReport['module_summary'] as Map)['module_count'],
        greaterThanOrEqualTo(6));
    expect((auditReport['event_ledger_summary'] as Map)['path'],
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect((auditReport['artifact_catalog_summary'] as Map)['path'],
        '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json');
    expect((auditReport['boundary'] as Map)['ui_blackbox_required'], isFalse);
    expect(
        (auditReport['boundary'] as Map)['secret_plaintext_written'], isFalse);

    final eventRows = File(
            '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any(
            (row) => row['event_type'] == 'audit_report_enhancement_validated'),
        isTrue);

    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'audit_report_enhancement_summary' &&
            row['status'] == 'completed'),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.eventType == 'audit_report_enhancement_validated'),
        isTrue);
    expect(
        reloaded.state.artifactRecords.any((record) =>
            record.artifactId == 'audit_report_enhancement_summary' &&
            record.status == 'completed'),
        isTrue);
  });

  test('skill generation persists type platform and personalization config',
      () async {
    final workspace = await createWorkspace();
    final activeWorkspace = Directory(
        '${workspace.path}${Platform.pathSeparator}workbooks${Platform.pathSeparator}assets${Platform.pathSeparator}默认工作本')
      ..createSync(recursive: true);
    final kbDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
          ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"test_kb.v1"}');
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(
            '${jsonEncode({
                  'text': '产品分析证据',
                  'source_path': 'alpha.txt',
                  'source_doc_id': 'doc_alpha',
                  'chunk_id': 'chunk_alpha_001',
                  'source_trace_id': 'trace_alpha_001',
                  'block_ids': ['block_alpha_001'],
                  'heading_path': ['产品分析'],
                  'semantic_unit_type': 'paragraph',
                  'lineage': {
                    'source_doc_id': 'doc_alpha',
                    'block_ids': ['block_alpha_001'],
                  },
                })}\n');
    File('${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(jsonEncode({
      'sources': [
        {
          'source_name': 'alpha.txt',
          'relative_path': 'alpha.txt',
          'document_id': 'doc_alpha',
        }
      ],
    }));
    final kbCatalogDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases')
      ..createSync(recursive: true);
    File('${kbCatalogDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'owner_product_kb',
          'kb_name': 'Owner 产品知识库',
          'status': 'searchable',
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
    final skillRoot = '${activeWorkspace.path}${Platform.pathSeparator}skill';
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
    final primarySkillConfig = jsonDecode(File(
            '$skillRoot${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}skill_config.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(primarySkillConfig['skill_config_id'], 'knowledge_qa_skill');
    expect(primarySkillConfig['legacy_skill_alias'], 'S1');
    expect(primarySkillConfig['legacy_compatibility_only'], isTrue);
    expect(primarySkillConfig['source_kb_ids'], ['owner_product_kb']);
    final skillSourceTracePath =
        '$skillRoot${Platform.pathSeparator}source_trace.jsonl';
    expect(File(skillSourceTracePath).existsSync(), isTrue);
    final skillSourceTraceRows = readJsonlFile(skillSourceTracePath);
    expect(skillSourceTraceRows, hasLength(1));
    final skillSourceTrace = skillSourceTraceRows.single;
    expect(skillSourceTrace['schema_version'], 'prd_v3_skill_source_trace.v1');
    expect(skillSourceTrace['skill_id'], 'knowledge_qa_skill');
    expect(skillSourceTrace['kb_id'], 'owner_product_kb');
    expect(skillSourceTrace['source_kb_ids'], ['owner_product_kb']);
    expect(skillSourceTrace['source_doc_id'], 'doc_alpha');
    expect(skillSourceTrace['source_chunk_id'], 'chunk_alpha_001');
    expect(skillSourceTrace['chunk_id'], 'chunk_alpha_001');
    expect(skillSourceTrace['source_trace_id'], 'trace_alpha_001');
    expect(skillSourceTrace['source_path'], 'alpha.txt');
    expect(skillSourceTrace['block_ids'], ['block_alpha_001']);
    expect(skillSourceTrace['heading_path'], ['产品分析']);
    expect(skillSourceTrace['semantic_unit_type'], 'paragraph');
    expect(primarySkillConfig['source_trace_path'], skillSourceTracePath);
    expect(primarySkillConfig['source_doc_ids'], ['doc_alpha']);
    expect(primarySkillConfig['source_chunk_ids'], ['chunk_alpha_001']);
    expect(primarySkillConfig['source_trace_ids'], ['trace_alpha_001']);
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
    expect(skillGenerationManifest['source_kb_ids'], ['owner_product_kb']);
    expect(skillGenerationManifest['source_trace_path'], skillSourceTracePath);
    expect(skillGenerationManifest['source_doc_ids'], ['doc_alpha']);
    expect(skillGenerationManifest['source_chunk_ids'], ['chunk_alpha_001']);
    expect(skillGenerationManifest['source_trace_ids'], ['trace_alpha_001']);
    expect(skillGenerationManifest['legacy_skill_aliases'],
        containsPair('S1', 'knowledge_qa_skill'));
    for (final helperSkillId in const [
      'reading_summary_skill',
      'quality_check_skill',
      'operation_conversion_skill',
      'product_analysis_skill',
    ]) {
      final helperManifest = jsonDecode(File(
              '$skillRoot${Platform.pathSeparator}$helperSkillId${Platform.pathSeparator}skill_manifest.json')
          .readAsStringSync()) as Map<String, dynamic>;
      expect(helperManifest['generation_mode'], 'built_in_template');
      expect(helperManifest['source_mode'], 'template_plus_current_kb');
      expect(helperManifest['is_method_extracted_from_kb'], isFalse);
      expect(helperManifest['status'], 'built_in_template_skill');
      final helperVerification = jsonDecode(File(
              '$skillRoot${Platform.pathSeparator}$helperSkillId${Platform.pathSeparator}verification_report.json')
          .readAsStringSync()) as Map<String, dynamic>;
      expect(helperVerification['generation_mode'], 'built_in_template');
      expect(helperVerification['source_mode'], 'template_plus_current_kb');
      expect(helperVerification['is_method_extracted_from_kb'], isFalse);
    }
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
    final skillVersionManifestJson =
        jsonDecode(File(skillVersionManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    expect((skillVersionManifestJson['versions'] as List).single['skill_id'],
        'knowledge_qa_skill');
    expect(
        (skillVersionManifestJson['versions'] as List)
            .single['legacy_skill_alias'],
        'S1');
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
    final operationManifestJson =
        jsonDecode(operationManifest) as Map<String, dynamic>;
    final bindingManifestJson = jsonDecode(File(
            '$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}agent_binding_manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(bindingManifestJson['skill_ids'], contains('knowledge_qa_skill'));
    expect(
        bindingManifestJson['skill_ids'], contains('localized_writing_skill'));
    expect(bindingManifestJson['skill_ids'], isNot(contains('S1')));
    expect(bindingManifestJson['skill_ids'], isNot(contains('S2')));
    expect(bindingManifestJson['legacy_skill_aliases'],
        containsPair('S2', 'localized_writing_skill'));
    expect(
        operationManifestJson['schema_version'], 'prd_v2_skill_operations.v1');
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
    expect(skillPackageManifest['source_kb_ids'], ['owner_product_kb']);
    expect(skillPackageManifest['source_trace_path'], skillSourceTracePath);
    expect(skillPackageManifest['source_doc_ids'], ['doc_alpha']);
    expect(skillPackageManifest['source_chunk_ids'], ['chunk_alpha_001']);
    expect(skillPackageManifest['source_trace_ids'], ['trace_alpha_001']);
    expect(
        (skillPackageManifest['artifact_records'] as List).any((item) =>
            (item as Map)['artifact_id'] == 'source_trace' &&
            item['exists'] == true),
        isTrue);
    expect(
        (skillPackageManifest['skill_packages'] as List)
            .map((item) => (item as Map)['skill_id'])
            .toList(),
        containsAll([
          'knowledge_qa_skill',
          'localized_writing_skill',
          'fused_product_ops_skill',
        ]));
    expect(
        (skillPackageManifest['skill_packages'] as List)
            .map((item) => (item as Map)['skill_id'])
            .toList(),
        isNot(contains('S1')));
    expect(skillPackageManifest['legacy_skill_aliases'],
        containsPair('S1', 'knowledge_qa_skill'));
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
    expect(skillValidationReport['source_trace_path'], skillSourceTracePath);
    expect(skillValidationReport['source_doc_ids'], ['doc_alpha']);
    expect(skillValidationReport['source_chunk_ids'], ['chunk_alpha_001']);
    expect(skillValidationReport['source_trace_ids'], ['trace_alpha_001']);
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
    expect(skillRuntimeManifest['source_kb_ids'], ['owner_product_kb']);
    expect(skillRuntimeManifest['source_skill_ids'],
        contains('knowledge_qa_skill'));
    expect(skillRuntimeManifest['source_skill_ids'], isNot(contains('S1')));
    expect(skillRuntimeManifest['legacy_skill_aliases'],
        containsPair('S2', 'localized_writing_skill'));
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
            '${activeWorkspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json')
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

  test('skill delete preserves tombstone operation history and restart evidence',
      () async {
    final workspace = await createWorkspace();
    final activeWorkspace = Directory(
        '${workspace.path}${Platform.pathSeparator}workbooks${Platform.pathSeparator}assets${Platform.pathSeparator}默认工作本')
      ..createSync(recursive: true);
    final kbDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}kb')
          ..createSync(recursive: true);
    File('${kbDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"schema_version":"test_kb.v1"}');
    File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl')
        .writeAsStringSync(
            '${jsonEncode({
                  'text': '删除 Skill 时不能误删知识库证据',
                  'source_path': 'alpha.txt',
                  'source_doc_id': 'doc_alpha',
                  'chunk_id': 'chunk_alpha_001',
                  'source_trace_id': 'trace_alpha_001',
                })}\n');
    final kbCatalogDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases')
      ..createSync(recursive: true);
    File('${kbCatalogDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {
          'kb_id': 'owner_product_kb',
          'kb_name': 'Owner 产品知识库',
          'status': 'searchable',
        }
      ],
    }));

    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
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
    await controller.generateSkill();
    expect(controller.state.hasSkill, isTrue);

    await controller.clearSkillArtifacts();

    expect(controller.state.hasSkill, isFalse);
    expect(File('${kbDir.path}${Platform.pathSeparator}chunks.jsonl').existsSync(),
        isTrue);
    final skillDeleteRoot = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}skill_deletions');
    expect(skillDeleteRoot.existsSync(), isTrue);
    final deleteEvidenceDirs = skillDeleteRoot
        .listSync()
        .whereType<Directory>()
        .toList(growable: false);
    expect(deleteEvidenceDirs, hasLength(1));
    final tombstonePath =
        '${deleteEvidenceDirs.single.path}${Platform.pathSeparator}skill_delete_tombstone.json';
    final historyPath =
        '${deleteEvidenceDirs.single.path}${Platform.pathSeparator}skill_operation_history.json';
    final manifestPath =
        '${deleteEvidenceDirs.single.path}${Platform.pathSeparator}skill_delete_manifest.json';
    final tombstone =
        jsonDecode(File(tombstonePath).readAsStringSync()) as Map;
    expect(tombstone['schema_version'], 'prd_v3_skill_delete_tombstone.v1');
    expect(tombstone['status'], 'deleted');
    expect(tombstone['deleted_skill_ids'], contains('knowledge_qa_skill'));
    expect(tombstone['kb_assets_deleted'], isFalse);
    expect(tombstone['source_kb_ids'], contains('owner_product_kb'));
    final deleteHistory =
        jsonDecode(File(historyPath).readAsStringSync()) as Map;
    expect(deleteHistory['schema_version'],
        'prd_v2_skill_operation_history.v1');
    expect(
        deleteHistory['records'],
        contains(isA<Map>()
            .having((record) => record['action'], 'action', 'delete_skill')
            .having((record) => record['status'], 'status', 'deleted')));
    final deleteManifest =
        jsonDecode(File(manifestPath).readAsStringSync()) as Map;
    expect(deleteManifest['tombstone_path'], tombstonePath);
    expect(deleteManifest['history_path'], historyPath);
    expect(controller.state.hasSkillOperationHistory, isTrue);
    expect(controller.state.skillOperationHistoryPath, historyPath);

    final eventRows = File(
            '${activeWorkspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'delete_skill' &&
            row['artifact_path'] == tombstonePath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${activeWorkspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final artifacts =
        (artifactCatalog['artifacts'] as List).cast<Map<String, dynamic>>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'skill_delete_tombstone' &&
            row['artifact_type'] == 'skill_tombstone' &&
            row['file_path'] == tombstonePath &&
            row['status'] == 'deleted'),
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
    expect(reloadedController.state.hasSkill, isFalse);
    expect(reloadedController.state.hasSkillOperationHistory, isTrue);
    expect(reloadedController.state.skillOperationHistoryPath, historyPath);
    expect(
        reloadedController.state.eventLedgerRecords.any((record) =>
            record.eventType == 'delete_skill' &&
            record.artifactPath == tombstonePath),
        isTrue);
    expect(
        reloadedController.state.artifactRecords.any((record) =>
            record.artifactId == 'skill_delete_tombstone' &&
            record.filePath == tombstonePath &&
            record.status == 'deleted'),
        isTrue);
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
    final workgroupSummaryPath = await controller.runMultiAgentDiscussion(
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
    final workgroupSummary =
        jsonDecode(File(workgroupSummaryPath).readAsStringSync()) as Map;
    expect(workgroupSummary['capability_gate'], 'P2-1 Workgroup Basic Runtime');
    expect(workgroupSummary['acceptance_type'], 'user_blackbox');
    expect(workgroupSummary['white_box_status'], 'passed');
    expect(workgroupSummary['black_box_status'], 'passed');
    expect(workgroupSummary['ui_blackbox_path'],
        'Agent -> Work Group -> Start Work Group');
    expect(workgroupSummary['p2_4_status'], 'not_closed_by_p2_1');
    expect(
        (workgroupSummary['boundary_evidence']
            as Map)['external_project_name_user_visible'],
        isFalse);
    final eventRows = readJsonlFile(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(
        eventRows.any((row) =>
            row['event_type'] == 'workgroup_basic_runtime_validated' &&
            row['artifact_path'] == workgroupSummaryPath),
        isTrue);
    final artifactCatalog = jsonDecode(File(
            '${workspace.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}catalog.json')
        .readAsStringSync()) as Map;
    final artifacts = (artifactCatalog['artifacts'] as List).cast<Map>();
    expect(
        artifacts.any((row) =>
            row['artifact_id'] == 'workgroup_basic_runtime_summary' &&
            row['file_path'] == workgroupSummaryPath),
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
        .ensureVisible(find.byKey(const Key('dashboard-artifact-overview')));
    await tester.tap(find.text('查看全部成果'), warnIfMissed: false);
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
    await controller.createOrSwitchWorkbook('产品研究工作本');
    final researchWorkspace = Directory(controller.state.workspacePath);
    final input =
        Directory('${researchWorkspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha workbook source');
    File('${researchWorkspace.path}${Platform.pathSeparator}source_manifest.json')
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
    final kbCatalogDir = Directory(
        '${researchWorkspace.path}${Platform.pathSeparator}knowledge_bases')
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
        '${researchWorkspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Skill');
    final agentDir = Directory(
        '${researchWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agent_manifest.json')
        .writeAsStringSync('{"agent_id":"A"}');
    final auditDir =
        Directory('${researchWorkspace.path}${Platform.pathSeparator}audit')
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
    expect(assetIndex['workspace_boundary'], controller.state.workspacePath);
    expect(assetIndex['source_manifest_path'], isEmpty);
    expect(assetIndex['document_ids'], isEmpty);
    expect(assetIndex['knowledge_base_ids'], isEmpty);
    expect(assetIndex['knowledge_index_artifacts'], isA<List>());
    expect(assetIndex['skill_artifacts'], isEmpty);
    expect(assetIndex['agent_artifacts'], isEmpty);
    expect(assetIndex['audit_artifacts'], isEmpty);
    expect(assetIndex['secret_plaintext_written'], isFalse);
    expect(assetIndex['directory_isolation'], 'workbook_asset_directory');
    expect(controller.state.currentWorkbookName, '运营复盘工作本');
    expect(controller.state.workspacePath,
        contains('workbooks${Platform.pathSeparator}assets'));
    expect(controller.state.workbookNames,
        containsAll(['默认工作本', '产品研究工作本', '运营复盘工作本']));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.currentWorkbookName, '运营复盘工作本');
    expect(reloaded.state.workspacePath,
        contains('运营复盘工作本'));
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

  test('prd workbook operations write event ledger across restart', () async {
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

    final ledger = File(
        '${workspace.path}${Platform.pathSeparator}audit${Platform.pathSeparator}event_ledger.jsonl');
    expect(ledger.existsSync(), isTrue);
    final rows = ledger
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(rows.where((row) => row['action'] == 'create_workbook'), hasLength(2));
    expect(rows.where((row) => row['action'] == 'delete_workbook'), hasLength(1));
    expect(rows.map((row) => row['target_name']), contains('产品研究工作本'));
    expect(rows.map((row) => row['target_name']), contains('运营复盘工作本'));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.eventLedgerRecords.map((record) => record.action),
        containsAll(['create_workbook', 'delete_workbook']));
    expect(
        reloaded.state.eventLedgerRecords.any((record) =>
            record.action == 'delete_workbook' &&
            record.targetName == '产品研究工作本' &&
            record.status == 'completed'),
        isTrue);
  });
  test('phase 1b workspace import kb lifecycle e2e persists and deletes safely',
      () async {
    final workspace = await createWorkspace();
    final sourceDir =
        Directory('${workspace.path}${Platform.pathSeparator}phase1b_sources')
          ..createSync(recursive: true);
    File('${sourceDir.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha phase1b source 赚钱 小生意');
    File('${sourceDir.path}${Platform.pathSeparator}beta.txt')
        .writeAsStringSync('beta phase1b source operations');

    final requests = <CoreBridgeRequest>[];
    Rc6RuntimeController buildController() => Rc6RuntimeController(
          coreBridge: LocalCoreBridge(
            runner: (request) async {
              requests.add(request);
              final output = Directory(request.outputPath!)
                ..createSync(recursive: true);
              switch (request.actionId) {
                case 'batch_import_documents':
                  File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                      .writeAsStringSync(
                          '{"status":"completed","imported_count":2}');
                case 'document_understanding':
                  writeDuRecords(
                      Directory(output.parent.path), ['alpha.md', 'beta.txt']);
                  File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                      .writeAsStringSync(
                          '{"status":"completed","success_count":2,"failed_count":0}');
                case 'knowledge_base_build':
                  File('${output.path}${Platform.pathSeparator}manifest.json')
                      .writeAsStringSync(
                          '{"schema_version":"kb.v1","status":"pass"}');
                  File('${output.path}${Platform.pathSeparator}quality_report.json')
                      .writeAsStringSync('{"status":"pass"}');
                  File('${output.path}${Platform.pathSeparator}knowledge_base_build_report.json')
                      .writeAsStringSync('{"source_count":2}');
                  final normalizedRoot =
                      '${workspace.path}${Platform.pathSeparator}du${Platform.pathSeparator}normalized_sources';
                  File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                      .writeAsStringSync(jsonl([
                    {
                      'text': 'alpha phase1b chunk',
                      'source_path':
                          '$normalizedRoot${Platform.pathSeparator}1.md',
                      'citation': 'alpha.md#chunk=1',
                    },
                    {
                      'text': 'beta phase1b chunk',
                      'source_path':
                          '$normalizedRoot${Platform.pathSeparator}2.md',
                      'citation': 'beta.txt#chunk=1',
                    },
                  ]));
                  File('${output.path}${Platform.pathSeparator}cards.jsonl')
                      .writeAsStringSync(
                          '{"title":"phase1b","summary":"real"}\n');
                  File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                      .writeAsStringSync('{"question":"q","answer":"a"}\n');
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

    final controller = buildController();
    await controller.initialize();
    await controller.createOrSwitchWorkbook('Phase 1B 临时工作区');
    await controller.deleteWorkbook('Phase 1B 临时工作区');
    await controller.createOrSwitchWorkbook('Phase 1B 恢复工作区');
    final activeWorkspace = Directory(controller.state.workspacePath);

    await controller.importFolderPath(sourceDir.path);
    await controller.importFolderPath(sourceDir.path);
    final inputFiles =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}input')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) =>
                file.path.endsWith('.md') || file.path.endsWith('.txt'))
            .toList(growable: false);
    expect(inputFiles.map((file) => file.uri.pathSegments.last),
        unorderedEquals(['alpha.md', 'beta.txt']));
    expect(controller.state.sourceRecords, hasLength(2));
    final alphaId = controller.state.sourceRecords
        .firstWhere((source) => source.sourceName == 'alpha.md')
        .documentId;
    final betaId = controller.state.sourceRecords
        .firstWhere((source) => source.sourceName == 'beta.txt')
        .documentId;

    await controller.parseAndChunkSources();
    expect(controller.state.parseReportPath, isNotEmpty);

    await controller.buildKnowledgeBase(documentIds: [alphaId]);
    await controller.buildKnowledgeBase(documentIds: [betaId]);
    expect(controller.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2']));
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1${Platform.pathSeparator}source_map.json')
            .existsSync(),
        isTrue);
    expect(
        File('${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K2${Platform.pathSeparator}chunks.jsonl')
            .existsSync(),
        isTrue);
    final k1Chunks = readJsonlFile(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1${Platform.pathSeparator}chunks.jsonl');
    expect(k1Chunks, isNotEmpty);
    expect(k1Chunks.every((row) => row['source_doc_id'] == alphaId), isTrue);
    expect(
        k1Chunks.every((row) => (row['block_ids'] as List).isNotEmpty), isTrue);
    expect(k1Chunks.every((row) => row['heading_path'] is List), isTrue);
    expect(
        k1Chunks
            .every((row) => row['semantic_unit_type'] == 'okf_semantic_chunk'),
        isTrue);
    expect(
        k1Chunks.every((row) => (row['source_trace_id'] as String).isNotEmpty),
        isTrue);
    expect(k1Chunks.every((row) => row['lineage'] is Map), isTrue);
    expect(
        k1Chunks.every((row) =>
            ((row['lineage'] as Map)['chunking_strategy'] as String) ==
            'okf_semantic_from_parsed_document'),
        isTrue);
    final k1TraceRows = readJsonlFile(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1${Platform.pathSeparator}source_trace.jsonl');
    expect(k1TraceRows.map((row) => row['source_trace_id']).toSet(),
        containsAll(k1Chunks.map((row) => row['source_trace_id'])));
    expect(k1TraceRows.every((row) => (row['block_ids'] as List).isNotEmpty),
        isTrue);

    final packagePath = await controller.exportStandardKnowledgePackage();
    expect(
        File('$packagePath${Platform.pathSeparator}standard_package_manifest.json')
            .existsSync(),
        isTrue);

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.currentWorkbookName, 'Phase 1B 恢复工作区');
    expect(reloaded.state.sourceRecords, hasLength(2));
    expect(reloaded.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2']));
    expect(reloaded.state.standardKnowledgePackageManifestPath, isNotEmpty);

    await reloaded.mergeKnowledgeBases(['K1', 'K2']);
    final mergedId = reloaded.state.knowledgeBases
        .map((kb) => kb.id)
        .firstWhere((id) => id.startsWith('K_MERGED'));
    expect(reloaded.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2', mergedId]));

    await reloaded.deleteKnowledgeBaseRecord(mergedId);
    expect(reloaded.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2']));
    expect(reloaded.state.knowledgeBases.map((kb) => kb.id),
        isNot(contains(mergedId)));
    expect(
        Directory(
                '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1')
            .existsSync(),
        isTrue);
    expect(
        Directory(
                '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K2')
            .existsSync(),
        isTrue);

    final finalReload = buildController();
    await finalReload.initialize();
    expect(finalReload.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2']));
    expect(finalReload.state.knowledgeBases.map((kb) => kb.id),
        isNot(contains(mergedId)));
    expect(
        requests.map((request) => request.actionId),
        containsAll([
          'batch_import_documents',
          'document_understanding',
          'knowledge_base_build'
        ]));
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
    final activeWorkspace = Directory(controller.state.workspacePath);
    final manifestPath =
        '${workspace.path}${Platform.pathSeparator}workbooks${Platform.pathSeparator}workbook_manifest.json';
    var payload = jsonDecode(File(manifestPath).readAsStringSync())
        as Map<String, dynamic>;
    var activeWorkbook = (payload['workbooks'] as List)
        .whereType<Map>()
        .firstWhere((row) => row['name'] == '产品研究工作本');
    expect((activeWorkbook['asset_index'] as Map)['document_ids'], isEmpty);

    final input =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}input')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.md')
        .writeAsStringSync('alpha workbook source');
    File('${activeWorkspace.path}${Platform.pathSeparator}source_manifest.json')
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
    final kbCatalogDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}knowledge_bases')
      ..createSync(recursive: true);
    File('${kbCatalogDir.path}${Platform.pathSeparator}kb_catalog.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'knowledge_bases': [
        {'kb_id': 'K1', 'kb_name': '产品研究知识库'}
      ],
    }));
    final skillDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}knowledge_qa_skill')
      ..createSync(recursive: true);
    File('${skillDir.path}${Platform.pathSeparator}SKILL.md')
        .writeAsStringSync('# Skill');
    final skillOps = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}operations')
      ..createSync(recursive: true);
    final skillBindingPath =
        '${skillOps.path}${Platform.pathSeparator}agent_binding_manifest.json';
    File(skillBindingPath).writeAsStringSync('{"status":"bound"}');
    final skillExportDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}skill${Platform.pathSeparator}exports')
      ..createSync(recursive: true);
    final skillExportPath =
        '${skillExportDir.path}${Platform.pathSeparator}skills_export.md';
    File(skillExportPath).writeAsStringSync('# exported Skill');
    final agentDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}knowledge_qa_agent')
      ..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}agent_manifest.json')
        .writeAsStringSync('{"agent_id":"A"}');
    final dialogueExportDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}dialogue_export')
      ..createSync(recursive: true);
    final dialogueExportPath =
        '${dialogueExportDir.path}${Platform.pathSeparator}agent_dialogue_export.md';
    File(dialogueExportPath).writeAsStringSync('# dialogue export');
    final multiAgentDir =
        Directory('${activeWorkspace.path}${Platform.pathSeparator}multi_agent')
          ..createSync(recursive: true);
    final discussionPath =
        '${multiAgentDir.path}${Platform.pathSeparator}multi_agent_discussion.md';
    File(discussionPath).writeAsStringSync('# A2A discussion');
    final a2aDir = Directory(
        '${activeWorkspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}workspaces${Platform.pathSeparator}W_M${Platform.pathSeparator}a2a_sessions${Platform.pathSeparator}A2A_001')
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
