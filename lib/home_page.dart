import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messagepart/activity_page.dart';
import 'package:messagepart/chat_page.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:provider/provider.dart';


class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState()=> _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }
  void navigateToChecklistScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChecklistScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page'),
        actions: [
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout),
          ),
        ],),
      body: Column(
          children: [
          Expanded(
          child: _buildUserList(),
    ),
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
    onPressed: () {
      navigateToChecklistScreen(context);
    },
    child: Text('Exercise ataması'),
    ),
    ),],),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading');
        }

        print(snapshot.data!.docs); // Bu satırı ekleyin

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }


  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>? ?? {};

    final String userEmail = data['email'] ?? '';
    final String userId = data['uid'] ?? '';

    if (_auth.currentUser!.email != userEmail) {
      return ListTile(
        title: Text(userEmail),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatPage(
                    receiverUserEmail: userEmail,
                    receiverUserID: userId,
                  ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }
}
