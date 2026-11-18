import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../services/departure_schedule.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'payment_screen.dart';

const _seatAvailableColor = Color(0xFF9AA0A6);
const _seatSelectedColor = Color(0xFFF5A00D);
const _seatFilledColor = Color(0xFF0B57A4);
const _bannerColor = Color(0xFFFCE4E8);
const _bannerTextColor = Color(0xFFD32F2F);

class BusSeatScreen extends StatefulWidget {
  const BusSeatScreen({
    super.key,
    required this.from,
    required this.to,
    required this.travelDate,
  });

  final String from;
  final String to;
  final DateTime travelDate;

  @override
  State<BusSeatScreen> createState() => _BusSeatScreenState();
}

class _BusSeatScreenState extends State<BusSeatScreen> {
  static const _rows = 9;
  static const _leftColumns = ['A', 'B', 'C'];
  static const _rightColumns = ['D', 'E', 'F'];

  late final List<DateTime> _departures;
  late DateTime _selectedDeparture;
  late Set<String> _filled;
  String? _selected;
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _departures = departuresFor(widget.travelDate, DateTime.now());
    _selectedDeparture = _departures.first;
    _filled = _generateFilledSeats(_selectedDeparture);
    _remaining = _selectedDeparture.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(
        () => _remaining = _selectedDeparture.difference(DateTime.now()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Set<String> _generateFilledSeats(DateTime departure) {
    final random = Random(departure.millisecondsSinceEpoch ~/ 60000);
    final columns = [..._leftColumns, ..._rightColumns];
    return {
      for (var row = 1; row <= _rows; row++)
        for (final column in columns)
          if (random.nextDouble() < 0.35) '$row$column',
    };
  }

  void _selectDeparture(DateTime departure) {
    setState(() {
      _selectedDeparture = departure;
      _filled = _generateFilledSeats(departure);
      _selected = null;
      _remaining = departure.difference(DateTime.now());
    });
  }

  String get _bannerText {
    if (_remaining.isNegative) {
      return tr('This departure has already left');
    }
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return tr('The remaining time to dispatch {time}', {
      'time': '$hours:$minutes:$seconds',
    });
  }

  int get _availableCount => _rows * 6 - _filled.length;

  void _toggleSeat(String seat) {
    setState(() => _selected = _selected == seat ? null : seat);
  }

  void _confirmSeat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          from: widget.from,
          to: widget.to,
          seat: _selected!,
          travelDate: _selectedDeparture,
        ),
      ),
    );
  }

  Widget _seat(String seat) {
    final isFilled = _filled.contains(seat);
    final isSelected = _selected == seat;
    final color = isFilled
        ? _seatFilledColor
        : isSelected
        ? _seatSelectedColor
        : _seatAvailableColor;

    return GestureDetector(
      onTap: isFilled ? null : () => _toggleSeat(seat),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(Icons.event_seat, size: 30, color: color),
      ),
    );
  }

  Widget _seatRow(int row) {
    return Row(
      children: [
        for (final column in _leftColumns)
          Expanded(child: Center(child: _seat('$row$column'))),
        SizedBox(
          width: 36,
          child: Center(
            child: Text(
              '$row',
              style: TextStyle(
                color: mutedText(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        for (final column in _rightColumns)
          Expanded(child: Center(child: _seat('$row$column'))),
      ],
    );
  }

  Widget _columnHeaders() {
    Widget header(String label) => Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: primaryText(context),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    return Row(
      children: [
        for (final column in _leftColumns) header(column),
        const SizedBox(width: 36),
        for (final column in _rightColumns) header(column),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_seat, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: primaryText(context), fontSize: 13),
        ),
      ],
    );
  }

  Widget _departureChip(DateTime departure) {
    final selected = departure == _selectedDeparture;
    return ChoiceChip(
      label: Text(formatDepartureTime(departure)),
      selected: selected,
      onSelected: (_) => _selectDeparture(departure),
      showCheckmark: false,
      selectedColor: _seatSelectedColor,
      backgroundColor: screenBackground(context),
      side: BorderSide(
        color: selected ? _seatSelectedColor : dividerColor(context),
      ),
      labelStyle: TextStyle(
        color: selected ? buttonTextColor(context) : primaryText(context),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
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
          'Select Seat',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? const Color(0xFF3A2024)
                      : _bannerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: _bannerTextColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _bannerText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _bannerTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.fromBorderSide(appCardBorder(context)),
                  boxShadow: appCardShadow(context),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.from} to ${widget.to}',
                            style: TextStyle(
                              color: primaryText(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('General  •  {count} seats available', {
                              'count': '$_availableCount',
                            }),
                            style: TextStyle(
                              color: mutedText(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: _seatSelectedColor),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'Departure time',
                  style: TextStyle(
                    color: primaryText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _departures.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    Center(child: _departureChip(_departures[index])),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _legendItem('Available', _seatAvailableColor),
                  _legendItem('Selected', _seatSelectedColor),
                  _legendItem('Filled', _seatFilledColor),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBackground(context),
                    border: Border.fromBorderSide(appCardBorder(context)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: appCardShadow(context),
                  ),
                  child: Column(
                    children: [
                      _columnHeaders(),
                      const SizedBox(height: 4),
                      for (var row = 1; row <= _rows; row++) _seatRow(row),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor(context))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected == null ? null : _confirmSeat,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor(context),
                    foregroundColor: buttonTextColor(context),
                    disabledBackgroundColor: accentColor(context)
                        .withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_selected == null ? 'Select a seat' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
