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
      
      // Get all properties with tenants
      final propertiesSnapshot = await _db
          .collection('artifacts/$_appId/users/$_userId/properties')
          .where('status', isEqualTo: 'Occupied')
          .get();

      for (var propertyDoc in propertiesSnapshot.docs) {
        final propertyData = propertyDoc.data();
        final rentDueDay = propertyData['rentDueDate'] as int? ?? 1;
        
        // Calculate next due date based on day of month
        final nextDueDate = _getNextDueDateFromDay(rentDueDay);
        
        // Check if we should send reminder (3 days before due date)
        if (_shouldSendReminder(nextDueDate, now)) {
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

  DateTime _getNextDueDateFromDay(int dueDay) {
    final now = DateTime.now();
    var nextDue = DateTime(now.year, now.month, dueDay);
    
    // If due date has passed this month, move to next month
    if (nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) {
      if (now.month == 12) {
        nextDue = DateTime(now.year + 1, 1, dueDay);
      } else {
        nextDue = DateTime(now.year, now.month + 1, dueDay);
      }
    }
    
    return nextDue;
  }

  bool _shouldSendReminder(DateTime dueDate, DateTime now) {
    final reminderDate = dueDate.subtract(const Duration(days: 3));
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    
    // Send reminder if today is exactly 3 days before due date
    return today.isAtSameMomentAs(reminderDay);
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