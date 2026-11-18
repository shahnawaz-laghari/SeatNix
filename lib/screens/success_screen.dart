import 'package:flutter/material.dart' hide Text;

import '../services/success_sound.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'ticket_screen.dart';

const _successOrange = Color(0xFFF5A00D);

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({
    super.key,
    required this.bookingId,
    required this.from,
    required this.to,
    required this.seat,
    required this.travelDate,
    required this.paymentMethod,
  });

  final String bookingId;
  final String from;
  final String to;
  final String seat;
  final DateTime travelDate;
  final String paymentMethod;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _badgeScale;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _cardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _badgeScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.78, curve: Curves.elasticOut),
      ),
    );
    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.82, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
    SuccessSound.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openTicket(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketScreen(
          bookingId: widget.bookingId,
          from: widget.from,
          to: widget.to,
          seat: widget.seat,
          travelDate: widget.travelDate,
          paymentMethod: widget.paymentMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context)
          ? const Color(0xFF121416)
          : const Color(0xFFD3D3D3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _cardOpacity,
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                  decoration: BoxDecoration(
                    color: cardBackground(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.fromBorderSide(appCardBorder(context)),
                    boxShadow: appCardShadow(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _badgeScale,
                        child: SizedBox(
                          width: 92,
                          height: 92,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  final progress = CurvedAnimation(
                                    parent: _controller,
                                    curve: const Interval(
                                      0.16,
                                      0.9,
                                      curve: Curves.easeOut,
                                    ),
                                  ).value;
                                  return Opacity(
                                    opacity:
                                        (1 - progress).clamp(0.0, 1.0) * 0.45,
                                    child: Transform.scale(
                                      scale: 0.75 + progress * 0.55,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _successOrange,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: _successOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              ScaleTransition(
                                scale: _checkScale,
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 46,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(
                            0.45,
                            0.9,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: const Text(
                          'Success !',
                          style: TextStyle(
                            color: _successOrange,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your payment was successful. A receipt for this purchase has been sent to your Number.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedText(context),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _openTicket(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _successOrange,
                            foregroundColor: buttonTextColor(context),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Check Ticket'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst),
                          style: FilledButton.styleFrom(
                            backgroundColor: _successOrange,
                            foregroundColor: buttonTextColor(context),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Go Back'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
