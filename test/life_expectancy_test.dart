import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori/models/user_profile.dart';
import 'package:memento_mori/services/life_expectancy.dart';
import 'package:memento_mori/services/countdown_formatter.dart';

LifeTable buildTable() {
  return LifeTable({
    'source': 'test',
    'maxAge': 100,
    'fallbackCode': 'WORLD',
    'countries': {
      'JP': {
        'male': {'50': 33.0, '51': 32.2, '100': 4.0},
        'female': {'50': 39.0, '51': 38.1, '100': 5.0},
      },
      'WORLD': {
        'male': {'50': 26.0, '51': 25.3, '100': 3.0},
        'female': {'50': 29.0, '51': 28.2, '100': 3.5},
      },
    },
  });
}

void main() {
  group('LifeTable.remainingYears', () {
    final table = buildTable();

    test('50歳ちょうどは e(50) に一致', () {
      final now = DateTime(2026, 6, 22);
      final p = UserProfile(
        name: 'A',
        birthDate: DateTime(1976, 6, 22),
        gender: Gender.male,
        countryCode: 'JP',
      );
      expect(table.remainingYears(p, now), closeTo(33.0, 1e-9));
    });

    test('50歳3ヶ月は e(50) と e(51) の実日数比補間', () {
      final now = DateTime(2026, 6, 22);
      final birth = DateTime(1976, 3, 22);
      final p = UserProfile(
        name: 'A',
        birthDate: birth,
        gender: Gender.male,
        countryCode: 'JP',
      );
      final last = DateTime(2026, 3, 22);
      final next = DateTime(2027, 3, 22);
      final fraction =
          now.difference(last).inSeconds / next.difference(last).inSeconds;
      final expected = 33.0 + (32.2 - 33.0) * fraction;
      expect(table.remainingYears(p, now), closeTo(expected, 1e-9));
      // 補間値は 32.2〜33.0 の範囲に入る。
      expect(table.remainingYears(p, now), inInclusiveRange(32.2, 33.0));
    });

    test('未収録国は世界平均（WORLD）にフォールバック', () {
      final now = DateTime(2026, 6, 22);
      final p = UserProfile(
        name: 'A',
        birthDate: DateTime(1976, 6, 22),
        gender: Gender.female,
        countryCode: 'ZZ', // 存在しない国
      );
      expect(table.hasCountry('ZZ'), isFalse);
      expect(table.remainingYears(p, now), closeTo(29.0, 1e-9)); // WORLD female e(50)
    });

    test('表上限を超える年齢はクランプ', () {
      final now = DateTime(2026, 6, 22);
      final p = UserProfile(
        name: 'A',
        birthDate: DateTime(1916, 6, 22), // 110歳
        gender: Gender.male,
        countryCode: 'JP',
      );
      expect(table.remainingYears(p, now), closeTo(4.0, 1e-9)); // e(100)
    });
  });

  group('LifeDelta（起動時の差分分解）', () {
    test('加齢で余命が伸びる典型ケース：30日経過・余命は27日減少', () {
      final old = DateTime(2026, 6, 22);
      final now = DateTime(2026, 7, 22); // 30日後
      final d = LifeDelta.compute(
        oldRemainingDays: 10000.0,
        oldOpenedAt: old,
        newRemainingDays: 9973.0, // 30日のうち27日分しか減っていない
        now: now,
      );
      expect(d.elapsedDays, closeTo(30.0, 1e-9));
      expect(d.timeDecreaseDays, closeTo(-30.0, 1e-9)); // 時間経過による減少
      expect(d.agingGainDays, closeTo(3.0, 1e-9)); // 加齢による伸び（正）
      expect(d.agingGainDays, greaterThan(0)); // 伸びは常に正
      expect(d.netChangeDays, closeTo(-27.0, 1e-9)); // 差し引き
      // 恒等式：差引 ＝ 伸び ＋ 時間減少 ＝ new − old。
      expect(d.netChangeDays, closeTo(d.agingGainDays + d.timeDecreaseDays, 1e-9));
    });

    test('表上限クランプ中（余命一定）は 伸び ＝ 経過', () {
      final old = DateTime(2026, 6, 22);
      final now = DateTime(2026, 6, 27); // 5日後
      final d = LifeDelta.compute(
        oldRemainingDays: 1460.0,
        oldOpenedAt: old,
        newRemainingDays: 1460.0, // 変化なし
        now: now,
      );
      expect(d.netChangeDays, closeTo(0.0, 1e-9));
      expect(d.agingGainDays, closeTo(d.elapsedDays, 1e-9)); // 伸び ＝ 経過
    });
  });

  group('formatSignedDuration', () {
    test('負の日数', () {
      expect(formatSignedDuration(-1.5), '−1日12時間0分0秒');
    });
    test('正の端数（日なし）', () {
      expect(formatSignedDuration(0.1), '＋2時間24分0秒');
    });
    test('ゼロは秒を表示', () {
      expect(formatSignedDuration(0), '＋0秒');
    });
    test('分・秒の端数', () {
      // 65秒 = 1分5秒。
      expect(formatSignedDuration(65 / 86400), '＋1分5秒');
    });
    test('秒未満は切り捨て', () {
      // 1.9秒 → 1秒。
      expect(formatSignedDuration(1.9 / 86400), '＋1秒');
      // 負側も絶対値で切り捨て（−59.9秒 → −59秒）。
      expect(formatSignedDuration(-59.9 / 86400), '−59秒');
    });
  });

  group('countdown breakdown', () {
    test('既知の差分を年月日時分秒へ分解', () {
      final now = DateTime(2026, 1, 1, 0, 0, 0);
      final target = DateTime(2028, 3, 4, 5, 6, 7);
      final c = breakdown(now, target);
      expect(c.years, 2);
      expect(c.months, 2);
      expect(c.days, 3);
      expect(c.hours, 5);
      expect(c.minutes, 6);
      expect(c.seconds, 7);
      expect(c.expired, isFalse);
    });

    test('過去（target <= now）は expired', () {
      final now = DateTime(2026, 6, 22);
      expect(breakdown(now, now).expired, isTrue);
      expect(breakdown(now, now.subtract(const Duration(days: 1))).expired,
          isTrue);
    });

    test('月末クランプ（1/31 + 1ヶ月 = 2月末）', () {
      final d = addMonths(DateTime(2026, 1, 31), 1);
      expect(d.month, 2);
      expect(d.day, 28); // 2026は平年
    });
  });
}
