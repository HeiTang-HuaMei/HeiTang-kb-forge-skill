import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpWorkbench(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
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

  testWidgets('rc3 desktop frame stays inside accepted viewport widths',
      (tester) async {
    for (final size in <Size>[
      const Size(1440, 900),
      const Size(1366, 768),
      const Size(1280, 720),
    ]) {
      await pumpWorkbench(tester, size);

      final frame = tester
          .getSize(find.byKey(const Key('desktop-window-preview-frame')).first);
      expect(frame.width, lessThanOrEqualTo(size.width), reason: '$size width');
      expect(frame.height, lessThanOrEqualTo(size.height),
          reason: '$size height');
      expect(
          find.byKey(const Key('desktop-topbar-single-row')), findsOneWidget);
      expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: size.toString());
    }
  });

  testWidgets('rc3 keeps every primary desktop page reachable at 1366x768',
      (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    expect(
        find.byKey(const Key('desktop-window-preview-frame')), findsOneWidget);
    expect(find.byKey(const Key('desktop-topbar-single-row')), findsOneWidget);
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final entry in <MapEntry<Key, String>>[
      const MapEntry(Key('sidebar-dashboard'), '首页'),
      const MapEntry(Key('sidebar-workbook'), '工作区'),
      const MapEntry(Key('sidebar-document-library'), '文档库'),
      const MapEntry(Key('sidebar-knowledge-package-management'), '知识库'),
      const MapEntry(Key('sidebar-retrieval-verification'), '测试知识库'),
      const MapEntry(Key('sidebar-document-generation'), '文档生成'),
      const MapEntry(Key('sidebar-skill-factory'), '技能生成'),
      const MapEntry(Key('sidebar-agent-factory-runtime'), '我的助手'),
      const MapEntry(Key('sidebar-artifact-center'), '成果中心'),
      const MapEntry(Key('sidebar-reports-audit'), '使用记录'),
      const MapEntry(Key('sidebar-workspace'), '设置'),
    ]) {
      final target = find.byKey(entry.key).first;
      await tester.ensureVisible(target);
      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsWidgets, reason: entry.value);
      expect(tester.takeException(), isNull, reason: entry.value);
    }
  });

  testWidgets('rc10 exposes product status without raw boundary labels',
      (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-agent-factory-runtime')));
    await tester.tap(find.byKey(const Key('sidebar-agent-factory-runtime')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('我的助手'), findsWidgets);
    expect(find.byKey(const Key('agent-workspace-setup')), findsOneWidget);
    await tester.tap(find.byKey(const Key('page-tab-1')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('单个助手'), findsOneWidget);
    expect(find.text('enabled_real'), findsNothing);
    expect(find.text('disabled_boundary'), findsNothing);
    expect(find.textContaining('安全边界'), findsNothing);
    expect(find.textContaining('arbitrary shell'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('sidebar-workspace')));
    await tester.tap(find.byKey(const Key('sidebar-workspace')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    final providerTab = find.text('记忆与存储').first;
    await tester.ensureVisible(providerTab);
    await tester.tap(providerTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('************'), findsWidgets);
    expect(find.text('配置系统'), findsNothing);
    expect(find.text('桌面交付'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary product pages do not expose internal gate language',
      (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    for (final entry in <MapEntry<Key, String>>[
      const MapEntry(Key('sidebar-dashboard'), '首页'),
      const MapEntry(Key('sidebar-document-library'), '文档库'),
      const MapEntry(Key('sidebar-knowledge-package-management'), '知识库'),
      const MapEntry(Key('sidebar-retrieval-verification'), '测试知识库'),
      const MapEntry(Key('sidebar-document-generation'), '文档生成'),
      const MapEntry(Key('sidebar-skill-factory'), '技能生成'),
      const MapEntry(Key('sidebar-agent-factory-runtime'), '我的助手'),
      const MapEntry(Key('sidebar-artifact-center'), '成果中心'),
      const MapEntry(Key('sidebar-reports-audit'), '使用记录'),
      const MapEntry(Key('sidebar-workspace'), '设置'),
    ]) {
      await tester.ensureVisible(find.byKey(entry.key).first);
      await tester.tap(find.byKey(entry.key).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      for (final forbidden in <String>[
        'Campaign',
        'campaign',
        'Gate',
        'gate',
        'disabled_boundary',
        'enabled_real',
        'Core 操作',
        '后端矩阵',
        'backend matrix',
        'Parser/OCR 后端证据面板',
      ]) {
        expect(find.textContaining(forbidden), findsNothing,
            reason: '${entry.value} exposes $forbidden');
      }
      expect(tester.takeException(), isNull, reason: entry.value);
    }
  });

  testWidgets('business pages expose natural capability status only',
      (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    final expectations = <MapEntry<Key, List<String>>>[
      const MapEntry(
          Key('sidebar-document-library'), ['资料整理', '图片文字识别', '网页导入']),
      const MapEntry(Key('sidebar-knowledge-package-management'),
          ['本地模式', '来源文档', '生成知识库']),
      const MapEntry(Key('sidebar-document-generation'),
          ['Markdown', 'JSON / CSV', 'DOCX / PDF / PPTX']),
      const MapEntry(
          Key('sidebar-agent-factory-runtime'), ['模型', '短期记忆', '长期记忆', '协作导出']),
    ];

    for (final entry in expectations) {
      await tester.ensureVisible(find.byKey(entry.key).first);
      await tester.tap(find.byKey(entry.key).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      for (final expected in entry.value) {
        expect(find.text(expected), findsWidgets,
            reason: '${entry.key} missing $expected');
      }
      for (final forbidden in <String>[
        '热插拔',
        'hot-swap',
        'external project',
        'n8n',
        'paddleocr',
        'qdrant',
        'provider_ref',
      ]) {
        expect(find.textContaining(forbidden), findsNothing,
            reason: '${entry.key} exposes $forbidden');
      }
      expect(tester.takeException(), isNull, reason: '${entry.key}');
    }
  });
}
