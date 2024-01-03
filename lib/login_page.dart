import 'package:flutter/material.dart';
import 'package:messagepart/admin_login.dart';
import 'package:messagepart/components/my_button.dart';
import 'package:messagepart/components/my_text_field.dart';
import 'package:messagepart/home_page.dart';
import 'package:messagepart/register_page.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:messagepart/tranee_home_page.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({Key? key, required this.onTap}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signInWithEmailandPassword(
          emailController.text, passwordController.text);

      UserType? userType = await authService.getUserType();

      if (userType == UserType.trainee) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      } else if (userType == UserType.trainer) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Handle the case where the user type is neither trainee nor trainer
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }
  void admin() {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminLoginPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                Icon(
                  Icons.message,
                  size: 80,
                  color: Colors.grey,
                ),
                const Text(
                  "Hello",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress, // Adjust the TextInputType as needed
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  keyboardType: TextInputType.text, // Adjust the TextInputType as needed
                ),

                const SizedBox(height: 25),
                MyButton(onTap: signin, text: 'Sign In'),
                MyButton(onTap: admin, text: 'Sign In Admin'),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Not a member'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "REGISTER",
                        style: TextStyle(
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
}