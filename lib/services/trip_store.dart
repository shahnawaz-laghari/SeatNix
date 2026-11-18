import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/appwrite_config.dart';
import '../models/trip.dart';
import 'appwrite_backend.dart';

class TripStore {
  static String _key(String userId) => 'trips_$userId';
  static String _lastPaymentKey(String userId) => 'last_payment_$userId';

  static Future<List<Trip>> load(String userId) async {
    final localTrips = await _loadLocal(userId);
    if (!AppwriteBackend.tripsConfigured) return localTrips;

    final List<Trip> remoteTrips;
    try {
      final rows = await AppwriteBackend.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.tripsTableId,
        queries: [Query.equal('userId', userId), Query.orderDesc('paidAt')],
      );
      remoteTrips = rows.rows.map((row) => Trip.fromJson(row.data)).toList();
    } on AppwriteException {
      return localTrips;
    }
    final byReference = <String, Trip>{
      for (final trip in localTrips) trip.reference: trip,
      for (final trip in remoteTrips) trip.reference: trip,
    };
    final trips = byReference.values.toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return trips;
  }

  static Future<void> add(String userId, Trip trip) async {
    await _addLocal(userId, trip);
    await _saveLastPaymentLocal(userId, trip);
    if (!AppwriteBackend.tripsConfigured) return;

    await AppwriteBackend.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.tripsTableId,
      rowId: ID.unique(),
      data: {...trip.toJson(), 'userId': userId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
    await _saveLastPaymentRemote(userId, trip);
  }

  static Future<Trip?> loadLastPayment(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString(_lastPaymentKey(userId));
    Trip? localLastPayment;
    if (localJson != null) {
      try {
        localLastPayment = Trip.fromJson(
          jsonDecode(localJson) as Map<String, dynamic>,
        );
      } on FormatException {
        await prefs.remove(_lastPaymentKey(userId));
      } on TypeError {
        await prefs.remove(_lastPaymentKey(userId));
      }
    }

    Trip? remoteLastPayment;
    try {
      final user = await AppwriteBackend.account.get();
      if (user.$id == userId) {
        remoteLastPayment = _tripFromMap(user.prefs.data['lastPayment']);
      }
    } on AppwriteException {
      // Fall back to this device's copy when offline or signed out.
    }

    if (localLastPayment != null || remoteLastPayment != null) {
      final saved = [localLastPayment, remoteLastPayment]
          .whereType<Trip>()
          .toList()
        ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
      final last = saved.first;
      if (localLastPayment?.reference != last.reference) {
        await _saveLastPaymentLocal(userId, last);
      }
      if (remoteLastPayment?.reference != last.reference) {
        try {
          await _saveLastPaymentRemote(userId, last);
        } on AppwriteException {
          // Local last-payment cache remains available if offline.
        }
      }
      return last;
    }

    // Migrate the last payment from older app versions, where it existed only
    // as a trip-history row.
    final trips = await load(userId);
    if (trips.isEmpty) return null;
    final last = trips.first;
    await _saveLastPaymentLocal(userId, last);
    try {
      await _saveLastPaymentRemote(userId, last);
    } on AppwriteException {
      // Local history remains the fallback if updating preferences fails.
    }
    return last;
  }

  static Future<void> delete(String userId, Set<String> references) async {
    if (references.isEmpty) return;

    if (AppwriteBackend.tripsConfigured) {
      final rows = await AppwriteBackend.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.tripsTableId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('paidAt'),
          Query.limit(100),
        ],
      );

      final rowsToDelete = rows.rows.where(
        (row) => references.contains(row.data['reference']),
      );
      for (final row in rowsToDelete) {
        await AppwriteBackend.tables.deleteRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.tripsTableId,
          rowId: row.$id,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final remaining = (prefs.getStringList(_key(userId)) ?? const <String>[])
        .where((item) {
          final trip = Trip.fromJson(jsonDecode(item) as Map<String, dynamic>);
          return !references.contains(trip.reference);
        })
        .toList();
    await prefs.setStringList(_key(userId), remaining);
  }

  static Future<List<Trip>> _loadLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? const <String>[];
    return raw
        .map((item) => Trip.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _addLocal(String userId, Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = List<String>.from(
      prefs.getStringList(_key(userId)) ?? const <String>[],
    );
    raw.insert(0, jsonEncode(trip.toJson()));
    await prefs.setStringList(_key(userId), raw);
  }

  static Future<void> _saveLastPaymentLocal(String userId, Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPaymentKey(userId), jsonEncode(trip.toJson()));
  }

  static Future<void> _saveLastPaymentRemote(String userId, Trip trip) async {
    final user = await AppwriteBackend.account.get();
    if (user.$id != userId) return;
    await AppwriteBackend.account.updatePrefs(
      prefs: {...user.prefs.data, 'lastPayment': trip.toJson()},
    );
  }

  static Trip? _tripFromMap(Object? value) {
    if (value is! Map) return null;
    try {
      return Trip.fromJson(Map<String, dynamic>.from(value));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
