import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/localized_text.dart';

import '../models/trip.dart';
import '../services/trip_store.dart';
import '../services/auth_service.dart';
import '../widgets/auth_style.dart';

const _paymentBlue = Color(0xFF0B57A4);

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  Trip? _lastPayment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AppwriteAuthService.cachedUser?.id;
    final lastPayment = userId == null
        ? null
        : await TripStore.loadLastPayment(userId);
    if (!mounted) return;
    setState(() {
      _lastPayment = lastPayment;
      _loading = false;
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: mutedText(context), fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: primaryText(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodLogo(String method) {
    final Widget logo;
    if (method == 'EasyPaisa') {
      logo = Image.asset(
        'assets/images/payments/easypaisa.png',
        width: 86,
        height: 34,
        fit: BoxFit.contain,
      );
    } else if (method == 'JazzCash') {
      logo = Image.asset(
        'assets/images/payments/jazzcash.png',
        width: 38,
        height: 38,
        fit: BoxFit.contain,
      );
    } else {
      logo = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/payments/visa.svg',
            width: 38,
            height: 22,
          ),
          const SizedBox(width: 5),
          SvgPicture.asset(
            'assets/images/payments/mastercard.svg',
            width: 24,
            height: 24,
          ),
        ],
      );
    }
    return Container(
      width: 94,
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }

  String _paymentDetailSummary(Trip trip) {
    if (trip.paymentDetail.startsWith('CARD|')) {
      final parts = trip.paymentDetail.split('|');
      return parts.length > 1 ? '•••• ${parts[1]}' : 'Visa / Mastercard';
    }
    return trip.paymentDetail;
  }

  Future<void> _showPaymentMethodDetails(Trip trip) {
    final isCard = trip.paymentMethod.toLowerCase().contains('card');
    final parts = trip.paymentDetail.split('|');
    final hasSavedCardData =
        isCard && trip.paymentDetail.startsWith('CARD|') && parts.length >= 4;
    final lastFour = hasSavedCardData ? parts[1] : null;
    final expiry = hasSavedCardData ? parts[2] : null;
    final cardholder = hasSavedCardData ? parts[3] : null;
    var showDetails = false;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: cardBackground(sheetContext),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor(sheetContext),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment method details',
                        style: TextStyle(
                          color: primaryText(sheetContext),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: tr(
                        showDetails ? 'Hide details' : 'Show details',
                      ),
                      onPressed: () =>
                          setSheetState(() => showDetails = !showDetails),
                      icon: Icon(
                        showDetails
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: primaryText(sheetContext),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isCard)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B57A4), Color(0xFF123B70)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              trip.paymentMethod,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _paymentMethodLogo(trip.paymentMethod),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          hasSavedCardData && showDetails
                              ? '••••  ••••  ••••  $lastFour'
                              : '••••  ••••  ••••  ••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _cardDetail(
                                sheetContext,
                                'Cardholder',
                                hasSavedCardData
                                    ? (showDetails ? cardholder! : '••••••••')
                                    : 'Details not saved',
                              ),
                            ),
                            _cardDetail(
                              sheetContext,
                              'Expires',
                              hasSavedCardData
                                  ? (showDetails ? expiry! : '••/••')
                                  : '--/--',
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _paymentBlue,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _paymentMethodLogo(trip.paymentMethod),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.paymentMethod,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                showDetails ? trip.paymentDetail : '••••••••',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  isCard
                      ? 'For your security, the full card number and security code are never saved.'
                      : 'This is the wallet number used for your last payment.',
                  style: TextStyle(
                    color: mutedText(sheetContext),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardDetail(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final last = _lastPayment;
    if (last == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No payment method used yet. Your last payment method will appear here after you book a seat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText(context),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Last payment method',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: _paymentBlue,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showPaymentMethodDetails(last),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _paymentMethodLogo(last.paymentMethod),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          last.paymentMethod,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _paymentDetailSummary(last),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view payment details',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Last payment',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: dividerColor(context)),
        _detailRow('Amount paid', 'Rs ${last.total}'),
        Divider(height: 1, color: dividerColor(context)),
        _detailRow('Date paid', formatShortDate(last.paidAt)),
        Divider(height: 1, color: dividerColor(context)),
        _detailRow('Booking code', last.reference),
        Divider(height: 1, color: dividerColor(context)),
      ],
    );
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
          'Payment Details',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _body()),
    );
  }
}
