import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messagepart/chat_page.dart';
import 'package:messagepart/groups_chat.dart';
import 'package:messagepart/taskdetay.dart';

class TranieeHomePage extends StatefulWidget {
  const TranieeHomePage({Key? key}) : super(key: key);

  @override
  State<TranieeHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<TranieeHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> tasksCollection =
  FirebaseFirestore.instance.collection('tasks');

  Future<Map<String, dynamic>> _fetchUserInfo(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data() ?? {};
    } catch (e) {
      print('Error fetching user information: $e');
      throw e;
    }
  }

  Future<bool> _isMemberOfGroup(String groupId, String currentUserEmail) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> groupDoc =
      await FirebaseFirestore.instance.collection('groups').doc(groupId).get();

      Map<String, dynamic> groupData = groupDoc.data() ?? {};
      List<String> members = List<String>.from(groupData['members'] ?? []);

      return members.contains(currentUserEmail);
    } catch (e) {
      print('Error checking group membership: $e');
      throw e;
    }
  }

  Future<String> _fetchOwnerName(String ownerId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> ownerDoc =
      await FirebaseFirestore.instance.collection('users').doc(ownerId).get();

      Map<String, dynamic> ownerData = ownerDoc.data() ?? {};
      String ownerName = ownerData['name'] ?? '';
      String ownerSurname = ownerData['surname'] ?? '';

      return '$ownerName $ownerSurname';
    } catch (e) {
      print('Error fetching owner information: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserTasks(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      return tasksSnapshot.docs.map((DocumentSnapshot<Map<String, dynamic>> doc) {
        Map<String, dynamic> taskData = doc.data() ?? {};
        // Ensure that 'taskId' is stored correctly in Firestore
        String taskId = doc.id; // Use doc.id to get the document ID as taskId
        // Add the taskId to the taskData map
        taskData['taskId'] = taskId;
        return taskData;
      }).toList();
    } catch (e) {
      print('Error fetching user tasks: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildUserList(),
          ),
          Expanded(
            child: _buildGroupList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    final String currentUserEmail = _auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> groups = snapshot.data?.docs ?? [];

        return ListView.separated(
          itemCount: groups.length,
          separatorBuilder: (BuildContext context, int index) => Divider(),
          itemBuilder: (context, index) {
            Map<String, dynamic> data = groups[index].data() as Map<String, dynamic>;
            final String groupId = data['groupId'] ?? '';
            final String groupName = data['groupName'] ?? '';
            final String ownerId = data['owner'] ?? '';

            final IconData groupIcon = Icons.group;

            return FutureBuilder<bool>(
              future: _isMemberOfGroup(groupId, currentUserEmail),
              builder: (context, isMemberSnapshot) {
                // Existing code...

                return FutureBuilder<String>(
                  future: _fetchOwnerName(ownerId),
                  builder: (context, ownerNameSnapshot) {
                    // Existing code...

                    if (isMemberSnapshot.data == true) {
                      return Card(
                        elevation: 3,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(groupIcon, size: 40, color: Colors.blue),
                              title: Text(
                                groupName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Owner: ${ownerNameSnapshot.data}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupDetailsScreen(
                                      groupId: groupId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 10), // Add some spacing
                            ElevatedButton(
                              onPressed: () {
                                _navigateToTaskDetailPage(); // Define this method
                              },
                              child: Text('Go to TaskDetay'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Card(
                        elevation: 3,
                        child: ListTile(
                          leading: Icon(groupIcon, size: 40, color: Colors.grey),
                          title: Text(
                            groupName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: Text('Owner: ${ownerNameSnapshot.data}'),
                          onTap: () {
                            _showNotMemberAlert(context);
                          },
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToTaskDetailPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetay(),
      ),
    );
  }
  void _showNotMemberAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Not a Member'),
          content: Text('You are not a member of this group.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 0)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Text('Error: ${userSnapshot.error}');
        }
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> users = userSnapshot.data?.docs ?? [];

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (BuildContext context, int index) => Divider(),
          itemBuilder: (context, index) {
            Map<String, dynamic> userData = users[index].data() as Map<String, dynamic>;
            final String userId = userData['uid'] ?? '';
            final String userName = userData['name'] ?? '';
            final String userSurname = userData['surname'] ?? '';
            final String userEmail = userData['email'] ?? '';

            return GestureDetector(
              onTap: () {
                // Navigate to ChatPage with the selected user
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverUserEmail: userEmail,
                      receiverUserID: userId,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://icons.veryicon.com/png/o/internet--web/prejudice/user-128.png',
                    ),
                  ),
                  title: Text(
                    '$userName $userSurname',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('User ID: $userId'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
