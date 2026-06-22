import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/user_profile.dart';

/// 平均余命（remaining life expectancy, e_x）表を扱うサービス。
///
/// データ出典：UN World Population Prospects 2024（国連人口部 / PPgp/wpp2024）の
/// 1x1（各歳）死亡率 mx から計算した完全生命表（2023年推計）。
/// 国別・男女別に各歳の e_x を保持し、未収録国は世界平均（WORLD）へフォールバックする。
class LifeTable {
  final Map<String, dynamic> _data;

  LifeTable(this._data);

  int get maxAge => _data['maxAge'] as int;
  String get fallbackCode => _data['fallbackCode'] as String;
  String get source => _data['source'] as String;

  /// assets/life_table.json から読み込む。
  static Future<LifeTable> load() async {
    final s = await rootBundle.loadString('assets/life_table.json');
    return LifeTable(jsonDecode(s) as Map<String, dynamic>);
  }

  /// 指定国コードの表を返す。未収録ならフォールバック（世界平均）。
  Map<String, dynamic> _countryTable(String code) {
    final countries = _data['countries'] as Map<String, dynamic>;
    final t = countries[code.toUpperCase()] ?? countries[fallbackCode];
    return t as Map<String, dynamic>;
  }

  /// 指定国に固有のデータが存在するか（false ＝ 世界平均が使われる）。
  bool hasCountry(String code) =>
      (_data['countries'] as Map<String, dynamic>)
          .containsKey(code.toUpperCase());

  double _ex(Map<String, dynamic> sexTable, int age) =>
      (sexTable['$age'] as num).toDouble();

  /// プロフィールと現在時刻から「残り平均余命（年）」を線形補間で求める。
  /// 端数月齢は e(age) と e(age+1) を実日数比で補間する（要件(4)）。
  double remainingYears(UserProfile p, DateTime now) {
    final table = _countryTable(p.countryCode);
    final sexTable =
        table[p.gender == Gender.male ? 'male' : 'female'] as Map<String, dynamic>;

    // 完了年齢と直近・次の誕生日を求める。
    int age = now.year - p.birthDate.year;
    DateTime lastBirthday =
        DateTime(p.birthDate.year + age, p.birthDate.month, p.birthDate.day);
    if (lastBirthday.isAfter(now)) {
      age -= 1;
      lastBirthday =
          DateTime(p.birthDate.year + age, p.birthDate.month, p.birthDate.day);
    }

    if (age >= maxAge) {
      // 表上限を超える場合は上限値でクランプ。
      return _ex(sexTable, maxAge);
    }

    final DateTime nextBirthday =
        DateTime(p.birthDate.year + age + 1, p.birthDate.month, p.birthDate.day);

    final double fraction = now.difference(lastBirthday).inSeconds /
        nextBirthday.difference(lastBirthday).inSeconds;

    final double eLow = _ex(sexTable, age);
    final double eHigh = _ex(sexTable, age + 1);
    return eLow + (eHigh - eLow) * fraction;
  }

  /// 死亡予測日時を1回だけ確定する（カウントダウンは滑らかさ優先のため再計算しない）。
  DateTime deathDateTime(UserProfile p, DateTime now) {
    final double years = remainingYears(p, now);
    final double days = years * 365.25; // 余命を日単位へ（要件(4)）
    final int millis = (days * 24 * 60 * 60 * 1000).round();
    return now.add(Duration(milliseconds: millis));
  }
}
