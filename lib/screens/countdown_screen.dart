import 'dart:async';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/countdown_formatter.dart';
import '../services/life_expectancy.dart';

/// 残り寿命を毎秒カウントダウン表示する画面。
class CountdownScreen extends StatefulWidget {
  final UserProfile profile;

  const CountdownScreen({super.key, required this.profile});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  Timer? _timer;
  DateTime? _deathDateTime;
  Countdown _countdown = Countdown.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final table = await LifeTable.load();
      final now = DateTime.now();
      // 死亡予測日時は1回だけ確定する。
      _deathDateTime = table.deathDateTime(widget.profile, now);
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  void _tick() {
    final death = _deathDateTime;
    if (death == null) return;
    setState(() => _countdown = breakdown(DateTime.now(), death));
  }

  @override
  void dispose() {
    _timer?.cancel();
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
