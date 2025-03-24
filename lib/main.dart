import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beavercash/userService.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  int cashBalance = 1000;

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void addMoney() {
    cashBalance += 100;
    notifyListeners();
  }
  
  void cashOut() {
    cashBalance = 0;
    notifyListeners();
  }
}

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
        page = FavoritesPage();
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
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: page,
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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(8.0),
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
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String action;
  
  QuickActionCard(this.action);
  
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: action,
      subtitle: 'Quick Action',
      bodyContent: Center(
        child: Icon(
          action == 'Send' ? Icons.send :
          action == 'Request' ? Icons.request_page :
          Icons.payment,
          size: 36,
        ),
      ),
      onTap: () {
        print('$action tapped');
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<User> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser = UserService().getUser();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: FutureBuilder<User> (
            future: futureUser, 
            builder: ((context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data?.name ?? 'No name');
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return const CircularProgressIndicator();
              }),
      ),
      ));
  }
}

// Modify the InfoCard class to accept a flex parameter
class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? bodyText;
  final Widget? bodyContent;
  final List<ButtonInfo>? buttons;
  final VoidCallback? onTap;
  final double minWidth;
  final double maxWidth;
  final bool expanded; // New parameter to control expansion behavior

  const InfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.bodyText,
    this.bodyContent,
    this.buttons,
    this.onTap,
    this.minWidth = 150.0,
    this.maxWidth = double.infinity,
    this.expanded = true, // Default to true for backward compatibility
  }) : assert(bodyText != null || bodyContent != null, 'Either bodyText or bodyContent must be provided'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // Choose between Expanded and Flexible based on the expanded parameter
    Widget cardWrapper = expanded 
      ? Expanded(
          child: _buildCardContent(context),
        )
      : Flexible(
          child: _buildCardContent(context),
        );
    
    return cardWrapper;
  }

  Widget _buildCardContent(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use LayoutBuilder to determine available width
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate if there's enough space for a row
                  // Estimate text widths - adjust based on your typical text lengths
                  final titleStyle = TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  );
                  final subtitleStyle = TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  );
                  
                  // If the card is narrow, stack vertically
                  if (constraints.maxWidth < 250) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: titleStyle,
                          textScaler: TextScaler.linear(1.2),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: subtitleStyle,
                          textScaler: TextScaler.linear(0.8),
                        ),
                      ],
                    );
                  } else {
                    // Otherwise use a row layout
                    return Row(
                      children: [
                        Text(
                          title,
                          style: titleStyle,
                          textScaler: TextScaler.linear(1.2),
                        ),
                        Spacer(),
                        Text(
                          subtitle,
                          style: subtitleStyle,
                          textScaler: TextScaler.linear(0.8),
                        ),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: bodyContent ?? Text(
                  bodyText!,
                  textScaler: TextScaler.linear(1.6),
                  textAlign: TextAlign.left,
                ),
              ),
              if (buttons != null && buttons!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Check available width to determine button layout
                      if (constraints.maxWidth < 250 && buttons!.length > 1) {
                        // Stack buttons vertically for narrow cards with multiple buttons
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: buttons!.map((button) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: FilledButton.tonal(
                                onPressed: button.onPressed,
                                child: Text(button.label),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        // Use row for wider cards
                        return Row(
                          children: _buildButtonsRow(buttons!),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtonsRow(List<ButtonInfo> buttons) {
    final List<Widget> buttonWidgets = [];
    
    for (int i = 0; i < buttons.length; i++) {
      buttonWidgets.add(
        FilledButton.tonal(
          onPressed: buttons[i].onPressed,
          child: Text(buttons[i].label),
        ),
      );
      
      if (i < buttons.length - 1) {
        buttonWidgets.add(Spacer());
      }
    }
    
    return buttonWidgets;
  }
}

class ButtonInfo {
  final String label;
  final VoidCallback onPressed;

  ButtonInfo({
    required this.label,
    required this.onPressed,
  });
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