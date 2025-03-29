import 'package:beavercash/pages/auth_page.dart';
import 'package:beavercash/pages/profile_page.dart';
import 'package:beavercash/components/infocard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:beavercash/firebase_options.dart';

void main() async {
  // final storage = FlutterSecureStorage();
  // await storage.write(key: 'jwt_token', value: 'your_jwt_token');
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'beavercash',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.dark,
          ),
          textTheme: TextTheme(
            displayLarge: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.oswald(
              fontSize: 30,
              fontStyle: FontStyle.italic,
            ),
            bodyMedium: GoogleFonts.merriweather(
              fontSize: 14
            ),
            displaySmall: GoogleFonts.pacifico(
              fontSize: 10,
            ),
          ),
        ),
        home: AuthPage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  int cashBalance = 1000;

  void addMoney() {
    cashBalance += 100;
    notifyListeners();
  }
  
  void cashOut() {
    cashBalance = 0;
    notifyListeners();
  }
}

class AddMoneyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CashBalanceWidget(),
      ],
    );
  }
}


class CashBalanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    
    return InfoCard(
      title: 'Cash Balance',
      subtitle: 'Account & Routing',
      bodyText: '\$${appState.cashBalance}',
      buttons: [
        ButtonInfo(
          label: 'Add money',
          onPressed: appState.addMoney,
        ),
        ButtonInfo(
          label: 'Cash out',
          onPressed: appState.cashOut,
        ),
      ],
      onTap: () {
        print('Cash balance card tapped');
      },
    );
  }
}

class TransactionHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Transaction History',
      subtitle: 'Recent Transactions',
      bodyText: 'View your recent transactions here.',
      onTap: () {
        print('Transaction history card tapped');
      },
    );
  }
}

class AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Account Status',
      subtitle: 'Details',
      bodyContent: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 36,
          ),
          SizedBox(width: 8),
          Text(
            'Verified',
            textScaler: TextScaler.linear(1.3),
          ),
        ],
      ),
      buttons: [
        ButtonInfo(
          label: 'Manage',
          onPressed: () {
            print('Manage account tapped');
          },
        ),
      ],
      onTap: () {
        print('Account card tapped');
      },
    );
  }
}

class NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'New Feature',
      subtitle: 'Announcement',
      bodyText: 'Try our new savings tools!',
      onTap: () {
        print('Notification card tapped');
      },
    );
  }
}

class SavingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Savings',
      subtitle: 'Tools',
      bodyContent: Container(
        width: double.infinity, // Ensure content takes full width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.savings,
              color: Colors.green,
              size: 36,
            ),
            Text(
              '\$0.00',
            ),
          ],
        ),
      ),
      onTap: () {
        print('Savings card tapped');
      },
    );
  }
}

class CryptoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Crypto',
      subtitle: 'Tools',
      bodyContent: Container(
        width: double.infinity, // Make sure this is here
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.currency_bitcoin,
              color: Colors.green,
              size: 36,
            ),
            Text(
              '\$0.00',
            ),
          ],
        ),
      ),
      onTap: () {
        print('Crypto card tapped');
      },
    );
  }
}