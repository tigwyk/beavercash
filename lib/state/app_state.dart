import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:beavercash/services/db_service.dart';
import 'package:logging/logging.dart';

final log = Logger('AppStateLogs');

class BeaverCashAppState extends ChangeNotifier {
  Map<String, dynamic> _cachedState = {};
  double cashBalance = 1000.00;

  // Load cached state from local storage
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('app_state');
    if (cachedData != null) {
      _cachedState = jsonDecode(cachedData);
    }
  }

  // Save current state to local storage
  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_state', jsonEncode(_cachedState));
  }

  // Get a value from the cached state
  dynamic getValue(String key) {
    return _cachedState[key];
  }

  // Set a value in the cached state
  void setValue(String key, dynamic value) {
    _cachedState[key] = value;
  }

  // Clear the cached state
  Future<void> clearState() async {
    _cachedState.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_state');
  }

  void addMoney() {
    cashBalance += 100.0;
    notifyListeners();
  }
  
  void cashOut() {
    cashBalance = 0.0;
    notifyListeners();
  }
  
  // Get the current balance
  double get currentBalance {
    updateBalanceFromFirestore();
    return cashBalance;
  }

  void updateBalanceFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log.warning('Cannot update balance: No logged in user');
      return;
    }
    
    try {
      final balance = await FirestoreService().getUserBalance(
        userId: user.uid,
        currency: 'CAD',
      );
      
      cashBalance = balance;
      notifyListeners();
    } catch (error) {
      log.severe('Error fetching balance from Firestore: $error');
    }
  }
}