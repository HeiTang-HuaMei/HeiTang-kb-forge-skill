import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller.dart';

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
    expect(
        indexMetadata.readAsStringSync(), contains('prd_v2_index_metadata.v1'));
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
    await tester.tap(find.text('来源文档'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library')), findsOneWidget);
    expect(find.text('等待导入真实文档'), findsOneWidget);
    expect(find.textContaining('display_only'), findsNothing);
    expect(find.textContaining('示例行保持'), findsNothing);
    expect(find.text('刷新文档列表'), findsOneWidget);
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
    await tester.tap(find.text('来源文档').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('document-library-search-input')), findsOneWidget);
    expect(find.text('名称升序'), findsOneWidget);
    expect(find.text('名称降序'), findsOneWidget);
    expect(find.text('类型排序'), findsOneWidget);
    expect(find.text('导入文档后可在这里多选、预览和批量删除。'), findsOneWidget);
    expect(find.text('删除当前文档'), findsOneWidget);
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
    expect(find.text('外部事实验证未启用'), findsOneWidget);
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
    expect(find.text('外部本地化'), findsOneWidget);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);

    await tester.tap(find.text('外部本地化').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('skill-external-localization')), findsOneWidget);

    await tester.tap(find.text('版本操作').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);

    await tester.tap(find.text('验证导出').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-agent-factory-runtime')));
    await tester.tap(find.byKey(const Key('sidebar-agent-factory-runtime')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-workspace-setup')), findsOneWidget);
    expect(find.text('创建 Agent'), findsWidgets);
    await tester.tap(find.text('创建 Agent').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('简单 Agent'), findsWidgets);
    expect(find.text('复杂 Agent'), findsOneWidget);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('运行 Owner input 链路'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);
    expect(find.text('生成 Agent 完整配置'), findsWidgets);
    expect(find.text('A2A 协作'), findsOneWidget);
    await tester.tap(find.text('A2A 协作').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('multi-agent-discussion-product-flow')),
        findsOneWidget);
    expect(find.text('启动联合讨论'), findsOneWidget);
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
    await controller.mergeKnowledgeBases(['K1', 'K1_COPY1']);
    await controller.splitKnowledgeBase('K2');
    expect(controller.state.knowledgeBases.map((kb) => kb.id),
        containsAll(['K1', 'K2', 'K1_COPY1', 'K_MERGED1', 'K2_SPLIT1']));
    expect(controller.state.knowledgeBases.first.versionCount, 1);

    await controller.updateKnowledgeBaseIncremental('K1');
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
    final rolledBackK1 =
        controller.state.knowledgeBases.firstWhere((kb) => kb.id == 'K1');
    expect(rolledBackK1.operation, 'rollback');
    expect(rolledBackK1.versionCount, 1);
    expect(
        File('${workspace.path}${Platform.pathSeparator}knowledge_bases${Platform.pathSeparator}K1${Platform.pathSeparator}rollback.log')
            .existsSync(),
        isTrue);

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
            '# 外部转化写作 Skill',
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
    expect(controller.state.hasSkill, isTrue);
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
    expect(result['schema_version'], 'prd_v2_multi_kb_query_result.v1');
    expect(result['selected_kb_ids'], ['K1', 'K2']);
    final rows = (result['results'] as List).cast<Map>();
    expect(rows.map((row) => row['kb_id']), ['K2', 'K1']);
    expect(rows.first['kb_name'], 'Beta KB');
    expect(controller.state.searchStatus, Rc6SearchStatus.success);
    expect(controller.state.searchResults.map((row) => row.kbName),
        ['Beta KB', 'Alpha KB']);
    expect(controller.state.queryResultPath, resultFile.path);

    final validationPath = await controller.saveRetrievalValidationReport({
      0: 'keep',
      1: 'conflict',
    });
    final validationFile = File(validationPath);
    expect(validationFile.existsSync(), isTrue);
    final validation =
        jsonDecode(validationFile.readAsStringSync()) as Map<String, dynamic>;
    expect(
        validation['schema_version'], 'prd_v2_retrieval_validation_report.v1');
    expect(validation['result_count'], 2);
    expect(validation['conflict_count'], 1);
    expect(validation['manual_corrections'], isA<List>());
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

    expect(requests.map((request) => request.actionId), [
      'batch_import_documents',
      'document_understanding',
      'knowledge_base_build',
      'rag_query',
      'generate_markdown',
      'generate_docx',
      'generate_pdf',
      'generate_pptx',
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
    final baseTurnCount = controller.state.agentDialogueTurnCount;
    await controller.runAgentDialogue(prompt: '总结真实输入主题');
    await controller.runAgentDialogue(prompt: '继续追问行动建议');
    expect(controller.state.hasAgentDialogue, isTrue);
    expect(controller.state.hasAgentDialogueHistory, isTrue);
    expect(controller.state.agentDialogueTurnCount, baseTurnCount + 2);
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
    expect(reloadedController.state.hasAgentDialogueExport, isTrue);
    expect(reloadedController.state.agentDialogueExportPath,
        endsWith('agent_dialogue_export.md'));
    expect(reloadedController.state.agentDialogueTurnCount, baseTurnCount + 2);
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
    expect(
        File('${workspace.path}${Platform.pathSeparator}agent${Platform.pathSeparator}exports${Platform.pathSeparator}agent_package_manifest.json')
            .readAsStringSync(),
        contains('prd_v2_agent_export_package.v1'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion.md')
            .readAsStringSync(),
        contains('每个 Agent 的观点'));
    expect(
        File('${workspace.path}${Platform.pathSeparator}multi_agent${Platform.pathSeparator}multi_agent_discussion.md')
            .readAsStringSync(),
        contains('真实输入命中赚钱小生意'));

    await controller.clearAgentArtifacts();
    expect(controller.state.hasAgent, isFalse);
    expect(controller.state.hasAgentDialogue, isFalse);
    expect(controller.state.hasMultiAgentDiscussion, isFalse);
    expect(controller.state.hasSkill, isTrue);
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}agent')
            .existsSync(),
        isFalse);

    await controller.generateAgent();
    expect(controller.state.hasAgent, isTrue);
    await controller.clearSkillArtifacts();
    expect(controller.state.hasSkill, isFalse);
    expect(controller.state.hasAgent, isFalse);
    expect(
        Directory('${workspace.path}${Platform.pathSeparator}skill')
            .existsSync(),
        isFalse);
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
      'generate_docx',
      'generate_pdf',
      'generate_pptx',
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
          isTrue);
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
    final generationManifest =
        File('$docRoot${Platform.pathSeparator}generation_manifest.json')
            .readAsStringSync();
    expect(
        generationManifest,
        allOf(
          contains('prd_v2_template_document_generation.v1'),
          contains('"generation_type": "product_analysis"'),
          contains('"output_format": "docx"'),
          contains('"citation_strategy": "filename_and_chunk"'),
          contains('"template_mode": "agent"'),
        ));
    expect(
        generationManifest,
        allOf(
          contains('"citations":'),
          contains('alpha.txt#chunk=1'),
          contains('"kb_name": "真实输入知识库"'),
          contains('"generation_history":'),
          contains('"citation_count": 1'),
        ));
    expect(
        File('$docRoot${Platform.pathSeparator}reading_notes.md')
            .readAsStringSync(),
        allOf(
          contains('真实输入产品分析'),
          contains('文件名 + Chunk'),
          contains('内置 Agent 题材'),
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
          contains('"generation_type": "product_analysis"'),
          contains('"output_format": "docx"'),
        ));
    expect(
        File('${workspace.path}${Platform.pathSeparator}export${Platform.pathSeparator}reading_notes_export.md')
            .readAsStringSync(),
        contains('final edited body from real KB'));
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
        skillType: 'product',
        targetPlatform: 'markdown',
        personalizationGoal: 'agent_specific',
      ),
    );

    expect(requests.single.actionId, 'package_to_skill');
    expect(requests.single.arguments, contains('真实输入产品 Skill'));
    final skillRoot = '${workspace.path}${Platform.pathSeparator}skill';
    expect(
        File('$skillRoot${Platform.pathSeparator}knowledge_qa_skill${Platform.pathSeparator}SKILL.md')
            .readAsStringSync(),
        allOf(
          contains('真实输入产品 Skill'),
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
        ));
    expect(
        File('$skillRoot${Platform.pathSeparator}skill_generation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('"selected_generation_config"'),
          contains('"skill_type": "product"'),
          contains('"target_platform": "markdown"'),
          contains('"personalization_goal": "agent_specific"'),
        ));

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

    await controller.completeSkillProductOperations();
    expect(
        File('$skillRoot${Platform.pathSeparator}exports${Platform.pathSeparator}skills_export.md')
            .readAsStringSync(),
        contains('Owner edited product Skill'));
    expect(
        File('$skillRoot${Platform.pathSeparator}operations${Platform.pathSeparator}skill_operation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('"operation": "edit"'),
          contains('skill_edit_manifest.json'),
          contains('"status": "saved"'),
        ));
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
        creationMode: 'advanced',
        agentType: 'product_analysis',
        outputFormat: 'json',
      ),
    );

    expect(requests.single.actionId, 'kb_bound_agent_generation');
    expect(requests.single.arguments, contains('advanced_kb_bound'));
    expect(requests.single.arguments, contains('产品分析 Agent'));
    final agentRoot = '${workspace.path}${Platform.pathSeparator}agent';
    expect(
        File('$agentRoot${Platform.pathSeparator}knowledge_qa_agent${Platform.pathSeparator}agent_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('prd_v2_selected_agent_manifest.v1'),
          contains('"creation_mode": "advanced"'),
          contains('"agent_type": "product_analysis"'),
          contains('"output_format": "json"'),
        ));
    expect(
        File('$agentRoot${Platform.pathSeparator}agent_generation_manifest.json')
            .readAsStringSync(),
        allOf(
          contains('"selected_generation_config"'),
          contains('"creation_mode": "advanced"'),
          contains('"agent_type": "product_analysis"'),
          contains('"output_format": "json"'),
        ));
    expect(
        File('$agentRoot${Platform.pathSeparator}product_config${Platform.pathSeparator}advanced_agent_config.json')
            .readAsStringSync(),
        allOf(
          contains('"selected_generation_config"'),
          contains('"creation_mode": "advanced"'),
          contains('"output_format": "json"'),
        ));
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
          'generate_docx',
          'generate_pdf',
          'generate_pptx',
          'package_to_skill',
          'kb_bound_agent_generation',
        ]));
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
    await pumpWorkbench(tester);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-artifact-center')));
    await tester.tap(find.byKey(const Key('sidebar-artifact-center')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('artifact-center-catalog')), findsOneWidget);
    expect(find.text('Agent 对话导出'), findsOneWidget);
    expect(find.textContaining('chat export'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(controller.state.currentWorkbookName, '运营复盘工作本');
    expect(controller.state.workbookNames,
        containsAll(['默认工作本', '产品研究工作本', '运营复盘工作本']));

    final reloaded = buildController();
    await reloaded.initialize();
    expect(reloaded.state.currentWorkbookName, '运营复盘工作本');
    expect(reloaded.state.workbookManifestPath, manifest.path);
    expect(reloaded.state.workbookNames, containsAll(['产品研究工作本', '运营复盘工作本']));
  });
}
