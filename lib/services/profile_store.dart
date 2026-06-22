import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// 前回起動時の残り余命スナップショット（差分のお知らせ用）。
class LifeSnapshot {
  final DateTime openedAt;
  final double remainingDays;

  const LifeSnapshot({required this.openedAt, required this.remainingDays});

  Map<String, dynamic> toMap() => {
        'openedAt': openedAt.toIso8601String(),
        'remainingDays': remainingDays,
      };

  factory LifeSnapshot.fromMap(Map<String, dynamic> m) => LifeSnapshot(
        openedAt: DateTime.parse(m['openedAt'] as String),
        remainingDays: (m['remainingDays'] as num).toDouble(),
      );
}

/// プロフィールを端末内に保存・復元する（初回入力を一度きりにするため）。
class ProfileStore {
  static const _key = 'user_profile';
  static const _snapshotKey = 'life_snapshot';

  Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return null;
    try {
      return UserProfile.fromJson(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile.toJson());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_snapshotKey);
  }

  Future<LifeSnapshot?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_snapshotKey);
    if (s == null) return null;
    try {
      return LifeSnapshot.fromMap(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSnapshot(LifeSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, jsonEncode(snapshot.toMap()));
  }
}
