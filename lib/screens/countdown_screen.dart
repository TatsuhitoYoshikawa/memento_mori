import 'dart:async';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/countdown_formatter.dart';
import '../services/life_expectancy.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';

/// 残り寿命を毎秒カウントダウン表示する画面。
///
/// 余命は固定せず、起動・復帰・暦日変化のたびに再計算する（加齢で平均余命が伸びるため）。
/// 起動時、前回起動から暦日が変わっていれば、前回からの差分を分解して知らせる。
class CountdownScreen extends StatefulWidget {
  final UserProfile profile;

  const CountdownScreen({super.key, required this.profile});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with WidgetsBindingObserver {
  final _store = ProfileStore();
  Timer? _timer;
  LifeTable? _table;
  DateTime? _deathDateTime;
  DateTime? _lastRecomputeDate; // 暦日変化の検知用
  Countdown _countdown = Countdown.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      _table = await LifeTable.load();
      await _onOpen(); // 起動 ＝ 「開いた」イベント
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 死亡予測日時を現在の年齢で再計算する（ダイアログ・スナップショット更新は行わない）。
  void _recompute(DateTime now) {
    final table = _table;
    if (table == null) return;
    final newRemaining = table.remainingDays(widget.profile, now);
    final millis = (newRemaining * 24 * 60 * 60 * 1000).round();
    _deathDateTime = now.add(Duration(milliseconds: millis));
    _lastRecomputeDate = _dateOnly(now);
  }

  /// アプリを「開いた」とき（起動・バックグラウンド復帰）の処理。
  /// 余命を再計算し、前回スナップショットと暦日が変わっていれば差分を知らせる。
  Future<void> _onOpen() async {
    final table = _table;
    if (table == null) return;
    final now = DateTime.now();
    final newRemaining = table.remainingDays(widget.profile, now);

    final snapshot = await _store.loadSnapshot();
    final bool dayChanged = snapshot != null &&
        _dateOnly(snapshot.openedAt) != _dateOnly(now);

    // 余命を反映。
    _recompute(now);
    if (mounted) setState(() {});

    // スナップショットを更新（次回比較用）。
    await _store
        .saveSnapshot(LifeSnapshot(openedAt: now, remainingDays: newRemaining));

    if (dayChanged) {
      final delta = LifeDelta.compute(
        oldRemainingDays: snapshot.remainingDays,
        oldOpenedAt: snapshot.openedAt,
        newRemainingDays: newRemaining,
        now: now,
      );
      if (mounted) _showDeltaSheet(delta);
    }
  }

  void _showDeltaSheet(LifeDelta delta) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x47000000),
      builder: (context) => _DeltaSheet(
        name: widget.profile.name,
        delta: delta,
      ),
    );
  }

  void _tick() {
    final death = _deathDateTime;
    if (death == null) return;
    final now = DateTime.now();
    // セッション中に暦日が変わったら静かに再計算（ダイアログは出さない）。
    if (_lastRecomputeDate != null && _dateOnly(now) != _lastRecomputeDate) {
      _recompute(now);
    }
    setState(() => _countdown = breakdown(now, _deathDateTime!));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンドから復帰したら「開いた」とみなして再計算＋差分通知。
    if (state == AppLifecycleState.resumed && _table != null) {
      _onOpen();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// これまで歩んだ時間の割合（生誕〜死亡予測日時のうち、生誕〜現在）。
  double get _livedFraction {
    final death = _deathDateTime;
    if (death == null) return 0;
    final born = widget.profile.birthDate;
    final total = death.difference(born).inSeconds;
    if (total <= 0) return 1;
    final lived = DateTime.now().difference(born).inSeconds;
    return (lived / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = _countdown;
    final pct = _livedFraction;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.countdown),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
            child: _error != null
                ? Center(
                    child: Text('エラー: $_error',
                        textAlign: TextAlign.center,
                        style: AppText.ui(color: AppColors.textMuted)),
                  )
                : Column(
                    children: [
                      // ---- グリーティング ----
                      const SizedBox(height: 34),
                      Text(
                        '${widget.profile.name} さん',
                        style: AppText.ui(
                          size: 14,
                          color: AppColors.textFaint,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.expired ? 'ご臨終です' : 'あなたに残された時間',
                        style: AppText.serif(size: 22, color: AppColors.textTitle),
                      ),

                      // ---- カウントダウングリッド ----
                      Expanded(
                        child: Center(
                          child: c.expired
                              ? Text('🕊',
                                  style: const TextStyle(fontSize: 64))
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        _cell('${c.years}', '年'),
                                        const SizedBox(width: 14),
                                        _cell('${c.months}', 'ヶ月'),
                                        const SizedBox(width: 14),
                                        _cell('${c.days}', '日'),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _cell(_pad(c.hours), '時間'),
                                        const SizedBox(width: 14),
                                        _cell(_pad(c.minutes), '分'),
                                        const SizedBox(width: 14),
                                        _cell(_pad(c.seconds), '秒', live: true),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // ---- 人生プログレス ----
                      if (!c.expired) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('これまで歩んだ時間',
                                style: AppText.ui(
                                    size: 12, color: AppColors.textFaint)),
                            Text('${(pct * 100).toStringAsFixed(1)}%',
                                style: AppText.numeric(
                                    size: 12, color: AppColors.accentDeep)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: const Color(0x29B06A52),
                              ),
                              FractionallySizedBox(
                                widthFactor: pct,
                                child: Container(
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFF3A98B), AppColors.accent],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('いま、この瞬間を大切に。',
                            textAlign: TextAlign.center,
                            style: AppText.serif(
                                size: 13,
                                weight: FontWeight.w500,
                                color: AppColors.textFaint,
                                height: 1.7)),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  Widget _cell(String value, String unit, {bool live = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: live
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFFFE6DA)],
                )
              : null,
          color: live ? null : AppColors.cellFill,
          border: Border.all(
            color: live ? const Color(0x66E07A5F) : AppColors.borderSoft,
            width: 1.5,
          ),
          boxShadow: live
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppText.serif(
                size: 38,
                weight: FontWeight.w700,
                height: 1.0,
                tabular: true,
                color: live ? const Color(0xFFD9694F) : AppColors.textDefault,
              ),
            ),
            const SizedBox(height: 8),
            Text(unit,
                style: AppText.ui(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textFaint,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

/// 「おかえりなさい」差分シート。
class _DeltaSheet extends StatelessWidget {
  final String name;
  final LifeDelta delta;
  const _DeltaSheet({required this.name, required this.delta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDFB), Color(0xFFFFF6EF)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A3C28).withOpacity(.2),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40B06A52),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(.12),
              ),
              child: const Text('🌅', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 14),
            Text('おかえりなさい、$name さん',
                style: AppText.serif(size: 20), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            _elapsedLine(),
            const SizedBox(height: 22),
            // ---- 内訳 ----
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0x0FB06A52),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _row('時間の経過による減少',
                      formatSignedDuration(delta.timeDecreaseDays),
                      AppColors.negative,
                      divider: true),
                  _row('加齢による余命の伸び',
                      formatSignedDuration(delta.agingGainDays),
                      AppColors.positive,
                      divider: true),
                  _row('差し引きの残り寿命',
                      formatSignedDuration(delta.netChangeDays),
                      delta.netChangeDays < 0
                          ? AppColors.negative
                          : AppColors.positive,
                      strong: true),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('今日も、ていねいに',
                          style: AppText.ui(
                              size: 16,
                              weight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _elapsedLine() {
    // 先頭の符号(＋)を除いた経過量を表示する。
    final elapsed = formatSignedDuration(delta.elapsedDays);
    final text = elapsed.isNotEmpty ? elapsed.substring(1) : elapsed;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppText.ui(size: 13, color: AppColors.textMuted),
        children: [
          const TextSpan(text: '前回から '),
          TextSpan(
            text: text,
            style: AppText.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.accentDeep),
          ),
          const TextSpan(text: ' が経過しました'),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor,
      {bool divider = false, bool strong = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: strong ? 13 : 12),
      decoration: divider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x1FB06A52), width: 1),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: AppText.ui(
                    size: strong ? 15 : 14,
                    weight: strong ? FontWeight.w700 : FontWeight.w400,
                    color: strong ? AppColors.textDefault : AppColors.textLabel)),
          ),
          const SizedBox(width: 12),
          Text(value,
              style: AppText.numeric(
                  size: strong ? 15 : 14,
                  weight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }
}
