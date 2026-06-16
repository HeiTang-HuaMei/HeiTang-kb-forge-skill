import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_actions/core_action_panel.dart';
import 'package:heitang_workbench/core_actions/workbench_actions.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  const coreCommit = 'f5fa13bb11211abb0bcecaccd845e545a2dacad3';

  test('contract fixture parses p1 workbench contracts', () {
    final contracts = sampleWorkbenchContracts;

    expect(contracts.source.coreCommit, coreCommit);
    expect(contracts.manifest.outputFiles,
        contains('workbench_action_contracts.json'));
    expect(contracts.navigation.views, hasLength(18));
    expect(
        contracts.actions.actions.map((action) => action.id),
        containsAll([
          'workspace_inspect',
          'rag_query',
          'book_to_skill',
          'extract_methodology',
          'skill_governance_report',
          'run_agent'
        ]));
    expect(contracts.reports.reports.map((report) => report.id),
        contains('report_p1_gate_summary'));
    expect(contracts.reports.reports.map((report) => report.id),
        contains('report_skill_governance'));
    expect(contracts.assets.assets.map((asset) => asset.id),
        contains('skill_governance_report_json'));
    expect(contracts.assets.assets.map((asset) => asset.id),
        contains('methodology_map_json'));
    expect(
        contracts.taskSchema.statuses,
        containsAll(
            ['queued', 'running', 'blocked', 'degraded', 'review_required']));
    expect(contracts.templates.templates, hasLength(6));
    expect(contracts.gate.status, 'blocked');
    expect(contracts.gate.notV4WorkbenchRc, isTrue);
    expect(contracts.gate.uiFullOperationPending, isTrue);
  });

  test('p2.2 skill governance report asset parses as display evidence',
      () async {
    final report = jsonDecode(await rootBundle
            .loadString('assets/fixtures/p2_2/skill_governance_report.json'))
        as Map<String, dynamic>;
    final checks = report['checks'] as Map<String, dynamic>;
    final uiContract = report['ui_contract'] as Map<String, dynamic>;

    expect(report['skill_governance_report_version'], 'v4.2-p2.2-1');
    expect(report['status'], 'pass');
    expect(report['release_ready'], isTrue);
    expect(checks['generation']['status'], 'pass');
    expect(checks['validation']['status'], 'pass');
    expect(checks['diff_comparison']['status'], 'pass');
    expect(checks['diff_comparison']['baseline_provided'], isTrue);
    expect(checks['installability']['status'], 'pass');
    expect(checks['privacy_boundary']['local_first_default'], isTrue);
    expect(checks['token_budget']['recommended_load_policy'], 'on_demand');
    expect(report['warnings'], isEmpty);
    expect(uiContract['asset_id'], 'skill_governance_report_json');
    expect(uiContract['ready_for_workbench_display'], isTrue);
    expect(report['tests_require_real_llm_api_network'], isFalse);
  });

  test('p2.2 methodology map asset preserves evidence and risk boundary',
      () async {
    final methodology = jsonDecode(await rootBundle.loadString(
        'assets/fixtures/p2_2/methodology_map.json')) as Map<String, dynamic>;
    final modules = methodology['methodology_modules'] as List<dynamic>;
    final first = modules.first as Map<String, dynamic>;

    expect(methodology['methodology_map_version'], 'v4.2-p2.2-1');
    expect(methodology['module_count'], 2);
    expect(methodology['source_evidence'], ['window_001', 'window_002']);
    expect(first['source_evidence'], ['window_001']);
    expect(first['principles'], isNotEmpty);
    expect(first['decision_rules'], isNotEmpty);
    expect(first['workflows'], isNotEmpty);
    expect(methodology['risk_flags'], contains('missing_execution_evidence'));
    expect(methodology['unsupported_claim_detection']['status'], 'pass');
    expect(methodology['tests_require_real_llm_api_network'], isFalse);
  });

  test('p1 real workflow v1 evidence parses and keeps gate blocked', () async {
    final evidence = P1WorkflowEvidence.fromJsonString(await rootBundle
        .loadString('assets/workflows/p1_real_workflow_v1_evidence.json'));

    expect(evidence.coreCommit, coreCommit);
    expect(evidence.status, 'passed');
    expect(evidence.fullGateStatus, 'blocked');
    expect(evidence.readyForV4Rc, isFalse);
    expect(evidence.notV4WorkbenchRc, isTrue);
    expect(evidence.driftCount, 0);
    expect(evidence.fixtureOnlyCountedAsReal, isFalse);
    expect(evidence.fullReadyActionExecutionComplete, isFalse);
    expect(evidence.workflowCount, 8);
    expect(evidence.remainingBlockers,
        contains('full_57_ready_action_business_input_execution_not_complete'));
  });

  test(
      'p1 real workflow v2 evidence parses final local path closure without v4 release',
      () async {
    final evidence = P1WorkflowEvidence.fromJsonString(await rootBundle
        .loadString('assets/workflows/p1_real_workflow_v2_evidence.json'));

    expect(evidence.coreCommit, coreCommit);
    expect(evidence.status, 'passed');
    expect(evidence.fullGateStatus, 'ready_for_v4_rc');
    expect(evidence.uiFullOperationPending, isFalse);
    expect(evidence.readyForV4RcCandidate, isTrue);
    expect(evidence.readyForV4Rc, isTrue);
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
    expect(
        evidence.remainingRisks,
        contains(
            'provider_secret_network_actions_remain_explicit_config_only'));
    expect(evidence.actionResults.where((action) => action.status == 'passed'),
        hasLength(57));
    expect(evidence.blockedActions.map((action) => action.actionId),
        contains('provider_redaction_check'));
    expect(
        evidence.blockedActions
            .firstWhere(
                (action) => action.actionId == 'provider_redaction_check')
            .classification,
        'blocked_secret_required');
  });

  test(
      'p1 real workflow v2 copied report assets parse and match the fixture summary',
      () async {
    final matrix = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/full_ready_action_execution_matrix.json'))
        as Map<String, dynamic>;
    final actionResults = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/action_execution_result_index.json'))
        as Map<String, dynamic>;
    final artifactAssertions = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/action_artifact_assertion_report.json'))
        as Map<String, dynamic>;
    final reportAssertions = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/action_report_assertion_report.json'))
        as Map<String, dynamic>;
    final errorBoundary = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/action_error_boundary_report.json'))
        as Map<String, dynamic>;
    final userPaths = P1WorkflowEvidence.fromJson(jsonDecode(
            await rootBundle.loadString(
                'assets/workflows/p1_real_workflow_v2/full_local_user_path_closure_report.json'))
        as Map<String, dynamic>);
    final gateReport = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/p1_real_workflow_v2_report.json'))
        as Map<String, dynamic>;
    final remainingBlockers = jsonDecode(await rootBundle.loadString(
            'assets/workflows/p1_real_workflow_v2/remaining_blockers.json'))
        as Map<String, dynamic>;

    expect(matrix['ready_core_cli_action_count'], 62);
    expect(matrix['execution_target_count'], 57);
    expect(
        (matrix['actions'] as List)
            .where((action) => action['execution_target'] == true),
        hasLength(57));
    expect(
        (matrix['actions'] as List).where((action) =>
            action['classification'] == 'blocked_provider_required'),
        hasLength(4));
    expect(actionResults['passed_count'], 57);
    expect(actionResults['failed_count'], 0);
    expect(
        (actionResults['results'] as List)
            .where((action) => action['evidence_level'] == 'blocked'),
        hasLength(5));
    expect(artifactAssertions['status'], 'pass');
    expect(reportAssertions['status'], 'pass');
    expect(errorBoundary['status'], 'pass');
    expect(errorBoundary['external_provider_or_secret_actions_not_executed'],
        isTrue);
    expect(userPaths.userPathCount, 10);
    expect(userPaths.userPathPassedCount, 10);
    expect(userPaths.userPaths.first.actionCount, 6);
    expect(gateReport['p1_real_workflow_v2_status'], 'passed');
    expect(gateReport['p1_full_operation_gate_status'],
        'core_passed_pending_ui_consumption');
    expect(remainingBlockers['status'], 'blocked');
  });

  test('external capability assets parse as boundary-only S/A contract data',
      () async {
    final registry = ExternalCapabilityRegistry.fromJsonString(await rootBundle
        .loadString('assets/external/external_capability_registry.json'));
    final matrix = jsonDecode(await rootBundle
            .loadString('assets/external/s_a_contract_inclusion_matrix.json'))
        as Map<String, dynamic>;
    final projects = {
      for (final project in registry.projects) project.projectId: project
    };

    expect(registry.sProjectCount, 7);
    expect(registry.aProjectCount, 16);
    expect(registry.externalProjectCount, 23);
    expect(registry.internalCapabilityAnchorCount, 8);
    expect(registry.releaseBoundary['p1_gate_changed'], isFalse);
    expect(registry.releaseBoundary['v4_0_started'], isFalse);
    expect(registry.releaseBoundary['external_features_implemented'], isFalse);
    expect(
        registry.projects
            .every((project) => project.canExecuteLocallyBeforeV4 == false),
        isTrue);
    expect(projects['n8n']!.requiresExternalRuntime, isTrue);
    expect(projects['anysearchskill']!.requiresApiKey, isTrue);
    expect(projects['anysearchskill']!.requiresNetwork, isTrue);
    expect(projects['llm_wiki_v2']!.contractStatus, contains('future_adapter'));
    expect(projects['weknora']!.contractStatus, contains('future_adapter'));
    expect(matrix['external_project_count'], 23);
  });

  test('p2.1 parser backend matrix asset parses with release boundaries',
      () async {
    final matrix = ParserBackendMatrix.fromJsonString(await rootBundle
        .loadString('assets/parser_backends/parser_backend_matrix.json'));
    final backendIds =
        matrix.backends.map((backend) => backend.backendId).toSet();
    final docling = matrix.backend('docling')!;
    final paddleocr = matrix.backend('paddleocr')!;
    final unstructured = matrix.backend('unstructured')!;

    expect(matrix.schemaVersion, 'p2.1.parser_backend_matrix.v1');
    expect(matrix.releaseVersion, 'v4.1.0');
    expect(matrix.runtimeBaselineCommit,
        '576a62075dc1ecbe00388bb0569fd1fc767be7cb');
    expect(matrix.defaultHeavyDependenciesBundled, isFalse);
    expect(matrix.staticWorkbenchRuntimeExecutionClaimed, isFalse);
    expect(backendIds, {'builtin', 'docling', 'paddleocr', 'unstructured'});
    expect(
        matrix.backends
            .every((backend) => backend.staticWorkbenchExecutable == false),
        isTrue);
    expect(docling.optionalExtra, 'parser-docling');
    expect(docling.installMode.label, 'parser-docling');
    expect(docling.evidence.status, 'pass');
    expect(docling.workbenchState,
        containsAll(['real_runtime_integrated', 'optional_dependency_gated']));
    expect(paddleocr.validatedStableSurface, ['.png']);
    expect(unstructured.validatedStableSurface, ['.md', '.txt']);
    expect(unstructured.isLimitedSurface, isTrue);
    expect(unstructured.capabilityBoundary.staticWorkbenchExecutable, isFalse);
    expect(unstructured.knownLimitations.join(' '), contains('.md/.txt'));
    expect(unstructured.knownLimitations.join(' '),
        contains('not claimed stable in v4.1.0'));
  });

  test(
      'full p1 fixture drives real local and deterministic smoke Core actions through the bridge request path',
      () async {
    final contracts = const WorkbenchContractLoader().loadFromBundleJson(
        await rootBundle
            .loadString('assets/contracts/p1_core_contract_fixture.json'));
    const bridge = LocalCoreBridge();
    final realLocalActions = contracts.actions.actions
        .where((action) =>
            action.status == 'ready' &&
            action.commandKind == 'core_cli' &&
            action.desktopEnabled)
        .toList();
    final smokeActions = contracts.actions.actions
        .where((action) =>
            action.status == 'dry_run' &&
            action.commandKind == 'ui_safe_wrapper' &&
            action.desktopBlockedReason == 'mock_only')
        .toList();
    final blockedActions = contracts.actions.actions
        .where((action) =>
            !realLocalActions.contains(action) &&
            !smokeActions.contains(action))
        .toList();

    expect(contracts.actions.actions, hasLength(110));
    expect(realLocalActions, hasLength(57));
    expect(smokeActions, hasLength(36));
    expect(blockedActions, isNotEmpty);

    const futureRuntimeActions = <String>{
      'run_agent',
      'multi_agent_orchestration',
      'summary_memory_lifecycle',
      'memory_compression',
      'memory_cleanup',
      'artifact_runtime_trace_inspect',
      'artifact_memory_files_inspect',
    };
    final productExecutableActions = [
      ...realLocalActions,
      ...smokeActions,
    ].where((action) => !futureRuntimeActions.contains(action.id)).toList();
    final futureBoundaryActions = contracts.actions.actions
        .where((action) => futureRuntimeActions.contains(action.id))
        .toList();

    expect(productExecutableActions, isNotEmpty);
    expect(futureBoundaryActions, hasLength(futureRuntimeActions.length));

    for (final action in productExecutableActions) {
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

    for (final action in futureBoundaryActions) {
      final request = coreRequestForAction(
        action: action,
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      if (request != null) {
        expect(
          () => bridge.buildCommand(request),
          throwsA(isA<CoreBridgeException>()),
          reason: action.id,
        );
      }
    }

    for (final action in blockedActions) {
      final request = coreRequestForAction(
        action: action,
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNull, reason: action.id);
      expect(
          action.desktopBlockedReason.isNotEmpty ||
              action.blockedReason.isNotEmpty ||
              action.webBlockedReason.isNotEmpty,
          isTrue,
          reason: action.id);
    }
  });

  testWidgets(
      'renders desktop HeiTang workbench shell without Flutter exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖'), findsOneWidget);
    expect(find.text('HeiTang 黑糖'), findsNothing);
    expect(find.textContaining('知识工作台'), findsWidgets);
    expect(find.byKey(const Key('desktop-window-title-bar')), findsNothing);
    expect(find.byKey(const Key('desktop-topbar-single-row')), findsOneWidget);
    expect(find.byKey(const Key('desktop-window-controls')), findsOneWidget);
    expect(find.text('安全边界已启用'), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('topbar-search-field')), findsOneWidget);
    expect(find.text('通知'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_outlined), findsOneWidget);
    expect(find.textContaining('系统状态: 正常运行'), findsOneWidget);
    expect(find.textContaining('版本: v1.0.0'), findsOneWidget);
    expect(pages, hasLength(10));
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders narrow desktop-target shell without Flutter exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖'), findsOneWidget);
    expect(find.text('页面'), findsNothing);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps English and dark mode controls usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(find.text('HeiTang'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.textContaining('Knowledge Workbench'), findsWidgets);
    expect(find.byKey(const Key('desktop-window-title-bar')), findsNothing);
    expect(find.byKey(const Key('desktop-topbar-single-row')), findsOneWidget);
    expect(find.byKey(const Key('desktop-window-controls')), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders dedicated p1 pages without Flutter exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    for (final title in [
      '导入与解析',
      '文档库',
      '知识库',
      '检索与验证',
      '文档生成',
      'Skill 工厂',
      'Agent 工厂',
      '审计与报告',
      '设置',
    ]) {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.textContaining('blocked_reason'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'renders p1 real workflow v1 evidence while final V2 gate is ready',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        workflowEvidence: sampleP1WorkflowEvidence));
    await tester.pumpAndSettle();

    await tester.tap(find.text('仪表盘').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('passed · full_gate=blocked'), findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.textContaining('passed · full_gate=blocked'), findsWidgets);
    expect(find.textContaining('drift_count=0'), findsWidgets);
    expect(
        find.textContaining(
            'full_57_ready_action_business_input_execution_not_complete'),
        findsWidgets);
    expect(find.textContaining('ready_for_v4_rc=true'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'renders p1 real workflow v2 evidence and keeps v4 release boundary',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester.pumpWidget(HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        workflowV2Evidence: sampleP1WorkflowV2Evidence));
    await tester.pumpAndSettle();

    await tester.tap(find.text('仪表盘').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('passed · full_gate=ready_for_v4_rc'),
        findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.textContaining('passed · full_gate=ready_for_v4_rc'),
        findsWidgets);
    expect(find.textContaining('57/57 passed'), findsWidgets);
    expect(find.textContaining('artifact=pass · report=pass · error=pass'),
        findsWidgets);
    expect(find.textContaining('pass · 10/10 paths'), findsWidgets);
    expect(
        find.textContaining(
            'ui_full_operation_pending=false · rc_candidate=true · ready_for_v4_rc=true'),
        findsWidgets);
    expect(
        find.textContaining('provider_redaction_check:blocked_secret_required'),
        findsWidgets);
    expect(find.textContaining('ready_for_v4_rc=true'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'renders S/A external capability boundaries without executable claims',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        workflowV2Evidence: sampleP1WorkflowV2Evidence,
        externalCapabilities: sampleExternalCapabilityRegistry,
      ),
    );
    await tester.pump();

    expect(find.textContaining('S=1 · A=1'), findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.textContaining('S=1 · A=1'), findsWidgets);
    expect(find.textContaining('planned=1'), findsWidgets);
    expect(find.textContaining('ready=false'), findsWidgets);
    expect(find.textContaining('local_ready=false'), findsWidgets);
    expect(find.text('运行 Core 操作'), findsWidgets);

    await tester.tap(find.text('审计与报告').first);
    await tester.pump();
    expect(find.textContaining('LLM Wiki v2'), findsNothing);
    expect(
        find.textContaining('future_adapter/capability_anchor'), findsNothing);
    expect(find.text('开发者诊断'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'renders parser backend evidence without executable parser claims',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        parserBackends: sampleParserBackendMatrix,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('导入与解析').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-import-parsing')),
        findsOneWidget);
    expect(find.byKey(const Key('product-status-panel')), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);
    expect(find.byKey(const Key('import-queue')), findsOneWidget);
    expect(find.byKey(const Key('parser-settings')), findsOneWidget);
    expect(find.byKey(const Key('manifest-preview')), findsOneWidget);
    expect(find.text('文件队列与进度'), findsWidgets);
    expect(find.text('解析器 / OCR / 分块'), findsOneWidget);
    expect(find.text('Parser Backend Matrix'), findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.text('Parser Backend Matrix'), findsWidgets);
    expect(find.text('Parser/OCR 后端证据面板'), findsOneWidget);
    expect(find.text('Backend Matrix Table'), findsOneWidget);
    expect(find.text('Reports & Audit Evidence'), findsOneWidget);
    expect(find.textContaining('v4.1.0 · 4 backends · static_runtime=false'),
        findsWidgets);
    expect(find.textContaining('docling:parser-docling'), findsWidgets);
    expect(find.textContaining('paddleocr:parser-paddleocr'), findsWidgets);
    expect(find.textContaining('unstructured:.md/.txt'), findsWidgets);
    expect(find.textContaining('default_heavy_deps=false'), findsWidgets);
    expect(find.textContaining('static_runtime=false'), findsWidgets);
    expect(find.textContaining('Failure Mode Report'), findsOneWidget);
    expect(find.textContaining('Fresh Clone Reproducibility'), findsOneWidget);
    expect(find.textContaining('Static Web Workbench'), findsOneWidget);
    expect(find.textContaining('Run parser'), findsNothing);
    expect(find.textContaining('Execute parser'), findsNothing);
    expect(find.textContaining('运行解析后端'), findsNothing);

    await tester.tap(find.text('仪表盘').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('审计与报告').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the Skill Factory workflow without runtime claims',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(
      contracts: sampleWorkbenchContracts,
      initialSelectedIndex:
          pages.indexWhere((page) => page.id == 'skill-factory'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Skill 工厂'), findsWidgets);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);
    expect(find.text('Skill 元数据与来源配置'), findsOneWidget);
    expect(find.text('Skill 包结构预览'), findsOneWidget);
    expect(find.text('治理报告与验证'), findsOneWidget);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.text('开发者诊断'), findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.text('边界摘要'), findsOneWidget);
    expect(find.text('契约证据'), findsOneWidget);
    expect(find.text('只读边界证据'), findsWidgets);
    expect(find.text('显示边界'), findsNothing);
    expect(find.textContaining('Skill Governance Report'), findsWidgets);
    expect(find.textContaining('Execute local runtime'), findsNothing);
    expect(find.textContaining('运行本地 runtime'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('renders contract-driven action and agent mode data in English',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent Factory').first);
    await tester.pumpAndSettle();

    expect(find.text('Agent Runtime'), findsWidgets);
    expect(find.text('Execution Overview'), findsOneWidget);
    expect(find.text('Single Agents'), findsOneWidget);
    expect(find.text('Multi-Agent / Memory'), findsOneWidget);
    expect(find.text('Tool Adapter'), findsOneWidget);
    expect(find.byKey(const Key('campaign6-runtime-overview')), findsOneWidget);
    expect(find.text('campaign6a_single_agent_runtime'), findsOneWidget);
    await tester.tap(find.text('Single Agents'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('campaign6-single-agent-status')), findsOneWidget);
    expect(find.text('Knowledge QA Agent'), findsOneWidget);
    expect(find.text('External Verification Agent'), findsOneWidget);
    await tester.tap(find.text('Multi-Agent / Memory'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campaign6-advanced-runtime-status')),
        findsOneWidget);
    expect(find.text('long_term_memory'), findsOneWidget);
    expect(find.text('agent_teams'), findsOneWidget);
    final toolAdapter = find.text('Tool Adapter');
    await tester.ensureVisible(toolAdapter);
    await tester.tap(toolAdapter);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('campaign6-tool-adapter-status')), findsOneWidget);
    expect(find.text('provider_runtime_reimplemented'), findsOneWidget);
    expect(find.text('Action Capability Boundary'), findsNothing);
    expect(find.text('Agent Package'), findsNothing);
    expect(find.text('Create Agent draft'), findsNothing);
    expect(find.text('Save Version and Export Agent package'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.textContaining('run_agent'), findsNothing);
    expect(find.textContaining('kb_bound'), findsNothing);
    expect(find.text('Developer Diagnostics'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'runs the desktop rag_query core action through an injected bridge',
      (tester) async {
    final requests = <CoreBridgeRequest>[];
    final bridge = LocalCoreBridge(
      runner: (request) async {
        requests.add(request);
        return const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'answer token=sk-test-secret', stderr: '');
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

    await tester.tap(find.text('知识库').first);
    await tester.pumpAndSettle();
    await openDeveloperDiagnostics(tester);
    expect(find.text('Run RAG query'), findsOneWidget);

    final ragPanel = find.widgetWithText(CoreActionPanel, 'Run RAG query');
    final runButton = find.descendant(
      of: ragPanel,
      matching: find.text('运行 Core 操作'),
    );
    await tester.ensureVisible(runButton);
    await tester.pumpAndSettle();
    await tester.tap(runButton);
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.actionId, 'rag_query');
    expect(requests.single.arguments.first, 'kb-query');
    expect(find.textContaining('<redacted>'), findsNothing);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core action clears running state after bridge startup failure',
      (tester) async {
    final bridge = LocalCoreBridge(
      runner: (request) async {
        throw StateError('missing cli token=sk-test-secret');
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

    await tester.tap(find.text('知识库').first);
    await tester.pumpAndSettle();
    await openDeveloperDiagnostics(tester);
    final ragPanel = find.widgetWithText(CoreActionPanel, 'Run RAG query');
    final runButton = find.descendant(
      of: ragPanel,
      matching: find.text('运行 Core 操作'),
    );
    await tester.ensureVisible(runButton);
    await tester.pumpAndSettle();
    await tester.tap(runButton);
    await tester.pumpAndSettle();

    expect(find.text('运行中'), findsNothing);
    expect(find.byKey(const Key('core-action-cancel')), findsNothing);
    expect(find.textContaining('core_operation_start_failed'), findsOneWidget);
    expect(find.textContaining('<redacted>'), findsWidgets);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'disables local CLI actions on web runtime without calling the runner',
      (tester) async {
    var runnerCalled = false;
    final bridge = LocalCoreBridge(
      runner: (request) async {
        runnerCalled = true;
        return const CoreBridgeProcessResult(
            exitCode: 0, stdout: 'unexpected', stderr: '');
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

    await tester.tap(find.text('知识库').first);
    await tester.pumpAndSettle();
    await openDeveloperDiagnostics(tester);
    final ragPanel = find.widgetWithText(CoreActionPanel, 'Run RAG query');
    final runButton = find.descendant(
      of: ragPanel,
      matching: find.byType(FilledButton),
    );
    final button = tester.widget<FilledButton>(runButton);

    expect(button.onPressed, isNull);
    expect(find.textContaining('web_local_cli_unsupported'), findsNothing);
    expect(find.text('当前环境不可执行本地命令。'), findsWidgets);
    expect(runnerCalled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides blocked reasons until advanced details are opened',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts, isWebRuntime: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('知识库').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('blocked_reason'), findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.textContaining('provider_required'), findsWidgets);

    await tester.tap(find.text('审计与报告').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('blocked_reason'), findsNothing);
    await openDeveloperDiagnostics(tester);
    expect(find.textContaining('secret_required'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> openDeveloperDiagnostics(WidgetTester tester) async {
  if (find.byType(DropdownButtonFormField<int>).evaluate().isNotEmpty) {
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    final settingsItem = find.text('设置').evaluate().isNotEmpty
        ? find.text('设置').last
        : find.text('Settings').last;
    await tester.tap(settingsItem);
    await tester.pumpAndSettle();
  } else {
    final settings = find.text('设置').evaluate().isNotEmpty
        ? find.text('设置').first
        : find.text('Settings').first;
    await tester.tap(settings);
    await tester.pumpAndSettle();
  }

  final diagnosticsTab = find.text('开发者诊断').evaluate().isNotEmpty
      ? find.text('开发者诊断').first
      : find.text('Developer Diagnostics').first;
  await tester.ensureVisible(diagnosticsTab);
  await tester.tap(diagnosticsTab, warnIfMissed: false);
  await tester.pumpAndSettle();

  final details = find.byKey(const Key('developer-diagnostics-details')).first;
  await tester.ensureVisible(details);
  await tester.pumpAndSettle();
  await tester.tap(details, warnIfMissed: false);
  await tester.pumpAndSettle();
}
