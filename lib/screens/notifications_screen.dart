import 'package:flutter/material.dart' hide Text;

import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/trip_store.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Trip>? _trips;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final userId = AppwriteAuthService.cachedUser?.id;
    try {
      final trips = userId == null ? <Trip>[] : await TripStore.load(userId);
      if (mounted) setState(() => _trips = trips);
    } catch (_) {
      if (mounted) setState(() => _trips = <Trip>[]);
    }
  }

  List<_NotificationItem> get _appNotifications => [
    _NotificationItem(
      title: 'Welcome to SeatNix',
      message: 'Choose your route and seat to plan your next trip.',
      time: 'Getting started',
      icon: Icons.directions_bus_outlined,
      color: accentColor(context),
      isTransaction: false,
    ),
    _NotificationItem(
      title: 'Your tickets are easy to find',
      message: 'View your saved tickets and travel history from your profile.',
      time: 'SeatNix update',
      icon: Icons.confirmation_number_outlined,
      color: const Color(0xFF42A5F5),
      isTransaction: false,
    ),
  ];

  List<_NotificationItem> get _transactionNotifications => [
    for (final trip in _trips ?? const <Trip>[])
      _NotificationItem(
        title: 'Booking confirmed',
        message:
            '${trip.from} to ${trip.to}  •  Seat ${trip.seat}  •  Rs ${trip.total}',
        time: _formatTime(trip.paidAt),
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF43A047),
        isTransaction: true,
      ),
  ];

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}, '
        '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _notificationTile(_NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(appCardBorder(context)),
        boxShadow: appCardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(notification.icon, color: notification.color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (notification.isTransaction)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: notification.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Transaction',
                          style: TextStyle(
                            color: notification.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: mutedText(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.time,
                  style: TextStyle(color: mutedText(context), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationList(List<_NotificationItem> notifications) {
    if (_trips == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: mutedText(context),
              ),
              const SizedBox(height: 12),
              Text(
                'No transaction notifications yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText(context), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: notifications.map(_notificationTile).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNotifications = <_NotificationItem>[
      ..._transactionNotifications,
      ..._appNotifications,
    ];

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
          'Notifications',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor(context),
          unselectedLabelColor: mutedText(context),
          indicatorColor: accentColor(context),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _notificationList(allNotifications),
          _notificationList(_transactionNotifications),
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.isTransaction,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final bool isTransaction;
}
