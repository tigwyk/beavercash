import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:beavercash/models/user.dart';

final log = Logger('dbServiceLogs');


class FirestoreService {
  final usersCollection = FirebaseFirestore.instance.collection('users');
  final transactionsCollection =
      FirebaseFirestore.instance.collection('transactions');

  // Optimized addUser method for the FirestoreService class
  Future<bool> addUser(User user) async {
    // Ensure we have a UID to use as document ID
    if (user.uid == null || user.uid!.isEmpty) {
      log.severe('Cannot add user without UID');
      return false;
    }

    try {
      // Initialize required fields with defaults for a Canadian payment app
      user.createdAt = Timestamp.now();

      // Set default account balances (focusing on CAD for Canadian app)
      user.accountBalances = {
        'CAD': 0, // Canadian dollars (primary currency)
        'USD': 0, // US dollars (common secondary currency)
        'BTC': 0, // Bitcoin (common crypto)
        'ETH': 0, // Ethereum (common crypto)
      };

      // Initialize with empty bank accounts map - we'll add accounts later
      // Don't create a placeholder empty account
      user.bankAccounts = {};

      // Convert user to JSON
      final userToAdd = user.toJson();

      // Use the UID as document ID for easy lookup
      await usersCollection.doc(user.uid).set(userToAdd);

      log.info('User added successfully with ID: ${user.uid}');
      return true;
    } catch (e) {
      log.severe('Error adding user: $e');
      return false;
    }
  }

  // Add a method to create a user after Firebase Auth sign-in
  Future<bool> createUserAfterSignIn(
      {required String uid, required String email, String? displayName, String? beaverTag, String? photoURL}) async {
    try {
      // Check if user already exists
      final docSnapshot = await usersCollection.doc(uid).get();

      // If user already exists, don't create a new one
      if (docSnapshot.exists) {
        log.info('User already exists in Firestore: $uid');
        return true;
      }

      // Create new user with Firebase Auth data
      final user = User(
        uid: uid,
        email: email,
        beavertag: beaverTag,
        photoURL: photoURL,
        displayName: displayName ?? email.split('@').first, // Use first part of email if no display name
      );

      // Add user to Firestore
      return await addUser(user);
    } catch (e) {
      log.severe('Error creating user after sign-in: $e');
      return false;
    }
  }

  // Add method to add a new bank account with proper ID generation
  Future<String?> addBankAccount(String userId, Map<String, dynamic> accountDetails) async {
    try {
      // Generate a unique ID for the bank account
      String bankId = FirebaseFirestore.instance.collection('temp').doc().id;

      // Check if this is the first account (make it default)
      final docSnapshot = await usersCollection.doc(userId).get();

      if (!docSnapshot.exists) {
        log.warning('User not found: $userId');
        return null;
      }

      final userData = docSnapshot.data() as Map<String, dynamic>;
      final bankAccounts = userData['bankAccounts'] as Map<String, dynamic>? ?? {};

      // If this is the first account, make it default
      if (bankAccounts.isEmpty) {
        accountDetails['isDefault'] = true;
      } else {
        accountDetails['isDefault'] = false;
      }

      // Add metadata about when the account was added
      accountDetails['addedAt'] = Timestamp.now();

      // Add bank account to the user document
      await usersCollection.doc(userId).update({
        'bankAccounts.$bankId': accountDetails
      });

      log.info('Bank account added successfully for user $userId with ID $bankId');
      return bankId;
    } catch (e) {
      log.severe('Error adding bank account: $e');
      return null;
    }
  }

  // Return single user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot querySnapshot = await usersCollection
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        log.warning('No user found with email: $email');
        return null;
      }
    } catch (e) {
      log.severe('Error fetching user by email: $e');
      return null;
    }
  }

  // List all users
  Future<void> listUsers() async {
    try {
      final QuerySnapshot querySnapshot = await usersCollection.get();
      final List<QueryDocumentSnapshot> documents = querySnapshot.docs;
      for (var doc in documents) {
        log.info('User: ${doc.data()}');
      }
    } catch (e) {
      log.severe('Error listing users: $e');
    }
  }

  // Add money to a user's account balance using a transaction
  Future<bool> addMoneyToUserBalance({
    required String userId, 
    required double amount, 
    required String currency
  }) async {
    if (amount <= 0) {
      log.warning('Cannot add non-positive amount: $amount');
      return false;
    }
    
    try {
      // Use a Firestore transaction to ensure atomicity
      bool success = await FirebaseFirestore.instance.runTransaction<bool>(
        (transaction) async {
          // Get the current user document within the transaction
          final docRef = usersCollection.doc(userId);
          final docSnapshot = await transaction.get(docRef);
          
          if (!docSnapshot.exists) {
            log.warning('User not found: $userId');
            return false;
          }
          
          // Get the current balance
          final userData = docSnapshot.data() as Map<String, dynamic>;
          final accountBalances = userData['accountBalances'] as Map<String, dynamic>? ?? {};
          final currentBalance = (accountBalances[currency] ?? 0).toDouble();
          
          // Calculate the new balance
          final newBalance = currentBalance + amount;
          
          // Update the user's balance within the transaction
          transaction.update(docRef, {
            'accountBalances.$currency': newBalance
          });
          
          // Create a transaction record ID to use in the transaction
          final transactionId = FirebaseFirestore.instance.collection('temp').doc().id;
          final transactionRef = transactionsCollection.doc(transactionId);
          
          // Set transaction record within the transaction
          transaction.set(transactionRef, {
            'userId': userId,
            'type': 'deposit',
            'amount': amount,
            'currency': currency,
            'timestamp': Timestamp.now(),
            'previousBalance': currentBalance,
            'balanceAfter': newBalance,
            'method': 'app',
            'status': 'completed',
            'transactionId': transactionId
          });
          
          return true;
        },
        maxAttempts: 3, // Retry up to 3 times on conflicts
      );
      
      if (success) {
        log.info('Successfully added $amount $currency to user $userId');
      } else {
        log.warning('Failed to add money to user balance');
      }
      
      return success;
    } catch (e) {
      log.severe('Error adding money to user balance: $e');
      return false;
    }
  }

  // Get user's current balance - No transaction needed for read-only operations
  Future<double> getUserBalance({required String userId, required String currency}) async {
    try {
      final docSnapshot = await usersCollection.doc(userId).get();
      
      if (!docSnapshot.exists) {
        log.warning('User not found when fetching balance: $userId');
        return 0.0;
      }
      
      final userData = docSnapshot.data() as Map<String, dynamic>;
      final accountBalances = userData['accountBalances'] as Map<String, dynamic>? ?? {};
      final balance = (accountBalances[currency] ?? 0).toDouble();
      
      log.info('Retrieved $currency balance for user $userId: $balance');
      return balance;
    } catch (e) {
      log.severe('Error fetching user balance: $e');
      return 0.0; // Return default on error
    }
  }

  // Cash out using a transaction
  Future<bool> cashOutUserBalance({required String userId, required String currency}) async {
    try {
      // Use a Firestore transaction to ensure atomicity
      bool success = await FirebaseFirestore.instance.runTransaction<bool>(
        (transaction) async {
          // Get the current user document within the transaction
          final docRef = usersCollection.doc(userId);
          final docSnapshot = await transaction.get(docRef);
          
          if (!docSnapshot.exists) {
            log.warning('User not found: $userId');
            return false;
          }
          
          // Get the current balance
          final userData = docSnapshot.data() as Map<String, dynamic>;
          final accountBalances = userData['accountBalances'] as Map<String, dynamic>? ?? {};
          final currentBalance = (accountBalances[currency] ?? 0).toDouble();
          
          if (currentBalance <= 0) {
            log.warning('Cannot cash out zero or negative balance for user $userId');
            return false;
          }
          
          // Update the user's balance within the transaction
          transaction.update(docRef, {
            'accountBalances.$currency': 0
          });
          
          // Create a transaction record ID to use in the transaction
          final transactionId = FirebaseFirestore.instance.collection('temp').doc().id;
          final transactionRef = transactionsCollection.doc(transactionId);
          
          // Set transaction record within the transaction
          transaction.set(transactionRef, {
            'userId': userId,
            'type': 'cash_out',
            'amount': currentBalance,
            'currency': currency,
            'timestamp': Timestamp.now(),
            'previousBalance': currentBalance,
            'balanceAfter': 0,
            'method': 'app',
            'status': 'completed',
            'transactionId': transactionId
          });
          
          return true;
        },
        maxAttempts: 3, // Retry up to 3 times on conflicts
      );
      
      if (success) {
        log.info('Successfully cashed out user $userId $currency balance');
      } else {
        log.warning('Failed to cash out user balance');
      }
      
      return success;
    } catch (e) {
      log.severe('Error cashing out user balance: $e');
      return false;
    }
  }

  // Transfer money between users (new method)
  Future<bool> transferMoney({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? notes
  }) async {
    if (amount <= 0) {
      log.warning('Cannot transfer non-positive amount: $amount');
      return false;
    }
    
    if (fromUserId == toUserId) {
      log.warning('Cannot transfer money to self');
      return false;
    }
    
    try {
      // Use a Firestore transaction to ensure atomicity
      bool success = await FirebaseFirestore.instance.runTransaction<bool>(
        (transaction) async {
          // Get sender document within the transaction
          final senderRef = usersCollection.doc(fromUserId);
          final senderDoc = await transaction.get(senderRef);
          
          if (!senderDoc.exists) {
            log.warning('Sender not found: $fromUserId');
            return false;
          }
          
          // Get recipient document within the transaction
          final recipientRef = usersCollection.doc(toUserId);
          final recipientDoc = await transaction.get(recipientRef);
          
          if (!recipientDoc.exists) {
            log.warning('Recipient not found: $toUserId');
            return false;
          }
          
          // Get sender's balance
          final senderData = senderDoc.data() as Map<String, dynamic>;
          final senderBalances = senderData['accountBalances'] as Map<String, dynamic>? ?? {};
          final senderBalance = (senderBalances[currency] ?? 0).toDouble();
          
          // Check if sender has enough funds
          if (senderBalance < amount) {
            log.warning('Insufficient funds for transfer: $senderBalance < $amount');
            return false;
          }
          
          // Get recipient's balance
          final recipientData = recipientDoc.data() as Map<String, dynamic>;
          final recipientBalances = recipientData['accountBalances'] as Map<String, dynamic>? ?? {};
          final recipientBalance = (recipientBalances[currency] ?? 0).toDouble();
          
          // Calculate new balances
          final newSenderBalance = senderBalance - amount;
          final newRecipientBalance = recipientBalance + amount;
          
          // Update sender's balance
          transaction.update(senderRef, {
            'accountBalances.$currency': newSenderBalance
          });
          
          // Update recipient's balance
          transaction.update(recipientRef, {
            'accountBalances.$currency': newRecipientBalance
          });
          
          // Create a unique transfer ID
          final transferId = FirebaseFirestore.instance.collection('temp').doc().id;
          
          // Create transaction records for both parties
          final senderTransactionRef = transactionsCollection.doc('${transferId}_send');
          transaction.set(senderTransactionRef, {
            'userId': fromUserId,
            'recipientId': toUserId,
            'type': 'send',
            'amount': amount,
            'currency': currency,
            'timestamp': Timestamp.now(),
            'previousBalance': senderBalance,
            'balanceAfter': newSenderBalance,
            'notes': notes,
            'status': 'completed',
            'transferId': transferId
          });
          
          final recipientTransactionRef = transactionsCollection.doc('${transferId}_receive');
          transaction.set(recipientTransactionRef, {
            'userId': toUserId,
            'senderId': fromUserId,
            'type': 'receive',
            'amount': amount,
            'currency': currency,
            'timestamp': Timestamp.now(),
            'previousBalance': recipientBalance,
            'balanceAfter': newRecipientBalance,
            'notes': notes,
            'status': 'completed',
            'transferId': transferId
          });
          
          return true;
        },
        maxAttempts: 3, // Retry up to 3 times on conflicts
      );
      
      if (success) {
        log.info('Successfully transferred $amount $currency from $fromUserId to $toUserId');
      } else {
        log.warning('Failed to complete transfer');
      }
      
      return success;
    } catch (e) {
      log.severe('Error transferring money: $e');
      return false;
    }
  }

  // Get user's transaction history
  Future<List<Map<String, dynamic>>> getUserTransactions({
    required String userId,
    int limit = 20
  }) async {
    try {
      final querySnapshot = await transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
        
      return querySnapshot.docs.map((doc) => 
        Map<String, dynamic>.from(doc.data() as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      log.severe('Error fetching user transactions: $e');
      return [];
    }
  }
}