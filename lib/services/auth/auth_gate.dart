import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messagepart/register_page.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:messagepart/services/auth/loginorregister.dart';
import 'package:messagepart/traniee_homepage.dart';
import 'package:messagepart/traniee_profilepage.dart';
import '../../home_page.dart';

class AuthGate extends StatelessWidget {
  final AuthService authService = AuthService();

  AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Return a loading indicator while checking authentication state
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return FutureBuilder<UserType?>(
              future: authService.getUserType(),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState == ConnectionState.done) {
                  if (userTypeSnapshot.hasData) {
                    UserType? userType = userTypeSnapshot.data;

                    switch (userType) {
                      case UserType.trainee:
                        return const HomePage();
                      case UserType.trainer:
                        return TranieeHomePage();
                      case UserType.waittrainer:
                        WidgetsBinding.instance!.addPostFrameCallback((_) {
                          // Use addPostFrameCallback to ensure the build is complete
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Approval Pending'),
                                content: Text(
                                    'Your trainer registration is pending approval by the admin. Please wait for approval.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to the login page
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => LoginOrRegister()),
                                      );
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        });
                        return Center(
                          child: CircularProgressIndicator(),

                        );
                      default:
                        return Center(
                          child: Text(
                            "Unknown User Type: ${UserType.values.first ?? 'null'}",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                    }
                  } else if (userTypeSnapshot.hasError) {
                    // Handle error when fetching user type
                    return Center(
                      child: Text(
                        "Error fetching user type: ${userTypeSnapshot.error}",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  } else {
                    // Return a loading indicator or another widget while waiting
                    return Center(child: CircularProgressIndicator());
                  }
                } else {
                  // Return a loading indicator while waiting for user type
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
