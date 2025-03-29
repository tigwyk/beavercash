import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Function()? onTap;

  const CustomButton({
    super.key,
    required this.onTap,
    // required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25.0),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Center(child: Text('Sign in', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,))),
      ),
    );
  }
}