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
        '任务工作台',
        '工作区',
        '导入资料',
        '知识库',
        '知识库验证',
        '文档生成',
        'Skill',
        'Agent',
        '成果中心',
        '操作记录',
        '配置',
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
    expect(primaryNavigationPageIds, [
      'document-library',
      'knowledge-package-management',
      'skill-factory',
      'agent-factory-runtime',
      'document-generation',
      'dashboard',
      'workspace',
    ]);
    expect(find.text('任务工作台'), findsWidgets);
    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('Skill'), findsWidgets);
    expect(find.text('Agent'), findsWidgets);
    expect(find.text('配置'), findsWidgets);
    expect(find.byKey(const Key('sidebar-workbook')), findsNothing);
    expect(
        find.byKey(const Key('sidebar-retrieval-verification')), findsNothing);
    expect(find.byKey(const Key('sidebar-artifact-center')), findsNothing);
    expect(find.byKey(const Key('sidebar-reports-audit')), findsNothing);
    expect(find.text('导入与解析'), findsNothing);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(find.text('运行与编排'), findsNothing);
    expect(find.text('记忆中心'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.text('knowledge-package-management'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    await tester.tap(find.text('导入资料').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    expect(find.text('添加资料'), findsWidgets);
    expect(find.text('来源文档'), findsWidgets);
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);
    await tester.tap(find.byKey(const Key('document-library-tab-1')));
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
    expect(find.text('下一步行动'), findsNothing);
    expect(nextAction('缺少资料'), findsOneWidget);
    expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-next-actions')),
          matching: find.textContaining('阻塞项 · 先导入资料'),
        ),
        findsOneWidget);
    expect(find.textContaining('下一步：整理资料并生成知识库'), findsOneWidget);
    expect(nextAction('生成知识库'), findsNothing);
    expect(nextAction('测试知识库'), findsNothing);
    expect(nextAction('生成文档'), findsNothing);

    await tester.tap(nextAction('缺少资料'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-dashboard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-next-actions')), findsOneWidget);

    expect(find.textContaining('operation-gate'), findsNothing);
    expect(find.textContaining('capability-matrix'), findsNothing);
    expect(find.textContaining('task-job-center'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'document library keeps knowledge build unavailable before import',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('document-library-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library')), findsOneWidget);
    expect(find.text('等待导入真实文档'), findsOneWidget);

    final buildAction = find.text('生成知识库');
    await tester.ensureVisible(buildAction);
    expect(buildAction, findsOneWidget);
    final buildButton = tester.widget<FilledButton>(find.ancestor(
      of: buildAction,
      matching: find.byType(FilledButton),
    ));
    expect(buildButton.onPressed, isNull);
    await tester.tap(buildAction);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-document-library')),
        findsOneWidget);
    expect(find.text('1. 选择来源文档'), findsNothing);
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

    expect(find.text('搜索资料、知识库、技能、助手'), findsOneWidget);
    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.pumpAndSettle();
    expect(find.text('页面 · 从知识库生成可复用技能'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('topbar-search-option-skill-factory')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-skill-factory')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), 'Agent');
    await tester.pumpAndSettle();
    expect(find.text('页面 · 创建助手、发起对话，并通过工作小组处理复杂任务'), findsOneWidget);
    await tester.tap(
        find.byKey(const Key('topbar-search-option-agent-factory-runtime')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-agent-factory-runtime')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), '没有这个对象');
    await tester.pumpAndSettle();
    expect(find.text('无匹配，前往知识库验证'), findsOneWidget);
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

    await tester.tap(find.text('配置').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记忆与存储'));
    await tester.pumpAndSettle();

    expect(find.text('enabled_real'), findsNothing);
    expect(find.text('专业短期记忆'), findsWidgets);
    expect(find.text('记忆与存储配置'), findsOneWidget);
    expect(find.text('本地可用'), findsWidgets);
    expect(find.text('API Key'), findsWidgets);
    expect(find.text('************'), findsWidgets);
    expect(find.text('掩码展示'), findsWidgets);
    expect(find.text('可用'), findsWidgets);
    expect(find.textContaining('Provider Gate'), findsNothing);
    expect(find.textContaining('开发者诊断'), findsNothing);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'settings exposes provider exporter CRUD and audit exposes parallel validation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1600));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('配置').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('模型服务'));
    await tester.pumpAndSettle();
    expect(find.text('连接配置'), findsOneWidget);
    expect(find.text('保存接口配置'), findsOneWidget);
    expect(find.text('测试 AI 模型接口'), findsOneWidget);
    expect(find.text('访问密钥'), findsOneWidget);
    expect(find.textContaining('redacted-runtime-input'), findsNothing);

    await tester.tap(find.text('导出'));
    await tester.pumpAndSettle();
    expect(find.text('文档生成工具设置'), findsOneWidget);
    expect(find.text('保存文档生成配置'), findsOneWidget);
    expect(find.text('测试文档生成配置'), findsOneWidget);
    expect(find.text('内置生成器'), findsOneWidget);
    expect(find.text('DOCX 生成工具'), findsOneWidget);
    expect(find.text('PDF 生成工具'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-dashboard')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看全部动态'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('page-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('验证并行任务'), findsOneWidget);
    expect(find.text('等待并行报告'), findsOneWidget);
    expect(find.text('并行任务验证'), findsOneWidget);
    expect(find.textContaining('task-job-center'), findsNothing);
    expect(find.textContaining('Provider Gate'), findsNothing);
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

    final visibleIndexes = primaryNavigationPageIds
        .map((pageId) => pages.indexWhere((page) => page.id == pageId));
    for (final index in visibleIndexes) {
      final title = pages[index].zhTitle;
      if (pages[index].id != 'document-library') {
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
    expect(find.text('概览'), findsOneWidget);
    expect(find.text('来源'), findsWidgets);
    expect(find.text('验证'), findsOneWidget);
    expect(find.byKey(const Key('knowledge-package-list')), findsOneWidget);
    expect(find.text('质量记录'), findsWidgets);
    expect(find.text('输出目标'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.byKey(const Key('product-status-panel')), findsNothing);
    expect(find.text('生成知识库'), findsWidgets);
    expect(find.text('1. 选择来源文档'), findsNothing);
    expect(find.text('开始生成知识库'), findsNothing);
    expect(find.text('从标准包构建'), findsNothing);
    expect(find.text('更多知识库操作'), findsOneWidget);
    expect(find.text('OKF'), findsNothing);
    expect(find.byKey(const Key('sidebar-okf')), findsNothing);
    await tester.tap(find.byKey(const Key('page-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('知识库验证'), findsWidgets);
    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), '没有这个对象');
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const Key('topbar-search-option-retrieval-verification')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('知识库验证'), findsWidgets);
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
    final reopenDraft = find.widgetWithText(OutlinedButton, '重新打开生成稿');
    final moreGenerationActions = find.text('更多生成操作');
    expect(reopenDraft, findsOneWidget);
    expect(moreGenerationActions, findsOneWidget);
    expect(tester.widget<OutlinedButton>(reopenDraft).onPressed, isNull);
    expect(find.widgetWithText(OutlinedButton, '删除最近记录'), findsNothing);
    expect(find.textContaining('内置本地导出'), findsWidgets);
    final docxChoice =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'DOCX'));
    expect(docxChoice.onSelected, isNotNull);
    await tester.tap(find.text('文档模板').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-template-library')), findsOneWidget);
    expect(find.text('文档模板归文档生成'), findsOneWidget);
    await tester.tap(find.text('导出预览'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-export-preview')), findsOneWidget);
    expect(find.text('PDF'), findsWidgets);
    expect(find.text('PPTX'), findsWidgets);
    final pdfChoice =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'PDF'));
    expect(pdfChoice.onSelected, isNotNull);
    expect(find.textContaining('display_only'), findsNothing);
    expect(find.textContaining('生成本地文件与导出清单'), findsWidgets);
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
    expect(find.text('导入模板技能'), findsWidgets);
    expect(find.text('版本操作'), findsOneWidget);
    expect(find.text('检查导出'), findsOneWidget);
    expect(find.text('从知识库生成技能'), findsWidgets);
    expect(find.byKey(const Key('skill-name-input')), findsOneWidget);
    expect(find.text('技能名称'), findsOneWidget);
    expect(find.text('生成技能'), findsWidgets);
    await tester.tap(find.text('导入模板技能').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('skill-external-localization')), findsOneWidget);
    expect(find.text('能力项'), findsOneWidget);
    expect(find.text('模板技能'), findsWidgets);
    expect(find.text('结构解析'), findsOneWidget);
    expect(find.text('本地知识库'), findsWidgets);
    expect(find.text('个性化目标'), findsWidgets);
    expect(find.text('本地化草稿'), findsOneWidget);
    expect(find.text('改动差异'), findsOneWidget);
    expect(find.text('检查导出绑定'), findsOneWidget);
    expect(find.text('1. 导入模板技能'), findsNothing);
    expect(find.text('查看模板技能结构'), findsNothing);
    expect(find.text('等待导入模板技能'), findsOneWidget);
    expect(find.text('查看本地化技能草稿'), findsNothing);
    expect(find.text('等待本地化草稿'), findsOneWidget);
    expect(find.text('查看改动差异'), findsNothing);
    expect(find.text('等待差异说明'), findsOneWidget);
    expect(find.text('创建助手后绑定'), findsNothing);
    await tester.tap(find.text('版本操作').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);
    expect(find.text('技能版本操作'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
    expect(find.text('复制'), findsOneWidget);
    expect(find.text('融合'), findsOneWidget);
    await tester.tap(find.text('检查导出').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);
    expect(find.text('治理报告与验证'), findsNothing);
    expect(find.text('检查导出'), findsOneWidget);
    expect(find.text('检查技能'), findsOneWidget);
    expect(find.text('更多技能操作'), findsOneWidget);
    expect(find.text('复制技能'), findsNothing);
    expect(find.text('融合技能'), findsNothing);
    expect(find.text('导出技能'), findsOneWidget);
    expect(find.text('绑定助手'), findsNothing);
    expect(find.text('操作清单'), findsOneWidget);
    expect(find.text('助手绑定'), findsOneWidget);
    expect(find.text('复制技能路径'), findsNothing);
    expect(find.text('等待真实技能产物'), findsNothing);
    expect(find.text('等待可预览技能'), findsNothing);
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
        initialSelectedIndex: 9,
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
    expect(find.text('生成知识库'), findsOneWidget);
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
    expect(find.text('导出操作记录报告'), findsOneWidget);
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

    expect(find.text('模型服务'), findsOneWidget);
    expect(find.text('记忆与存储'), findsOneWidget);
    expect(find.text('导出'), findsOneWidget);
    expect(find.text('网络与安全'), findsOneWidget);
    expect(find.text('模板管理'), findsNothing);
    expect(find.text('配置系统'), findsNothing);
    expect(find.text('桌面交付'), findsNothing);
    expect(find.byKey(const Key('settings-provider-storage')), findsNothing);
    await tester.tap(find.text('记忆与存储'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-provider-storage')), findsOneWidget);
    expect(find.textContaining('************'), findsOneWidget);
    expect(find.text('测试存储连接'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    await tester.tap(find.text('导出'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-exporter')), findsOneWidget);
    expect(find.text('文档生成工具设置'), findsOneWidget);
    expect(find.text('高级文档生成工具'), findsWidgets);
    expect(find.text('保存文档生成配置'), findsOneWidget);
    expect(find.text('测试文档生成配置'), findsOneWidget);
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
    expect(find.text('Agent'), findsWidgets);
    expect(find.byKey(const Key('agent-primary-entry-switch')), findsOneWidget);
    expect(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('助手对话'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('工作小组'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('助手配置'),
        ),
        findsOneWidget);
    await tester.tap(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('助手配置'),
        ),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('简单构造'), findsWidgets);
    expect(find.text('复杂构造'), findsOneWidget);
    expect(find.byKey(const Key('agent-name-input')), findsOneWidget);
    expect(find.byKey(const Key('agent-model-config-input')), findsOneWidget);
    expect(find.byKey(const Key('agent-role-goal-input')), findsOneWidget);
    expect(find.text('助手名称'), findsOneWidget);
    expect(find.text('模型配置'), findsWidgets);
    expect(find.text('角色说明'), findsOneWidget);
    expect(find.text('助手对话配置'), findsOneWidget);
    expect(find.text('复杂助手运行配置'), findsNothing);
    expect(find.text('专业短期记忆'), findsNothing);
    expect(find.text('专业长期记忆'), findsNothing);
    expect(find.text('Tool 配置'), findsNothing);
    await tester.tap(find.text('复杂构造'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('复杂助手运行配置'), findsOneWidget);
    expect(find.text('专业短期记忆'), findsOneWidget);
    expect(find.text('专业长期记忆'), findsOneWidget);
    expect(find.text('Tool 配置'), findsNothing);
    expect(find.text('创建助手并进入对话'), findsWidgets);
    expect(find.text('复制助手路径'), findsNothing);
    expect(find.text('等待真实助手产物'), findsNothing);
    expect(find.text('等待可预览助手'), findsNothing);
    expect(find.text('助手对话'), findsWidgets);
    expect(find.text('工作小组'), findsWidgets);
    expect(find.text('助手配置'), findsWidgets);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('生成知识库'), findsNothing);
    expect(find.text('生成技能'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);

    final createAndChatButton = find.text('创建助手并进入对话').first;
    await tester.ensureVisible(createAndChatButton);
    await tester.tap(createAndChatButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('助手对话'),
        ),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-im-dialogue-pane')), findsOneWidget);

    expect(find.byKey(const Key('agent-im-dialogue-pane')), findsOneWidget);
    expect(find.byKey(const Key('agent-im-message-stream')), findsOneWidget);
    expect(find.byKey(const Key('agent-dialogue-input')), findsOneWidget);
    expect(find.byKey(const Key('agent-dialogue-send-button')), findsOneWidget);
    expect(find.text('等待对话产物'), findsNothing);
    expect(find.text('等待会话历史'), findsNothing);
    expect(find.text('等待可预览对话'), findsNothing);
    expect(find.text('等待可预览历史'), findsNothing);
    expect(find.text('等待可清空历史'), findsNothing);

    await tester.tap(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('工作小组'),
        ),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('multi-agent-discussion-product-flow')),
        findsOneWidget);
    expect(find.text('启动工作小组'), findsOneWidget);
    expect(find.text('协作任务输入'), findsWidgets);
    expect(find.byKey(const Key('a2a-topic-input')), findsOneWidget);
    expect(find.text('当前状态'), findsOneWidget);
    expect(find.text('本轮结论'), findsOneWidget);
    expect(find.text('常用助手模板'), findsOneWidget);
    expect(find.text('用常用助手模板创建工作小组'), findsOneWidget);
    expect(find.text('会话记录'), findsNothing);
    expect(find.text('讨论记录'), findsNothing);
    expect(find.text('等待讨论纪要'), findsNothing);
    expect(find.text('等待可预览纪要'), findsNothing);
    expect(find.text('等待会话记录'), findsNothing);
    expect(find.text('等待讨论记录'), findsNothing);
    await tester.tap(
        find.descendant(
          of: find.byKey(const Key('agent-primary-entry-switch')),
          matching: find.text('助手对话'),
        ),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-im-dialogue-pane')), findsOneWidget);
    expect(find.byKey(const Key('agent-dialogue-input')), findsOneWidget);
    expect(find.text('失败与恢复'), findsNothing);
    expect(find.textContaining('Campaign'), findsNothing);
    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(find.textContaining('安全边界'), findsNothing);
    expect(find.text('助手包'), findsNothing);
    expect(find.text('创建助手草稿'), findsNothing);
    expect(find.text('保存版本与导出助手包'), findsNothing);
    expect(find.text('Workspace and Future Runtime'), findsNothing);
    expect(find.text('Subagent'), findsNothing);
    expect(find.text('Sandbox'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.textContaining('Assistant Runtime complete'), findsNothing);
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
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Sources'), findsWidgets);
    expect(find.text('Verification'), findsOneWidget);
    await tester.tap(find.text('Knowledge Base').first);
    await tester.pumpAndSettle();
    expect(find.text('Generate Knowledge Base'), findsOneWidget);
    expect(find.text('知识库'), findsNothing);
    expect(find.text('文档库'), findsNothing);
    expect(find.text('测试知识库'), findsNothing);
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

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('page-scroll-dashboard')), findsOneWidget);
    final statusRect =
        tester.getRect(find.byKey(const Key('desktop-status-bar')));
    expect(statusRect.bottom, lessThanOrEqualTo(1080));
  });
}
