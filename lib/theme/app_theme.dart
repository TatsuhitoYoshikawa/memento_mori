import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// メメント・モリ — 暖色系デザインのトークン。
/// 淡いクリーム→ピーチ→ローズのグラデーションと、テラコッタのアクセント。
class AppColors {
  AppColors._();

  // アクセント（テラコッタ）
  static const accent = Color(0xFFE07A5F);
  static const accentLight = Color(0xFFEF8E6F);
  static const accentDark = Color(0xFFC9684F);
  static const accentDeep = Color(0xFFB06A52);

  // テキスト
  static const textDefault = Color(0xFF4A3A33);
  static const textTitle = Color(0xFF5A4438);
  static const textLabel = Color(0xFF6A5A51);
  static const textMuted = Color(0xFF8A7A70);
  static const textFaint = Color(0xFF9A8278);

  // 線・面
  static const border = Color(0x38B06A52); // ~0.22
  static const borderSoft = Color(0x29B06A52); // ~0.16
  static const fieldFill = Color(0xB3FFFFFF); // white 0.7
  static const cellFill = Color(0x9EFFFFFF); // white 0.62

  // ステート
  static const positive = Color(0xFF3A9B7E);
  static const negative = Color(0xFFC2554A);
}

class AppGradients {
  AppGradients._();

  /// CSS 168deg ≒ ほぼ上→下（わずかに右傾き）。
  static const _begin = Alignment(-0.18, -1.0);
  static const _end = Alignment(0.18, 1.0);

  static const input = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFFFFF8F1), Color(0xFFFFEEDE), Color(0xFFFFE1DD)],
    stops: [0.0, 0.46, 1.0],
  );

  static const countdown = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFFFFF7EF), Color(0xFFFFE9D9), Color(0xFFFFDCD9)],
    stops: [0.0, 0.5, 1.0],
  );

  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentLight, AppColors.accent],
  );
}

/// テキストスタイル。見出し・数字は明朝(Shippori Mincho)、UI は Zen Kaku Gothic New。
class AppText {
  AppText._();

  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textDefault,
    double height = 1.5,
    bool tabular = false,
  }) =>
      GoogleFonts.shipporiMincho(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );

  static TextStyle ui({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textDefault,
    double height = 1.6,
    double? letterSpacing,
  }) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// 数字（Roboto・等幅数字）。差分表示などに。
  static TextStyle numeric({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textDefault,
  }) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
