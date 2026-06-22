import 'dart:convert';

enum Gender { male, female }

/// アプリ利用者のプロフィール。
/// インストール後の初回入力で一度だけ作成し、端末内に保存する（要件(1)）。
class UserProfile {
  final String name;
  final DateTime birthDate;
  final Gender gender;

  /// 国籍を表す ISO 3166-1 alpha-2 コード（大文字。例: "JP", "US"）。
  /// 平均余命表に該当国が無い場合は計算時に世界平均へフォールバックする。
  final String countryCode;

  const UserProfile({
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.countryCode,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender.name,
        'countryCode': countryCode,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        name: m['name'] as String,
        birthDate: DateTime.parse(m['birthDate'] as String),
        gender: Gender.values.byName(m['gender'] as String),
        countryCode: (m['countryCode'] as String?) ?? 'JP',
      );

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromJson(String s) =>
      UserProfile.fromMap(jsonDecode(s) as Map<String, dynamic>);
}
