import 'package:beavercash/components/custom_button.dart';
import 'package:beavercash/components/custom_textfield.dart';
import 'package:beavercash/components/square_tile.dart';
import 'package:beavercash/services/auth_service.dart';
import 'package:beavercash/services/db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('RegisterPage');

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final passwordController = TextEditingController();
  final displayNameController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();

  // Improved registration flow
  Future<void> registerUser() async {
    try {
      log.info("Starting user registration process...");
      
      // Create user in Firebase Auth
      log.info("Creating Firebase Auth user: ${emailController.text.trim()}");
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      
      // Get the newly created user
      User? user = userCredential.user;
      log.info("Firebase Auth user created with ID: ${user?.uid}");
      
      if (user != null) {
        // Update display name if provided
        if (displayNameController.text.isNotEmpty) {
          log.info("Updating display name: ${displayNameController.text.trim()}");
          await user.updateDisplayName(displayNameController.text.trim());
        }
        
        // Create user in Firestore using the new method
        log.info("Creating user document in Firestore...");
        bool success = await firestoreService.createUserAfterSignIn(
          uid: user.uid,
          email: user.email!,
          displayName: displayNameController.text.trim().isNotEmpty 
              ? displayNameController.text.trim() 
              : null,
        );
        
        if (success) {
          log.info('User registered and document created successfully');
          return; // Registration successful
        } else {
          log.warning('User registered but document creation failed');
          return;
          // Still return normally - we have the Firebase Auth user
        }
      } else {
        log.warning('Firebase Auth returned null user after createUserWithEmailAndPassword');
        throw Exception('Failed to create user account');
      }
    } catch (e) {
      log.severe('Error during registration: $e');
      rethrow; // Ensure the error propagates to the calling method
    }
  }

  void signUp() async {
    // Show loading indicator
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Validate input fields first, before making any network requests
      if (!validateInputs()) {
        // Important: Always dismiss the dialog when validation fails
        Navigator.pop(context);
        log.warning('Input validation failed, aborting registration.');
        showErrorMessage('Please correct the errors and try again.');
        return;
      }
      log.info("Input validation passed, proceeding with registration...");
      // Register the user
      await registerUser();
      
      // Dismiss loading indicator if still in the context
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show success message or navigate to next screen
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully!'))
        );
      
    } on FirebaseAuthException catch (e) {
      log.warning('Firebase Auth Exception: ${e.code} - ${e.message}');
      // Dismiss loading indicator
      Navigator.pop(context);
      
      // Show appropriate error message
      String errorMessage = getErrorMessage(e);
      showErrorMessage(errorMessage);
    } catch (e) {
      log.severe('Unexpected error during sign up: $e');
      // Dismiss loading indicator
      if(mounted) {
        Navigator.pop(context);
      }
      
      // Show generic error message
      showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  bool validateInputs() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      log.warning('Email or password field is empty');
      showErrorMessage('Please fill in all required fields!');
      return false;
    }
    
    if (passwordController.text != confirmPasswordController.text) {
      log.warning('Passwords do not match');
      showErrorMessage('Passwords do not match!');
      return false;
    }
    
    if (passwordController.text.length < 8) {
      log.warning('Password is too short');
      showErrorMessage('Password must be at least 8 characters long!');
      return false;
    }
    
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(emailController.text)) {
      log.warning('Invalid email format');
      showErrorMessage('Please enter a valid email address!');
      return false;
    }
    log.info('All input validations passed');
    return true;
  }

  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or log in.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      default:
        return 'Registration failed: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 25),
                // logo
                const Icon(
                  Icons.account_balance,
                  size: 100,
                ),
                
                const SizedBox(height: 25),
                      
                // welcome text
                Text(
                  'Create your BeaverCash account',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 20),

                // display name textfield (optional)
                CustomTextfield(
                  hintText: 'Display Name (optional)',
                  obscureText: false,
                  controller: displayNameController,
                ),
                SizedBox(height: 10),

                // email textfield
                CustomTextfield(
                  hintText: 'Email',
                  obscureText: false,
                  controller: emailController,
                ),
                SizedBox(height: 10),

                // password textfield
                CustomTextfield(
                  hintText: 'Password',
                  obscureText: true,
                  controller: passwordController,
                ),
                SizedBox(height: 10),

                // confirm password textfield
                CustomTextfield(
                  hintText: 'Confirm Password',
                  obscureText: true,
                  controller: confirmPasswordController,
                ),
                SizedBox(height: 25.0),

                // sign up button
                CustomButton(
                  onTap: signUp,
                  text: 'Sign Up',
                ),
                SizedBox(height: 25),

                // or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[400],
                          thickness: 0.5,
                          indent: 25,
                          endIndent: 10,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[400],
                          thickness: 0.5,
                          indent: 10,
                          endIndent: 25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25.0),

                // social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google sign in
                    SquareTile(
                      imagePath: 'lib/images/google.png',
                      onTap: () async {
                        try {
                          UserCredential? credential = await authService.signInWithGoogle();
                          if (credential != null && credential.user != null) {
                            // Create Firestore document for the user if needed
                            await firestoreService.createUserAfterSignIn(
                              uid: credential.user!.uid,
                              email: credential.user!.email!,
                              displayName: credential.user!.displayName,
                            );
                          }
                        } catch (e) {
                          showErrorMessage('Failed to sign in with Google');
                          log.severe('Google sign in error: $e');
                        }
                      },
                    ),
                    SizedBox(width: 25.0),
                    
                    // Apple sign in
                    SquareTile(
                      imagePath: 'lib/images/apple.png',
                      onTap: () async {
                        try {
                          UserCredential? credential = await authService.signInWithApple();
                          if (credential != null && credential.user != null) {
                            // Create Firestore document for the user if needed
                            await firestoreService.createUserAfterSignIn(
                              uid: credential.user!.uid,
                              email: credential.user!.email!,
                              displayName: credential.user!.displayName,
                            );
                          }
                        } catch (e) {
                          showErrorMessage('Failed to sign in with Apple');
                          log.severe('Apple sign in error: $e');
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 25.0),

                // already a member link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already a member?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: 4.0),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Login here',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registration Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}