import 'package:flutter/material.dart';
class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final obsurceText;
  const MyTextField({super.key,
  required this.controller,
    required this.hintText,
    required this.obsurceText
  });
  @override
  Widget build(BuildContext context){
    return TextField(
      controller: controller,
      obscureText:obsurceText,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide:BorderSide(color:Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color:Colors.yellow),
        ),

        fillColor: Colors.grey[200],
        filled:true,
        hintText:hintText,
        hintStyle: const TextStyle(color:Colors.grey),
      ),
    );
  }
}