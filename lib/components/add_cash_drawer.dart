import 'package:beavercash/services/db_service.dart';
import 'package:beavercash/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

final log = Logger('AddCashDrawerLogs');

class AddCashDrawer extends StatefulWidget {
  const AddCashDrawer({Key? key}) : super(key: key);

  @override
  State<AddCashDrawer> createState() => _AddCashDrawerState();
}

class _AddCashDrawerState extends State<AddCashDrawer> {
  double _currentAmount = 0.0;
  bool _isCustomInput = false;
  String _customInput = '';

  void _addAmount(double amount) {
    setState(() {
      _currentAmount += amount;
    });
  }

  void _switchToCustomInput() {
    setState(() {
      _isCustomInput = true;
      _customInput = '';
    });
  }

  void _updateCustomInput(String value) {
    setState(() {
      _customInput += value;
      _currentAmount = double.tryParse(_customInput) ?? 0.0;
    });
  }

  void _clearCustomInput() {
    setState(() {
      _customInput = '';
      _currentAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the app state using watch to rebuild if it changes
    
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$${_currentAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              if (!_isCustomInput)
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () => _addAmount(1),
                      child: const Text('\$1'),
                    ),
                    ElevatedButton(
                      onPressed: () => _addAmount(10),
                      child: const Text('\$10'),
                    ),
                    ElevatedButton(
                      onPressed: () => _addAmount(20),
                      child: const Text('\$20'),
                    ),
                    ElevatedButton(
                      onPressed: () => _addAmount(50),
                      child: const Text('\$50'),
                    ),
                    ElevatedButton(
                      onPressed: () => _addAmount(100),
                      child: const Text('\$100'),
                    ),
                    ElevatedButton(
                      onPressed: _switchToCustomInput,
                      child: const Text('...'),
                    ),
                  ],
                )
              else
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index < 9) {
                        return ElevatedButton(
                          onPressed: () => _updateCustomInput('${index + 1}'),
                          child: Text('${index + 1}'),
                        );
                      } else if (index == 9) {
                        return ElevatedButton(
                          onPressed: _clearCustomInput,
                          child: const Text('C'),
                        );
                      } else if (index == 10) {
                        return ElevatedButton(
                          onPressed: () => _updateCustomInput('0'),
                          child: const Text('0'),
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCustomInput = false;
                            });
                          },
                          child: const Text('OK'),
                        );
                      }
                    },
                  ),
                ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () async {
                  if (_currentAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an amount greater than zero'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  // Get current user ID
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be logged in to add cash'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    // Call the FirestoreService to update the user's balance in Firestore
                    final firestoreService = FirestoreService();
                    final success = await firestoreService.addMoneyToUserBalance(
                      userId: currentUser.uid,
                      amount: _currentAmount,
                      currency: 'CAD', // Using CAD as default currency for Canadian app
                    );
                    
                    if (success) {
                      // Update the app state
                      final appState = context.read<BeaverCashAppState>();
                      appState.updateBalanceFromFirestore();
                      
                      // Close the drawer
                      Navigator.pop(context);
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added \$${_currentAmount.toStringAsFixed(2)} to your account'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Log the transaction
                      log.info('Added \$${_currentAmount.toStringAsFixed(2)} to account for user ${currentUser.uid}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add money to your account. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    log.severe('Error adding money to account: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An error occurred: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Add Cash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}