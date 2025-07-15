// lib/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ReminderService {
  final FirebaseFirestore _db;
  final String _userId;
  static const String _appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

  ReminderService(this._db, this._userId);

  // Check for upcoming rent due dates and create reminders
  Future<void> checkAndCreateReminders() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      
      // Get all properties with tenants
      final propertiesSnapshot = await _db
          .collection('artifacts/$_appId/users/$_userId/properties')
          .where('status', isEqualTo: 'Occupied')
          .get();

      for (var propertyDoc in propertiesSnapshot.docs) {
        final propertyData = propertyDoc.data();
        final rentDueDate = propertyData['rentDueDate'] as int? ?? 1;
        
        // Calculate next due date
        final nextDueDate = _getNextDueDate(rentDueDate);
        
        // Check if due date is within 3 days
        if (_isWithinThreeDays(nextDueDate, threeDaysFromNow)) {
          await _createReminderNotification(
            propertyDoc.id,
            propertyData['name'] ?? 'Property',
            nextDueDate,
            propertyData['rentPrice'] ?? 0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  }

  DateTime _getNextDueDate(int dueDay) {
    final now = DateTime.now();
    var nextDue = DateTime(now.year, now.month, dueDay);
    
    // If due date has passed this month, move to next month
    if (nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month + 1, dueDay);
    }
    
    return nextDue;
  }

  bool _isWithinThreeDays(DateTime dueDate, DateTime checkDate) {
    final difference = dueDate.difference(checkDate).inDays;
    return difference >= 0 && difference <= 3;
  }

  Future<void> _createReminderNotification(
    String propertyId,
    String propertyName,
    DateTime dueDate,
    double rentAmount,
  ) async {
    final reminder = {
      'propertyId': propertyId,
      'propertyName': propertyName,
      'dueDate': Timestamp.fromDate(dueDate),
      'rentAmount': rentAmount,
      'message': 'Rent payment of ₹${rentAmount.toStringAsFixed(0)} for $propertyName is due on ${dueDate.day}/${dueDate.month}/${dueDate.year}',
      'type': 'rent_reminder',
      'status': 'pending',
      'createdAt': Timestamp.now(),
    };

    await _db
        .collection('artifacts/$_appId/users/$_userId/reminders')
        .add(reminder);
  }

  // Get pending reminders for display
  Stream<QuerySnapshot> getPendingReminders() {
    return _db
        .collection('artifacts/$_appId/users/$_userId/reminders')
        .where('status', isEqualTo: 'pending')
        .orderBy('dueDate')
        .snapshots();
  }

  // Mark reminder as sent
  Future<void> markReminderAsSent(String reminderId) async {
    await _db
        .collection('artifacts/$_appId/users/$_userId/reminders')
        .doc(reminderId)
        .update({'status': 'sent', 'sentAt': Timestamp.now()});
  }
}