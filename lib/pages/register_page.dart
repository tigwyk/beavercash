import 'package:beavercash/components/custom_button.dart';
import 'package:beavercash/components/custom_textfield.dart';
import 'package:beavercash/components/square_tile.dart';
import 'package:beavercash/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final passwordController = TextEditingController();

  void signUp() async {
    showDialog(context: context, builder: (context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    });
    try {
      if (passwordController.text != confirmPasswordController.text) {
        showErrorMessage('Passwords do not match!');
        return;
      }
      if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
        showErrorMessage('Please fill in all fields!');
        return;
      }
      if (passwordController.text.length < 8) {
        showErrorMessage('Password must be at least 8 characters long!');
        return;
      }
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(usernameController.text)) {
        showErrorMessage('Please enter a valid email address!');
        return;
      }
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: usernameController.text,
        password: passwordController.text,
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'user-not-found') {
        showErrorMessage('Email not found!');
      } else if (e.code == 'wrong-password') {
        showErrorMessage('Wrong password!');
      } else {
        showErrorMessage(e.code);
      }
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
                    
              // welcome back text
            Text(
              'Create an account, buddy!',
              style: TextStyle( color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 20),
              // username textfield
            CustomTextfield(
              hintText: 'Username',
              obscureText: false,
              controller: usernameController,
            ),
            SizedBox(height: 10),
              // password textfield
            CustomTextfield(
              hintText: 'Password',
              obscureText: true,
              controller: passwordController,
            ),
            SizedBox(height: 10),
            CustomTextfield(
              hintText: 'Confirm Password',
              obscureText: true,
              controller: confirmPasswordController,
            ),
            SizedBox(height: 25.0),
              // or continue with
            CustomButton(
              onTap: signUp,
              text: 'Sign Up',
                // Handle sign in action
            ),
            SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  Expanded(child: 
                  Divider(
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
                      style: TextStyle( color: Colors.grey[700]),
                    ),
                  ),
                  Expanded(child: 
                  Divider(
                    color: Colors.grey[400],
                    thickness: 0.5,
                    indent: 10,
                    endIndent: 25,
                  )
                  ),
                ],
              ),
            ),
            SizedBox(height: 25.0),
              // google button + apple button
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SquareTile(
                imagePath: 'lib/images/google.png',
                onTap: () {
                  AuthService().signInWithGoogle();
                },
                ),
              SizedBox(width: 25.0),
              SquareTile(
                imagePath: 'lib/images/apple.png',
                onTap: () {
                  // AuthService().signInWithApple();
                },
                ),
            ],
            ),
            SizedBox(height: 25.0),
              // not a member? register now link button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already a member?',
                  style: TextStyle( color: Colors.grey[700]),
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
            ]),
          ),
        ),
      )
    );
  }
  
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          message,
        ),
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