# メメント・モリ（Memento Mori）

「残り寿命」を 年・月・日・時間・分・秒 でリアルタイムにカウントダウン表示する Flutter アプリ。

平均「寿命」ではなく **平均余命（remaining life expectancy, e_x）** を使う。例えば現在50歳なら
「50歳時点の平均余命」が残り寿命のベースになる。端数月齢は e(年齢) と e(年齢+1) を実日数比で
線形補間し、日単位の精度で死亡予測日時を求める。

## 入力項目
- 名前
- 生年月日
- 性別（男/女）— 平均余命は性別で大きく異なるため
- **国籍（国）** — 国別に平均余命が異なるため。未収録国は世界平均にフォールバック

入力は初回のみ。`shared_preferences` で端末内に保存し、次回以降はカウントダウン画面から開始する。

## 平均余命データ
- 出典：**UN World Population Prospects 2024**（国連人口部 / [PPgp/wpp2024](https://github.com/PPgp/wpp2024)）。
- 同梱の 1x1（各歳）死亡率 `mx`（2023年推計）から完全生命表を計算し、各国・男女別に各歳の e_x を算出。
  計算した e0 は WPP 公表値と一致することを検証済み（例：日本 男81.69 / 女87.74）。
- `assets/life_table.json` に **236の国・地域 ＋ 世界平均（`WORLD`）** を ISO 3166-1 alpha-2 コードで収録。
- 国名の日本語表示と国コードの突き合わせには `country_picker` パッケージを利用。

データの再生成手順は `tool/build_life_table.py` を参照。

## セットアップ
このリポジトリには `lib/`・`assets/`・`pubspec.yaml`・`test/` のみを含む。プラットフォーム
（android/ios 等）の足場は未生成なので、初回は以下を実行する：

```bash
flutter create .          # android/ios 等の足場を生成（lib/pubspec は上書きされない）
flutter pub get
flutter analyze
flutter test
flutter run               # エミュレータ/実機で起動
```

## 主なファイル
- `lib/models/user_profile.dart` — 入力プロフィール（name/birthDate/gender/countryCode）
- `lib/services/life_expectancy.dart` — 生命表ロード・国選択／Worldフォールバック・補間・死亡日時算出
- `lib/services/countdown_formatter.dart` — 残り時間の 年月日時分秒 への分解
- `lib/services/profile_store.dart` — プロフィールの保存/復元
- `lib/screens/input_screen.dart` — 入力画面
- `lib/screens/countdown_screen.dart` — カウントダウン画面
- `test/life_expectancy_test.dart` — 補間・フォールバック・分解の単体テスト
