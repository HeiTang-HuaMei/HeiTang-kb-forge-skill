import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/workbench/task_model.dart';
import 'package:heitang_workbench/workbench/task_workbench.dart';

void main() {
  testWidgets('dashboard shows one current task and hides technical details',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskWorkbenchSurface(
              localeCode: 'zh-CN',
              workspace: r'C:\workspace',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('dashboard-current-task-panel')), findsOneWidget);
    expect(find.text('当前任务'), findsOneWidget);
    expect(find.text('本地优先'), findsOneWidget);
    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('下一步'), findsOneWidget);
    expect(find.text('选择本地文件或文件夹'), findsOneWidget);
    expect(find.text('当前状态'), findsOneWidget);
    expect(find.text('输出位置'), findsOneWidget);
    expect(find.byKey(const Key('workbench-side-panel')), findsOneWidget);
    expect(find.text('工作台概览'), findsOneWidget);
    expect(find.text('真实完成度'), findsOneWidget);
    expect(find.text('运行状态'), findsOneWidget);
    expect(find.text('输出与活动'), findsOneWidget);
    expect(find.byKey(const Key('side-output-导入清单')), findsOneWidget);
    expect(find.text('最近活动'), findsWidgets);
    expect(find.text('现在'), findsOneWidget);
    expect(find.byKey(const Key('workbench-command-panel')), findsNothing);
    expect(find.byKey(const Key('workflow-stepper')), findsNothing);
    expect(find.text('工作流阶段 1'), findsNothing);
    expect(find.byKey(const Key('workbench-advanced-task-details')),
        findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const Key('workbench-advanced-task-details')));
    await tester.tap(find.byKey(const Key('workbench-advanced-task-details')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workbench-input-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-progress-area')), findsWidgets);
    expect(find.byKey(const Key('workbench-output-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-evidence-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-error-area')), findsOneWidget);
    expect(find.text('任务进度区'), findsOneWidget);
    expect(find.textContaining('6 个阶段'), findsOneWidget);
    expect(find.textContaining('只有真实 Core 结果返回后才能显示已完成'), findsOneWidget);
    for (final stage in WorkbenchTaskStage.values) {
      expect(find.byKey(Key('task-card-${stage.id}')), findsOneWidget);
      expect(find.byKey(Key('task-progress-${stage.id}')), findsOneWidget);
    }
    expect(find.text('等待开始'), findsWidgets);
    expect(find.text('pending'), findsNothing);
    expect(find.textContaining('Agent Runtime complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top-level navigation is limited to seven entries',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, hasLength(7));
    expect(find.text('工作台'), findsWidgets);
    expect(find.text('Agent'), findsWidgets);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('设置'), findsWidgets);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.text('import-parsing'), findsNothing);
    expect(find.text('knowledge-package-management'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'knowledge page exposes package, document, and retrieval workflows',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(
            const Key('dense-page-workbench-knowledge-package-management')),
        findsOneWidget);
    expect(find.byKey(const Key('knowledge-package-list')), findsOneWidget);
    expect(find.text('文档库'), findsOneWidget);
    expect(find.text('检索验证'), findsOneWidget);
    expect(find.text('输出目标'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.byKey(const Key('product-status-panel')), findsNothing);
    expect(find.text('构建知识包草稿'), findsOneWidget);
    await tester.tap(find.text('文档库'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library')), findsOneWidget);
    await tester.tap(find.text('检索验证'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('运行检索验证'), findsOneWidget);
    expect(find.text('disabled_boundary'), findsNothing);
    expect(find.text('display_only'), findsNothing);
    expect(find.text('Document Library'), findsNothing);
    expect(find.text('Retrieval & Verification'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'skill builder uses page-specific builder surfaces without fake generation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 3,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-skill-factory')),
        findsOneWidget);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);
    expect(find.text('元数据与来源配置'), findsOneWidget);
    expect(find.text('输出结构预览'), findsOneWidget);
    expect(find.text('验证摘要'), findsOneWidget);
    expect(find.text('生成 Skill 草稿'), findsOneWidget);
    expect(find.text('Skill Governance Report'), findsOneWidget);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.text('enabled_real'), findsNothing);
    expect(find.text('generated'), findsNothing);
    expect(find.textContaining('生成完成'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agent page is an Agent workspace, not primary Agent Package',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 4,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-agent-factory-runtime')),
        findsOneWidget);
    expect(find.text('Agent'), findsWidgets);
    expect(find.byKey(const Key('agent-create-edit-form')), findsOneWidget);
    expect(find.text('创建 Agent'), findsOneWidget);
    expect(find.text('简单模式'), findsOneWidget);
    expect(find.text('高级模式'), findsOneWidget);
    expect(find.text('绑定'), findsOneWidget);
    expect(find.text('预览与导出'), findsOneWidget);
    expect(find.text('创建 Agent 草稿'), findsOneWidget);
    await tester.tap(find.text('简单模式'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-simple-mode')), findsOneWidget);
    await tester.tap(find.text('高级模式'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-advanced-mode')), findsOneWidget);
    await tester.tap(find.text('绑定'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-bindings')), findsOneWidget);
    await tester.tap(find.text('预览与导出'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-preview-export')), findsOneWidget);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('Workspace and Future Runtime'), findsNothing);
    expect(find.text('Agent Teams'), findsNothing);
    expect(find.text('Subagent'), findsNothing);
    expect(find.text('Computer Use'), findsNothing);
    expect(find.text('Sandbox'), findsNothing);
    expect(find.text('A2A'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.textContaining('Agent Runtime complete'), findsNothing);
    expect(find.textContaining('自主执行'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('english mode switches the whole page language only',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 2,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN').first);
    await tester.pumpAndSettle();

    expect(find.text('Knowledge Package'), findsWidgets);
    expect(find.text('Document Library'), findsOneWidget);
    expect(find.text('Retrieval Verification'), findsOneWidget);
    expect(find.text('Build package draft'), findsOneWidget);
    expect(find.text('知识库'), findsNothing);
    expect(find.text('文档库'), findsNothing);
    expect(find.text('检索与验证'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workbench does not claim later campaign completion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    for (final claim in [
      'Agent Runtime complete',
      'Memory Runtime complete',
      'Configuration complete',
      'Full Testing complete',
      'EXE complete',
      'Release complete',
    ]) {
      expect(find.textContaining(claim), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
