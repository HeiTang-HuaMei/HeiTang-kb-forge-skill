import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_actions/page_action_mapping.dart';
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
    expect(contracts.taskSchema.statuses,
        containsAll(['queued', 'running', 'blocked', 'review_required']));
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

  test(
      'import parsing maps document backend actions to the desktop bridge only',
      () {
    final actions =
        coreActionsForPage('import-parsing', sampleWorkbenchContracts);
    const expectedCommands = <String, String>{
      'preflight_documents': 'preflight-documents',
      'batch_import_documents': 'batch-import-documents',
      'run_document_understanding': 'run-document-understanding',
      'fallback_parser_contract': 'fallback-parser-contract',
      'check_marker_backend': 'check-marker-backend',
      'smoke_marker_backend': 'smoke-marker-backend',
      'run_marker_convert': 'run-marker-convert',
      'check_docling_backend': 'check-docling-backend',
      'smoke_docling_backend': 'smoke-docling-backend',
      'run_docling_convert': 'run-docling-convert',
      'check_unstructured_backend': 'check-unstructured-backend',
      'smoke_unstructured_backend': 'smoke-unstructured-backend',
      'check_mineru_backend': 'check-mineru-backend',
      'smoke_mineru_backend': 'smoke-mineru-backend',
      'run_mineru_document_understanding': 'run-mineru-document-understanding',
      'check_opendataloader_backend': 'check-opendataloader-backend',
      'smoke_opendataloader_backend': 'smoke-opendataloader-backend',
      'run_opendataloader_convert': 'run-opendataloader-convert',
      'check_paddleocr_backend': 'check-paddleocr-backend',
      'smoke_paddleocr_backend': 'smoke-paddleocr-backend',
      'run_paddleocr_ocr': 'run-paddleocr-ocr',
    };
    const bridge = LocalCoreBridge();

    expect(
        actions.map((action) => action.id), containsAll(expectedCommands.keys));
    for (final action
        in actions.where((item) => expectedCommands.containsKey(item.id))) {
      expect(action.desktopEnabled, isTrue, reason: action.id);
      expect(action.webEnabled, isFalse, reason: action.id);
      expect(action.webBlockedReason, 'web_local_cli_unsupported',
          reason: action.id);
      final request = coreRequestForAction(
        action: action,
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNotNull, reason: action.id);
      expect(request!.arguments.first, expectedCommands[action.id]);
      expect(bridge.buildCommand(request)[1], expectedCommands[action.id]);
      if (action.id.contains('marker')) {
        expect(request.environment['MODEL_CACHE_DIR'],
            r'C:\workspace\.heitang\runtime_cache\marker');
        expect(request.environment['HEITANG_MARKER_MODEL_CACHE'],
            r'C:\workspace\.heitang\runtime_cache\marker');
      }
      expect(
        () => bridge.buildCommand(request, isWeb: true),
        throwsA(isA<CoreBridgeException>().having((error) => error.errorId,
            'errorId', 'core_bridge_web_unsupported')),
        reason: action.id,
      );
    }
    for (final action in actions.where((item) => item.id.contains('surya'))) {
      expect(action.status, 'blocked', reason: action.id);
      expect(action.desktopEnabled, isFalse, reason: action.id);
      expect(action.desktopBlockedReason,
          'surya_reference_benchmark_dependency_remediation_pending',
          reason: action.id);
      expect(
        coreRequestForAction(
          action: action,
          coreCli: 'python',
          workingDirectory: r'C:\repo',
          workspace: r'C:\workspace',
        ),
        isNull,
        reason: action.id,
      );
    }
  });

  test('knowledge workflow actions map DU to KB to package paths', () {
    final actions = coreActionsForPage(
        'knowledge-package-management', sampleWorkbenchContracts);
    final byId = {for (final action in actions) action.id: action};
    const bridge = LocalCoreBridge();

    for (final entry in const <String, String>{
      'build_knowledge_base': 'build-knowledge-base',
      'build_knowledge_package': 'build-knowledge-package',
    }.entries) {
      final request = coreRequestForAction(
        action: byId[entry.key]!,
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNotNull);
      expect(request!.arguments.first, entry.value);
      expect(bridge.buildCommand(request)[1], entry.value);
      expect(request.arguments, contains('--progress-jsonl'));
    }
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

  test('external capability assets preserve boundaries and current provider status',
      () async {
    final registry = ExternalCapabilityRegistry.fromJsonString(await rootBundle
        .loadString('assets/external/external_capability_registry.json'));
    final matrix = jsonDecode(await rootBundle
            .loadString('assets/external/s_a_contract_inclusion_matrix.json'))
        as Map<String, dynamic>;
    final projects = {
      for (final project in registry.projects) project.projectId: project
    };

    expect(registry.sProjectCount, 8);
    expect(registry.aProjectCount, 18);
    expect(registry.externalProjectCount, 26);
    expect(registry.internalCapabilityAnchorCount, 8);
    expect(registry.releaseBoundary['p1_gate_changed'], isFalse);
    expect(registry.releaseBoundary['v4_0_started'], isFalse);
    expect(registry.releaseBoundary['external_features_implemented'], isTrue);
    expect(
        registry.projects
            .every((project) => project.canExecuteLocallyBeforeV4 == false),
        isTrue);
    expect(projects['n8n']!.requiresExternalRuntime, isTrue);
    expect(projects['anysearchskill']!.requiresApiKey, isFalse);
    expect(projects['anysearchskill']!.requiresNetwork, isTrue);
    expect(projects['anysearchskill']!.contractStatus,
        containsAll(['provider_adapter', 'real_smoke_passed', 'needs_strengthening']));
    expect(projects['anysearchskill']!.blockedReason,
        'ui_configuration_pending');
    expect(projects['llm_wiki_v2']!.contractStatus,
        containsAll(['capability_fusion', 'real_integration']));
    expect(projects['weknora']!.contractStatus,
        containsAll(['capability_fusion', 'real_integration']));
    expect(projects['n8n']!.contractStatus,
        containsAll(['workflow_export_adapter', 'export_validation_passed']));
    expect(projects['skill_prompt_generator']!.contractStatus,
        containsAll(['prompt_asset_library_enhancer', 'real_integration']));
    expect(projects['skill_prompt_generator']!.uiVisibility, 'visible_status_only');
    expect(projects['skill_prompt_generator']!.canExecuteLocallyBeforeV4, isFalse);
    expect(projects['mmskills']!.contractStatus,
        containsAll(['schema_package_reference', 'reference_only']));
    expect(projects['mmskills']!.uiVisibility, 'visible_status_only');
    expect(projects['mmskills']!.canExecuteLocallyBeforeV4, isFalse);
    expect(projects['jellyfish']!.contractStatus,
        containsAll(['content_asset_schema_reference', 'reference_only', 'runtime_not_bundled']));
    expect(projects['jellyfish']!.uiVisibility, 'visible_status_only');
    expect(projects['jellyfish']!.ready, isFalse);
    expect(projects['jellyfish']!.localReady, isTrue);
    expect(projects['jellyfish']!.executableAction, isFalse);
    expect(projects['jellyfish']!.canExecuteLocallyBeforeV4, isFalse);
    expect(projects['jellyfish']!.requiresNetwork, isFalse);
    expect(projects['jellyfish']!.requiresExternalRuntime, isFalse);
    expect(projects['jellyfish']!.relatedWorkbenchPageIds,
        containsAll(['template_library', 'artifact_management', 'document_generation']));
    expect(projects['story_flicks']!.contractStatus,
        containsAll(['aigc_video_pipeline_schema_reference', 'reference_only', 'runtime_not_bundled']));
    expect(projects['story_flicks']!.uiVisibility, 'visible_status_only');
    expect(projects['story_flicks']!.ready, isFalse);
    expect(projects['story_flicks']!.localReady, isTrue);
    expect(projects['story_flicks']!.executableAction, isFalse);
    expect(projects['story_flicks']!.canExecuteLocallyBeforeV4, isFalse);
    expect(projects['story_flicks']!.requiresNetwork, isFalse);
    expect(projects['story_flicks']!.requiresExternalRuntime, isFalse);
      expect(projects['story_flicks']!.relatedWorkbenchPageIds,
          containsAll(['template_library', 'artifact_management', 'document_generation']));
      expect(projects['seedance2_skill']!.contractStatus,
          containsAll([
            'verified_video_skill_template_metadata',
            'reference_only',
            'template_reference',
            'provider_not_integrated',
            'runtime_not_bundled'
          ]));
      expect(projects['seedance2_skill']!.uiVisibility, 'visible_status_only');
      expect(projects['seedance2_skill']!.ready, isFalse);
      expect(projects['seedance2_skill']!.localReady, isTrue);
      expect(projects['seedance2_skill']!.executableAction, isFalse);
      expect(projects['seedance2_skill']!.canExecuteLocallyBeforeV4, isFalse);
      expect(projects['seedance2_skill']!.requiresApiKey, isTrue);
      expect(projects['seedance2_skill']!.requiresNetwork, isTrue);
      expect(projects['seedance2_skill']!.requiresExternalRuntime, isFalse);
      expect(projects['seedance2_skill']!.relatedWorkbenchPageIds,
          containsAll(['template_library', 'artifact_management', 'document_generation']));
      expect(projects['rag_anything']!.contractStatus,
          containsAll([
            'cross_modal_rag_schema_reference',
            'reference_only',
            'runtime_not_bundled'
          ]));
      expect(projects['rag_anything']!.uiVisibility, 'visible_status_only');
      expect(projects['rag_anything']!.ready, isFalse);
      expect(projects['rag_anything']!.localReady, isTrue);
      expect(projects['rag_anything']!.executableAction, isFalse);
      expect(projects['rag_anything']!.canExecuteLocallyBeforeV4, isFalse);
      expect(projects['rag_anything']!.requiresApiKey, isFalse);
      expect(projects['rag_anything']!.requiresNetwork, isFalse);
      expect(projects['rag_anything']!.requiresExternalRuntime, isFalse);
      expect(projects['rag_anything']!.relatedWorkbenchPageIds,
          containsAll(['retrieval_verification', 'reports_audit']));
      expect(projects['mattpocock_skills']!.contractStatus,
          containsAll([
            'engineering_governance_rule_pack',
            'real_integration',
            'runtime_not_bundled'
          ]));
      expect(projects['mattpocock_skills']!.uiVisibility, 'visible_status_only');
      expect(projects['mattpocock_skills']!.ready, isFalse);
      expect(projects['mattpocock_skills']!.localReady, isTrue);
      expect(projects['mattpocock_skills']!.executableAction, isFalse);
      expect(projects['mattpocock_skills']!.canExecuteLocallyBeforeV4, isFalse);
      expect(projects['mattpocock_skills']!.requiresApiKey, isFalse);
      expect(projects['mattpocock_skills']!.requiresNetwork, isFalse);
      expect(projects['mattpocock_skills']!.requiresExternalRuntime, isFalse);
      expect(projects['mattpocock_skills']!.relatedWorkbenchPageIds,
          containsAll(['governance', 'reports_audit']));
      expect(projects['sirchmunk']!.contractStatus,
          containsAll([
            'bounded_direct_file_search_provider',
            'real_integration',
            'runtime_not_bundled',
            'embedding_free',
            'vector_db_not_required'
          ]));
      expect(projects['sirchmunk']!.uiVisibility, 'visible_status_only');
      expect(projects['sirchmunk']!.ready, isFalse);
      expect(projects['sirchmunk']!.localReady, isTrue);
      expect(projects['sirchmunk']!.executableAction, isFalse);
      expect(projects['sirchmunk']!.canExecuteLocallyBeforeV4, isFalse);
      expect(projects['sirchmunk']!.requiresApiKey, isFalse);
      expect(projects['sirchmunk']!.requiresNetwork, isFalse);
      expect(projects['sirchmunk']!.requiresExternalRuntime, isFalse);
      expect(projects['sirchmunk']!.relatedWorkbenchPageIds,
          containsAll(['retrieval_verification', 'reports_audit']));
      expect(projects['ai_marketing_skills']!.contractStatus,
        containsAll(['marketing_skill_pattern_library', 'real_integration', 'runtime_not_bundled']));
    expect(projects['ai_marketing_skills']!.uiVisibility, 'visible_status_only');
    expect(projects['ai_marketing_skills']!.canExecuteLocallyBeforeV4, isFalse);
    expect(projects['ai_marketing_skills']!.requiresNetwork, isFalse);
    expect(projects['ai_marketing_skills']!.requiresExternalRuntime, isFalse);
    expect(projects['ai_marketing_skills']!.relatedWorkbenchPageIds,
        containsAll(['template_library', 'skill_factory']));
    expect(matrix['external_project_count'], 26);
  });

  test('p2.1 parser backend matrix asset parses with release boundaries',
      () async {
    final matrix = ParserBackendMatrix.fromJsonString(await rootBundle
        .loadString('assets/parser_backends/parser_backend_matrix.json'));
    final backendIds =
        matrix.backends.map((backend) => backend.backendId).toSet();
    final builtin = matrix.backend('builtin')!;
    final docling = matrix.backend('docling')!;
    final marker = matrix.backend('marker')!;
    final mineru = matrix.backend('mineru')!;
    final opendataloader = matrix.backend('opendataloader')!;
    final paddleocr = matrix.backend('paddleocr')!;
    final surya = matrix.backend('surya')!;
    final unstructured = matrix.backend('unstructured')!;

    expect(matrix.schemaVersion, 'p2.1.parser_backend_matrix.v1');
    expect(matrix.releaseVersion, 'v4.1.0');
    expect(matrix.runtimeBaselineCommit,
        '576a62075dc1ecbe00388bb0569fd1fc767be7cb');
    expect(matrix.defaultHeavyDependenciesBundled, isFalse);
    expect(matrix.staticWorkbenchRuntimeExecutionClaimed, isFalse);
    expect(backendIds, {
      'builtin',
      'docling',
      'marker',
      'mineru',
      'opendataloader',
      'paddleocr',
      'surya',
      'unstructured'
    });
    expect(
        matrix.backends
            .every((backend) => backend.staticWorkbenchExecutable == false),
        isTrue);
    expect(builtin.validatedStableSurface, ['.md', '.txt']);
    expect(builtin.evidence.evidencePath,
        contains('fallback_parser_contract.json'));
    expect(builtin.knownLimitations.join(' '),
        contains('basic Markdown/TXT text documents'));
    expect(builtin.knownLimitations.join(' '),
        contains('Not a replacement for optional layout/OCR runtimes'));
    expect(docling.optionalExtra, 'parser-docling');
    expect(docling.installMode.label, 'parser-docling');
    expect(docling.evidence.status, 'pass');
    expect(docling.workbenchState,
        containsAll(['real_runtime_integrated', 'optional_dependency_gated']));
    expect(marker.status, 'real_runtime_integrated');
    expect(marker.validatedStableSurface, ['.pdf']);
    expect(marker.runtimeInvoked, isTrue);
    expect(
        marker.workbenchState,
        containsAll([
          'real_runtime_integrated',
          'smoke_passed',
          'license_gate_pending'
        ]));
    expect(mineru.optionalExtra, 'parser-mineru');
    expect(mineru.validatedStableSurface, ['.pdf', '.png']);
    expect(opendataloader.optionalExtra, 'parser-opendataloader');
    expect(opendataloader.validatedStableSurface, ['.pdf']);
    expect(opendataloader.evidence.status, 'pass');
    expect(opendataloader.workbenchState,
        containsAll(['real_runtime_integrated', 'smoke_passed']));
    expect(paddleocr.validatedStableSurface, ['.pdf', '.png']);
    expect(surya.optionalExtra, 'parser-surya');
    expect(surya.status, 'future_hardening');
    expect(surya.workbenchState,
        containsAll(['needs_strengthening', 'reference_benchmark']));
    expect(surya.evidence.status, 'blocked_by_dependency');
    expect(unstructured.validatedStableSurface, ['.md', '.txt']);
    expect(unstructured.isLimitedSurface, isTrue);
    expect(unstructured.capabilityBoundary.staticWorkbenchExecutable, isFalse);
    expect(unstructured.evidence.evidencePath,
        contains('unstructured_integration_decision_report.json'));
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

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(pages, hasLength(18));
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace reserves portable runtime and model cache paths',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        coreWorkspace: r'D:\HeiTangWorkspace',
        initialSelectedIndex: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('运行时缓存设置'), findsOneWidget);
    expect(
      find.textContaining(r'D:\HeiTangWorkspace\.heitang\runtime_cache\marker'),
      findsOneWidget,
    );
    expect(
      find.textContaining(r'D:\HeiTangWorkspace\.heitang\runtime_cache\surya'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long Core action shows progress bar and event path',
      (tester) async {
    final completer = Completer<CoreBridgeProcessResult>();
    final bridge = LocalCoreBridge(runner: (request) => completer.future);
    const action = ContractAction(
      id: 'run_document_understanding',
      label: 'Run Document Understanding',
      command: 'run-document-understanding',
      requires: <String>['workspace'],
      pageId: 'import_parsing',
      status: 'ready',
      commandKind: 'core_cli',
      blockedReason: '',
      desktopEnabled: true,
      webEnabled: false,
      desktopBlockedReason: '',
      webBlockedReason: 'web_local_cli_unsupported',
      reportIds: <String>[],
      artifactIds: <String>[],
      errorCodes: <String>[],
    );
    const request = CoreBridgeRequest(
      actionId: 'run_document_understanding',
      coreCli: 'python',
      workingDirectory: r'C:\repo',
      arguments: <String>[
        'run-document-understanding',
        '--output',
        r'C:\workspace\workbench_runs\run_document_understanding',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoreActionPanel(
            action: action,
            request: request,
            coreBridge: bridge,
            isWebRuntime: false,
            enabled: true,
            localeCode: 'zh-CN',
          ),
        ),
      ),
    );
    await tester.tap(find.text('运行 Core 操作'));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('progress_events.jsonl'), findsOneWidget);

    completer.complete(const CoreBridgeProcessResult(
        exitCode: 0, stdout: 'completed', stderr: ''));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
          r'C:\workspace\workbench_runs\run_document_understanding/progress_events.jsonl'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'renders mobile HeiTang workbench shell without Flutter exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
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
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
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

  testWidgets('renders dedicated p1 pages without Flutter exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1320));
    await tester
        .pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    for (final title in [
      '工作空间',
      '向量索引 / 提供方 / 存储',
      '技能工厂',
      '任务 / 作业中心',
      '产物管理',
      '错误修复中心',
      '运行门禁',
      '能力矩阵',
      '报表与审计'
    ]) {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.textContaining('Core'), findsWidgets);
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

    await tester.tap(find.text('运行门禁').first);
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('运行门禁').first);
    await tester.pumpAndSettle();

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

    expect(find.textContaining('S=1 · A=1'), findsWidgets);
    expect(find.textContaining('planned=0'), findsWidgets);
    expect(find.textContaining('ready=false'), findsWidgets);
    expect(find.textContaining('local_ready=false'), findsWidgets);
    expect(find.text('运行 Core 操作'), findsNothing);

    await tester.tap(find.text('记忆中心').first);
    await tester.pump();
    expect(find.textContaining('LLM Wiki v2'), findsWidgets);
    expect(
        find.textContaining('future_adapter/capability_anchor'), findsWidgets);
    expect(find.textContaining('显示边界'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('n8n export status maps to UI page without runtime execution claims',
      () async {
    final registry = ExternalCapabilityRegistry.fromJsonString(await rootBundle
        .loadString('assets/external/external_capability_registry.json'));
    final taskView = sampleWorkbenchContracts.navigation.views
        .firstWhere((view) => view.id == 'task-job-center');
    final taskProjects = registry.projectsForCorePage(taskView.corePageId);
    final n8n = taskProjects.firstWhere((project) => project.projectId == 'n8n');
    final statusLine = '${n8n.projectName}:${n8n.contractStatus.join('/')}';
    final blockedReasonLine = '${n8n.projectId}:${n8n.blockedReason}';

    expect(taskView.corePageId, 'task_job_center');
    expect(statusLine,
        'n8n:workflow_export_adapter/export_validation_passed/runtime_not_bundled');
    expect(blockedReasonLine, 'n8n:external_runtime_required');
    expect(n8n.requiresExternalRuntime, isTrue);
    expect(statusLine, isNot(contains('workflow execution passed')));
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

    expect(find.text('Parser Backend Matrix'), findsWidgets);
    expect(find.text('Parser/OCR 后端证据面板'), findsOneWidget);
    expect(find.text('Core 集成适配器'), findsOneWidget);
    expect(find.text('Docling 状态'), findsOneWidget);
    expect(find.text('Marker 状态'), findsOneWidget);
    expect(find.text('OpenDataLoader 状态'), findsOneWidget);
    expect(find.text('PaddleOCR 状态'), findsOneWidget);
    expect(find.text('Surya 基准'), findsOneWidget);
    expect(find.text('Unstructured 状态'), findsOneWidget);
    expect(find.text('Backend Matrix Table'), findsOneWidget);
    expect(find.text('Reports & Audit Evidence'), findsOneWidget);
    expect(find.textContaining('v4.1.0 · 8 backends · static_runtime=false'),
        findsWidgets);
    expect(find.textContaining('docling:parser-docling'), findsWidgets);
    expect(find.textContaining('marker:parser-marker'), findsWidgets);
    expect(find.textContaining('mineru:parser-mineru'), findsWidgets);
    expect(find.textContaining('opendataloader:parser-opendataloader'),
        findsWidgets);
    expect(find.textContaining('paddleocr:parser-paddleocr'), findsWidgets);
    expect(find.textContaining('surya:parser-surya'), findsWidgets);
    expect(find.textContaining('parser-mineru · .pdf, .png'), findsWidgets);
    expect(find.textContaining('parser-opendataloader · .pdf'), findsWidgets);
    expect(find.textContaining('parser-paddleocr · .pdf, .png'), findsWidgets);
    expect(find.textContaining('unstructured:.md/.txt'), findsWidgets);
    expect(find.textContaining('default_heavy_deps=false'), findsWidgets);
    expect(find.textContaining('no_static_execution=true'), findsWidgets);
    expect(find.textContaining('Failure Mode Report'), findsOneWidget);
    expect(find.textContaining('Fresh Clone Reproducibility'), findsOneWidget);
    expect(find.textContaining('Static Web Workbench'), findsOneWidget);
    expect(find.textContaining('Fallback Parser Contract'), findsWidgets);
    expect(find.textContaining('不是完整 Document Understanding'), findsOneWidget);
    expect(find.textContaining('Run parser'), findsNothing);
    expect(find.textContaining('Execute parser'), findsNothing);
    expect(find.textContaining('运行解析后端'), findsNothing);

    await tester.tap(find.text('运行门禁').first);
    await tester.pumpAndSettle();
    expect(find.text('Parser/OCR 后端证据面板'), findsOneWidget);

    await tester.tap(find.text('能力矩阵').first);
    await tester.pumpAndSettle();
    expect(find.text('Backend Matrix Table'), findsOneWidget);
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

    expect(find.text('Knowledge-to-Skill Suite 工作流'), findsOneWidget);
    expect(find.textContaining('release_candidate'), findsWidgets);
    expect(find.textContaining('Core 证据快照'), findsOneWidget);
    expect(find.text('知识包'), findsWidgets);
    expect(find.text('方法论'), findsWidgets);
    expect(find.text('Skill Suite'), findsWidgets);
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
    await tester.tap(find.text('Agent Factory & Runtime').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('run_agent'), findsWidgets);
    expect(find.textContaining('kb_bound'), findsWidgets);
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

    await tester.tap(find.text('检索与验证').first);
    await tester.pumpAndSettle();
    expect(find.text('Run RAG query'), findsOneWidget);

    await tester.ensureVisible(find.text('运行 Core 操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行 Core 操作'));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.actionId, 'rag_query');
    expect(requests.single.arguments.first, 'kb-query');
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

    await tester.tap(find.text('Agent 工厂与运行').first);
    await tester.pumpAndSettle();
    expect(find.text('Run Agent'), findsOneWidget);
    expect(find.textContaining('blocked_reason: web_local_cli_unsupported'),
        findsOneWidget);

    await tester.tap(find.text('运行 Core 操作'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(runnerCalled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows disabled blocked_reason for provider and secret actions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts, isWebRuntime: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('向量索引 / 提供方 / 存储').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('anysearchskill:ui_configuration_pending'),
        findsOneWidget);
    expect(find.textContaining('blocked_reason: provider_required'),
        findsOneWidget);

    await tester.tap(find.text('错误修复中心').first);
    await tester.pumpAndSettle();
    expect(
        find.textContaining('blocked_reason: secret_required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
