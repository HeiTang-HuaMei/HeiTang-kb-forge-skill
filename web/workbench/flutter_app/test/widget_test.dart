import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_actions/workbench_actions.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  const coreCommit = 'f9c9718666376adf8540fea075f916b3f22b85e4';

  test('contract fixture parses p1 workbench contracts', () {
    final contracts = sampleWorkbenchContracts;

    expect(contracts.source.coreCommit, coreCommit);
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

    expect(evidence.coreCommit, coreCommit);
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

  test('p1 real workflow v2 evidence parses final local path closure without v4 release', () async {
    final evidence = P1WorkflowEvidence.fromJsonString(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2_evidence.json'));

    expect(evidence.coreCommit, coreCommit);
    expect(evidence.status, 'passed');
    expect(evidence.fullGateStatus, 'passed_for_v4_rc_candidate');
    expect(evidence.uiFullOperationPending, isFalse);
    expect(evidence.readyForV4RcCandidate, isTrue);
    expect(evidence.readyForV4Rc, isFalse);
    expect(evidence.notV4WorkbenchRc, isTrue);
    expect(evidence.driftCount, 0);
    expect(evidence.fixtureOnlyCountedAsReal, isFalse);
    expect(evidence.fullReadyActionExecutionComplete, isTrue);
    expect(evidence.readyCoreCliActionCount, 62);
    expect(evidence.executionTargetCount, 57);
    expect(evidence.passedActionCount, 57);
    expect(evidence.failedActionCount, 0);
    expect(evidence.blockedActionCount, 5);
    expect(evidence.artifactAssertionStatus, 'pass');
    expect(evidence.reportAssertionStatus, 'pass');
    expect(evidence.errorBoundaryStatus, 'pass');
    expect(evidence.userPathClosureStatus, 'pass');
    expect(evidence.userPathCount, 10);
    expect(evidence.userPathPassedCount, 10);
    expect(evidence.remainingBlockers, isEmpty);
    expect(evidence.remainingRisks, contains('provider_secret_network_actions_remain_explicit_config_only'));
    expect(evidence.actionResults.where((action) => action.status == 'passed'), hasLength(57));
    expect(evidence.blockedActions.map((action) => action.actionId), contains('provider_redaction_check'));
    expect(evidence.blockedActions.firstWhere((action) => action.actionId == 'provider_redaction_check').classification, 'blocked_secret_required');
  });

  test('p1 real workflow v2 copied report assets parse and match the fixture summary', () async {
    final matrix = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/full_ready_action_execution_matrix.json')) as Map<String, dynamic>;
    final actionResults = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/action_execution_result_index.json')) as Map<String, dynamic>;
    final artifactAssertions = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/action_artifact_assertion_report.json')) as Map<String, dynamic>;
    final reportAssertions = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/action_report_assertion_report.json')) as Map<String, dynamic>;
    final errorBoundary = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/action_error_boundary_report.json')) as Map<String, dynamic>;
    final userPaths = P1WorkflowEvidence.fromJson(jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/full_local_user_path_closure_report.json')) as Map<String, dynamic>);
    final gateReport = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/p1_real_workflow_v2_report.json')) as Map<String, dynamic>;
    final remainingBlockers = jsonDecode(await rootBundle.loadString('assets/workflows/p1_real_workflow_v2/remaining_blockers.json')) as Map<String, dynamic>;

    expect(matrix['ready_core_cli_action_count'], 62);
    expect(matrix['execution_target_count'], 57);
    expect((matrix['actions'] as List).where((action) => action['execution_target'] == true), hasLength(57));
    expect((matrix['actions'] as List).where((action) => action['classification'] == 'blocked_provider_required'), hasLength(4));
    expect(actionResults['passed_count'], 57);
    expect(actionResults['failed_count'], 0);
    expect((actionResults['results'] as List).where((action) => action['evidence_level'] == 'blocked'), hasLength(5));
    expect(artifactAssertions['status'], 'pass');
    expect(reportAssertions['status'], 'pass');
    expect(errorBoundary['status'], 'pass');
    expect(errorBoundary['external_provider_or_secret_actions_not_executed'], isTrue);
    expect(userPaths.userPathCount, 10);
    expect(userPaths.userPathPassedCount, 10);
    expect(userPaths.userPaths.first.actionCount, 6);
    expect(gateReport['p1_real_workflow_v2_status'], 'passed');
    expect(gateReport['p1_full_operation_gate_status'], 'core_passed_pending_ui_consumption');
    expect(remainingBlockers['status'], 'blocked');
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

  testWidgets('renders p1 real workflow v2 evidence and keeps v4 release boundary', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts, workflowV2Evidence: sampleP1WorkflowV2Evidence));
    await tester.pumpAndSettle();

    await tester.tap(find.text('运行门禁').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('passed · full_gate=passed_for_v4_rc_candidate'), findsWidgets);
    expect(find.textContaining('57/57 passed'), findsWidgets);
    expect(find.textContaining('artifact=pass · report=pass · error=pass'), findsWidgets);
    expect(find.textContaining('pass · 10/10 paths'), findsWidgets);
    expect(find.textContaining('ui_full_operation_pending=false · rc_candidate=true'), findsWidgets);
    expect(find.textContaining('provider_redaction_check:blocked_secret_required'), findsWidgets);
    expect(find.textContaining('ready_for_v4_rc=true'), findsNothing);
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
