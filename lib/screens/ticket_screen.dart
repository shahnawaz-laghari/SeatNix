import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/rendering.dart';

import '../services/departure_schedule.dart';
import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';

class TicketScreen extends StatelessWidget {
  TicketScreen({
    super.key,
    required this.bookingId,
    required this.from,
    required this.to,
    required this.seat,
    required this.travelDate,
    required this.paymentMethod,
  }) : _ticketBoundaryKey = GlobalKey();

  final GlobalKey _ticketBoundaryKey;
  final String bookingId;
  final String from;
  final String to;
  final String seat;
  final DateTime travelDate;
  final String paymentMethod;

  String get _formattedDate {
    final d = travelDate;
    return '${d.day.toString().padLeft(2, '0')} '
        '${_months[d.month - 1]} ${d.year}, ${formatDepartureTime(d)}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Future<void> _downloadTicket(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final renderObject = _ticketBoundaryKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('The e-ticket is not ready to save.');
      }

      final image = await renderObject.toImage(pixelRatio: 3);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw StateError('Could not create the ticket image.');
        }
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        final fileName = 'seatnix-ticket-$bookingId';
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          await FileSaver.instance.saveToGallery(
            name: fileName,
            bytes: bytes,
            fileExtension: 'png',
            mimeType: MimeType.png,
            album: 'SeatNix Tickets',
          );
        } else {
          await FileSaver.instance.saveFile(
            name: fileName,
            bytes: bytes,
            fileExtension: 'png',
            mimeType: MimeType.png,
          );
        }
      } finally {
        image.dispose();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('e-Ticket image saved to your device.')),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr('Could not download the ticket: {error}', {'error': '$e'}),
            ),
          ),
        );
    }
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(color: mutedText(context), fontSize: 13),
    );
  }

  Widget _value(BuildContext context, String text, {bool large = false}) {
    return Text(
      text,
      style: TextStyle(
        color: primaryText(context),
        fontSize: large ? 16 : 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _leftColumn(List<Widget> children) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _rightColumn(List<Widget> children) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppwriteAuthService.cachedUser;
    final name = user?.name ?? '-';
    final phone = user?.phoneNumber ?? '-';

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
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          'e-Ticket',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: RepaintBoundary(
                  key: _ticketBoundaryKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBackground(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.fromBorderSide(appCardBorder(context)),
                      boxShadow: appCardShadow(context),
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _value(context, 'SeatNix Coach', large: true),
                              const SizedBox(height: 2),
                              _label(context, 'General'),
                            ],
                          ),
                        ),
                        const _DashedDivider(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _leftColumn([
                              _label(context, 'From'),
                              const SizedBox(height: 4),
                              _value(context, from, large: true),
                            ]),
                            _rightColumn([
                              _label(context, 'To'),
                              const SizedBox(height: 4),
                              _value(context, to, large: true),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _leftColumn([_value(context, _formattedDate)]),
                            _rightColumn([_label(context, 'Date of travel')]),
                          ],
                        ),
                        const _DashedDivider(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _leftColumn([
                              _label(context, 'Name'),
                              const SizedBox(height: 4),
                              _value(context, name),
                              const SizedBox(height: 14),
                              _label(context, 'Class'),
                              const SizedBox(height: 4),
                              _value(context, 'General'),
                              const SizedBox(height: 14),
                              _label(context, 'Phone number'),
                              const SizedBox(height: 4),
                              _value(context, phone),
                            ]),
                            _rightColumn([
                              _label(context, 'Booking code'),
                              const SizedBox(height: 4),
                              _value(context, bookingId),
                              const SizedBox(height: 14),
                              _label(context, 'Seat'),
                              const SizedBox(height: 4),
                              _value(context, seat, large: true),
                              const SizedBox(height: 14),
                              _label(context, 'Paid with'),
                              const SizedBox(height: 4),
                              _value(context, paymentMethod),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 64,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BarcodePainter(
                              bookingId,
                              primaryText(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookingId,
                          style: TextStyle(
                            color: primaryText(context),
                            fontSize: 13,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _downloadTicket(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor(context),
                    foregroundColor: buttonTextColor(context),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Download e-Ticket Image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(
          40,
          (i) => Expanded(
            child: Container(
              height: 1,
              color: i.isEven ? dividerColor(context) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed, this.color);

  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(
      seed.codeUnits.fold(0, (a, b) => a * 31 + b) & 0x7fffffff,
    );
    final paint = Paint()..color = color;
    var x = 0.0;
    while (x < size.width) {
      final width = 1.0 + random.nextInt(3);
      if (random.nextBool()) {
        canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      }
      x += width + 1 + random.nextInt(2);
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}
