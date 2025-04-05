import 'package:beavercash/components/custom_button.dart';
import 'package:beavercash/components/custom_textfield.dart';
import 'package:beavercash/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beavercash/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void signIn() async {
    showDialog(context: context, builder: (context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    });
    try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
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
              SizedBox(height: 50),
              // logo
            const Icon(
              Icons.account_balance,
              size: 100,
            ),
              
            const SizedBox(height: 25),
                    
              // welcome back text
            Text(
              'Welcome back, eh!',
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
              // forgot password text
            SizedBox(height: 10),
                    
              // sign in button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Forgot password?',
                    style: TextStyle( color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25.0),
              // or continue with
            CustomButton(
              onTap: signIn,
              text: 'Sign In',
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
                  AuthService().signInWithApple();
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
                  'Not a member?',
                  style: TextStyle( color: Colors.grey[700]),
                ),
                SizedBox(width: 4.0),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    'Register now',
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