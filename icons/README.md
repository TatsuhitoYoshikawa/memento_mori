# メメント・モリ アプリアイコン（稜線に沈む）

夕陽が砂時計の地平に沈む — 砂が落ちる＝陽が沈むのダブルミーニング。

## ファイル
| ファイル | 用途 |
|---|---|
| `memento_icon_1024.png` | **マスター（1024×1024 / 不透明 / 角丸なし）**。iOS App Store・汎用ソース。 |
| `memento_icon_1024_rounded.png` | プレビュー／参考用（iOS風の角丸付き）。配布には不要。 |
| `android/memento_bg_1024.png` | Android アダプティブ用 **背景**レイヤー（グラデーション）。 |
| `android/memento_fg_1024.png` | Android アダプティブ用 **前景**レイヤー（図案を中央62%・セーフゾーン内に配置・背景透過）。 |

## 形式の指針
- **iOS**：1024×1024 PNG・**透過なし・角丸なし**（角丸はOSが自動でマスク）。← マスターがこの仕様。
- **Android**：アダプティブアイコン（前景＋背景の2レイヤー）推奨。端末ごとに丸/角丸/しずく型へ自動マスクされます。
- 各サイズ（20pt〜1024pt、mdpi〜xxxhdpi）は、マスター1枚から自動生成するのが確実です。

## Flutter での導入（flutter_launcher_icons）
1. マスターを `assets/icon/` に配置（例）。
2. `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  ios: true
  android: true
  remove_alpha_ios: true                       # iOSは透過不可
  image_path: "assets/icon/memento_icon_1024.png"
  adaptive_icon_background: "assets/icon/android/memento_bg_1024.png"
  adaptive_icon_foreground: "assets/icon/android/memento_fg_1024.png"
```
3. 実行：
```bash
flutter pub get
dart run flutter_launcher_icons
```
これで iOS / Android の全サイズが生成・差し替えされます。

> 背景を単色で十分なら `adaptive_icon_background: "#ee9a6f"` でも可（その場合グラデーションは平坦色になります）。
