// my_button.dart
import 'package:flutter/material.dart';

class MyButton1 extends StatelessWidget {
  final void Function({required String role}) onTap;
  final String text;

  const MyButton1({required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onTap(role: 'default'), // Provide a default value for role or modify as needed
      child: Text(text),
    );
  }
}
