import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/core_actions/workbench_actions.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpWorkbench(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        campaign6AgentRuntimeStatus: sampleCampaign6AgentRuntimeStatus,
        campaign7ConfigurationStatus: sampleCampaign7ConfigurationStatus,
        campaign9DesktopDeliveryStatus: sampleCampaign9DesktopDeliveryStatus,
        isWebRuntime: false,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rc5 exposes real runtime chains on declared main pages',
      (tester) async {
    await pumpWorkbench(tester);

    const expectedSurfaces = <MapEntry<Key, Key>>[
      MapEntry(Key('sidebar-import-parsing'),
          Key('rc5-primary-runtime-actions-import-parsing')),
      MapEntry(Key('sidebar-knowledge-package-management'),
          Key('rc5-primary-runtime-actions-knowledge-package-management')),
      MapEntry(Key('sidebar-retrieval-verification'),
          Key('rc5-primary-runtime-actions-retrieval-verification')),
      MapEntry(Key('sidebar-document-generation'),
          Key('rc5-primary-runtime-actions-document-generation')),
      MapEntry(Key('sidebar-skill-factory'),
          Key('rc5-primary-runtime-actions-skill-factory')),
      MapEntry(Key('sidebar-agent-factory-runtime'),
          Key('rc5-primary-runtime-actions-agent-factory-runtime')),
      MapEntry(Key('sidebar-workspace'),
          Key('rc5-primary-runtime-actions-workspace')),
    ];

    for (final entry in expectedSurfaces) {
      await tester.ensureVisible(find.byKey(entry.key));
      await tester.tap(find.byKey(entry.key), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(entry.value), findsOneWidget, reason: '${entry.key}');
      expect(find.text('真实运行链路'), findsWidgets, reason: '${entry.key}');
      expect(find.text('运行 Core 操作'), findsWidgets, reason: '${entry.key}');
      expect(find.textContaining('allowlisted_core_bridge'), findsWidgets,
          reason: '${entry.key}');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc5 page tabs have selected state and change visible content',
      (tester) async {
    await pumpWorkbench(tester);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-generation')));
    await tester.tap(find.byKey(const Key('sidebar-document-generation')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-generation-tasks')), findsOneWidget);
    await tester.tap(find.text('文档模板').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-template-library')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('page-tab-1')),
            matching: find.byIcon(Icons.check)),
        findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('sidebar-workspace')));
    await tester.tap(find.byKey(const Key('sidebar-workspace')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('配置系统').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('settings-configuration-system')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('page-tab-2')),
            matching: find.byIcon(Icons.check)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc5 removes duplicate window controls and keeps boundaries',
      (tester) async {
    await pumpWorkbench(tester);

    expect(find.byKey(const Key('desktop-window-controls')), findsNothing);
    expect(find.byKey(const Key('window-control-minimize')), findsNothing);
    expect(find.byKey(const Key('window-control-maximize')), findsNothing);
    expect(find.byKey(const Key('window-control-close')), findsNothing);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-agent-factory-runtime')));
    await tester.tap(find.byKey(const Key('sidebar-agent-factory-runtime')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    final memoryTab = find.text('多 Agent / Memory').first;
    await tester.ensureVisible(memoryTab);
    await tester.tap(memoryTab, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('Computer Use'), findsWidgets);
    expect(find.textContaining('disabled_boundary'), findsWidgets);
    expect(find.textContaining('arbitrary shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('rc5 primary runtime actions map to allowlisted Core requests', () {
    const bridge = LocalCoreBridge();
    const actions = <ContractAction>[
      ContractAction(
        id: 'document_preflight',
        label: 'Document Preflight',
        command: 'preflight-documents --input <input> --output <output>',
        requires: <String>['input', 'workspace'],
        pageId: 'import_parsing',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['document_preflight_report'],
        artifactIds: <String>['document_inventory'],
        errorCodes: <String>['document_preflight_failed'],
      ),
      ContractAction(
        id: 'batch_import_documents',
        label: 'Batch Import Documents',
        command: 'batch-import-documents --input <input> --output <output>',
        requires: <String>['input', 'workspace'],
        pageId: 'import_parsing',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['batch_import_report'],
        artifactIds: <String>['source_manifest'],
        errorCodes: <String>['batch_import_failed'],
      ),
      ContractAction(
        id: 'knowledge_base_build',
        label: 'Build Knowledge Base',
        command:
            'build-knowledge-base --document-understanding <source> --output <output>',
        requires: <String>['document_understanding', 'workspace'],
        pageId: 'knowledge_package_management',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['knowledge_base_build_report'],
        artifactIds: <String>['kb_manifest'],
        errorCodes: <String>['knowledge_base_build_failed'],
      ),
      ContractAction(
        id: 'knowledge_package_build',
        label: 'Build Knowledge Package',
        command:
            'build-knowledge-package --knowledge-base <package> --output <output>',
        requires: <String>['knowledge_base', 'workspace'],
        pageId: 'knowledge_package_management',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['knowledge_package_build_report'],
        artifactIds: <String>['portable_kb_package'],
        errorCodes: <String>['knowledge_package_build_failed'],
      ),
      ContractAction(
        id: 'rag_query',
        label: 'Run RAG Query',
        command:
            'kb-query --package <package> --query <query> --output <output>',
        requires: <String>['package', 'query', 'workspace'],
        pageId: 'retrieval_verification',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['rag_query_report'],
        artifactIds: <String>['citation_trace'],
        errorCodes: <String>['rag_query_failed'],
      ),
      ContractAction(
        id: 'evidence_selection',
        label: 'Select Evidence',
        command:
            'select-evidence --package <package> --query <query> --output <output>',
        requires: <String>['package', 'query', 'workspace'],
        pageId: 'retrieval_verification',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['evidence_selection_report'],
        artifactIds: <String>['evidence_trace'],
        errorCodes: <String>['evidence_selection_failed'],
      ),
      ContractAction(
        id: 'generate_markdown',
        label: 'Generate Markdown',
        command: 'generate-md --package <package> --output <output>',
        requires: <String>['package', 'workspace'],
        pageId: 'document_generation',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['markdown_generation_report'],
        artifactIds: <String>['markdown_document'],
        errorCodes: <String>['document_generation_failed'],
      ),
      ContractAction(
        id: 'generate_manual_user_guide',
        label: 'Generate Document Bundle',
        command: 'generate-documents --package <package> --output <output>',
        requires: <String>['package', 'workspace'],
        pageId: 'document_generation',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['document_bundle_report'],
        artifactIds: <String>['generated_documents'],
        errorCodes: <String>['document_bundle_failed'],
      ),
      ContractAction(
        id: 'package_to_skill',
        label: 'Generate Skill Package',
        command: 'generate-skill --package <package> --output <output>',
        requires: <String>['package', 'workspace'],
        pageId: 'skill_factory',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['skill_generation_report'],
        artifactIds: <String>['skill_package'],
        errorCodes: <String>['skill_generation_failed'],
      ),
      ContractAction(
        id: 'skill_governance_report',
        label: 'Skill Governance Report',
        command: 'skill-governance-report --skill <skill> --output <output>',
        requires: <String>['skill', 'workspace'],
        pageId: 'skill_factory',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['skill_governance_report'],
        artifactIds: <String>['governance_report'],
        errorCodes: <String>['skill_governance_failed'],
      ),
      ContractAction(
        id: 'standalone_agent_generation',
        label: 'Generate Standalone Agent',
        command: 'generate-agent --mode standalone --output <output>',
        requires: <String>['workspace'],
        pageId: 'agent_factory_runtime',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['agent_generation_report'],
        artifactIds: <String>['agent_package'],
        errorCodes: <String>['agent_generation_failed'],
      ),
      ContractAction(
        id: 'kb_bound_agent_generation',
        label: 'Generate KB-bound Agent',
        command:
            'generate-agent --mode kb_bound --package <package> --skill <skill> --output <output>',
        requires: <String>['package', 'skill', 'workspace'],
        pageId: 'agent_factory_runtime',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['kb_bound_agent_generation_report'],
        artifactIds: <String>['agent_package'],
        errorCodes: <String>['agent_generation_failed'],
      ),
      ContractAction(
        id: 'provider_config_validate',
        label: 'Validate Provider Config',
        command: 'provider-config-validate --config <config> --output <output>',
        requires: <String>['config_profile', 'workspace'],
        pageId: 'workspace',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['provider_config_validation_report'],
        artifactIds: <String>['masked_provider_profile'],
        errorCodes: <String>['provider_config_invalid'],
      ),
      ContractAction(
        id: 'provider_readiness',
        label: 'Provider Readiness',
        command: 'provider-readiness --workspace <workspace> --output <output>',
        requires: <String>['workspace'],
        pageId: 'workspace',
        status: 'ready',
        commandKind: 'core_cli',
        blockedReason: '',
        desktopEnabled: true,
        webEnabled: false,
        desktopBlockedReason: '',
        webBlockedReason: 'web_local_cli_unsupported',
        reportIds: <String>['provider_readiness_report'],
        artifactIds: <String>['provider_status'],
        errorCodes: <String>['provider_readiness_failed'],
      ),
    ];

    for (final action in actions) {
      final request = coreRequestForAction(
        action: action,
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );

      expect(request, isNotNull, reason: action.id);
      expect(request!.outputPath, isNotNull, reason: action.id);
      expect(request.allowedOutputRoot, r'C:\workspace', reason: action.id);
      expect(bridge.buildCommand(request).first, 'python', reason: action.id);
      expect(bridge.buildCommand(request), contains(request.outputPath),
          reason: action.id);
    }
  });
}
