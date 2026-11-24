import 'package:material_ui/material_ui.dart';
import 'package:country_picker/country_picker.dart';

import 'models/user_profile.dart';
import 'screens/countdown_screen.dart';
import 'screens/input_screen.dart';
import 'services/profile_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MementoMoriApp());
}

class MementoMoriApp extends StatelessWidget {
  const MementoMoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'メメント・モリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7EF),
        useMaterial3: true,
      ),
      // 日本語表示（国名ピッカー・日付ピッカーを含む）。
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja'), Locale('en')],
      // Material / Cupertino / Widgets の各ローカライズは material_ui の
      // GlobalMaterialLocalizations.delegates にまとめて含まれる。
      localizationsDelegates: const [
        CountryLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const _Root(),
    );
  }
}

/// 保存済みプロフィールがあればカウントダウン、なければ入力画面へ。
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: ProfileStore().load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.countdown),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) return const InputScreen();
        return CountdownScreen(profile: profile);
      },
    );
  }
}
