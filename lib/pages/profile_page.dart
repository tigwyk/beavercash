import 'package:beavercash/services/db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final FirestoreService firestoreService = FirestoreService();

  void signOut() async {
    // Handle sign out logic here
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile Page',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            UserInformation(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                signOut();
              },
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class UserInformation extends StatefulWidget {
  @override
  _UserInformationState createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Return early if there's no logged in user
    if (user == null) {
      return const Text('No user logged in');
    }

    // Query only the specific document for the current user
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // Check if the document exists
        if (!snapshot.hasData || !snapshot.data!.exists) {
          log.info('UID: ${user!.uid}');
          return const Text('User profile not found');
        }

        // Get the data from the document
        Map<String, dynamic> userData =
            snapshot.data!.data() as Map<String, dynamic>;

        return Column(
          children: [
            Text(
              userData['displayName'] ?? 'Name not set',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userData['email'] ?? user!.email ?? 'Email not available',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Display additional user information if available
            if (userData.containsKey('phoneNumber') && userData['phoneNumber'] != null)
              Text(
                'Phone: ${userData['phoneNumber']}',
                style: const TextStyle(fontSize: 14),
              ),
            if (userData.containsKey('createdAt') && userData['createdAt'] != null)
              Text(
                'Member since: ${_formatDate(userData['createdAt'])}',
                style: const TextStyle(fontSize: 14),
              ),
          ],
        );
      },
    );
  }

  // Helper method to format Firestore timestamp
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'Date unavailable';
  }
}


