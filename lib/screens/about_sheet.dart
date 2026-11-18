import 'package:flutter/material.dart' hide Text;

import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';

/// Opens the About slider from Settings.
void showAboutSheet(BuildContext context, {required String version}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AboutSheet(version: version),
  );
}

class AboutSheet extends StatefulWidget {
  const AboutSheet({super.key, required this.version});

  final String version;

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = primaryText(context);
    final muted = mutedText(context);
    final rtl = isRtlLayout(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        height: MediaQuery.sizeOf(context).height * 0.86,
        decoration: BoxDecoration(
          color: cardBackground(context),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
              child: Row(
                textDirection: Directionality.of(context),
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Text(
                        'About SeatNix',
                        style: TextStyle(
                          color: text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: muted),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5A00D), Color(0xFFF7C948)],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                textDirection: Directionality.of(context),
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Image.asset(
                      'assets/images/app-icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SeatNix',
                          style: TextStyle(
                            color: buttonTextColor(context),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Plan. Book. Ride.',
                          style: TextStyle(
                            color: buttonTextColor(context)
                                .withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'v${widget.version}',
                      style: TextStyle(
                        color: buttonTextColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  _AboutPage(text: text, muted: muted),
                  _TeamPage(text: text, muted: muted),
                  _WhyPage(text: text, muted: muted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                textDirection: Directionality.of(context),
                children: [
                  if (_page > 0)
                    IconButton(
                      onPressed: () => _goToPage(_page - 1),
                      icon: Icon(
                        rtl ? Icons.chevron_right : Icons.chevron_left,
                        color: text,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pageCount; i++)
                          GestureDetector(
                            onTap: () => _goToPage(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _page == i ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _page == i
                                    ? authAccentColor
                                    : dividerColor(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_page < _pageCount - 1) {
                        _goToPage(_page + 1);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: authAccentColor,
                      foregroundColor: buttonTextColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_page < _pageCount - 1 ? 'Next' : 'Done'),
                        const SizedBox(width: 4),
                        Icon(
                          _page < _pageCount - 1
                              ? directionalChevronIcon(context)
                              : Icons.check_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage({required this.text, required this.muted});

  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is SeatNix',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A simple way to plan a bus trip.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.directions_bus_outlined,
            title: 'Book a seat',
            body: 'Search routes, pick a departure time and choose your seat from an easy seat map.',
            color: const Color(0xFF0B57A4),
            text: text,
          ),
          _InfoCard(
            icon: Icons.receipt_long_outlined,
            title: 'Keep your tickets',
            body: 'View a digital e-ticket, save it as an image, and find all past trips in Travel History.',
            color: authAccentColor,
            text: text,
          ),
          _InfoCard(
            icon: Icons.translate_outlined,
            title: 'Made for everyone',
            body: 'Use the app in English or Urdu, with full right-to-left layout, and switch between light and dark themes.',
            color: const Color(0xFF43A047),
            text: text,
          ),
        ],
      ),
    );
  }
}

class _TeamPage extends StatelessWidget {
  const _TeamPage({required this.text, required this.muted});

  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final members = [
      (
        name: 'Shah Nawaz Ahmed',
        role: 'Developer',
        initials: 'SA',
        color: const Color(0xFF0B57A4),
      ),
      (
        name: 'Israr Memon',
        role: 'UI Designer',
        initials: 'IM',
        color: const Color(0xFFF5A00D),
      ),
      (
        name: 'Shahzaib Shaikh',
        role: 'Requirement Engineer',
        initials: 'SS',
        color: const Color(0xFF43A047),
      ),
      (
        name: 'Asim Nawaz Khan',
        role: 'Project Manager',
        initials: 'AN',
        color: const Color(0xFF7E57C2),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who made it',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The people behind SeatNix.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final member in members)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? const Color(0xFF262C2F)
                      : const Color(0xFFF5F7F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.fromBorderSide(appCardBorder(context)),
                  boxShadow: appCardShadow(context),
                ),
                child: Row(
                  textDirection: Directionality.of(context),
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: member.color,
                      child: Text(
                        member.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              color: text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            member.role,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.verified_outlined,
                      size: 18,
                      color: member.color,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WhyPage extends StatelessWidget {
  const _WhyPage({required this.text, required this.muted});

  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why we made it',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The idea behind the app.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.speed_outlined,
            title: 'Simplify booking',
            body: 'Finding a seat and planning a trip should take seconds, not minutes. SeatNix keeps the whole flow in one place.',
            color: const Color(0xFF0B57A4),
            text: text,
          ),
          _InfoCard(
            icon: Icons.apps_outlined,
            title: 'Learn by building',
            body: 'The project is a hands-on learning exercise covering Flutter UI, authentication, storage, localization and theming.',
            color: authAccentColor,
            text: text,
          ),
          _InfoCard(
            icon: Icons.people_outline,
            title: 'A team effort',
            body: 'Design, requirements, development and project management came together to shape the app you see today.',
            color: const Color(0xFF43A047),
            text: text,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        textDirection: Directionality.of(context),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: mutedText(context),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
