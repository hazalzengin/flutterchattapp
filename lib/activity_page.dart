import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messagepart/ActivityShow.dart';

class ChecklistScreen extends StatefulWidget {
  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class Task {
  late String id;
  late String userId;
  late String task;
  late bool isCompleted;
  late String userEmail;  // Add this line for user email

  Task(this.id, this.userId, this.task, this.isCompleted, this.userEmail);  // Update the constructor

  Task.fromMap(Map<String, dynamic>? map) {
    id = map?['id'] ?? '';
    userId = map?['userId'] ?? '';
    task = map?['task'] ?? '';
    isCompleted = map?['isCompleted'] ?? false;
    userEmail = map?['userEmail'] ?? '';  // Add this line for user email
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'task': task, 'isCompleted': isCompleted, 'userEmail': userEmail};  // Update the toMap method
  }
}

class _ChecklistScreenState extends State<ChecklistScreen> {

  void navigateToChecklistScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityScreen(),
        settings: RouteSettings(arguments: _firebaseHelper),

    ),

    );
  }

  final TextEditingController _taskController = TextEditingController();
  final FirebaseHelper _firebaseHelper = FirebaseHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String selectedUserId = '';
  String selectedUserEmail = '';
  List<DropdownMenuItem<String>> dropdownItemsForUsers = [];

  @override
  @override
  void initState() {
    super.initState();
    _fetchUsersAndUpdateDropdown().then((_) {
      selectedUserId = dropdownItemsForUsers.isNotEmpty ? dropdownItemsForUsers.first.value ?? '' : '';
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'Enter task',
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedUserId,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedUserId = newValue;
                      });
                    }
                  },
                  items: dropdownItemsForUsers.isNotEmpty
                      ? dropdownItemsForUsers
                      : [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text('No users'),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    String task = _taskController.text.trim();
                    if (task.isNotEmpty && selectedUserId.isNotEmpty) {
                      await _firebaseHelper.addTask(
                        Task('', selectedUserId, task, false, ''),
                        selectedUserId,
                      );
                      _taskController.clear();
                    }
                  },
                ),





              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to the ActivityScreen page
              navigateToChecklistScreen(context);
            },
            child: Text('Go to Activity Screen'),
          ),
        ],
      ),
    );
  }
  Future<List<DropdownMenuItem<String>>> _fetchUsersAndUpdateDropdown() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final List<DropdownMenuItem<String>> dropdownItems = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final String userEmail = data['email'] ?? '';
        final String userId = data['uid'] ?? '';

        dropdownItems.add(DropdownMenuItem<String>(
          value: userId,
          child: Text(userEmail),
        ));

        if (userId == selectedUserId) {
          // Set the selectedUserEmail when the userId matches the selectedUserId
          setState(() {
            selectedUserEmail = userEmail;
          });
        }
      }

      if (mounted) {
        setState(() {
          dropdownItemsForUsers = dropdownItems;
        });
      }

      return dropdownItems;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }


}
class FirebaseHelper {
  final CollectionReference tasksCollection =
  FirebaseFirestore.instance.collection('tasks');
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  Future<void> addTask(Task task, String userId) async {
    String userEmail = await getUserEmail(userId);
    await tasksCollection.add({
      ...task.toMap(),
      'userEmail': userEmail,
    });
  }

  Future<String> getUserEmail(String userId) async {
    try {
      DocumentSnapshot userDoc =
      await usersCollection.doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>? ?? {};
      return userData['email'] ?? '';
    } catch (e) {
      print('Error getting user email: $e');
      return '';
    }
  }

  Stream<List<Task>> getTasks() {
    return tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          Task.fromMap(doc.data() as Map<String, dynamic>? ?? {}))
          .toList();
    });
  }
}
