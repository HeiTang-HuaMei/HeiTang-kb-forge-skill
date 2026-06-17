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

  Future<void> pumpWorkbench(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    final workspace = await createWorkspace();
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

  testWidgets('rc6 document library binds to real runtime state',
      (tester) async {
    await pumpWorkbench(tester);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-library')));
    await tester.tap(find.byKey(const Key('sidebar-document-library')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('document-library')), findsOneWidget);
    expect(find.text('等待导入真实文档'), findsOneWidget);
    expect(find.textContaining('display_only'), findsWidgets);
    expect(find.textContaining('示例行保持'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc6 retrieval tabs switch visible content and keep boundaries',
      (tester) async {
    await pumpWorkbench(tester);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-retrieval-verification')));
    await tester.tap(find.byKey(const Key('sidebar-retrieval-verification')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);

    await tester.tap(find.text('证据结果').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-evidence-results')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('page-tab-1')),
            matching: find.byIcon(Icons.check)),
        findsOneWidget);

    await tester.tap(find.text('外部边界').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('retrieval-external-boundary')), findsOneWidget);
    expect(find.textContaining('Computer Use'), findsWidgets);
    expect(find.textContaining('disabled_boundary'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc6 skill and agent pages expose real runtime surfaces',
      (tester) async {
    await pumpWorkbench(tester);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('来源配置'), findsOneWidget);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);

    await tester.tap(find.text('包结构').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);

    await tester.tap(find.text('治理报告').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-agent-factory-runtime')));
    await tester.tap(find.byKey(const Key('sidebar-agent-factory-runtime')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rc6-runtime-truth-panel')), findsWidgets);
    expect(find.text('搜索当前关键词'), findsWidgets);
    expect(find.text('生成 Agent'), findsWidgets);
    expect(find.text('Agent 草稿'), findsWidgets);
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
}
