import 'package:flutter/material.dart' hide Text;
import 'package:appwrite/appwrite.dart' show AppwriteException;

import '../widgets/localized_text.dart';

import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/departure_schedule.dart';
import '../services/trip_store.dart';
import '../widgets/auth_style.dart';

const _tripBlue = Color(0xFF0B57A4);

class TravelHistoryScreen extends StatefulWidget {
  const TravelHistoryScreen({super.key});

  @override
  State<TravelHistoryScreen> createState() => _TravelHistoryScreenState();
}

class _TravelHistoryScreenState extends State<TravelHistoryScreen> {
  List<Trip>? _trips;
  final Set<String> _selectedReferences = <String>{};
  bool _selectionMode = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AppwriteAuthService.cachedUser?.id;
    final trips = userId == null ? <Trip>[] : await TripStore.load(userId);
    if (!mounted) return;
    setState(() => _trips = trips);
  }

  void _startSelection(Trip trip) {
    setState(() {
      _selectionMode = true;
      _selectedReferences.add(trip.reference);
    });
  }

  void _toggleSelection(Trip trip) {
    setState(() {
      if (_selectedReferences.contains(trip.reference)) {
        _selectedReferences.remove(trip.reference);
      } else {
        _selectedReferences.add(trip.reference);
      }
    });
  }

  void _toggleSelectAll() {
    final trips = _trips ?? const <Trip>[];
    setState(() {
      if (_selectedReferences.length == trips.length) {
        _selectedReferences.clear();
      } else {
        _selectedReferences
          ..clear()
          ..addAll(trips.map((trip) => trip.reference));
      }
    });
  }

  void _stopSelection() {
    setState(() {
      _selectionMode = false;
      _selectedReferences.clear();
    });
  }

  Future<void> _confirmDelete() async {
    if (_selectedReferences.isEmpty || _isDeleting) return;
    final references = Set<String>.from(_selectedReferences);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardBackground(context),
        title: Text(
          'Delete selected trips?',
          style: TextStyle(color: primaryText(context)),
        ),
        content: Text(
          tr('This will delete {count} trip(s) from your history.', {
            'count': '${references.length}',
          }),
          style: TextStyle(color: mutedText(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await _deleteSelected(references);
  }

  Future<void> _deleteSelected(Set<String> references) async {
    final userId = AppwriteAuthService.cachedUser?.id;
    if (userId == null) return;

    setState(() => _isDeleting = true);
    try {
      await TripStore.delete(userId, references);
      if (!mounted) return;
      setState(() {
        _trips = (_trips ?? <Trip>[])
            .where((trip) => !references.contains(trip.reference))
            .toList();
        _selectedReferences.clear();
        _selectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('{count} trip(s) deleted.', {'count': '${references.length}'}),
          ),
        ),
      );
    } on AppwriteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Could not delete trips: {error}', {
              'error': e.message ?? tr('Please try again.'),
            }),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete trips. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _tripCard(Trip trip) {
    final selected = _selectedReferences.contains(trip.reference);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: selected
            ? authAccentColor.withValues(alpha: 0.12)
            : cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? authAccentColor : dividerColor(context),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_selectionMode) {
            _toggleSelection(trip);
          } else {
            _startSelection(trip);
          }
        },
        onLongPress: () => _startSelection(trip),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (_selectionMode)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 14),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? authAccentColor : mutedText(context),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.from} to ${trip.to}',
                        style: TextStyle(
                          color: primaryText(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatLongDate(trip.travelDate)}, '
                        '${formatDepartureTime(trip.travelDate)}',
                        style: TextStyle(
                          color: mutedText(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Seat ${trip.seat}  •  ${trip.paymentMethod}',
                        style: TextStyle(
                          color: mutedText(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 110,
                color: _tripBlue,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Paid',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${trip.total}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trip.reference,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1,
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

  Widget _body() {
    final trips = _trips;
    if (trips == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No trips yet. Your booked trips will appear here.',
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
        if (!_selectionMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Long press a trip or tap Select to choose trips for deletion.',
              style: TextStyle(color: mutedText(context), fontSize: 13),
            ),
          ),
        for (final trip in trips) _tripCard(trip),
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
            _selectionMode ? Icons.close : directionalBackIcon(context),
            textDirection: TextDirection.ltr,
            color: primaryText(context),
          ),
          onPressed: _selectionMode
              ? _stopSelection
              : () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _selectionMode
              ? tr('{count} selected', {
                  'count': '${_selectedReferences.length}',
                })
              : 'Travel History',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if ((_trips?.isNotEmpty ?? false) && !_selectionMode)
            IconButton(
              tooltip: tr('Select trips'),
              onPressed: () => setState(() => _selectionMode = true),
              icon: Icon(Icons.checklist, color: primaryText(context)),
            ),
          if (_selectionMode) ...[
            IconButton(
              tooltip: tr('Select all'),
              onPressed: _toggleSelectAll,
              icon: Icon(Icons.select_all, color: primaryText(context)),
            ),
            IconButton(
              tooltip: tr('Delete selected trips'),
              onPressed: _selectedReferences.isEmpty || _isDeleting
                  ? null
                  : _confirmDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.delete_outline,
                      color: _selectedReferences.isEmpty
                          ? mutedText(context)
                          : Colors.redAccent,
                    ),
            ),
          ],
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }
}
