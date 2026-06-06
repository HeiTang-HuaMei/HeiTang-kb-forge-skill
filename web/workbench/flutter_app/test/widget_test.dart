import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  testWidgets('renders HeiTang workbench shell', (tester) async {
    await tester.pumpWidget(const HeiTangWorkbenchApp());

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
  });
}
