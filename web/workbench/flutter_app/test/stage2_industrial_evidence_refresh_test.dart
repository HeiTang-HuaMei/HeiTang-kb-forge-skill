import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes fixed Stage2 industrial evidence workspace', () async {
    final appRoot = Directory.current;
    final outputRoot =
        Directory('${appRoot.path}${Platform.pathSeparator}output');
    final workspace = Directory(
        '${outputRoot.path}${Platform.pathSeparator}stage2_industrial_runtime_workspace');
    if (!workspace.absolute.path
        .toLowerCase()
        .startsWith(outputRoot.absolute.path.toLowerCase())) {
      fail('Stage2 evidence workspace must stay under flutter_app/output.');
    }
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
    workspace.createSync(recursive: true);

    final input =
        Directory('${workspace.path}${Platform.pathSeparator}input_src')
          ..createSync(recursive: true);
    File('${input.path}${Platform.pathSeparator}alpha.pdf')
        .writeAsStringSync('alpha pdf text 赚钱 小生意');
    File('${input.path}${Platform.pathSeparator}scan.png')
        .writeAsBytesSync(<int>[
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0x00,
      0x00,
      0x00,
      0x0d,
      0x49,
      0x48,
      0x44,
      0x52,
    ]);
    final nested = Directory('${input.path}${Platform.pathSeparator}nested')
      ..createSync(recursive: true);
    File('${nested.path}${Platform.pathSeparator}beta.txt')
        .writeAsStringSync('beta text');

    final controller = Rc6RuntimeController(
      coreBridge: LocalCoreBridge(
        runner: (request) async {
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
              _writeDuRecords(
                  workspace, ['alpha.pdf', 'scan.png', 'nested/beta.txt']);
              File('${output.path}${Platform.pathSeparator}document_understanding_manifest.json')
                  .writeAsStringSync(jsonEncode({
                'status': 'completed',
                'success_count': 3,
                'failed_count': 0,
                'normalized_source_count': 3,
              }));
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
                  .writeAsStringSync(_jsonl([
                {
                  'chunk_id': 'chunk_alpha_1',
                  'text': '赚钱 小生意',
                  'source_path': '$normalizedRoot${Platform.pathSeparator}1.md',
                  'citation': 'alpha.pdf#chunk=1',
                },
                {
                  'chunk_id': 'chunk_beta_1',
                  'text': 'beta 小生意 运营',
                  'source_path': '$normalizedRoot${Platform.pathSeparator}2.md',
                  'citation': 'nested/beta.txt#chunk=1',
                },
              ]));
              File('${output.path}${Platform.pathSeparator}cards.jsonl')
                  .writeAsStringSync('{"title":"赚钱小生意","summary":"真实主题"}\n');
              File('${output.path}${Platform.pathSeparator}qa_pairs.jsonl')
                  .writeAsStringSync(
                      '{"question":"主题是什么?","answer":"赚钱小生意"}\n');
            case 'rag_query':
              File('${output.path}${Platform.pathSeparator}kb_query_result.json')
                  .writeAsStringSync(jsonEncode({
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
              _writeGeneratedDocumentExport(output, 'docx');
            case 'generate_pdf':
              _writeGeneratedDocumentExport(output, 'pdf');
            case 'generate_pptx':
              _writeGeneratedDocumentExport(output, 'pptx');
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
    await controller.runAgentDialogue(prompt: '总结真实输入主题');
    await controller.runAgentDialogue(prompt: '继续追问行动建议');
    await controller.exportAgentDialogue();
    await controller.runRealInputFolderE2E(input.path);
    await controller.exportStandardKnowledgePackage();
    await controller.buildKnowledgeBaseFromStandardPackage();
    await controller.runSkillOperation('fusion');
    await controller.saveProviderRuntimeSettings(
      llmProvider: 'official_openai',
      modelId: 'gpt-industrial',
      embeddingProvider: 'local_keyword_embedding',
      searchProvider: 'local_index',
      parserProvider: 'local_parser',
      ocrProvider: 'optional_ocr',
      apiKey: '',
    );
    await controller.saveExporterSettings(
      docxExporter: 'office_exporter_optional',
      pdfExporter: 'pdf_exporter_optional',
      pptxExporter: 'pptx_exporter_optional',
      exportRoot: '${workspace.path}${Platform.pathSeparator}export',
    );
    await controller.validateProviderRuntimeSettings();
    await controller.validateExporterSettings();
    await controller.runParallelTaskCapacityValidation(taskCount: 8);
    await controller.testAllRegisteredProviderCapabilities();

    final smokeReport = _readJson(
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}industrial_exe_smoke_report.json');
    expect(smokeReport['status'], 'passed');
    expect(smokeReport['step_count'], greaterThanOrEqualTo(38));
    for (final step
        in (smokeReport['step_results'] as List).cast<Map<String, dynamic>>()) {
      expect(step['status'], 'passed', reason: jsonEncode(step));
      final artifact = (step['artifact'] ?? '').toString();
      expect(artifact, isNotEmpty, reason: jsonEncode(step));
      expect(File(artifact).existsSync() || Directory(artifact).existsSync(),
          isTrue,
          reason: artifact);
    }
    for (final kbId in ['K1', 'K2', 'K3']) {
      _expectKbRuntimeArtifacts(workspace, kbId);
    }
    final query = _readJson(
        '${workspace.path}${Platform.pathSeparator}query${Platform.pathSeparator}multi_kb_query_result.json');
    expect(query['selected_kb_ids'], containsAll(['K1', 'K2', 'K3']));
    final rows = (query['results'] as List).cast<Map>();
    expect(rows.map((row) => row['kb_id']).toSet(),
        containsAll(['K1', 'K2', 'K3']));
    final readiness = _readJson(
        '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}provider_adapter_readiness_report.json');
    Map<String, dynamic> readinessEntry(String providerRef) =>
        (readiness['readiness_entries'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['provider_ref'] == providerRef);
    for (final providerRef in ['paddleocr', 'surya']) {
      final entry = readinessEntry(providerRef);
      expect(entry['status'], '连接成功');
      expect(entry['ready_for_user_selection'], isTrue);
      expect(entry['runtime_loaded'], isFalse);
      final probe = _readJson((entry['test_artifacts'] as List).single);
      expect(probe['schema_version'],
          'prd_v3_provider_adapter_probe_document_parser_ocr.v1');
      expect(probe['has_ocr_input_evidence'], isTrue);
      expect(probe['du_ocr_input_evidence'], isTrue);
      expect(probe['du_ocr_record_count'], greaterThanOrEqualTo(1));
      expect(probe['external_runtime_executed'], isFalse);
      expect(probe['vendor_runtime_loaded'], isFalse);
    }
    final n8n = readinessEntry('n8n');
    expect(n8n['status'], '连接成功');
    expect(n8n['ready_for_user_selection'], isTrue);
    expect(n8n['runtime_loaded'], isFalse);
    final n8nProbe = _readJson((n8n['test_artifacts'] as List).single);
    expect(n8nProbe['schema_version'], 'prd_v3_provider_adapter_probe_n8n.v1');
    expect(n8nProbe['passed'], isTrue);
    expect(n8nProbe['external_runtime_executed'], isFalse);
    expect(n8nProbe['vendor_runtime_loaded'], isFalse);
    final binding = _readJson(
        '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}provider_capability_binding_manifest.json');
    final workflowBinding = (binding['bindings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) =>
            entry['capability_id'] == 'workflow_collaboration_export');
    expect(workflowBinding['active_provider_ref'], 'n8n');
    expect(workflowBinding['active_provider_kind'], 'registered_provider');
    expect(workflowBinding['selection_allowed'], isTrue);
    expect(workflowBinding['runtime_loaded'], isFalse);
    for (final relative in [
      'config${Platform.pathSeparator}provider_runtime_settings.json',
      'config${Platform.pathSeparator}storage_provider_settings.json',
      'config${Platform.pathSeparator}exporter_settings.json',
      'config${Platform.pathSeparator}config_test_log.jsonl',
      'config${Platform.pathSeparator}profile_change_log.jsonl',
      'workbooks${Platform.pathSeparator}workbook_manifest.json',
    ]) {
      expect(
          File('${workspace.path}${Platform.pathSeparator}$relative')
              .existsSync(),
          isTrue);
    }
    final runtimeStatus = _readJson(
        '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json');
    final preflight =
        runtimeStatus['stage_2_industrial_preflight'] as Map<String, dynamic>;
    final failedChecks =
        (preflight['failed_checks'] as List).cast<String>().toList();
    expect(failedChecks, ['industrial_exe_launch_smoke']);
    final checks = (preflight['checks'] as List).cast<Map<String, dynamic>>();
    for (final check in checks) {
      if (check['check_id'] == 'industrial_exe_launch_smoke') continue;
      expect(check['status'], 'passed', reason: jsonEncode(check));
    }
  });

  test('refreshes Stage2 preflight after independent EXE smoke', () async {
    final appRoot = Directory.current;
    final workspace = Directory(
        '${appRoot.path}${Platform.pathSeparator}output${Platform.pathSeparator}stage2_industrial_runtime_workspace');
    final exeSmokeReport = File(
        '${workspace.path}${Platform.pathSeparator}acceptance${Platform.pathSeparator}exe_launch_smoke_report.json');
    expect(exeSmokeReport.existsSync(), isTrue);

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

    final runtimeStatus = _readJson(
        '${workspace.path}${Platform.pathSeparator}config${Platform.pathSeparator}project_config_runtime_status.json');
    final preflight =
        runtimeStatus['stage_2_industrial_preflight'] as Map<String, dynamic>;
    expect(preflight['status'], 'passed');
    expect(preflight['runtime_load_allowed'], isTrue);
    expect(preflight['failed_checks'], isEmpty);
    final checks = (preflight['checks'] as List).cast<Map<String, dynamic>>();
    for (final check in checks) {
      expect(check['status'], 'passed', reason: jsonEncode(check));
    }
  }, skip: Platform.environment['STAGE2_VERIFY_EXE_SMOKE'] != '1');

  test('proves live Redis and Qdrant provider runtime when configured',
      () async {
    final redisPassword =
        Platform.environment['HEITANG_REDIS_PASSWORD']?.trim() ?? '';
    expect(redisPassword, isNotEmpty,
        reason:
            'Set HEITANG_REDIS_PASSWORD to run live Redis industrial evidence.');

    final appRoot = Directory.current;
    final outputRoot =
        Directory('${appRoot.path}${Platform.pathSeparator}output');
    final workspace = Directory(
        '${outputRoot.path}${Platform.pathSeparator}stage2_live_provider_runtime_workspace');
    if (!workspace.absolute.path
        .toLowerCase()
        .startsWith(outputRoot.absolute.path.toLowerCase())) {
      fail(
          'Stage2 live provider workspace must stay under flutter_app/output.');
    }
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
    workspace.createSync(recursive: true);

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
    final previousHttpOverride = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() {
      HttpOverrides.global = previousHttpOverride;
    });
    final redis = await controller.testRedisConnection(
      host: '127.0.0.1',
      port: 6379,
      keyPrefix: 'heitang:stage2:',
      password: '',
    );
    expect(redis.status, 'connected', reason: redis.detail);
    final qdrant = await controller.testQdrantConnection(
      endpoint: 'http://127.0.0.1:6333',
      collection: 'heitang_stage2_live_provider',
      dimension: 8,
      apiKey: '',
    );
    expect(qdrant.status, 'connected', reason: qdrant.detail);

    final configDir = '${workspace.path}${Platform.pathSeparator}config';
    final storage = _readJson(
        '$configDir${Platform.pathSeparator}storage_provider_settings.json');
    final redisSettings = storage['redis'] as Map<String, dynamic>;
    final qdrantSettings = storage['qdrant'] as Map<String, dynamic>;
    expect(redisSettings['status'], 'connected');
    expect(redisSettings['password_secret_ref'], 'env:HEITANG_REDIS_PASSWORD');
    expect(jsonEncode(storage), isNot(contains(redisPassword)));
    expect(qdrantSettings['status'], 'connected');

    final runtimeStatus = _readJson(
        '$configDir${Platform.pathSeparator}project_config_runtime_status.json');
    final modules = runtimeStatus['module_status'] as Map<String, dynamic>;
    expect((modules['knowledge_base'] as Map)['index_backend'], 'Qdrant');
    expect((modules['agent_workbench'] as Map)['redis_memory_status'], '连接成功');
    expect((modules['agent_workbench'] as Map)['vector_memory_status'], '连接成功');
    expect((runtimeStatus['degradation'] as Map)['redis_failure'],
        contains('Redis 短期记忆可用'));
    expect((runtimeStatus['degradation'] as Map)['vector_failure'],
        contains('外部向量库可用'));

    final testLog =
        File('$configDir${Platform.pathSeparator}config_test_log.jsonl')
            .readAsStringSync();
    expect(testLog, contains('"config_type":"redis"'));
    expect(testLog, contains('"config_type":"vector_db"'));
    expect(testLog, contains('"status":"连接成功"'));
    expect(testLog, isNot(contains(redisPassword)));
  }, skip: Platform.environment['STAGE2_VERIFY_LIVE_PROVIDERS'] != '1');
}

String _jsonl(List<Map<String, Object?>> rows) =>
    '${rows.map(jsonEncode).join('\n')}\n';

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync().replaceFirst('\ufeff', ''))
        as Map<String, dynamic>;

void _writeGeneratedDocumentExport(Directory output, String format) {
  final file = File('${output.path}${Platform.pathSeparator}generated.$format');
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

void _writeDuRecords(Directory workspace, List<String> relativePaths) {
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
      if (relativePaths[index].toLowerCase().endsWith('.png'))
        'ocr_text': 'normalized OCR image text',
    }));
  }
  File('${du.path}${Platform.pathSeparator}document_understanding_records.jsonl')
      .writeAsStringSync('${rows.join('\n')}\n');
}

void _expectKbRuntimeArtifacts(Directory workspace, String kbId) {
  final kbRoot =
      '${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}$kbId';
  for (final file in [
    'manifest.json',
    'prd_kb_manifest.json',
    'chunks.jsonl',
    'index_metadata.json',
    'index_profile.json',
    'keyword_index.json',
    'vector_index_reference.json',
    'metadata_index.json',
    'citation_index.json',
    'memory_index_reference.json',
    'index_build_report.json',
  ]) {
    expect(File('$kbRoot${Platform.pathSeparator}$file').existsSync(), isTrue,
        reason: '$kbId/$file');
  }
}
