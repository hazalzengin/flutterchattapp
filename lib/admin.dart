import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home Page'),
      ),
      body: UserList(),
    );
  }
}

class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var userDoc = snapshot.data!.docs[index];
            var userEmail = userDoc['email'];
            var userType = userDoc['userType'];

            var userData = userDoc.data() as Map<String, dynamic>?;
            var certificationFileURL =
            userData != null && userData.containsKey('certificationFileURL')
                ? userData['certificationFileURL']
                : null;

            return ListTile(
              title: Text(userEmail),
              subtitle: Text('User Type: ${userType ?? "N/A"}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (userType == 2) ...[
                    ElevatedButton(
                      onPressed: () {
                        _showConfirmationDialog(
                          context,
                          'Accept User',
                          'Are you sure you want to accept this user?',
                              () => _acceptUser(userDoc.id),
                        );
                      },
                      child: Text('Accept'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showConfirmationDialog(
                          context,
                          'View Certification',
                          'Are you sure you want to view the certification?',
                              () => _launchPDF(certificationFileURL),
                        );
                      },
                      child: Text('View Certification'),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(
                        context,
                        'Reject User',
                        'Are you sure you want to reject this user?',
                            () => _rejectUser(userDoc.id),
                      );
                    },
                    child: Text('Reject'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConfirmationDialog(
      BuildContext context,
      String title,
      String content,
      Function onPressed,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onPressed();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _acceptUser(String userId) {
    // Update user type to 'trainee'
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'userType': '0',
    });
  }

  void _rejectUser(String userId) {
    print('User with ID $userId has been rejected.');
    FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _launchPDF(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
