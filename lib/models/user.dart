
/*
  user collection

  accountBalances {
    "USD": 1000,
    "EUR": 500,
    "BTC": 0.5,
    "ETH": 2.0,
  }
  bankAccounts {
    accountNumber: "123456789",
    accountType: "checking",
    bankName: "Bank of America",
    isDefault: true,
  }
  */

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? displayName;
  String? email;
  String? uid;
  String? beavertag;
  String? photoURL;
  Timestamp? createdAt;
  Map<String, dynamic>? accountBalances;
  Map<String, Map<String, dynamic>>? bankAccounts;
  bool? isPublic;
  bool? isVerified;
  bool? isBusiness;

  User({
    this.displayName,
    this.email,
    this.uid,
    this.beavertag,
    this.photoURL,
    this.createdAt,
    this.accountBalances,
    this.bankAccounts,
    this.isPublic,
    this.isVerified,
    this.isBusiness,
  });

  // Convert a User object to a Map
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'uid': uid,
      'beavertag': beavertag,
      'photoURL': photoURL,
      'createdAt': createdAt ?? Timestamp.now(),
      'accountBalances': accountBalances ?? {},
      'bankAccounts': bankAccounts ?? {},
      'isPublic': isPublic ?? false,
      'isVerified': isVerified ?? false,
      'isBusiness': isBusiness ?? false,
    };
  }

  // Factory constructor to create a User from Firestore data
  factory User.fromFirestore(Map<String, dynamic> data) {
    Map<String, Map<String, dynamic>>? bankAccountsMap;

    if (data['bankAccounts'] != null) {
      bankAccountsMap = {};
      (data['bankAccounts'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map) {
          bankAccountsMap![key] = Map<String, dynamic>.from(value);
        }
      });
    }

    return User(
      displayName: data['displayName'],
      email: data['email'],
      uid: data['uid'],
      beavertag: data['beavertag'],
      photoURL: data['photoURL'],
      createdAt: data['createdAt'],
      accountBalances: data['accountBalances'] != null
          ? Map<String, dynamic>.from(data['accountBalances'])
          : {},
      bankAccounts: bankAccountsMap,
      isPublic: data['isPublic'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isBusiness: data['isBusiness'] ?? false,
    );
  }

  // Helper methods for bankAccounts management
  void addBankAccount(String bankId, Map<String, dynamic> account) {
    bankAccounts ??= {};
    bankAccounts![bankId] = account;
  }

  void removeBankAccount(String bankId) {
    bankAccounts?.remove(bankId);
  }

  Map<String, dynamic>? getBankAccount(String bankId) {
    return bankAccounts?[bankId];
  }

  Map<String, dynamic>? getDefaultBankAccount() {
    if (bankAccounts == null || bankAccounts!.isEmpty) {
      return null;
    }

    for (var entry in bankAccounts!.entries) {
      if (entry.value['isDefault'] == true) {
        return entry.value;
      }
    }

    // If no default is set, return the first account
    return bankAccounts!.values.first;
  }

  void setDefaultBankAccount(String bankId) {
    if (bankAccounts == null || bankAccounts!.isEmpty) {
      return;
    }

    // First reset all existing defaults
    for (var account in bankAccounts!.values) {
      account['isDefault'] = false;
    }

    // Then set the new default if it exists
    if (bankAccounts!.containsKey(bankId)) {
      bankAccounts![bankId]!['isDefault'] = true;
    }
  }

  // Get all bank accounts as a list
  List<Map<String, dynamic>> getBankAccountsList() {
    if (bankAccounts == null) {
      return [];
    }

    return bankAccounts!.entries.map((entry) {
      final account = Map<String, dynamic>.from(entry.value);
      account['id'] = entry.key; // Include the ID in the account data
      return account;
    }).toList();
  }
}