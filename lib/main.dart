import 'package:beavercash/pages/auth_page.dart';
import 'package:beavercash/components/infocard.dart';
import 'package:beavercash/pages/notifications_page.dart';
import 'package:beavercash/pages/settings_page.dart';
import 'package:beavercash/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:beavercash/firebase_options.dart';
// Import your profile page
import 'package:beavercash/pages/profile_page.dart';

void main() async {
  // Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final appState = BeaverCashAppState();
  await appState.loadState();
  
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: MyApp(),
    ),
  );
}

final log = Logger('beavercashLogs');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          bodyLarge: GoogleFonts.merriweather(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodySmall: GoogleFonts.merriweather(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          titleMedium: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: GoogleFonts.pacifico(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelLarge: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: GoogleFonts.pacifico(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      // Define the initial route (home)
      home: AuthPage(),
      
      // Define named routes
      
      routes: {
        '/profile': (context) => ProfilePage(),
        '/settings': (context) => SettingsPage(),
        '/notifications': (context) => NotificationsPage(),
        '/auth': (context) => AuthPage(), // Add this line
      },
      
      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Page Not Found')),
            body: Center(
              child: Text('The requested page does not exist.'),
            ),
          ),
        );
      },
    );
  }
}

class AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InfoCard(
      title: 'Account Status',
      subtitle: 'Details',
      bodyContent: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 28,
          ),
          SizedBox(width: 8),
          Text(
            'Verified',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      buttons: [
        ButtonInfo(
          label: 'Manage',
          onPressed: () {
            log.info('Manage account tapped');
          },
        ),
      ],
      onTap: () {
        log.info('Account card tapped');
      },
    );
  }
}

class NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InfoCard(
      title: 'New Feature',
      subtitle: 'Announcement',
      bodyContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.new_releases,
                color: colorScheme.tertiary,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Try our new savings tools!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
      buttons: [
        ButtonInfo(
          label: 'Try Now',
          onPressed: () {
            log.info('Try savings tools tapped');
          },
        ),
      ],
      onTap: () {
        log.info('Notification card tapped');
      },
    );
  }
}