import 'dart:typed_data';

import 'package:flutter/material.dart' hide Text;

import '../widgets/localized_text.dart';

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../services/departure_schedule.dart';
import 'bus_seat_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

const _cardCream = Color(0xFFFDF3E2);
const _journeyBlue = Color(0xFF0B57A4);
const _greetingPink = Color(0xFFB0475C);

class _Journey {
  const _Journey({
    required this.title,
    required this.from,
    required this.to,
    required this.time,
    required this.date,
  });

  final String title;
  final String from;
  final String to;
  final String time;
  final String date;
}

const _upcomingJourneys = [
  _Journey(
    title: 'Bus terminal 1',
    from: 'FET',
    to: 'Phatak',
    time: '11 AM',
    date: 'Sun, 1 Nov 2026',
  ),
  _Journey(
    title: 'Bus terminal 2',
    from: 'Hyderabad',
    to: 'Jamshoro',
    time: '2 PM',
    date: 'Sun, 8 Nov 2026',
  ),
  _Journey(
    title: 'Bus terminal 3',
    from: 'FET',
    to: 'Kotri',
    time: '9 AM',
    date: 'Sun, 15 Nov 2026',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  int _selectedDay = 0;
  DateTime? _otherDate;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final bytes = await widget.authService.currentAvatar();
      if (mounted) setState(() => _avatarBytes = bytes);
    } on AuthException {
      // Keep the initials placeholder when an avatar is unavailable.
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            tr('{feature} is coming soon.', {'feature': tr(feature)}),
          ),
        ),
      );
  }

  DateTime get _selectedTravelDate {
    final now = DateTime.now();
    switch (_selectedDay) {
      case 1:
        return DateTime(now.year, now.month, now.day + 1);
      case 2:
        return _otherDate ?? DateTime(now.year, now.month, now.day + 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  String _shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _pickOtherDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appTheme = Theme.of(context);
    final pickerTheme = DatePickerThemeData(
      backgroundColor: cardBackground(context),
      headerBackgroundColor: authAccentColor,
      headerForegroundColor: buttonTextColor(context),
      dividerColor: dividerColor(context),
      dayStyle: TextStyle(color: primaryText(context)),
      weekdayStyle: TextStyle(
        color: mutedText(context),
        fontWeight: FontWeight.w700,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return buttonTextColor(context);
        }
        if (states.contains(WidgetState.disabled)) {
          return mutedText(context).withValues(alpha: 0.4);
        }
        return primaryText(context);
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return authAccentColor;
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.all(authAccentColor),
      todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: mutedText(context),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: authAccentColor,
      ),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _otherDate ?? today.add(const Duration(days: 2)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: appTheme.copyWith(
          colorScheme: appTheme.colorScheme.copyWith(
            primary: authAccentColor,
            onPrimary: buttonTextColor(context),
            surface: cardBackground(context),
            onSurface: primaryText(context),
          ),
          datePickerTheme: pickerTheme,
          canvasColor: cardBackground(context),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _otherDate = picked;
      _selectedDay = 2;
    });
  }

  void _openSeatSelection() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please enter your boarding point and destination.'),
          ),
        );
      return;
    }
    final day = _selectedTravelDate;
    if (departuresFor(day, DateTime.now()).isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No more buses today. Please choose Tomorrow or Other.',
            ),
          ),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BusSeatScreen(from: from, to: to, travelDate: _selectedTravelDate),
      ),
    );
  }

  void _swapLocations() {
    final from = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = from;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(authService: widget.authService),
      ),
    );
    if (mounted) {
      _loadAvatar();
      setState(() {});
    }
  }

  void _openNotifications() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = AppwriteAuthService.cachedUser;
    final name = user?.name ?? 'there';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode(context)
                ? const [Color(0xFF1A1E20), Color(0xFF121416)]
                : const [Color(0xFFFBE7EB), Color(0xFFF6F4F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  children: [
                    _buildHeader(name, _avatarBytes),
                    const SizedBox(height: 24),
                    _buildSearchCard(),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        'Upcoming Journey',
                        style: TextStyle(
                          color: primaryText(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final journey in _upcomingJourneys)
                      _JourneyCard(
                        journey: journey,
                        onTap: () => _comingSoon('Journey details'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openSeatSelection,
                    style: FilledButton.styleFrom(
                      backgroundColor: authAccentColor,
                      foregroundColor: buttonTextColor(context),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Proceed Further'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, Uint8List? avatarBytes) {
    final initials = Text(
      _initials(name),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );

    return Row(
      children: [
        GestureDetector(
          onTap: _openProfile,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: _journeyBlue,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: avatarBytes == null
                ? initials
                : Image.memory(
                    avatarBytes,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => initials,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Hello, {name}', {'name': name}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryText(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Where do you want to go?',
                style: TextStyle(color: _greetingPink, fontSize: 13),
              ),
            ],
          ),
        ),
        Material(
          color: cardBackground(context),
          shape: const CircleBorder(),
          elevation: 1,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openNotifications,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.notifications_none_rounded,
                color: primaryText(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: authAccentColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Column(
                children: [
                  _LocationField(
                    controller: _fromController,
                    hint: 'Boarding from',
                    icon: Icons.radio_button_checked,
                  ),
                  const SizedBox(height: 8),
                  _LocationField(
                    controller: _toController,
                    hint: 'To destination',
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
              Positioned(
                right: 12,
                top: 38,
                child: Material(
                  color: authTextColor,
                  shape: const CircleBorder(
                    side: BorderSide(color: authAccentColor, width: 3),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _swapLocations,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DayChip(
                  label: 'Today',
                  selected: _selectedDay == 0,
                  onTap: () => setState(() => _selectedDay = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DayChip(
                  label: 'Tomorrow',
                  selected: _selectedDay == 1,
                  onTap: () => setState(() => _selectedDay = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DayChip(
                  label: _otherDate == null ? 'Other' : _shortDate(_otherDate!),
                  icon: Icons.calendar_today_outlined,
                  selected: _selectedDay == 2,
                  onTap: _pickOtherDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openSeatSelection,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: authAccentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Find Buses'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: authTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: tr(hint),
          hintStyle: const TextStyle(color: authMutedColor, fontSize: 15),
          prefixIcon: Icon(icon, color: authTextColor, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 56,
          ),
          border: InputBorder.none,
          isCollapsed: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? authTextColor : Colors.white;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.white : _cardCream,
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey, required this.onTap});

  final _Journey journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: mutedText(context), fontSize: 14);
    final valueStyle = TextStyle(
      color: primaryText(context),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(appCardBorder(context)),
        boxShadow: appCardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.title,
                        style: TextStyle(
                          color: primaryText(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text('From', style: labelStyle),
                          ),
                          Expanded(
                            child: Text(journey.from, style: valueStyle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text('To', style: labelStyle),
                          ),
                          Expanded(child: Text(journey.to, style: valueStyle)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 130,
                color: _journeyBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'departure time',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      journey.time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      journey.date,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
