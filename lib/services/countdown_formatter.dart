import 'dart:math' as math;

/// 残り時間を 年/月/日/時/分/秒 に分解した結果。
class Countdown {
  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final bool expired;

  const Countdown({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.expired = false,
  });

  static const Countdown zero = Countdown(
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0,
    expired: true,
  );
}

int _daysInMonth(int year, int month) {
  // 翌月0日 ＝ 当月末日。
  return DateTime(year, month + 1, 0).day;
}

/// month ヶ月後の日時。月跨ぎ（例: 1/31 + 1ヶ月）は月末でクランプする。
DateTime addMonths(DateTime d, int months) {
  final int total = d.month - 1 + months;
  final int year = d.year + (total ~/ 12);
  final int month = (total % 12) + 1;
  final int day = math.min(d.day, _daysInMonth(year, month));
  return DateTime(year, month, day, d.hour, d.minute, d.second, d.millisecond);
}

/// 符号付きの日数を「＋○日○時間○分」「−○日○時間○分」へ整形する。
/// 差分のお知らせ表示に用いる（端数は時間・分まで）。
String formatSignedDuration(double days) {
  final int totalSeconds = (days.abs() * 86400).round();
  final String sign = days < 0 ? '−' : '＋';
  final int d = totalSeconds ~/ 86400;
  int rem = totalSeconds % 86400;
  final int h = rem ~/ 3600;
  rem %= 3600;
  final int m = rem ~/ 60;

  final buf = StringBuffer(sign);
  if (d > 0) buf.write('$d日');
  if (h > 0) buf.write('$h時間');
  // 日も時間も0、または分が残る場合は分を出す（必ず何か表示する）。
  if (m > 0 || (d == 0 && h == 0)) buf.write('$m分');
  return buf.toString();
}

/// now から target までの残り時間をカレンダー基準で 年月日時分秒に分解する。
Countdown breakdown(DateTime now, DateTime target) {
  if (!target.isAfter(now)) return Countdown.zero;

  // まず whole-month 数を求める（年＝月÷12）。
  int totalMonths = 0;
  while (!addMonths(now, totalMonths + 1).isAfter(target)) {
    totalMonths += 1;
  }
  final int years = totalMonths ~/ 12;
  final int months = totalMonths % 12;

  final DateTime anchor = addMonths(now, totalMonths);
  int rem = target.difference(anchor).inSeconds;
  final int days = rem ~/ 86400;
  rem %= 86400;
  final int hours = rem ~/ 3600;
  rem %= 3600;
  final int minutes = rem ~/ 60;
  final int seconds = rem % 60;

  return Countdown(
    years: years,
    months: months,
    days: days,
    hours: hours,
    minutes: minutes,
    seconds: seconds,
  );
}
