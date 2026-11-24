import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:memento_mori/main.dart';
import 'package:memento_mori/screens/input_screen.dart';

void main() {
  setUp(() {
    // 保存済みプロフィールなし（初回起動）の状態をモックする。
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('初回起動時は入力画面が表示される', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MementoMoriApp());
    // ローカライズ・プロフィールの非同期読み込みを反映する
    // （ローディング表示のアニメーションがあるため pumpAndSettle は使わない）。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(InputScreen), findsOneWidget);
    expect(find.text('MEMENTO MORI'), findsOneWidget);
  });
}
