import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  test('contract fixture parses p1 workbench contracts', () {
    final contracts = sampleWorkbenchContracts;

    expect(contracts.source.coreCommit, '1e786cd1da1f557cd22eae622a721c431902e6b4');
    expect(contracts.manifest.outputFiles, contains('workbench_action_contracts.json'));
    expect(contracts.navigation.views, hasLength(18));
    expect(contracts.actions.actions.map((action) => action.id), containsAll(['workspace_inspect', 'rag_query', 'book_to_skill', 'run_agent']));
    expect(contracts.reports.reports.map((report) => report.id), contains('report_p1_gate_summary'));
    expect(contracts.taskSchema.statuses, containsAll(['queued', 'running', 'blocked', 'review_required']));
    expect(contracts.templates.templates, hasLength(6));
    expect(contracts.gate.status, 'blocked');
    expect(contracts.gate.notV4WorkbenchRc, isTrue);
    expect(contracts.gate.uiFullOperationPending, isTrue);
  });

  testWidgets('renders desktop HeiTang workbench shell without Flutter exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(pages, hasLength(18));
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

  testWidgets('renders dedicated p1 pages without Flutter exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    for (final title in ['工作空间', '向量索引 / 提供方 / 存储', '技能工厂', '产物管理', '错误修复中心', '运行门禁', '能力矩阵']) {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.textContaining('Core'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders contract-driven action and agent mode data in English', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent Factory & Runtime').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('run_agent'), findsWidgets);
    expect(find.textContaining('kb_bound'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs the desktop rag_query core action through an injected bridge', (tester) async {
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

    await tester.tap(find.text('检索与验证').first);
    await tester.pumpAndSettle();
    expect(find.text('Run RAG query'), findsOneWidget);

    await tester.tap(find.text('运行 Core 操作'));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.actionId, 'rag_query');
    expect(requests.single.arguments.first, 'kb-query');
    expect(find.textContaining('<redacted>'), findsWidgets);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables local CLI actions on web runtime without calling the runner', (tester) async {
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

    await tester.tap(find.text('Agent 工厂与运行').first);
    await tester.pumpAndSettle();
    expect(find.text('Run Agent'), findsOneWidget);
    expect(find.textContaining('blocked_reason: web_local_cli_unsupported'), findsOneWidget);

    await tester.tap(find.text('运行 Core 操作'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(runnerCalled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows disabled blocked_reason for provider and secret actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts, isWebRuntime: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('向量索引 / 提供方 / 存储').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('blocked_reason: provider_required'), findsOneWidget);

    await tester.tap(find.text('错误修复中心').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('blocked_reason: secret_required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
