import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
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
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x47000000),
      builder: (context) => _BirthDateSheet(
        initial: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
        minDate: DateTime(1900),
        maxDate: now,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickCountry() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x47000000),
      builder: (context) => const _CountryPickerSheet(),
    );
    if (code != null) setState(() => _countryCode = code);
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
                          color: AppColors.accent.withValues(alpha: .4),
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
                decoration: _fieldDecoration(hint: '太郎'),
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
                      color: AppColors.accent.withValues(alpha: .28),
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

/// 生年月日をロール（ホイール）で選ぶボトムシート。
/// 月ごとの日数・閏年は CupertinoDatePicker が自動で正しく扱う。
class _BirthDateSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime minDate;
  final DateTime maxDate;
  const _BirthDateSheet({
    required this.initial,
    required this.minDate,
    required this.maxDate,
  });

  @override
  State<_BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<_BirthDateSheet> {
  late int _year;
  late int _month;
  late int _day;
  late final List<int> _years;
  late final FixedExtentScrollController _yearCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _dayCtrl;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
    _day = widget.initial.day;
    _years = [
      for (int y = widget.minDate.year; y <= widget.maxDate.year; y++) y
    ];
    _yearCtrl = FixedExtentScrollController(initialItem: _years.indexOf(_year));
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  /// 選択中の年月の日数（閏年・月末を正しく扱う）。
  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  /// 月や年の変更で日数が減ったとき、選択日を月末へ丸めてホイールも合わせる。
  void _clampDay() {
    final maxDay = _daysInMonth;
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayCtrl.hasClients) _dayCtrl.jumpToItem(_day - 1);
      });
    }
  }

  /// 1900-01-01〜今日の範囲にクランプした確定値。
  DateTime get _result {
    var d = DateTime(_year, _month, _day);
    if (d.isBefore(widget.minDate)) d = widget.minDate;
    if (d.isAfter(widget.maxDate)) d = widget.maxDate;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDFB), Color(0xFFFFF6EF)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A3C28).withValues(alpha: .2),
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
            const SizedBox(height: 16),
            Text('生年月日を選択', style: AppText.serif(size: 18)),
            const SizedBox(height: 14),
            // 年・月・日を独立したホイールに分割（それぞれ単独で回せる）。
            SizedBox(
              height: 190,
              child: Row(
                children: [
                  _wheel(
                    controller: _yearCtrl,
                    count: _years.length,
                    label: (i) => '${_years[i]}年',
                    onChanged: (i) => setState(() {
                      _year = _years[i];
                      _clampDay();
                    }),
                  ),
                  const SizedBox(width: 10),
                  _wheel(
                    controller: _monthCtrl,
                    count: 12,
                    label: (i) => '${i + 1}月',
                    onChanged: (i) => setState(() {
                      _month = i + 1;
                      _clampDay();
                    }),
                  ),
                  const SizedBox(width: 10),
                  _wheel(
                    controller: _dayCtrl,
                    count: _daysInMonth,
                    label: (i) => '${i + 1}日',
                    onChanged: (i) => setState(() => _day = i + 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryButton(
              label: '決定',
              enabled: true,
              onPressed: () => Navigator.of(context).pop(_result),
            ),
          ],
        ),
      ),
    );
  }

  /// 枠で囲った単独のホイール。
  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int index) label,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: 40,
          squeeze: 1.1,
          diameterRatio: 1.3,
          onSelectedItemChanged: onChanged,
          selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
            background: Color(0x1FE07A5F),
          ),
          children: [
            for (int i = 0; i < count; i++)
              Center(
                child: Text(label(i),
                    style: AppText.ui(size: 18, color: AppColors.textDefault)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 国籍を選ぶボトムシート。検索は国名（日本語・英語）・国コードの部分一致。
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  final List<Country> _all = CountryService().getAll();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ローカライズされた国名（無ければ英語名）。
  String _displayName(Country c) =>
      CountryLocalizations.of(context)?.countryName(countryCode: c.countryCode) ??
      c.name;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final results = _all.where((c) {
      if (query.isEmpty) return true;
      // 部分一致：日本語名・英語名・国コードのいずれかに含まれれば対象。
      return _displayName(c).toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query) ||
          c.countryCode.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFDFB), Color(0xFFFFF6EF)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x40B06A52),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text('国籍を選択', style: AppText.serif(size: 18)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: AppText.ui(size: 16),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    hintText: '国名で検索（部分一致）',
                    hintStyle: AppText.ui(size: 15, color: AppColors.textMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.accentDeep),
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text('見つかりませんでした',
                            style: AppText.ui(color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final c = results[i];
                          return ListTile(
                            leading: Text(c.flagEmoji,
                                style: const TextStyle(fontSize: 24)),
                            title: Text(_displayName(c),
                                style: AppText.ui(size: 16)),
                            onTap: () =>
                                Navigator.of(context).pop(c.countryCode),
                          );
                        },
                      ),
              ),
            ],
          ),
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
                  color: AppColors.accent.withValues(alpha: .34),
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
