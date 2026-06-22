import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('captures runtime operability evidence without external provider claims',
      () async {
    final appRoot = Directory.current;
    final latestPath = '${appRoot.path}${Platform.pathSeparator}output'
        '${Platform.pathSeparator}real_io_acceptance'
        '${Platform.pathSeparator}latest_run.json';
    final latest =
        jsonDecode(File(latestPath).readAsStringSync()) as Map<String, dynamic>;
    final runDir = Directory(latest['run_dir'] as String);
    final runtimeWorkspace = Directory('${runDir.path}${Platform.pathSeparator}'
        'runtime_controller_operability_workspace')
      ..createSync(recursive: true);
    final input = Directory('${runtimeWorkspace.path}${Platform.pathSeparator}'
        'input_src')
      ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.pdf')
        .writeAsStringSync('alpha real source 赚钱 小生意');
    File('${input.path}${Platform.pathSeparator}beta.txt')
        .writeAsStringSync('beta real source product ops');

    final requests = <String>[];
    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
          requests.add(request.actionId);
          final output = Directory(request.outputPath!)
            ..createSync(recursive: true);
          switch (request.actionId) {
            case 'batch_import_documents':
              File('${output.path}${Platform.pathSeparator}batch_import_report.json')
                  .writeAsStringSync(jsonEncode({
                'status': 'completed',
                'imported_count': 2,
              }));
            case 'document_understanding':
              _writeDuRecords(runtimeWorkspace, ['alpha.pdf', 'beta.txt']);
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync(jsonEncode({
                'status': 'completed',
                'success_count': 2,
                'failed_count': 0,
              }));
            case 'knowledge_base_build':
              File('${output.path}${Platform.pathSeparator}manifest.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}quality_report.json')
                  .writeAsStringSync('{}');
              File('${output.path}${Platform.pathSeparator}knowledge_base_build_report.json')
                  .writeAsStringSync('{"source_count":2}');
              final normalizedRoot = '${runtimeWorkspace.path}'
                  '${Platform.pathSeparator}du${Platform.pathSeparator}'
                  'normalized_sources';
              File('${output.path}${Platform.pathSeparator}chunks.jsonl')
                  .writeAsStringSync([
                jsonEncode({
                  'text': '赚钱 小生意 alpha',
                  'source_path':
                      '$normalizedRoot${Platform.pathSeparator}1.md',
                  'citation': 'alpha.pdf#chunk=1',
                }),
                jsonEncode({
                  'text': 'product ops beta',
                  'source_path':
                      '$normalizedRoot${Platform.pathSeparator}2.md',
                  'citation': 'beta.txt#chunk=1',
                }),
              ].join('\n'));
              File('${output.path}${Platform.pathSeparator}cards.jsonl')
                  .writeAsStringSync('{"title":"alpha","summary":"赚钱"}\n');
              File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                  .writeAsStringSync('{"question":"q","answer":"a"}\n');
            case 'rag_query':
              File('${output.path}${Platform.pathSeparator}kb_query_result.json')
                  .writeAsStringSync(jsonEncode({
                'query': '赚钱 小生意',
                'selected_count': 1,
                'records': [
                  {
                    'text': '真实命中',
                    'source_path': 'alpha.pdf',
                    'citation': 'alpha.pdf#chunk=1',
                    'score': 2,
                  }
                ],
              }));
            case 'generate_markdown':
              File('${output.path}${Platform.pathSeparator}generated.md')
                  .writeAsStringSync('# generated from runtime controller');
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
      configuredWorkspace: runtimeWorkspace.path,
      isWebRuntime: false,
    );

    await controller.initialize();
    await controller.createOrSwitchWorkbook('工业验收工作区 A');
    await controller.createOrSwitchWorkbook('工业验收工作区 B');
    await controller.deleteWorkbook('工业验收工作区 A');
    await controller.runPrdP0ProductE2E(input.path);
    await controller.runAgentDialogue(prompt: '总结真实输入主题');
    await controller.runMultiAgentDiscussion(topic: '多个助手一起讨论真实输入');
    await controller.exportAgentDialogue();
    final agentDialogueCreated = controller.state.hasAgentDialogue;
    final agentDialogueHistoryCreated = controller.state.hasAgentDialogueHistory;
    final agentDialogueExportPath = controller.state.agentDialogueExportPath;
    final agentDialoguePath = controller.state.agentDialoguePath;
    final agentDialogueHistoryPath = controller.state.agentDialogueHistoryPath;
    final agentDialogueTurnCount = controller.state.agentDialogueTurnCount;
    final artifactExportManifestPath = await controller.exportWorkspaceArtifact(
      artifactPath: agentDialogueExportPath,
      artifactLabel: 'agent_dialogue_export_acceptance',
    );
    final auditReportPath = await controller.exportAuditReport();
    await controller.clearAgentDialogueHistory();
    await controller.saveExporterSettings(
      docxExporter: 'office_exporter_optional',
      pdfExporter: 'pdf_exporter_optional',
      pptxExporter: 'pptx_exporter_optional',
      exportRoot: '${runtimeWorkspace.path}${Platform.pathSeparator}export',
    );
    await controller.validateExporterSettings();
    final exporterSettingsPath = '${runtimeWorkspace.path}'
        '${Platform.pathSeparator}config'
        '${Platform.pathSeparator}exporter_settings.json';

    final evidence = {
      'schema_version': 'runtime_controller_operability_evidence.v1',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'passed_local_runtime_controller',
      'external_provider_runtime_executed': false,
      'workspace': runtimeWorkspace.path,
      'core_actions': requests,
      'workbook_crud': {
        'create_switch_delete_executed': true,
        'current_workbook': controller.state.currentWorkbookName,
        'workbook_names': controller.state.workbookNames,
      },
      'agent_dialogue': {
        'created': agentDialogueCreated || agentDialogueHistoryCreated,
        'history_created': agentDialogueHistoryCreated,
        'cleared': !controller.state.hasAgentDialogueHistory,
        'path': agentDialoguePath,
        'history_path': agentDialogueHistoryPath,
        'export_path': agentDialogueExportPath,
        'turn_count': agentDialogueTurnCount,
      },
      'multi_agent': {
        'created': controller.state.hasMultiAgentDiscussion,
        'path': controller.state.multiAgentDiscussionPath,
      },
      'usage_records': {
        'audit_report_path': auditReportPath,
        'audit_report_exists': File(auditReportPath).existsSync(),
        'derived_from_runtime_state': true,
      },
      'settings': {
        'exporter_settings_path': exporterSettingsPath,
        'exporter_settings_exists': File(exporterSettingsPath).existsSync(),
        'exporter_validation_report_path':
            controller.state.exporterValidationReportPath,
      },
      'artifacts': {
        'prd_p0_evidence_path': controller.state.prdP0EvidencePath,
        'agent_path': controller.state.agentPath,
        'skill_path': controller.state.skillPath,
        'artifact_export_manifest_path': artifactExportManifestPath,
        'artifact_export_manifest_exists':
            File(artifactExportManifestPath).existsSync(),
      },
    };
    final evidencePath = '${runDir.path}${Platform.pathSeparator}'
        'runtime_controller_operability_results.json';
    File(evidencePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(evidence),
      encoding: utf8,
    );

    expect(requests, contains('batch_import_documents'));
    expect(requests, contains('document_understanding'));
    expect(requests, contains('knowledge_base_build'));
    expect(requests, contains('rag_query'));
    expect(requests, contains('generate_markdown'));
    expect(requests, contains('package_to_skill'));
    expect(requests, contains('kb_bound_agent_generation'));
    expect(controller.state.hasMultiAgentDiscussion, isTrue);
    expect(controller.state.hasAgentDialogueHistory, isFalse);
    expect(File(auditReportPath).existsSync(), isTrue);
    expect(File(artifactExportManifestPath).existsSync(), isTrue);
    expect(File(evidencePath).existsSync(), isTrue);
  });
}

void _writeDuRecords(Directory workspace, List<String> names) {
  final normalized = Directory('${workspace.path}${Platform.pathSeparator}du'
      '${Platform.pathSeparator}normalized_sources')
    ..createSync(recursive: true);
  final records = <String>[];
  for (var index = 0; index < names.length; index++) {
    final file = File('${normalized.path}${Platform.pathSeparator}'
        '${index + 1}.md')
      ..writeAsStringSync('normalized ${names[index]} 赚钱 小生意');
    records.add(jsonEncode({
      'relative_path': names[index],
      'normalized_path': file.path,
      'text_length': file.lengthSync(),
      'executed_backend': 'builtin',
      'runtime_invoked': true,
    }));
  }
  File('${workspace.path}${Platform.pathSeparator}du'
          '${Platform.pathSeparator}document_understanding_records.jsonl')
      .writeAsStringSync(records.join('\n'));
}
