// Import the icons library
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messagepart/activity_page.dart';
import 'package:messagepart/create_groupchat_screen.dart';
import 'package:messagepart/groups_chat.dart';
import 'package:messagepart/user_task.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
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

  void _createGroup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: () {
              _createGroup(context);
            },
            icon: const Icon(Icons.group_add),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCombinedList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                navigateToChecklistScreen(context);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue, // Background color
              ),
              child: Text(
                'Exercise ataması',
                style: TextStyle(
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedList() {
    return ListView(
      children: [
        _buildListTitle('User List'),
        _buildUserList(),
        _buildListTitle('Your Groups'),
        _buildGroupUserList(),
      ],
    );
  }

  Widget _buildListTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue, // Text color
        ),
      ),
    );
  }

  Widget _buildGroupUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Loading');
        }

        List<DocumentSnapshot> userGroups = [];

        snapshot.data!.docs.forEach((groupDoc) {
          List<String> members = (groupDoc['members'] as List<dynamic>).cast<String>();
          if (members.contains(_auth.currentUser!.uid)) {
            userGroups.add(groupDoc);
          }
        });

        return ListView.builder(
          shrinkWrap: true,
          itemCount: userGroups.length,
          itemBuilder: (context, index) {
            return _buildGroupListItem(userGroups[index]);
          },
        );
      },
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Loading');
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildUserListItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  Widget _buildGroupListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>? ?? {};
    final String groupId = data['groupId'] ?? '';
    final String groupName = data['groupName'] ?? '';

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.lightGreenAccent, // Background color
      child: ListTile(
        leading: Icon(Icons.group, color: Colors.blue), // Group icon
        title: Text(
          groupName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(groupId: groupId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>? ?? {};
    final String userEmail = data['email'] ?? '';
    final int userType = data['userType'] ?? 0; // Assuming 'userType' is a field in your data.

    if (_auth.currentUser!.email != userEmail) {
      return Card(
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: userType == 1 ? Colors.orangeAccent : Colors.blueAccent, // Background color
        child: ListTile(
          leading: Icon(Icons.person), // Add an icon here (you can change it)
          title: Text(
            '$userEmail ${userType == 1 ? 'Trainee' : 'Trainer'}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserTasksPage(userEmail: userEmail),
              ),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }
}
