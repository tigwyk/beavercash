import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:beavercash/services/db_service.dart';
import 'package:logging/logging.dart';

final log = Logger('PayPageLogs');

class PayPage extends StatefulWidget {
  @override
  _PayPageState createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  String _amountString = '';
  double _amount = 0.0;
  bool _isRequesting = false; // To track if user is requesting or paying
  
  void _updateAmount(String digit) {
    // Only allow one decimal point
    if (digit == '.' && _amountString.contains('.')) {
      return;
    }
    
    // Limit decimal places to 2
    if (_amountString.contains('.')) {
      var parts = _amountString.split('.');
      if (parts.length > 1 && parts[1].length >= 2 && digit != 'del') {
        return;
      }
    }
    
    setState(() {
      if (digit == 'del') {
        if (_amountString.isNotEmpty) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        }
      } else {
        _amountString += digit;
      }
      
      _amount = _amountString.isEmpty ? 0.0 : double.tryParse(_amountString) ?? 0.0;
    });
  }
  
  void _clearAmount() {
    setState(() {
      _amountString = '';
      _amount = 0.0;
    });
  }
  
  void _navigateToRecipientSelection(bool isRequesting) {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isRequesting = isRequesting;
    });
    
    // In a real app, you'd navigate to the recipient selection screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => RecipientSelectionPage(
    //       amount: _amount,
    //       isRequesting: isRequesting,
    //     ),
    //   ),
    // );
    
    // For now, just show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRequesting 
          ? 'Request for \$${_amount.toStringAsFixed(2)} ready for recipient selection' 
          : 'Payment of \$${_amount.toStringAsFixed(2)} ready for recipient selection'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with scan button and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // QR code scanner button
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                    onPressed: () {
                      // In a real app, you'd navigate to a QR scanner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('QR Scanner would open here')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Amount display
            Expanded(
              flex: 2,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // Focus on amount field if tapped
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _amountString.isEmpty
                            ? '\$0'
                            : '\$' + (_amountString.endsWith('.')
                                ? _amountString + '0'
                                : _amountString),
                        style: textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _amount > 0 ? 'Tap to edit' : 'Enter an amount',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Custom numpad
            Expanded(
              flex: 4,
              child: Container(
                color: colorScheme.surface,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Numpad rows
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('1'),
                          _buildNumKey('2'),
                          _buildNumKey('3'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('4'),
                          _buildNumKey('5'),
                          _buildNumKey('6'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('7'),
                          _buildNumKey('8'),
                          _buildNumKey('9'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('.'),
                          _buildNumKey('0'),
                          _buildNumKey('del', icon: Icons.backspace_outlined),
                        ],
                      ),
                    ),
                    
                    // Request and Pay buttons
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Request button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: OutlinedButton(
                              onPressed: () => _navigateToRecipientSelection(true),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.primary),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Pay button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: FilledButton(
                              onPressed: () => _navigateToRecipientSelection(false),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'Pay',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNumKey(String value, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: TextButton(
        onPressed: () => _updateAmount(value),
        style: TextButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(8),
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 28,
                color: colorScheme.onSurface,
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}