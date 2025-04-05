import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:beavercash/services/db_service.dart';
import 'package:beavercash/components/infocard.dart';
import 'package:beavercash/components/add_cash_drawer.dart';
import 'package:beavercash/state/app_state.dart'; // Import the app state instead of main.dart

final log = Logger('CashBalanceWidgetLogs');

class CashBalanceWidget extends StatefulWidget {
  @override
  _CashBalanceWidgetState createState() => _CashBalanceWidgetState();
}

class _CashBalanceWidgetState extends State<CashBalanceWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  double _currentBalance = 0.0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserBalance();
  }

  Future<void> _loadUserBalance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not logged in';
        });
        return;
      }

      final balance = await _firestoreService.getUserBalance(
        userId: currentUser.uid,
        currency: 'CAD'
      );
      
      setState(() {
        _currentBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      log.severe('Error loading user balance: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load balance';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We still access the AppState to keep the local UI in sync
    final appState = context.watch<BeaverCashAppState>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return InfoCard(
      title: 'Cash Balance',
      subtitle: 'Account & Routing',
      bodyText: _isLoading 
          ? 'Loading...' 
          : _errorMessage.isNotEmpty 
              ? _errorMessage 
              : '\$${_currentBalance.toStringAsFixed(2)}',
      buttons: [
        ButtonInfo(
          label: 'Add money',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: false, // Makes the drawer take up proper space
              builder: (context) {
                return AddCashDrawer();
              },
            ).then((_) {
              // Refresh balance when the drawer is closed
              _loadUserBalance();
              
              // Also update the app state
              appState.updateBalanceFromFirestore();
            });
          },
        ),
        ButtonInfo(
          label: 'Cash out',
          onPressed: () async {
            if (_currentBalance <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No funds to cash out')),
              );
              return;
            }
            
            // Show confirmation dialog
            final shouldCashOut = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Cash Out'),
                content: Text('Are you sure you want to cash out \$${_currentBalance.toStringAsFixed(2)}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Cash Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ) ?? false;
            
            if (!shouldCashOut) return;
            
            try {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You must be logged in to cash out')),
                );
                return;
              }
              
              final success = await _firestoreService.cashOutUserBalance(
                userId: currentUser.uid, 
                currency: 'CAD'
              );
              
              if (success) {
                // Refresh the displayed balance
                _loadUserBalance();
                
                // Update app state
                appState.updateBalanceFromFirestore();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully cashed out \$${_currentBalance.toStringAsFixed(2)}'),
                    backgroundColor: colorScheme.tertiary,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cash out. Please try again.'),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            } catch (e) {
              log.severe('Error during cash out: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('An error occurred: $e'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      onTap: () {
        log.info('Cash balance card tapped');
        _loadUserBalance(); // Refresh when card is tapped
      },
    );
  }
}