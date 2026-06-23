import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

import '../models/user_profile.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
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

  String _countryFlag() =>
      _countryCode.toUpperCase().codeUnits.map((c) => String.fromCharCode(0x1F1E6 + c - 0x41)).join();

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '生年月日を選択',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.accent),
        ),
        child: child!,
      ),
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
        : '${_birthDate!.year}年 ${_birthDate!.month}月 ${_birthDate!.day}日';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.input),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
            children: [
              // ---- ヘッダー ----
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF3A98B), AppColors.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MEMENTO MORI',
                    style: AppText.serif(
                      size: 15,
                      color: AppColors.accentDeep,
                    ).copyWith(letterSpacing: 1.8),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'かぎりある時間を、\n見つめるために。',
                style: AppText.serif(size: 27, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                'はじめに、あなたのことを\n少しだけ教えてください。',
                style: AppText.ui(
                    size: 14, height: 1.7, color: AppColors.textMuted),
              ),
              const SizedBox(height: 36),

              // ---- お名前 ----
              _label('お名前'),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                style: AppText.ui(size: 16),
                cursorColor: AppColors.accent,
                decoration: _fieldDecoration(hint: '例：美咲'),
              ),

              // ---- 生年月日 ----
              const SizedBox(height: 24),
              _label('生年月日'),
              _TapField(
                onTap: _pickBirthDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      birthLabel,
                      style: AppText.ui(
                        size: 16,
                        color: _birthDate == null
                            ? AppColors.textMuted
                            : AppColors.textDefault,
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.accentDeep),
                  ],
                ),
              ),

              // ---- 性別 ----
              const SizedBox(height: 24),
              _label('性別'),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0x8CFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft, width: 1.5),
                ),
                child: Row(
                  children: [
                    _segment('男性', Gender.male),
                    const SizedBox(width: 8),
                    _segment('女性', Gender.female),
                  ],
                ),
              ),

              // ---- 国籍 ----
              const SizedBox(height: 24),
              _label('国籍'),
              _TapField(
                onTap: _pickCountry,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(_countryFlag(),
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(_countryLabel(context),
                            style: AppText.ui(size: 16)),
                      ],
                    ),
                    const Icon(Icons.public,
                        size: 20, color: AppColors.accentDeep),
                  ],
                ),
              ),

              // ---- 決定 ----
              const SizedBox(height: 36),
              _PrimaryButton(
                label: '決定',
                enabled: _isValid,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(text,
            style:
                AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.textLabel)),
      );

  InputDecoration _fieldDecoration({required String hint}) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.ui(size: 16, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: border(AppColors.border, 1.5),
      focusedBorder: border(AppColors.accent, 1.8),
    );
  }

  Widget _segment(String label, Gender value) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected ? AppGradients.accent : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppText.ui(
              size: 15,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF8A7064),
            ),
          ),
        ),
      ),
    );
  }
}

/// タップで開くフィールド（生年月日・国籍）。
class _TapField extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapField({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// アクセントのメインボタン。
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.accent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(.34),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: AppText.ui(
                    size: 17,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
