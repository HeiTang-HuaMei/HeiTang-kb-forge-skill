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

    for (final label in <String>[
      '仪表盘',
      '检索与验证',
      '文档库',
      '知识库',
      '文档生成',
      'Skill 工厂',
      'Agent 工厂',
      '审计与报告',
      '设置',
    ]) {
      final target = find.text(label).first;
      await tester.ensureVisible(target);
      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets, reason: label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('rc10 exposes product status without raw boundary labels',
      (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    await tester.ensureVisible(find.text('Agent 工厂').first);
    await tester.tap(find.text('Agent 工厂').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Agent 工厂'), findsWidgets);
    expect(find.byKey(const Key('agent-workspace-setup')), findsOneWidget);
    await tester.tap(find.byKey(const Key('page-tab-1')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('最小对话'), findsOneWidget);
    expect(find.text('enabled_real'), findsNothing);
    expect(find.text('disabled_boundary'), findsNothing);
    expect(find.textContaining('安全边界'), findsNothing);
    expect(find.textContaining('arbitrary shell'), findsNothing);

    await tester.ensureVisible(find.text('设置').first);
    await tester.tap(find.text('设置').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    final providerTab = find.text('Provider 与存储').first;
    await tester.ensureVisible(providerTab);
    await tester.tap(providerTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('************'), findsWidgets);

    final desktopTab = find.text('桌面交付').first;
    await tester.ensureVisible(desktopTab);
    await tester.tap(desktopTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('v4.3.0-rc10'), findsWidgets);
    expect(find.text('v4.3.0-rc6'), findsNothing);
    expect(find.text('v4.3.0-rc2'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
