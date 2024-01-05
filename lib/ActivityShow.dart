import 'package:flutter/material.dart';
import 'package:messagepart/activity_page.dart';

class ActivityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseHelper _firebaseHelper =
    ModalRoute.of(context)!.settings.arguments as FirebaseHelper;

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Screen'),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseHelper.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks available.'));
          } else {
            List<Task> tasks = snapshot.data!;

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                // Calculate the difference between start day and end day
                Duration difference = task.selectedEndDay.difference(task.selectedStartDay);

                return Card(
                  elevation: 3.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      '${task.task ?? 'No task name'}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assigned to: ${task.userEmail ?? 'Unknown'}'),
                        SizedBox(height: 4.0),
                        Text('Duration: ${difference.inDays} days'),
                        Text('Times: ${task.repetitionCount} times'),
                      ],
                    ),
                    trailing: Checkbox(
                      value: task.isCompleted,
                      onChanged: null, // Set onChanged to null to make it non-interactive
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
