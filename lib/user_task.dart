import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messagepart/chat_page.dart'; // Replace with your actual import path

class UserTasksPage extends StatefulWidget {
  final String userEmail;

  const UserTasksPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserTasksPageState createState() => _UserTasksPageState();
}

class _UserTasksPageState extends State<UserTasksPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize Awesome Notifications
    AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Channel',
          channelDescription: 'Default channel for basic notifications',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks for ${widget.userEmail}'),
      ),
      body: _buildUserTasksList(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _triggerNotificationManually,
            child: Icon(Icons.notifications),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              // Trigger navigation to ChatPage when the button is pressed
              _navigateToChatPage(context);
            },
            child: Icon(Icons.chat),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTasksList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userEmail', isEqualTo: widget.userEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading');
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => ListTile(
            title: Text(doc['task'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration: ${_formatDate(doc['selectedStartDay'])} - ${_formatDate(doc['selectedEndDay'])}',
                ),
                Text(
                  'Remaining Days: ${_calculateRemainingDays(doc['selectedEndDay'])}',
                ),
                Text('Repetition Count: ${doc['repetitionCount']}'),
                // Add more details as needed
              ],
            ),
          ))
              .toList(),
        );
      },
    );
  }

  Future<void> _scheduleNotification(
      int daysRemaining, DateTime endDate) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: 'Task Reminder',
        body: '$daysRemaining days remaining for your task!',
      ),
      schedule: NotificationCalendar(
        timeZone: 'America/New_York',
      ),
    );
  }

  void _triggerNotificationManually() {
    DateTime now = DateTime.now();
    DateTime endDate = now.add(Duration(minutes: 1));
    int daysRemaining = 1;

    _scheduleNotification(daysRemaining, endDate);
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }

    DateTime dateTime = timestamp.toDate();
    String formattedDate = DateFormat('MMMM d, y').format(dateTime);
    return formattedDate;
  }

  String _calculateRemainingDays(Timestamp? endDay) {
    if (endDay == null) {
      return 'N/A';
    }

    DateTime endDate = endDay.toDate();
    DateTime now = DateTime.now();
    Duration remainingDuration = endDate.difference(now);

    if (remainingDuration.isNegative) {
      return 'Expired';
    } else {
      return '${remainingDuration.inDays} days remaining';
    }
  }

  void _navigateToChatPage(BuildContext context) {
    // Retrieve the user ID from Firebase Auth
    String userId = _auth.currentUser?.uid ?? '';

    // Navigate to the ChatPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          receiverUserEmail: widget.userEmail,
          receiverUserID: userId,
        ),
      ),
    );
  }
}
