import 'dart:async';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/countdown_formatter.dart';
import '../services/life_expectancy.dart';
import '../services/profile_store.dart';

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
      if (mounted) _showDeltaDialog(delta);
    }
  }

  void _showDeltaDialog(LifeDelta delta) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('おかえりなさい、${widget.profile.name}さん'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('前回から ${formatSignedDuration(delta.elapsedDays).substring(1)} '
                'が経過しました'),
            const SizedBox(height: 12),
            _deltaRow('時間の経過による減少',
                formatSignedDuration(delta.timeDecreaseDays)),
            _deltaRow('加齢による平均余命の伸び',
                formatSignedDuration(delta.agingGainDays)),
            const Divider(),
            _deltaRow('差し引きの残り寿命',
                formatSignedDuration(delta.netChangeDays)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _deltaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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

  @override
  Widget build(BuildContext context) {
    final c = _countdown;
    final text =
        '${c.years}年${c.months}ヶ月${c.days}日${c.hours}時間${c.minutes}分${c.seconds}秒';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error != null)
                Text('エラー: $_error', textAlign: TextAlign.center)
              else ...[
                Text(
                  '${widget.profile.name}さん',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Text(
                  c.expired ? 'ご臨終です' : text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
