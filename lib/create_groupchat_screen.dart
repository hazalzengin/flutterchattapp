import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroupChatScreen extends StatefulWidget {
  @override
  _CreateGroupChatScreenState createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  TextEditingController groupNameController = TextEditingController();
  List<String> selectedMembers = [];
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool isCreatingGroup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Name:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            TextFormField(
              controller: groupNameController,
              style: TextStyle(fontSize: 16.0),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter group name',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _handleCreateGroup(context);
              },
              child: isCreatingGroup
                  ? CircularProgressIndicator()
                  : Text('Create Group'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue[100],
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Select Members:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            _buildUserList(),
            SizedBox(height: 16.0),
            Text(
              'Selected Members:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            _buildSelectedMembers(),
          ],
        ),
      ),
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

        return ListView(
          shrinkWrap: true,
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserCheckboxItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserCheckboxItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>? ?? {};
    final String userName = data['name'] ?? ''; // Replace 'name' with the actual field name for the user's name
    final String userSurname = data['surname'] ?? ''; // Replace 'surname' with the actual field name for the user's surname
    final String userId = data['uid'] ?? '';

    return CheckboxListTile(
      title: Text('$userName $userSurname'),
      value: selectedMembers.contains(userName),
      onChanged: (bool? value) {
        setState(() {
          if (value!) {
            selectedMembers.add(userId);
          } else {
            selectedMembers.remove(userId);
          }
        });
      },
    );
  }

  Widget _buildSelectedMembers() {
    return Wrap(
      children: selectedMembers.map((userId) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Chip(
            label: Text(userId),
            deleteIconColor: Colors.red,
            onDeleted: () {
              setState(() {
                selectedMembers.remove(userId);
              });
            },
            backgroundColor: Colors.blue.shade100,
          ),
        );
      }).toList(),
    );
  }

  void _handleCreateGroup(BuildContext context) async {
    try {
      setState(() {
        isCreatingGroup = true;
      });

      DocumentReference groupRef =
      FirebaseFirestore.instance.collection('groups').doc();

      await groupRef.set({
        'groupId': groupRef.id,
        'groupName': groupNameController.text,
        'members': [currentUserId, ...selectedMembers],
        'owner': currentUserId,
      });

      Navigator.pop(context);
    } catch (error) {
      print('Error creating group: $error');
    } finally {
      setState(() {
        isCreatingGroup = false;
      });
    }
  }
}
