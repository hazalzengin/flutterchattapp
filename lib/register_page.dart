import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:messagepart/components/my_button.dart';
import 'package:messagepart/components/my_text_field.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
enum UserType { trainee, trainer,waittrainer}


class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({Key? key, required this.onTap}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final ageController = TextEditingController();
  FilePickerResult? certificationFileResult;
  UserType userType = UserType.trainee;

  Future<void> uploadCertification() async {
    await Future.delayed(Duration.zero); // Ensure it's scheduled in the next frame

    if (userType == UserType.trainer) {
      certificationFileResult = await FilePicker.platform.pickFiles();

      if (certificationFileResult != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certification file selected.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certification file selection canceled.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certification file can only be uploaded for Trainers.'),
        ),
      );
    }
  }


  void signup(BuildContext context) async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    if (userType == UserType.trainer && certificationFileResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certification file is required for trainers.'),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      // Set userType to trainer if the user is a trainer
      if (userType == UserType.trainer) {
        userType = UserType.waittrainer; // Change userType to waittrainer or update accordingly
      }

      await authService.signUpWithEmailandPassword(
        emailController.text,
        passwordController.text,
        certificationFileResult,
        nameController.text,
        surnameController.text,
        phoneNumberController.text,
        int.parse(ageController.text),
        (userType=UserType.waittrainer) as UserType,
        context
      );

      if (userType == UserType.waittrainer) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Your registration is pending approval'),
              content: Text('You will be notified once your registration is approved by the admin.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration failed. ${e.toString()}',
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Trainee'),
                      Switch(
                        value: userType == UserType.trainer,
                        onChanged: (value) {
                          setState(() {
                            userType = value ? UserType.trainer : UserType.trainee;
                          });
                        },
                      ),
                      Text('Trainer'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (userType == UserType.trainer)
                    MyButton(onTap: uploadCertification, text: 'Upload Certification'),
                  const SizedBox(height: 20),
                  MyTextField(
                    controller: nameController,
                    hintText: 'Name',
                    obscureText: false,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: surnameController,
                    keyboardType: TextInputType.text,
                    hintText: 'Surname',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: phoneNumberController,
                    hintText: 'Phone Number',
                    obscureText: false,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: ageController,
                    hintText: 'Age',
                    obscureText: false,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 25),
                  MyTextField(
                    controller: confirmPasswordController,
                    hintText: 'Password Confirm',
                    obscureText: true,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  MyButton(onTap: () => signup(context), text: 'Sign Up'),

                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already a member'),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          'Login',
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
      ),
    );
  }

}
