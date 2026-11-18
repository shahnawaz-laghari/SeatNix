import 'dart:math';

import 'package:appwrite/appwrite.dart' show AppwriteException;
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/localized_text.dart';

import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/departure_schedule.dart';
import '../services/trip_store.dart';
import '../widgets/auth_style.dart';
import 'success_screen.dart';

const _paymentBlue = Color(0xFF0B57A4);
const _ticketPrice = 20;
const _taxes = 0;

enum PaymentMethod {
  easyPaisa('EasyPaisa'),
  jazzCash('JazzCash'),
  debitCard('Debit/Credit Card');

  const PaymentMethod(this.label);

  final String label;
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.from,
    required this.to,
    required this.seat,
    required this.travelDate,
  });

  final String from;
  final String to;
  final String seat;
  final DateTime travelDate;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _walletPhoneController;
  final _cardholderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  PaymentMethod _method = PaymentMethod.easyPaisa;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _walletPhoneController = TextEditingController(
      text: AppwriteAuthService.cachedUser?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _walletPhoneController.dispose();
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  int get _total => _ticketPrice + _taxes;

  String get _formattedDate {
    final d = widget.travelDate;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${(d.year % 100).toString().padLeft(2, '0')}, '
        '${formatDepartureTime(d)}';
  }

  String _paymentDetailForTrip() {
    if (_method != PaymentMethod.debitCard) {
      return _walletPhoneController.text.trim();
    }
    final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final lastFour = digits.substring(digits.length - 4);
    final holder = _cardholderController.text
        .trim()
        .replaceAll('|', ' ')
        .toUpperCase();
    final safeHolder = holder.length > 18 ? holder.substring(0, 18) : holder;
    return 'CARD|$lastFour|${_expiryController.text}|$safeHolder';
  }

  String _newBookingId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _payNow() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final bookingId = _newBookingId();
    final userId = AppwriteAuthService.cachedUser?.id;
    if (userId != null) {
      try {
        await TripStore.add(
          userId,
          Trip(
            reference: bookingId,
            from: widget.from,
            to: widget.to,
            seat: widget.seat,
            travelDate: widget.travelDate,
            total: _total,
            paymentMethod: _method.label,
            paymentDetail: _paymentDetailForTrip(),
            paidAt: DateTime.now(),
          ),
        );
      } on AppwriteException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ticket saved on this device; cloud sync failed: '
                '${e.message ?? 'Please try again later.'}',
              ),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          bookingId: bookingId,
          from: widget.from,
          to: widget.to,
          seat: widget.seat,
          travelDate: widget.travelDate,
          paymentMethod: _method.label,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      color: bold ? primaryText(context) : mutedText(context),
      fontSize: bold ? 16 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _methodCard({
    required PaymentMethod method,
    required Widget logo,
    required String subtitle,
  }) {
    final selected = _method == method;
    final textColor = selected ? Colors.white : primaryText(context);
    final subColor = selected ? Colors.white70 : mutedText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? _paymentBlue : cardBackground(context),
        elevation: selected ? 3 : 2,
        shadowColor: isDarkMode(context)
            ? authAccentColor.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected
              ? const BorderSide(color: authAccentColor, width: 1.4)
              : appCardBorder(context),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _method = method),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 76, child: logo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: subColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? Colors.white : mutedText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandTile(Widget logo) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }

  Widget _selectedPaymentFields() {
    final labelStyle = TextStyle(
      color: primaryText(context),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    if (_method != PaymentMethod.debitCard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Mobile wallet number', style: labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _walletPhoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: authFieldDecoration(
              context,
              hint: '+92 300 1234567',
              icon: Icons.phone_android_outlined,
            ),
            validator: (value) {
              final number = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
              if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(number)) {
                return tr('Please enter a valid wallet number');
              }
              return null;
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Cardholder name', style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cardholderController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: authFieldDecoration(
            context,
            hint: 'Name on card',
            icon: Icons.person_outline,
          ),
          validator: (value) => value?.trim().isNotEmpty == true
              ? null
              : tr('Please enter the cardholder name'),
        ),
        const SizedBox(height: 16),
        Text('Card number', style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: authFieldDecoration(
            context,
            hint: '0000 0000 0000 0000',
            icon: Icons.credit_card_outlined,
          ),
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
            return digits.length == 16
                ? null
                : tr('Enter a valid 16-digit card number');
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Expiry date', style: labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [_ExpiryDateFormatter()],
                    decoration: authFieldDecoration(
                      context,
                      hint: 'MM/YY',
                      icon: Icons.calendar_month_outlined,
                    ),
                    validator: _validateExpiry,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Security code', style: labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: authFieldDecoration(
                      context,
                      hint: 'CVV',
                      icon: Icons.lock_outline,
                    ),
                    validator: (value) {
                      final length = value?.length ?? 0;
                      return length == 3 || length == 4
                          ? null
                          : tr('Enter a valid security code');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Demo only. Card details are not stored.',
          style: TextStyle(color: mutedText(context), fontSize: 12),
        ),
      ],
    );
  }

  String? _validateExpiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return tr('Enter expiry as MM/YY');

    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return tr('Enter a valid expiry date');

    final now = DateTime.now();
    final isExpired =
        year < now.year || (year == now.year && month < now.month);
    return isExpired ? tr('This card has expired') : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      appBar: AppBar(
        backgroundColor: screenBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            directionalBackIcon(context),
            textDirection: TextDirection.ltr,
            color: primaryText(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Payment',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  children: [
                    Text(
                      'Booking summary',
                      style: TextStyle(
                        color: primaryText(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _summaryRow('Route', '${widget.from} to ${widget.to}'),
                    _summaryRow('Seat', widget.seat),
                    _summaryRow('Ticket', 'Rs $_ticketPrice'),
                    if (_taxes > 0) _summaryRow('Taxes', 'Rs $_taxes'),
                    Divider(height: 24, color: dividerColor(context)),
                    _summaryRow('Total', 'Rs $_total', bold: true),
                    _summaryRow('Date of travel', _formattedDate),
                    const SizedBox(height: 24),
                    Text(
                      'Payment methods',
                      style: TextStyle(
                        color: primaryText(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _methodCard(
                      method: PaymentMethod.easyPaisa,
                      logo: _brandTile(
                        Image.asset(
                          'assets/images/payments/easypaisa.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      subtitle: 'Mobile wallet',
                    ),
                    _methodCard(
                      method: PaymentMethod.jazzCash,
                      logo: _brandTile(
                        Image.asset(
                          'assets/images/payments/jazzcash.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                        ),
                      ),
                      subtitle: 'Mobile wallet',
                    ),
                    _methodCard(
                      method: PaymentMethod.debitCard,
                      logo: _brandTile(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/payments/visa.svg',
                              width: 34,
                              height: 20,
                            ),
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              'assets/images/payments/mastercard.svg',
                              width: 22,
                              height: 22,
                            ),
                          ],
                        ),
                      ),
                      subtitle: 'Visa or Mastercard',
                    ),
                    _selectedPaymentFields(),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor(context))),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total price',
                        style: TextStyle(
                          color: mutedText(context),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Rs $_total',
                        style: const TextStyle(
                          color: authAccentColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isPaying ? null : _payNow,
                      style: FilledButton.styleFrom(
                        backgroundColor: _paymentBlue,
                        foregroundColor: buttonTextColor(context),
                        disabledBackgroundColor: _paymentBlue.withValues(
                          alpha: 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isPaying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Pay Now'),
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

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = limitedDigits.length <= 2
        ? limitedDigits
        : '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
