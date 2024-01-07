import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetay extends StatefulWidget {
  @override
  _TaskDetayState createState() => _TaskDetayState();
}

class _TaskDetayState extends State<TaskDetay> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Page'),
      ),
      body: _buildUserTasks(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context); // Navigate back to the home page
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }

  Widget _buildUserTasks() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserTasks(_auth.currentUser!.uid),
      builder: (context, tasksSnapshot) {
        if (tasksSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (tasksSnapshot.hasError) {
          return Text('Error fetching user tasks');
        }

        List<Map<String, dynamic>> tasks = tasksSnapshot.data ?? [];

        return ListView.separated(
          itemCount: tasks.length,
          separatorBuilder: (BuildContext context, int index) => Divider(),
          itemBuilder: (context, index) {
            Map<String, dynamic> taskData = tasks[index];

            final String taskId = taskData['taskId'] ?? '';
            final String taskName = taskData['task'] ?? '';
            final String taskDescription = taskData['taskDescription'] ?? '';
            final int repetitionCount = taskData['repetitionCount'] ?? 0;
            final Timestamp startDayTimestamp = taskData['selectedStartDay'] ?? Timestamp.now();
            final Timestamp endDayTimestamp = taskData['selectedEndDay'] ?? Timestamp.now();

            final DateTime startDay = startDayTimestamp.toDate();
            final DateTime endDay = endDayTimestamp.toDate();
            final DateTime today = DateTime.now();

            bool isTodayInRange = today.isAfter(startDay) && today.isBefore(endDay);

            return Card(
              elevation: 3,
              child: ListTile(
                title: Text(
                  taskName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Task ID: $taskId'),
                    Text('Description: $taskDescription'),
                    Text('Repetition Count: $repetitionCount'),
                    ElevatedButton(
                      onPressed: isTodayInRange
                          ? () => _showDaySelectionDialog(taskId, endDay)
                          : null,
                      child: Text('Mark Day as Completed'),
                    ),
                    _buildCheckboxList(taskId, taskData['completedDays'] ?? [], endDay),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckboxList(String taskId, List<dynamic> completedDays, DateTime endDay) {
    List<int?> convertedCompletedDays = (completedDays as List<dynamic>?)?.cast<int>() ?? [];
    DateTime today = DateTime.now();
    int day = today.day;

    bool isToday = today.isAfter(endDay.subtract(Duration(days: endDay.day - day))) &&
        today.isBefore(endDay.add(Duration(days: 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(1, (index) {
        return CheckboxListTile(
          title: Text('Day $day - ${isToday ? "true" : "false"}'),
          value: isToday ? convertedCompletedDays.contains(day) : false,
          onChanged: (isToday)
              ? (value) {
            if (value != null && value) {
              convertedCompletedDays = [day];
              print('Checkbox for today selected!');
            } else {
              convertedCompletedDays = [];
            }
            _updateDayCompletionStatus(taskId, day, value ?? false);
          }
              : null,
        );
      }),
    );
  }

  Future<void> _updateDayCompletionStatus(String taskId, int dayIndex, bool isCompleted) async {
    try {
      print('Updating day completion status for taskId: $taskId');
      if (taskId != null && taskId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
          'completedDays': isCompleted ? FieldValue.arrayUnion([dayIndex]) : FieldValue.arrayRemove([dayIndex]),
        });
        print('Day $dayIndex completion status updated to $isCompleted');
      } else {
        print('Error: taskId is null or empty');
      }
    } catch (e) {
      print('Error updating day completion status: $e');
    }
  }

  void _showDaySelectionDialog(String taskId, DateTime endDay) {
    print('Showing dialog for taskId: $taskId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark Day as Completed'),
          content: _buildDaySelectionList(taskId, endDay),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDaySelectionList(String taskId, DateTime endDay) {
    final DateTime today = DateTime.now();
    final int totalDays = endDay.difference(today).inDays;

    List<bool> dayCompletionStatus = List.generate(totalDays, (index) => false);

    return Column(
      children: List.generate(totalDays, (index) {
        DateTime dayDate = today.add(Duration(days: index));
        bool isDaySelectable = today.isBefore(dayDate) && (index == 0);

        return CheckboxListTile(
          title: Text('Day ${index + 1} - ${dayDate.toString().substring(0, 10)}'),
          value: dayCompletionStatus[index],
          onChanged: isDaySelectable
              ? (value) {
            print('Checkbox changed for Day ${index + 1}. New value: $value');
            setState(() {
              dayCompletionStatus[index] = value ?? false;
            });

            if (value ?? false) {
              _updateDayCompletionStatus(taskId, index + 1, value ?? false);
            } else {

            }
          }
              : null,
        );
      }),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserTasks(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      return tasksSnapshot.docs.map((DocumentSnapshot<Map<String, dynamic>> doc) {
        Map<String, dynamic> taskData = doc.data() ?? {};

        String taskId = doc.id;

        taskData['taskId'] = taskId;
        return taskData;
      }).toList();
    } catch (e) {
      print('Error fetching user tasks: $e');
      throw e;
    }
  }
}
