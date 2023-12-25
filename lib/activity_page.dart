import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late String userEmail;
  late DateTime selectedStartDay;
  late DateTime selectedEndDay;
  late int repetitionCount;

  Task(this.id, this.userId, this.task, this.isCompleted, this.userEmail, this.selectedStartDay, this.selectedEndDay, this.repetitionCount);

  Task.fromMap(Map<String, dynamic>? map) {
    id = map?['id'] ?? '';
    userId = map?['userId'] ?? '';
    task = map?['task'] ?? '';
    isCompleted = map?['isCompleted'] ?? false;
    userEmail = map?['userEmail'] ?? '';
    selectedStartDay = (map?['selectedStartDay'] as Timestamp?)?.toDate() ?? DateTime.now();
    selectedEndDay = (map?['selectedEndDay'] as Timestamp?)?.toDate() ?? DateTime.now();
    repetitionCount = map?['repetitionCount'] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'task': task,
      'isCompleted': isCompleted,
      'userEmail': userEmail,
      'selectedStartDay': selectedStartDay,
      'selectedEndDay': selectedEndDay,
      'repetitionCount': repetitionCount,
    };
  }
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  void navigateToChecklistScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityScreen(), // Make sure ActivityScreen is imported correctly
        settings: RouteSettings(arguments: _firebaseHelper),
      ),
    );
  }
  int selectedRepetitionCount = 7;
  List<int> repetitionCountOptions = [7, 10, 15, 20, 25, 30];

  DateTime _selectedStartDay = DateTime.now();
  DateTime _selectedEndDay = DateTime.now();
  final TextEditingController _taskController = TextEditingController();
  final FirebaseHelper _firebaseHelper = FirebaseHelper();
  String selectedUserId = '';
  String selectedUserEmail = '';
  List<DropdownMenuItem<String>> dropdownItemsForUsers = [];

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: 'Enter task',
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
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
                ),
                SizedBox(width: 8.0),
                DropdownButton<int>(
                  value: selectedRepetitionCount,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedRepetitionCount = newValue;
                      });
                    }
                  },
                  items: repetitionCountOptions.map((int count) {
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count repetitions'),
                    );
                  }).toList(),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () async {
                    String task = _taskController.text.trim();
                    if (task.isNotEmpty && selectedUserId.isNotEmpty) {
                      await _firebaseHelper.addTask(
                        Task('', selectedUserId, task, false, '', _selectedStartDay, _selectedEndDay, selectedRepetitionCount),
                        selectedUserId,
                        selectedStartDay: _selectedStartDay,
                        selectedEndDay: _selectedEndDay,
                        repetitionCount: selectedRepetitionCount,
                      );
                      _taskController.clear();
                    }
                  },
                  child: Text('Add Task'),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _selectNewDay(context, true);
              },
              child: Text('Select Start Day'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _selectNewDay(context, false);
              },
              child: Text('Select End Day'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                navigateToChecklistScreen(context);
              },
              child: Text('Go to Activity Screen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectNewDay(BuildContext context, bool isStartDay) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.utc(2023, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDay) {
          _selectedStartDay = pickedDate;
        } else {
          _selectedEndDay = pickedDate;
        }
      });
    }
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
  final CollectionReference tasksCollection = FirebaseFirestore.instance.collection('tasks');
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> addTask(Task task, String userId,
      {required DateTime selectedStartDay, required DateTime selectedEndDay, required int repetitionCount}) async {
    String userEmail = await getUserEmail(userId);
    await tasksCollection.add({
      ...task.toMap(),
      'userEmail': userEmail,
      'selectedStartDay': selectedStartDay,
      'selectedEndDay': selectedEndDay,
      'repetitionCount': repetitionCount,
    });
  }

  Future<String> getUserEmail(String userId) async {
    try {
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>? ?? {};
      return userData['email'] ?? '';
    } catch (e) {
      print('Error getting user email: $e');
      return '';
    }
  }

  Stream<List<Task>> getTasks() {
    return tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>? ?? {})).toList();
    });
  }
}
