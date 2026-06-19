import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
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
    expect(find.text('一个主操作'), findsOneWidget);
    expect(find.text('选择本地文件或文件夹'), findsOneWidget);
    expect(find.text('当前阶段状态'), findsOneWidget);
    expect(find.text('预期产物'), findsOneWidget);
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
    expect(
        find.byKey(const Key('workbench-advanced-task-details')), findsNothing);
    expect(find.text('产物交接链'), findsOneWidget);
    expect(find.textContaining('承接: 新来源'), findsOneWidget);
    expect(find.textContaining('下一阶段: 解析资料'), findsWidgets);
    expect(find.text('等待开始'), findsWidgets);
    expect(find.text('pending'), findsNothing);
    expect(find.textContaining('Agent Runtime complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop navigation follows the real product chain',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, hasLength(11));
    expect(
      pages.map((page) => page.zhTitle),
      [
        '首页',
        '工作本管理',
        '文档库',
        '知识库',
        '检索与验证',
        '文档生成',
        'Skill 工厂',
        'Agent 工作台',
        '审计中心',
        '产物中心',
        '运行设置',
      ],
    );
    expect(pages[0].pageIds, ['dashboard']);
    expect(
      pages[2].pageIds,
      ['import-parsing', 'document-library'],
    );
    expect(pages[5].pageIds, ['document-generation']);
    expect(pages[6].pageIds, ['skill-factory']);
    expect(pages[7].pageIds, ['agent-factory-runtime']);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('导入与解析'), findsNothing);
    expect(find.text('Agent 工作台'), findsWidgets);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(find.text('运行与编排'), findsNothing);
    expect(find.text('记忆中心'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.text('knowledge-package-management'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    await tester.tap(find.text('工作本管理').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workbook-overview')), findsOneWidget);
    expect(find.byKey(const Key('workbook-next-actions')), findsOneWidget);
    expect(find.byKey(const Key('workbook-name-input')), findsOneWidget);
    expect(find.text('创建 / 切换工作本'), findsOneWidget);
    await tester.tap(find.text('文档库').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    expect(find.text('导入与解析'), findsWidgets);
    expect(find.text('来源文档'), findsOneWidget);
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);
    await tester.tap(find.byKey(const Key('page-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard next actions route through the product flow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    Finder nextAction(String label) => find.descendant(
          of: find.byKey(const Key('dashboard-next-actions')),
          matching: find.text(label),
        );

    expect(find.byKey(const Key('dashboard-next-actions')), findsOneWidget);
    expect(find.text('下一步行动'), findsOneWidget);
    expect(nextAction('文档库导入资料'), findsOneWidget);
    expect(nextAction('构建知识库'), findsOneWidget);
    expect(nextAction('检索验证'), findsOneWidget);
    expect(nextAction('生成并导出文档'), findsOneWidget);

    await tester.tap(nextAction('文档库导入资料'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-dashboard')));
    await tester.pumpAndSettle();
    await tester.tap(nextAction('构建知识库'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(
            const Key('dense-page-workbench-knowledge-package-management')),
        findsOneWidget);
    expect(find.text('1. 选择来源文档'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-dashboard')));
    await tester.pumpAndSettle();
    await tester.tap(nextAction('检索验证'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-retrieval-verification')),
        findsOneWidget);
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-dashboard')));
    await tester.pumpAndSettle();
    await tester.tap(nextAction('生成并导出文档'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-document-generation')),
        findsOneWidget);
    expect(find.byKey(const Key('document-generation-tasks')), findsOneWidget);

    expect(find.textContaining('operation-gate'), findsNothing);
    expect(find.textContaining('capability-matrix'), findsNothing);
    expect(find.textContaining('task-job-center'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document library hands imported sources to knowledge build',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    final workspace = Directory.systemTemp
        .createTempSync('kb_forge_product_flow_document_handoff_');
    addTearDown(() {
      if (workspace.existsSync()) {
        workspace.deleteSync(recursive: true);
      }
    });
    final input = Directory('${workspace.path}${Platform.pathSeparator}input')
      ..createSync(recursive: true);
    final source = File('${input.path}${Platform.pathSeparator}owner-note.txt')
      ..writeAsStringSync('product flow source document');
    File('${workspace.path}${Platform.pathSeparator}source_manifest.json')
        .writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'rc10_source_manifest.v1',
        'status': 'imported',
        'source_path': input.path,
        'source_name': 'input',
        'source_count': 1,
        'workspace': workspace.path,
        'sources': [
          {
            'source_path': source.path,
            'source_name': 'owner-note.txt',
            'relative_path': 'owner-note.txt',
            'source_type': 'local_file',
            'document_id': 'doc_owner_note',
            'extension': '.txt',
            'size_bytes': 28,
            'word_count': 4,
            'image_count': 0,
            'table_count': 0,
            'link_count': 0,
            'structure_status': 'local_text_scan',
          }
        ],
      }),
    );

    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        isWebRuntime: false,
        coreWorkspace: workspace.path,
        initialSelectedIndex: 2,
      ),
    );
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('page-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library')), findsOneWidget);

    final buildAction = find.text('用文档构建知识库');
    await tester.ensureVisible(buildAction);
    expect(buildAction, findsOneWidget);
    await tester.tap(buildAction);
    await tester.pumpAndSettle();

    expect(
        find.byKey(
            const Key('dense-page-workbench-knowledge-package-management')),
        findsOneWidget);
    expect(find.text('1. 选择来源文档'), findsOneWidget);
    expect(find.textContaining('operation-gate'), findsNothing);
    expect(find.textContaining('capability-matrix'), findsNothing);
    expect(find.textContaining('task-job-center'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top bar search exposes product destinations and no-match state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('搜索文档、知识库、Skill、Agent'), findsOneWidget);
    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.pumpAndSettle();
    expect(find.text('页面 · 从知识库生成 Skill，并绑定给 Agent'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('topbar-search-option-skill-factory')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-skill-factory')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), 'Agent');
    await tester.pumpAndSettle();
    expect(find.text('页面 · 创建 Agent、单 Agent 对话和多 Agent 协作'), findsOneWidget);
    await tester.tap(
        find.byKey(const Key('topbar-search-option-agent-factory-runtime')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-agent-factory-runtime')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), '没有这个对象');
    await tester.pumpAndSettle();
    expect(find.text('无匹配，前往查询控制台'), findsOneWidget);
    await tester.tap(
        find.byKey(const Key('topbar-search-option-retrieval-verification')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-retrieval-verification')),
        findsOneWidget);

    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider settings use product status labels and masked secrets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1400));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('运行设置').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provider 与存储'));
    await tester.pumpAndSettle();

    expect(find.text('enabled_real'), findsNothing);
    expect(find.text('LLM Provider'), findsWidgets);
    expect(find.text('Provider 与存储配置'), findsOneWidget);
    expect(find.text('live smoke 通过'), findsWidgets);
    expect(find.text('API Key'), findsWidgets);
    expect(find.text('************'), findsWidgets);
    expect(find.text('掩码展示'), findsWidgets);
    expect(find.text('可用'), findsWidgets);
    expect(find.textContaining('Provider Gate'), findsNothing);
    expect(find.textContaining('开发者诊断'), findsNothing);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop business pages hide the old state strip',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < pages.length; index++) {
      final title = pages[index].zhTitle;
      if (index > 0) {
        await tester.tap(find.text(title).first);
        await tester.pumpAndSettle();
      }

      expect(
          find.byKey(Key('page-state-strip-${pages[index].id}')), findsNothing);
      expect(find.textContaining('正常态'), findsNothing);
      expect(find.textContaining('空态'), findsNothing);
      expect(find.textContaining('加载态'), findsNothing);
      expect(find.textContaining('错误态'), findsNothing);
      expect(find.textContaining('可用操作'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'knowledge page exposes knowledge base, document, and retrieval workflows',
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

    expect(
        find.byKey(
            const Key('dense-page-workbench-knowledge-package-management')),
        findsOneWidget);
    expect(find.text('知识库'), findsWidgets);
    expect(find.text('向量索引'), findsOneWidget);
    expect(find.text('存储边界'), findsOneWidget);
    expect(find.byKey(const Key('knowledge-package-list')), findsOneWidget);
    expect(find.text('质量记录'), findsOneWidget);
    expect(find.text('输出目标'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.byKey(const Key('product-status-panel')), findsNothing);
    expect(find.text('1. 选择来源文档'), findsOneWidget);
    expect(find.text('开始构建知识库'), findsOneWidget);
    await tester.tap(find.text('质量记录'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('knowledge-quality-records')), findsOneWidget);
    expect(find.text('质量与验证记录'), findsOneWidget);
    expect(find.textContaining('实时外部比对均已验收'), findsOneWidget);
    await tester.tap(find.text('检索与验证').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('运行真实检索'), findsOneWidget);
    expect(find.text('Document Library'), findsNothing);
    expect(find.text('Retrieval & Verification'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('documents are a first-class top-level workbench entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 5,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-document-generation')),
        findsOneWidget);
    expect(find.text('文档生成'), findsWidgets);
    expect(find.byKey(const Key('document-generation-tasks')), findsOneWidget);
    expect(find.text('生成任务'), findsWidgets);
    expect(find.byKey(const Key('document-central-preview')), findsOneWidget);
    expect(find.textContaining('需要导出器配置'), findsWidgets);
    expect(find.text('DOCX（需配置）'), findsOneWidget);
    final disabledDocxChoice =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'DOCX（需配置）'));
    expect(disabledDocxChoice.onSelected, isNull);
    await tester.tap(find.text('文档模板').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-template-library')), findsOneWidget);
    expect(find.text('文档模板归文档生成'), findsOneWidget);
    await tester.tap(find.text('导出预览'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-export-preview')), findsOneWidget);
    expect(find.text('PDF'), findsWidgets);
    expect(find.text('PPTX'), findsWidgets);
    expect(find.text('PDF（需配置）'), findsOneWidget);
    final disabledPdfChoice =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'PDF（需配置）'));
    expect(disabledPdfChoice.onSelected, isNull);
    expect(find.textContaining('display_only'), findsNothing);
    expect(find.textContaining('需要导出器配置'), findsWidgets);
    expect(find.textContaining('本地导出器'), findsNothing);
    expect(find.textContaining('本地 Core 生成'), findsNothing);
    expect(find.textContaining('Release complete'), findsNothing);
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
        initialSelectedIndex: 6,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-skill-factory')),
        findsOneWidget);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);
    expect(find.text('从知识库生成'), findsOneWidget);
    expect(find.text('外部本地化'), findsOneWidget);
    expect(find.text('版本操作'), findsOneWidget);
    expect(find.text('验证导出'), findsOneWidget);
    expect(find.text('从知识库生成 Skill'), findsWidgets);
    expect(find.byKey(const Key('skill-name-input')), findsOneWidget);
    expect(find.text('Skill 名称'), findsOneWidget);
    expect(find.text('生成 Skill'), findsWidgets);
    await tester.tap(find.text('外部本地化').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('skill-external-localization')), findsOneWidget);
    expect(find.text('1. 导入外部 Skill'), findsOneWidget);
    expect(find.text('2. 解析结构'), findsOneWidget);
    expect(find.text('3. 选择本地知识库'), findsOneWidget);
    expect(find.text('4. 选择个性化目标'), findsOneWidget);
    expect(find.text('5. 融合并生成草稿'), findsOneWidget);
    expect(find.text('6. 展示改动差异'), findsOneWidget);
    expect(find.text('7. 验证 / 导出 / 绑定'), findsOneWidget);
    expect(find.text('查看外部 Skill 结构'), findsNothing);
    expect(find.text('等待导入外部 Skill'), findsOneWidget);
    expect(find.text('查看本地化 Skill 草稿'), findsNothing);
    expect(find.text('等待本地化草稿'), findsOneWidget);
    expect(find.text('查看改动差异'), findsNothing);
    expect(find.text('等待差异说明'), findsOneWidget);
    expect(find.text('创建 Agent 后绑定'), findsOneWidget);
    await tester.tap(find.text('版本操作').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);
    expect(find.text('Skill 版本操作'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
    expect(find.text('复制'), findsOneWidget);
    expect(find.text('融合'), findsOneWidget);
    await tester.tap(find.text('验证导出').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);
    expect(find.text('治理报告与验证'), findsNothing);
    expect(find.text('验证导出'), findsOneWidget);
    expect(find.text('校验 Skill'), findsOneWidget);
    expect(find.text('复制 Skill'), findsOneWidget);
    expect(find.text('融合 Skill'), findsOneWidget);
    expect(find.text('导出 Skill'), findsOneWidget);
    expect(find.text('绑定 Agent'), findsOneWidget);
    expect(find.text('操作清单'), findsOneWidget);
    expect(find.text('Agent 绑定'), findsOneWidget);
    expect(find.text('复制 Skill 路径'), findsNothing);
    expect(find.text('等待真实 Skill 产物'), findsWidgets);
    expect(find.text('等待可预览 Skill'), findsOneWidget);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.textContaining('生成完成'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audit center shows real execution records and export action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 8,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('validation-checklist')), findsOneWidget);
    expect(find.text('执行记录'), findsWidgets);
    expect(find.text('失败记录'), findsWidgets);
    expect(find.text('产物记录'), findsWidgets);
    expect(find.text('筛选执行记录'), findsOneWidget);
    expect(find.text('全部模块'), findsOneWidget);
    expect(find.text('全部状态'), findsOneWidget);
    expect(find.text('已完成 / 执行中'), findsOneWidget);
    expect(find.text('未运行'), findsWidgets);

    await tester.tap(find.byKey(const Key('audit-module-filter-知识库')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('构建知识库'), findsOneWidget);
    expect(find.text('导入来源'), findsNothing);

    await tester.tap(find.byKey(const Key('audit-status-filter-done')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('无匹配记录'), findsOneWidget);
    expect(find.text('请调整模块或状态'), findsOneWidget);

    await tester.tap(find.byKey(const Key('page-tab-1')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-evidence-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('page-tab-2')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('controlled-export-summary')), findsOneWidget);
    expect(find.text('导出审计报告'), findsOneWidget);
    expect(find.textContaining('rc10 等待 Owner 复验'), findsNothing);
    expect(find.textContaining('Owner 视觉验收已通过'), findsNothing);
    expect(find.textContaining('Release'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings owns providers and storage without template management',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 10,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider 与存储'), findsOneWidget);
    expect(find.text('模板管理'), findsNothing);
    expect(find.byKey(const Key('settings-provider-storage')), findsNothing);
    await tester.tap(find.text('Provider 与存储'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-provider-storage')), findsOneWidget);
    expect(find.textContaining('************'), findsOneWidget);
    expect(find.text('测试存储连接'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(find.text('导出器与授权状态'), findsOneWidget);
    expect(find.text('文档导出器'), findsOneWidget);
    expect(find.textContaining('需要导出器配置'), findsWidgets);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(find.text('模板库'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agent page owns creation, minimal chat, discussion, and history',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 7,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-agent-factory-runtime')),
        findsOneWidget);
    expect(find.text('Agent 工作台'), findsWidgets);
    expect(find.byKey(const Key('agent-workspace-setup')), findsOneWidget);
    expect(find.text('工作区'), findsOneWidget);
    expect(find.text('创建 Agent'), findsWidgets);
    expect(find.text('单 Agent 对话'), findsOneWidget);
    expect(find.text('Agent 与会话列表'), findsOneWidget);
    expect(find.text('创建 Agent 工作区并进入对话'), findsOneWidget);
    final configTab = find.byKey(const Key('page-tab-1'));
    await tester.ensureVisible(configTab);
    await tester.tap(configTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('简单 Agent'), findsWidgets);
    expect(find.text('复杂 Agent'), findsOneWidget);
    expect(find.byKey(const Key('agent-name-input')), findsOneWidget);
    expect(find.byKey(const Key('agent-model-config-input')), findsOneWidget);
    expect(find.byKey(const Key('agent-role-goal-input')), findsOneWidget);
    expect(find.text('Agent 名称'), findsOneWidget);
    expect(find.text('模型配置'), findsOneWidget);
    expect(find.text('角色说明'), findsOneWidget);
    expect(find.text('简单 Agent 对话配置'), findsOneWidget);
    expect(find.text('复杂 Agent 运行配置'), findsNothing);
    expect(find.text('Redis 短期记忆'), findsNothing);
    expect(find.text('向量长期记忆'), findsNothing);
    expect(find.text('Tool 配置'), findsNothing);
    await tester.tap(find.text('复杂构造'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('复杂 Agent 运行配置'), findsOneWidget);
    expect(find.text('Redis 短期记忆'), findsOneWidget);
    expect(find.text('向量长期记忆'), findsOneWidget);
    expect(find.text('Tool 配置'), findsOneWidget);
    expect(find.text('创建 Agent 并进入对话'), findsWidgets);
    expect(find.text('复制 Agent 路径'), findsNothing);
    expect(find.text('等待真实 Agent 产物'), findsWidgets);
    expect(find.text('等待可预览 Agent'), findsOneWidget);
    expect(find.text('单 Agent 对话'), findsOneWidget);
    expect(find.text('A2A 协作'), findsOneWidget);
    expect(find.text('运行审计'), findsOneWidget);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('构建知识库'), findsNothing);
    expect(find.text('生成 Skill'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);

    final createAndChatButton = find.text('创建 Agent 并进入对话').first;
    await tester.ensureVisible(createAndChatButton);
    await tester.tap(createAndChatButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-minimal-chat')), findsOneWidget);

    final chatTab = find.byKey(const Key('page-tab-2'));
    await tester.ensureVisible(chatTab);
    await tester.tap(chatTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-minimal-chat')), findsOneWidget);
    expect(find.text('审计清单'), findsOneWidget);
    expect(find.text('模型配置'), findsOneWidget);
    expect(find.text('绑定知识库'), findsOneWidget);
    expect(find.text('绑定 Skill'), findsOneWidget);
    expect(find.text('引用证据'), findsOneWidget);
    expect(find.text('记忆写入'), findsOneWidget);
    expect(find.text('错误状态'), findsOneWidget);
    expect(find.text('等待对话产物'), findsOneWidget);
    expect(find.text('等待会话历史'), findsOneWidget);
    expect(find.text('等待可预览对话'), findsOneWidget);
    expect(find.text('等待可预览历史'), findsOneWidget);

    final discussionTab = find.byKey(const Key('page-tab-3'));
    await tester.ensureVisible(discussionTab);
    await tester.tap(discussionTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('multi-agent-discussion-product-flow')),
        findsOneWidget);
    expect(find.text('启动联合讨论'), findsOneWidget);
    expect(find.text('协作议题'), findsWidgets);
    expect(find.text('参与 Agent'), findsOneWidget);
    expect(find.text('证据引用'), findsOneWidget);
    expect(find.text('会话状态'), findsOneWidget);
    expect(find.text('会话审计'), findsOneWidget);
    expect(find.text('讨论审计'), findsOneWidget);
    expect(find.text('等待讨论纪要'), findsOneWidget);
    expect(find.text('等待可预览纪要'), findsOneWidget);
    expect(find.text('等待会话审计'), findsOneWidget);
    expect(find.text('等待讨论审计'), findsOneWidget);

    final historyTab = find.byKey(const Key('page-tab-4'));
    await tester.ensureVisible(historyTab);
    await tester.tap(historyTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-run-history')), findsOneWidget);
    expect(find.text('多 Agent 总工作区'), findsOneWidget);
    expect(find.textContaining('Campaign'), findsNothing);
    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(find.textContaining('安全边界'), findsNothing);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('创建 Agent 草稿'), findsNothing);
    expect(find.text('保存版本与导出 Agent package'), findsNothing);
    expect(find.text('Workspace and Future Runtime'), findsNothing);
    expect(find.text('Subagent'), findsNothing);
    expect(find.text('Sandbox'), findsNothing);
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
        initialSelectedIndex: 3,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN').first);
    await tester.pumpAndSettle();

    expect(find.text('Knowledge Base'), findsWidgets);
    expect(find.text('Vector Index'), findsOneWidget);
    await tester.tap(find.text('Knowledge Base').last);
    await tester.pumpAndSettle();
    expect(find.text('Build Knowledge Base'), findsOneWidget);
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

  testWidgets('desktop shell does not duplicate native window controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktop-window-title-bar')), findsNothing);
    expect(find.byKey(const Key('desktop-topbar-single-row')), findsOneWidget);
    expect(find.byKey(const Key('desktop-window-controls')), findsNothing);
    expect(find.byKey(const Key('window-control-minimize')), findsNothing);
    expect(find.byKey(const Key('window-control-maximize')), findsNothing);
    expect(find.byKey(const Key('window-control-close')), findsNothing);
    expect(find.text('黑糖'), findsOneWidget);

    final topbarRect =
        tester.getRect(find.byKey(const Key('desktop-topbar-single-row')));
    final searchRect =
        tester.getRect(find.byKey(const Key('topbar-search-field')));
    expect((topbarRect.center.dy - searchRect.center.dy).abs(),
        lessThanOrEqualTo(1));

    await tester.binding.setSurfaceSize(const Size(1920, 1000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('page-scroll-dashboard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
