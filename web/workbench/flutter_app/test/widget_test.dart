import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_actions/workbench_actions.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  test('contract fixture parses p1 workbench contracts', () {
    final contracts = sampleWorkbenchContracts;

    expect(contracts.source.coreCommit, 'fa00d6c00a11e7fda62919318f4cf17f9b72bfd9');
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

  test('p1 real workflow v1 evidence parses and keeps gate blocked', () async {
    final evidence = P1WorkflowEvidence.fromJsonString(await rootBundle.loadString('assets/workflows/p1_real_workflow_v1_evidence.json'));

    expect(evidence.coreCommit, 'fa00d6c00a11e7fda62919318f4cf17f9b72bfd9');
    expect(evidence.status, 'passed');
    expect(evidence.fullGateStatus, 'blocked');
    expect(evidence.readyForV4Rc, isFalse);
    expect(evidence.notV4WorkbenchRc, isTrue);
    expect(evidence.driftCount, 0);
    expect(evidence.fixtureOnlyCountedAsReal, isFalse);
    expect(evidence.fullReadyActionExecutionComplete, isFalse);
    expect(evidence.workflowCount, 8);
    expect(evidence.remainingBlockers, contains('full_57_ready_action_business_input_execution_not_complete'));
  });

  test('full p1 fixture drives real local and deterministic smoke Core actions through the bridge request path', () async {
    final contracts = const WorkbenchContractLoader().loadFromBundleJson(await rootBundle.loadString('assets/contracts/p1_core_contract_fixture.json'));
    const bridge = LocalCoreBridge();
    final realLocalActions = contracts.actions.actions.where((action) => action.status == 'ready' && action.commandKind == 'core_cli' && action.desktopEnabled).toList();
    final smokeActions = contracts.actions.actions.where((action) => action.status == 'dry_run' && action.commandKind == 'ui_safe_wrapper' && action.desktopBlockedReason == 'mock_only').toList();
    final blockedActions = contracts.actions.actions.where((action) => !realLocalActions.contains(action) && !smokeActions.contains(action)).toList();

    expect(contracts.actions.actions, hasLength(110));
    expect(realLocalActions, hasLength(57));
    expect(smokeActions, hasLength(36));
    expect(blockedActions, isNotEmpty);

    for (final action in [...realLocalActions, ...smokeActions]) {
      final request = coreRequestForAction(
        action: action,
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNotNull, reason: action.id);
      final command = bridge.buildCommand(request!);
      expect(command.first, 'heitang-kb-forge', reason: action.id);
      expect(command[1], request.arguments.first, reason: action.id);
    }

    for (final action in blockedActions) {
      final request = coreRequestForAction(
        action: action,
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNull, reason: action.id);
      expect(action.desktopBlockedReason.isNotEmpty || action.blockedReason.isNotEmpty || action.webBlockedReason.isNotEmpty, isTrue, reason: action.id);
    }
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

    for (final title in ['工作空间', '向量索引 / 提供方 / 存储', '技能工厂', '任务 / 作业中心', '产物管理', '错误修复中心', '运行门禁', '能力矩阵', '报表与审计']) {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.textContaining('Core'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders p1 real workflow v1 evidence without claiming full gate pass', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts, workflowEvidence: sampleP1WorkflowEvidence));
    await tester.pumpAndSettle();

    await tester.tap(find.text('运行门禁').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('passed · full_gate=blocked'), findsWidgets);
    expect(find.textContaining('drift_count=0'), findsWidgets);
    expect(find.textContaining('full_57_ready_action_business_input_execution_not_complete'), findsWidgets);
    expect(find.textContaining('ready_for_v4_rc'), findsNothing);
    expect(tester.takeException(), isNull);
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
