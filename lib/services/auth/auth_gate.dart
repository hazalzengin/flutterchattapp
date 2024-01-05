import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messagepart/register_page.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:messagepart/services/auth/loginorregister.dart';
import 'package:messagepart/traniee_homepage.dart';
import 'package:messagepart/traniee_profilepage.dart';
import '../../home_page.dart';


class AuthGate extends StatelessWidget {
  final AuthService authService = AuthService(); // Non-const initialization

  AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<UserType?>(
              future: authService.getUserType(),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState == ConnectionState.done) {
                  UserType? userType = userTypeSnapshot.data;

                  // Navigate based on user type
                  if (userType == UserType.values.first) {
                    return const HomePage();

                  } else if (userType == UserType.values.last) {
                    return TranieeHomePage();
                  } else {
                    return Center(
                      child: Text(
                        "Unknown User Type: ${UserType.values.first ?? 'null'}",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }
                } else {
                  // Return a loading indicator or another widget while waiting
                  return CircularProgressIndicator();
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
}


