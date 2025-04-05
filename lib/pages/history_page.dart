import 'package:flutter/material.dart';
import '../services/db_service.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Transaction>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = DBService.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Transaction>>(
        future: _transactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No transactions found.'));
          } else {
            final transactions = snapshot.data!;
            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(transaction.description),
                  subtitle: Text(transaction.date.toString()),
                  trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Transaction {
  final String description;
  final DateTime date;
  final double amount;

  Transaction({
    required this.description,
    required this.date,
    required this.amount,
  });
}

class DBService {
  static Future<List<Transaction>> getTransactions() async {
    // Mock data for demonstration purposes
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    return [
      Transaction(description: 'Groceries', date: DateTime.now(), amount: 50.0),
      Transaction(description: 'Electricity Bill', date: DateTime.now().subtract(Duration(days: 1)), amount: 75.0),
      Transaction(description: 'Internet', date: DateTime.now().subtract(Duration(days: 2)), amount: 30.0),
    ];
  }
}