import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupChatScreen({
    required this.groupId,
    required this.groupName,
  });

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder(
      stream: _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var messages = snapshot.data?.docs;

        List<Widget> messageWidgets = [];
        for (var message in messages!) {
          var messageText = message['text'];
          var messageSender = message['sender'];

          var messageWidget =
          MessageWidget(messageSender, messageText);
          messageWidgets.add(messageWidget);
        }

        return ListView(
          reverse: true,
          children: messageWidgets,
        );
      },
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
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    try {
      String messageText = _messageController.text.trim();
      String currentUserId = _auth.currentUser!.uid;

      if (messageText.isNotEmpty) {
        await _firestore
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'text': messageText,
          'sender': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _messageController.clear();
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}

class MessageWidget extends StatelessWidget {
  final String sender;
  final String text;

  MessageWidget(this.sender, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}
