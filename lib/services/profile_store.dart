import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// プロフィールを端末内に保存・復元する（初回入力を一度きりにするため）。
class ProfileStore {
  static const _key = 'user_profile';

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
  }
}
