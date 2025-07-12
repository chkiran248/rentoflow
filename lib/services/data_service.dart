// lib/services/data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataService {
  final FirebaseFirestore _db;
  final String _userId;
  static const String _appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

  DataService(this._db, this._userId);

  // Properties CRUD
  Future<void> addProperty(Map<String, dynamic> property) async {
    await _db.collection('artifacts/$_appId/users/$_userId/properties').add(property);
  }

  Stream<QuerySnapshot> getProperties() {
    return _db.collection('artifacts/$_appId/users/$_userId/properties').snapshots();
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> updates) async {
    await _db.collection('artifacts/$_appId/users/$_userId/properties').doc(propertyId).update(updates);
  }

  Future<void> deleteProperty(String propertyId) async {
    await _db.collection('artifacts/$_appId/users/$_userId/properties').doc(propertyId).delete();
  }

  // Tenants CRUD
  Future<void> addTenant(Map<String, dynamic> tenant) async {
    await _db.collection('artifacts/$_appId/users/$_userId/tenants').add(tenant);
  }

  Stream<QuerySnapshot> getTenants() {
    return _db.collection('artifacts/$_appId/users/$_userId/tenants').snapshots();
  }

  Future<void> updateTenant(String tenantId, Map<String, dynamic> updates) async {
    await _db.collection('artifacts/$_appId/users/$_userId/tenants').doc(tenantId).update(updates);
  }

  Future<void> deleteTenant(String tenantId) async {
    await _db.collection('artifacts/$_appId/users/$_userId/tenants').doc(tenantId).delete();
  }

  // Payments CRUD
  Future<void> addPayment(Map<String, dynamic> payment) async {
    await _db.collection('artifacts/$_appId/users/$_userId/payments').add(payment);
  }

  Stream<QuerySnapshot> getPayments({int? limit}) {
    var query = _db.collection('artifacts/$_appId/users/$_userId/payments')
        .orderBy('date', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  // Financial calculations
  Future<Map<String, double>> getFinancialSummary() async {
    try {
      final propertiesSnapshot = await _db.collection('artifacts/$_appId/users/$_userId/properties').get();
      final paymentsSnapshot = await _db.collection('artifacts/$_appId/users/$_userId/payments').get();
      
      double totalRentalIncome = 0;
      double totalInvested = 0;
      
      for (var doc in propertiesSnapshot.docs) {
        final data = doc.data();
        totalRentalIncome += (data['rentPrice'] as num?)?.toDouble() ?? 0;
      }
      
      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'Paid') {
          totalInvested += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      
      return {
        'totalRentalIncome': totalRentalIncome,
        'totalInvested': totalInvested * 0.3,
        'projectedIncome': (totalInvested * 0.3) * 3.87,
      };
    } catch (e) {
      debugPrint('Error calculating financial summary: $e');
      return {'totalRentalIncome': 0, 'totalInvested': 0, 'projectedIncome': 0};
    }
  }
}