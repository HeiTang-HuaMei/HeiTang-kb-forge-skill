import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/workbench/task_model.dart';
import 'package:heitang_workbench/workbench/task_workbench.dart';

void main() {
  testWidgets('workbench renders five areas and six task progress cards',
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

    expect(find.text('Campaign 4 工作台'), findsOneWidget);
    expect(find.text('本地优先'), findsOneWidget);
    expect(find.text('本地 Agent 知识供应链'), findsOneWidget);
    expect(find.text('知识供应链'), findsOneWidget);
    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('构建知识库'), findsWidgets);
    expect(find.text('生成 Skill'), findsWidgets);
    expect(find.text('创建 Agent'), findsWidgets);
    expect(find.text('验证与导出'), findsWidgets);
    expect(find.byKey(const Key('workbench-command-panel')), findsOneWidget);
    expect(find.text('本地资料输入台'), findsOneWidget);
    expect(find.text('资料来源'), findsOneWidget);
    expect(find.text('输出目标'), findsOneWidget);
    expect(find.text('导入门禁'), findsOneWidget);
    expect(
        find.byKey(const Key('material-source-console-card')), findsOneWidget);
    expect(find.byKey(const Key('output-target-console-card')), findsOneWidget);
    expect(find.byKey(const Key('import-gate-console-card')), findsOneWidget);
    expect(find.byKey(const Key('material-format-strip')), findsOneWidget);
    expect(find.text('PDF'), findsWidgets);
    expect(find.text('等待本地输入'), findsOneWidget);
    expect(find.text('门禁未开放'), findsOneWidget);
    expect(find.byKey(const Key('workbench-side-panel')), findsOneWidget);
    expect(find.text('工作台概览'), findsOneWidget);
    expect(find.text('真实完成度'), findsOneWidget);
    expect(find.text('运行状态'), findsOneWidget);
    expect(find.text('输出与活动'), findsOneWidget);
    expect(find.byKey(const Key('side-output-导入清单')), findsOneWidget);
    expect(find.text('最近活动'), findsOneWidget);
    expect(find.text('现在'), findsOneWidget);
    expect(find.text('工作台操作'), findsOneWidget);
    expect(find.text('完成门禁保持关闭'), findsOneWidget);
    expect(find.text('查看输出路径'), findsOneWidget);
    expect(find.text('工作流阶段 1'), findsOneWidget);
    expect(find.text('工作流阶段 5'), findsOneWidget);
    expect(find.byKey(const Key('workflow-next-action-1')), findsOneWidget);
    expect(find.byKey(const Key('workflow-output-pill-1')), findsOneWidget);
    expect(find.byKey(const Key('workflow-stepper')), findsOneWidget);
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
    expect(find.text('任务阶段'), findsOneWidget);
    expect(find.textContaining('结果 + 证据'), findsOneWidget);
    expect(find.textContaining('没有 Core 结果不会展示完成'), findsOneWidget);
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
      'page-level redesign exposes secondary tabs and capability matrix',
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
    expect(find.text('文档库'), findsOneWidget);
    expect(find.text('检索与验证'), findsOneWidget);
    expect(find.text('输出目标'), findsWidgets);
    expect(find.byKey(const Key('action-capability-matrix')), findsOneWidget);
    expect(find.text('构建知识包草稿'), findsOneWidget);
    expect(find.text('运行检索'), findsOneWidget);
    expect(find.text('边界禁用'), findsWidgets);
    expect(find.text('仅展示'), findsWidgets);
    expect(find.text('disabled_boundary'), findsNothing);
    expect(find.text('display_only'), findsNothing);
    expect(find.text('Document Library'), findsNothing);
    expect(find.text('Retrieval & Verification'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'skill builder uses dense builder surfaces without fake generation',
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
    expect(find.text('生成器'), findsWidgets);
    expect(find.text('输出预览'), findsOneWidget);
    expect(find.text('生成报告'), findsOneWidget);
    expect(find.text('生成 Skill 草稿'), findsOneWidget);
    expect(find.text('Skill Governance Report'), findsOneWidget);
    expect(find.text('已接入'), findsOneWidget);
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
    expect(find.text('Agent 概览'), findsWidgets);
    expect(find.text('创建与编辑'), findsOneWidget);
    expect(find.text('模式与绑定'), findsOneWidget);
    expect(find.text('工具与权限'), findsOneWidget);
    expect(find.text('创建 Agent 草稿'), findsOneWidget);
    expect(find.text('预览 Agent 配置'), findsOneWidget);
    expect(find.text('预览包导出产物'), findsOneWidget);
    expect(find.text('Agent 包'), findsNothing);
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
    expect(find.text('Retrieval & Verification'), findsOneWidget);
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
