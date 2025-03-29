import 'package:beavercash/components/infocard.dart';
import 'package:beavercash/main.dart';
import 'package:beavercash/pages/profile_page.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
        break;
      case 1:
        page = AddMoneyPage();
        break;
      case 2:
        page = AddMoneyPage();
        break;
      case 3:
        page = ProfilePage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('beavercash')),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: page,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.money),
            label: 'Add Money',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            children: [
              // Full width cash balance card at the top
              Row(
                children: [
                  CashBalanceWidget(),
                ],
              ),
              
              // Row with two smaller cards (Account and Notification)
              Row(
                children: [
                  SavingsCard(),
                  CryptoCard(),
                ],
              ),
              
              // Row with two quick action cards
              Row(
                children: [
                  QuickActionCard('Send'),
                  QuickActionCard('Request'),
                ],
              ),
              
              // Full width transaction history at the bottom
              Row(
                children: [
                  TransactionHistoryCard(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
