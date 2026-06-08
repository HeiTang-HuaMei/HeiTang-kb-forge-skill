import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  test('contract fixture parses core workbench contracts', () {
    final contracts = sampleWorkbenchContracts;

    expect(contracts.manifest.outputFiles, contains('workbench_navigation_contract.json'));
    expect(contracts.navigation.views, hasLength(14));
    expect(contracts.actions.actions.map((action) => action.id), contains('generate_documents'));
    expect(contracts.agent.supportedModes, containsAll(['standalone', 'kb_bound']));
    expect(contracts.hierarchy.bindingFields, containsAll(['parent', 'child', 'child_mode', 'bound_kbs']));
    expect(contracts.memory.lifecycleFields, contains('token_budget_policy'));
    expect(contracts.storage.storageAreas.keys, containsAll(['package_storage', 'skill_storage', 'agent_storage', 'memory_storage', 'index_storage']));
    expect(contracts.errors.errorStates, contains('contract_file_missing'));
  });

  testWidgets('renders desktop HeiTang workbench shell without Flutter exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(pages, hasLength(14));
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders mobile HeiTang workbench shell without Flutter exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('页面'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps English and dark mode controls usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(find.text('HeiTang'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders contract-driven agent hierarchy memory and storage pages', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1120));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('多 Agent 工作流').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('parent'), findsWidgets);
    expect(find.textContaining('standalone'), findsWidgets);

    await tester.tap(find.text('记忆范围查看器').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('explicit_only'), findsWidgets);
    expect(find.textContaining('queue_memory_writeback'), findsWidgets);

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('local_workspace'), findsWidgets);
    expect(find.textContaining('package_storage'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders contract-driven action and agent mode data in English', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent / Skill management').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('standalone'), findsWidgets);
    expect(find.textContaining('kb_bound'), findsWidgets);
    expect(find.textContaining('retrieval_config.yaml'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs the desktop kb_query core action through an injected bridge', (tester) async {
    final requests = <CoreBridgeRequest>[];
    final bridge = LocalCoreBridge(
      runner: (request) async {
        requests.add(request);
        return const CoreBridgeProcessResult(exitCode: 0, stdout: 'answer token=sk-test-secret', stderr: '');
      },
    );

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        coreBridge: bridge,
        coreCli: 'heitang-kb-forge',
        coreWorkspace: 'fixture_workspace',
        isWebRuntime: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('知识库查询').first);
    await tester.pumpAndSettle();
    expect(find.text('Query / Verify KB'), findsOneWidget);

    await tester.tap(find.text('运行 Core 操作'));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.actionId, 'kb_query');
    expect(requests.single.arguments.first, 'kb-answer');
    expect(find.textContaining('<redacted>'), findsWidgets);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks the run_agent action on web runtime without calling the runner', (tester) async {
    var runnerCalled = false;
    final bridge = LocalCoreBridge(
      runner: (request) async {
        runnerCalled = true;
        return const CoreBridgeProcessResult(exitCode: 0, stdout: 'unexpected', stderr: '');
      },
    );

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        coreBridge: bridge,
        coreCli: 'heitang-kb-forge',
        isWebRuntime: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agent / Skill 管理').first);
    await tester.pumpAndSettle();
    expect(find.text('Run Local Agent'), findsOneWidget);

    await tester.tap(find.text('运行 Core 操作'));
    await tester.pumpAndSettle();

    expect(runnerCalled, isFalse);
    expect(find.text('blocked'), findsWidgets);
    expect(find.text('core_bridge_web_unsupported'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
