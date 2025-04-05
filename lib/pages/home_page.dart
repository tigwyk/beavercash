import 'package:beavercash/components/cash_balance_widget.dart';
import 'package:beavercash/components/crypto_card.dart';
import 'package:beavercash/components/savings_card.dart';
import 'package:beavercash/components/transaction_history_card.dart';
import 'package:beavercash/pages/history_page.dart';
import 'package:beavercash/pages/pay_page.dart';
import 'package:beavercash/pages/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('HomePageLogs');

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  
  // Define page titles 
  final List<String> _pageTitles = [
    'Home',
    'Wallet',
    'Pay',
    'Search',
    'History',
  ];
  
  // Define pages statically to avoid recreating them on each build
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    // Initialize pages here to avoid rebuilding them
    _pages = [
      HomePage(),
      AddMoneyPage(),
      PayPage(),
      SearchPage(),
      HistoryPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[selectedIndex]),
        backgroundColor: selectedIndex == 2 ? colorScheme.primary : null, // Highlight Pay page
        elevation: selectedIndex == 0 ? 0 : 1, // No elevation on home page
        // Customize the AppBar actions based on the selected page
        actions: _buildAppBarActions(selectedIndex, context),
      ),
      body: SafeArea(
        // Use IndexedStack to preserve state of all pages
        child: IndexedStack(
          index: selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surface,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          // Make the Pay button stand out visually
          NavigationDestination(
            icon: Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.attach_money,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
            selectedIcon: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.attach_money,
                color: colorScheme.onPrimary,
                size: 26,
              ),
            ),
            label: 'Pay',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
        ],
      ),
    );
  }
  
  // Method to build different AppBar actions based on the selected page
  List<Widget> _buildAppBarActions(int index, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    
    switch (index) {
      case 0: // Home page
        return [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
              log.info('Notifications tapped');
            },
          ),
          IconButton(
            icon: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      child: currentUser?.photoURL == null
                          ? Text(
                              currentUser?.displayName?.isNotEmpty == true
                                  ? currentUser!.displayName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
            onPressed: () {
              // Show profile
              log.info('Profile tapped');
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ];
      
      case 1: // Wallet page
        return [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Add money option
              log.info('Add money tapped');
            },
          ),
        ];
        
      case 2: // Pay page
        return [
          IconButton(
            icon: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      child: currentUser?.photoURL == null
                          ? Text(
                              currentUser?.displayName?.isNotEmpty == true
                                  ? currentUser!.displayName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
            onPressed: () {
              // Scan QR code
              log.info('Scan QR tapped');
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ];
        
      case 3: // Search page
        return [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filters
              log.info('Filter search tapped');
            },
          ),
        ];
        
      case 4: // History page
        return [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              // Show date filter
              log.info('Date filter tapped');
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show transaction filters
              log.info('Transaction filter tapped');
            },
          ),
        ];
        
      default:
        return [];
    }
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Remove the Scaffold here since it's already in the parent
    return Container(
      color: colorScheme.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with app name and welcome message
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 20,  // Slightly larger than the default displaySmall
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,  // Use the primary color for emphasis
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your finances at a glance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Full width cash balance card at the top
            CashBalanceWidget(),
            
            SizedBox(height: 16),
            
            // Row with two cards - savings and crypto
            Row(
              children: [
                Expanded(child: SavingsCard()),
                SizedBox(width: 12),
                Expanded(child: CryptoCard()),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Quick action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  context, 
                  'Send', 
                  Icons.send, 
                  colorScheme.primary,
                  () {
                    // Navigate to payment page
                  },
                ),
                _buildQuickActionButton(
                  context, 
                  'Request', 
                  Icons.request_page, 
                  colorScheme.secondary,
                  () {
                    // Navigate to request page
                  },
                ),
                _buildQuickActionButton(
                  context, 
                  'Transfer', 
                  Icons.compare_arrows, 
                  colorScheme.tertiary,
                  () {
                    // Navigate to transfer page
                  },
                ),
                _buildQuickActionButton(
                  context, 
                  'Scan', 
                  Icons.qr_code_scanner, 
                  colorScheme.error,
                  () {
                    // Open QR scanner
                  },
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Recent activity header with "See all" link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity page
                  },
                  child: Text('See all'),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Recent transactions list
            TransactionHistoryCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    BuildContext context, 
    String label, 
    IconData icon, 
    Color color,
    VoidCallback onTap
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// Enhanced AddMoneyPage
class AddMoneyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Balance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          CashBalanceWidget(),
          SizedBox(height: 24),
          Text(
            'Add Money From',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildPaymentMethodCard(
            context, 
            'Bank Account', 
            Icons.account_balance,
            colorScheme.primary
          ),
          SizedBox(height: 12),
          _buildPaymentMethodCard(
            context, 
            'Debit Card', 
            Icons.credit_card,
            colorScheme.secondary
          ),
          SizedBox(height: 12),
          _buildPaymentMethodCard(
            context, 
            'Mobile Wallet', 
            Icons.wallet,
            colorScheme.tertiary
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodCard(
    BuildContext context, 
    String title, 
    IconData icon,
    Color color
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          log.info('$title payment method selected');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Deposit funds instantly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
