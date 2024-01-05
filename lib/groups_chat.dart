import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  GroupDetailsScreen({required this.groupId});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isUserListVisible = false;
  List<String> _selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              setState(() {
                _isUserListVisible = !_isUserListVisible;
              });
            },
          ),
        ],
        backgroundColor: Colors.blue, // Set your desired app bar color
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildGroupMessages(),
          ),
          _buildMessageInput(),
          if (_isUserListVisible) _buildUserList(),
        ],
      ),
    );
  }

  Widget _buildGroupMessages() {
    return Flexible(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> messages = snapshot.data!.docs;

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
              messages[index].data() as Map<String, dynamic>;

              bool isCurrentUser =
                  data['sender'] == FirebaseAuth.instance.currentUser!.email;

              return Align(
                alignment: isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.green,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['text'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          'Sender: ${data['sender']}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _handleSendMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Flexible(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return _buildUserListItem(snapshot.data!.docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>? ?? {};

    final String userName = data['name'] ?? '';
    final String userSurname = data['surname'] ?? '';
    final String userEmail = data['email'] ?? '';
    final String userId = data['uid'] ?? '';

    if (FirebaseAuth.instance.currentUser!.email != userEmail) {
      return Card(
        elevation: 3.0,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.0),
          title: Text(
            '$userName $userSurname',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            userEmail,
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: _selectedUsers.contains(userId)
              ? Icon(Icons.check_circle, color: Colors.green, size: 24.0)
              : null,
          onTap: () {
            _showUserConfirmationDialog('$userName $userSurname', userId);
          },
        ),
      );
    } else {
      return Container();
    }
  }


  void _handleSendMessage() async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser!.email;

      if (_messageController.text.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'sender': currentUserId,
          'text': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _messageController.clear();

        // Scroll to the bottom after sending a message
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (error) {
      print('Error sending message: $error');
    }
  }

  Future<void> _showUserConfirmationDialog(String userEmail, String userId) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add User to Group'),
          content: Text('Do you want to add $userEmail to the group?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                _handleAddToGroup(userId);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      // Add the user to the group
      setState(() {
        _selectedUsers.add(userId);
      });
    }
  }

  void _handleAddToGroup(String userId) async {
    try {
      // Add selected user to the group
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (error) {
      print('Error adding user to the group: $error');
    }
  }
}
