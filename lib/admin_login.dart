import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messagepart/admin.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Sign In',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _signInAsAdmin(
                    _emailController.text,
                    _passwordController.text,
                  );
                } catch (e) {
                  print('Error signing in as admin: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign in as admin. Check your credentials.'),
                    ),
                  );
                }
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInAsAdmin(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user is an admin by querying the "admin" collection
      DocumentSnapshot adminSnapshot =
      await _firestore.collection('admin').doc(userCredential.user!.uid).get();

      if (!adminSnapshot.exists) {
        // The user is not an admin
        throw FirebaseAuthException(
          code: 'not-an-admin',
          message: 'User is not authorized as an admin',
        );
      }

      // Navigate to the AdminHomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle different authentication failure scenarios
      if (e.code == 'user-not-found') {
        print('User not found');
      } else if (e.code == 'wrong-password') {
        print('Invalid password');
      } else if (e.code == 'not-an-admin') {
        print('User is not authorized as an admin');
      } else {
        print('Error signing in as admin: ${e.code}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in as admin. Check your credentials.'),
        ),
      );
    }
  }

}
