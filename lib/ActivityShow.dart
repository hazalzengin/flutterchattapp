import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messagepart/activity_page.dart';

class ActivityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseHelper _firebaseHelper = ModalRoute.of(context)!.settings.arguments as FirebaseHelper;

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Screen'),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseHelper.getTasks(),
        builder: (context, snapshot) {
          print('Connection State: ${snapshot.connectionState}');
          print('Has Error: ${snapshot.hasError}');
          print('Data Available: ${snapshot.hasData}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks available.'));
          } else {
            List<Task> tasks = snapshot.data!;
            print('Number of tasks: ${tasks.length}');
            print('First task: ${tasks.isNotEmpty ? tasks[0].task : "No tasks"}');

            return  ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text('${task.task ?? 'No task name'} : ${task.userEmail ?? 'Unknown'}'),
                  trailing: Checkbox(
                    value: task.isCompleted,
                    onChanged: null, // Set onChanged to null to make it non-interactive
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
