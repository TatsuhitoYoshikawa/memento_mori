import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

import '../models/user_profile.dart';
import '../services/profile_store.dart';
import 'countdown_screen.dart';

/// 初回起動時の入力画面：名前・生年月日・性別・国籍を入力する。
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  Gender _gender = Gender.male;
  String _countryCode = 'JP'; // 既定: 日本

  final _store = ProfileStore();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _countryLabel(BuildContext context) {
    final localized =
        CountryLocalizations.of(context)?.countryName(countryCode: _countryCode);
    return localized ?? _countryCode;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '生年月日を選択',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() => _countryCode = country.countryCode);
      },
    );
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _birthDate != null;

  Future<void> _submit() async {
    if (!_isValid) return;
    final profile = UserProfile(
      name: _nameController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender,
      countryCode: _countryCode,
    );
    await _store.save(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CountdownScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final birthLabel = _birthDate == null
        ? '生年月日を選択'
        : '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日';

    return Scaffold(
      appBar: AppBar(title: const Text('メメント・モリ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'お名前'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('生年月日'),
              subtitle: Text(birthLabel),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickBirthDate,
            ),
            const SizedBox(height: 8),
            const Text('性別'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<Gender>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('男性'),
                    value: Gender.male,
                    groupValue: _gender,
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<Gender>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('女性'),
                    value: Gender.female,
                    groupValue: _gender,
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('国籍'),
              subtitle: Text(_countryLabel(context)),
              trailing: const Icon(Icons.public),
              onTap: _pickCountry,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isValid ? _submit : null,
              child: const Text('決定'),
            ),
          ],
        ),
      ),
    );
  }
}
