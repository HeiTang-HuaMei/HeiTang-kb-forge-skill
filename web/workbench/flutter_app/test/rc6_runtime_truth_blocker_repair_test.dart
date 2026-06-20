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

  List<Map<String, dynamic>> readJsonlFile(String path) => File(path)
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map((line) => jsonDecode(line) as Map<String, dynamic>)
      .toList(growable: false);

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
    expect(find.text('用文档构建知识库'), findsOneWidget);
    final buildButton = tester.widget<FilledButton>(find.ancestor(
      of: find.text('用文档构建知识库'),
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
    expect(find.text('单 Agent'), findsWidgets);
    await tester.tap(find.text('单 Agent').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('简单 Agent'), findsWidgets);
    expect(find.text('复杂 Agent'), findsOneWidget);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('运行 Owner input 链路'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);
    expect(find.text('创建 Agent 并进入对话'), findsWidgets);
    expect(find.text('多 Agent / A2A'), findsOneWidget);
    await tester.tap(find.text('多 Agent / A2A').first, warnIfMissed: false);
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
    final redisMissing = await controller.testRedisConnection(
      host: '127.0.0.1',
      port: 6379,
      keyPrefix: 'heitang:',
      password: '',
    );
    expect(redisMissing.status, 'missing_password');
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
    expect(referenceStatuses, contains('needs_verification'));
    expect(referenceStatuses, contains('reference_only'));
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
        30);
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
        30);
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
    expect(providerEntries, hasLength(30));
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
    expect(providerAdapterContracts['provider_mapping_count'], 30);
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
    expect(providerAdapterReadiness['ready_for_user_selection_count'], 2);
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
    expect(readyProviderRefs, {'mattpocock_skills', 'ai_marketing_skills'});
    expect(readinessEntries.every((entry) => entry['runtime_loaded'] == false),
        isTrue);
    expect(readinessEntries.every((entry) => entry['secret_masked'] == true),
        isTrue);
    expect(
        readinessEntries.map((entry) => entry['status']).toSet(),
        containsAll([
          '需安装外部服务',
          '已配置未测试',
          '已禁用',
          '需启动外部服务',
        ]));
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
    final registeredActivationLogPath =
        runtimeStatus['registered_provider_activation_log_path'] as String;
    final registeredActivationLog =
        File(registeredActivationLogPath).readAsLinesSync();
    expect(registeredActivationLog, hasLength(30));
    final registeredRollbackPath =
        runtimeStatus['registered_provider_rollback_manifest_path'] as String;
    final registeredRollback =
        jsonDecode(File(registeredRollbackPath).readAsStringSync()) as Map;
    expect(registeredRollback['schema_version'],
        'prd_v3_registered_provider_rollback_manifest.v1');
    expect((registeredRollback['rollback_targets'] as List), hasLength(30));
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
    expect(skillTemplateBinding['active_provider_ref'], 'mattpocock_skills');
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
    expect(providerHealth['provider_entry_count'], 30);
    expect(providerHealth['unique_provider_ref_count'], 26);
    expect(providerHealth['capability_area_count'], 8);
    expect(providerHealth['all_entries_checked'], isTrue);
    expect(providerHealth['runtime_loaded_count'], 0);
    expect(providerHealth['ready_for_user_selection_count'], 3);
    expect(providerHealth['external_runtime_load_allowed'], isFalse);
    expect((providerHealth['stage_2_industrial_preflight'] as Map)['status'],
        'blocked');
    expect(providerHealth['normal_ui_project_names_visible'], isFalse);
    expect(providerHealth['unverified_entries_marked_ready'], isFalse);
    expect(providerHealth['secret_plaintext_written'], isFalse);
    final healthEntries =
        (providerHealth['health_entries'] as List).cast<Map>();
    expect(healthEntries, hasLength(30));
    expect(healthEntries.every((entry) => entry['runtime_loaded'] == false),
        isTrue);
    final selectableHealthRefs = healthEntries
        .where((entry) => entry['selection_allowed'] == true)
        .map((entry) => entry['provider_ref'])
        .toSet();
    expect(selectableHealthRefs, {'mattpocock_skills', 'ai_marketing_skills'});
    expect(
        healthEntries.every((entry) => entry['secret_masked'] == true), isTrue);
    expect(
        healthEntries.map((entry) => entry['health_status']).toSet(),
        containsAll([
          '需安装外部服务',
          '已配置未测试',
          '已禁用',
          '需启动外部服务',
        ]));
    expect(
        healthEntries.every((entry) => entry.containsKey('blocked_reason_zh')),
        isTrue);
    final healthLogPath = providerHealth['health_log_path'] as String;
    expect(File(healthLogPath).readAsLinesSync(), hasLength(30));
    final stabilityPath = providerHealth['stability_report_path'] as String;
    final stability = jsonDecode(File(stabilityPath).readAsStringSync()) as Map;
    expect(stability['schema_version'],
        'prd_v3_registered_provider_hot_swap_stability_report.v1');
    expect(stability['provider_entry_count'], 30);
    expect(stability['runtime_loaded_count'], 0);
    expect(stability['external_runtime_load_allowed'], isFalse);
    expect((stability['stage_2_industrial_preflight'] as Map)['status'],
        'blocked');
    expect(stability['failure_isolation_validated'], isTrue);
    expect(stability['local_fallback_available'], isTrue);
    expect(stability['rollback_supported_count'], 30);
    expect(
        stability['unavailable_provider_does_not_block_local_chain'], isTrue);
    expect(stability['registered_project_names_visible_in_normal_ui'], isFalse);
    expect(stability['secret_plaintext_written'], isFalse);
    expect((stability['downstream_binding_checks'] as List), isNotEmpty);

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
    final selectionLog = File(
            '$configDir${Platform.pathSeparator}registered_provider_selection_log.jsonl')
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map)
        .toList(growable: false);
    expect(selectionLog.map((event) => event['action']),
        containsAll(['activate', 'rollback']));
    expect(
        selectionLog
            .firstWhere((event) => event['action'] == 'activate')['status'],
        '配置缺失');
    expect(
        selectionLog
            .every((event) => event['runtime_loaded_after_event'] == false),
        isTrue);
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
    expect(reloaded.state.exporterValidationReportPath,
        endsWith('exporter_validation_report.json'));
    expect(reloaded.state.parallelTaskCapacityReportPath,
        endsWith('parallel_task_capacity_report.json'));
    expect(reloaded.state.taskIsolationMatrixPath,
        endsWith('task_isolation_matrix.json'));
    expect(reloaded.state.taskRecoveryReportPath,
        endsWith('task_recovery_report.json'));
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
        3);
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

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], 4);
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
        2);
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

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], 3);
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
        3);
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

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], 4);
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
        2);
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

    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], 3);
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
      'retrieval_results': [
        {
          'title': 'real export evidence',
          'citation': 'input/source.md#chunk=1',
        }
      ],
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
    final health = jsonDecode(File(healthPath).readAsStringSync()) as Map;
    expect(health['ready_for_user_selection_count'], greaterThanOrEqualTo(4));
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
    File(launchLogPath).writeAsStringSync('CI-safe EXE launch smoke evidence');
    final fakeExePath =
        '${acceptanceDir.path}${Platform.pathSeparator}heitang_workbench.exe';
    File(fakeExePath).writeAsStringSync('windows exe placeholder for smoke');
    File('${acceptanceDir.path}${Platform.pathSeparator}exe_launch_smoke_report.json')
        .writeAsStringSync(jsonEncode({
      'schema_version': 'prd_v3_exe_launch_smoke_report.v1',
      'status': 'passed',
      'platform': 'windows',
      'exe_path': fakeExePath,
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
        isNot(contains('industrial_exe_launch_smoke')));
    final exeLaunchCheck = (launchPreflight['checks'] as List)
        .cast<Map>()
        .firstWhere(
            (check) => check['check_id'] == 'industrial_exe_launch_smoke');
    expect(exeLaunchCheck['status'], 'passed');
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
        allOf(
          contains('"selected_generation_config"'),
          contains('"skill_type": "product"'),
          contains('"target_platform": "markdown"'),
          contains('"personalization_goal": "agent_specific"'),
          contains('"custom_skill_name": "Owner 产品方法论 Skill"'),
        ));
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
        allOf(
          contains('"selected_generation_config"'),
          contains('"custom_agent_name": "Owner 产品分析 Agent"'),
          contains('"creation_mode": "advanced"'),
          contains('"agent_type": "product_analysis"'),
          contains('"model_config_id": "owner-provider-model"'),
          contains('"output_format": "json"'),
          contains('"role_goal": "以产品经理视角分析证据并输出可执行结论。"'),
        ));
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
        allOf(
          contains('"model_config_id": "owner-provider-model"'),
          contains('"role_goal": "以产品经理视角分析证据并输出可执行结论。"'),
          contains('"used_kb_ids"'),
          contains('"K1"'),
          contains('"used_skill_ids"'),
          contains('"S1"'),
        ));
    expect(
        dialogueManifest,
        allOf(
          contains('"output_format": "json"'),
          contains('"redis_config_id": "settings_redis_optional"'),
          contains(
              '"vector_config_id": "settings_agent_memory_vector_optional"'),
        ));
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
          contains('"operation_conversion_agent"'),
          contains('"product_analysis_agent"'),
        ));
    expect(
        File('$agentRoot${Platform.pathSeparator}audit${Platform.pathSeparator}run_history.json')
            .readAsStringSync(),
        allOf(
          contains('"action": "run_agent_dialogue"'),
          contains('"action": "run_a2a_discussion"'),
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
    expect(find.text('Agent 对话导出'), findsOneWidget);
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
