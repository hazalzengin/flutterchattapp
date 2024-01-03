import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messagepart/ActivityShow.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';


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
  late String videoDownloadUrl;

  Task(
      this.id,
      this.userId,
      this.task,
      this.isCompleted,
      this.userEmail,
      this.selectedStartDay,
      this.selectedEndDay,
      this.repetitionCount,
      this.videoDownloadUrl,
      );

  Task.fromMap(Map<String, dynamic>? map) {
    id = map?['id'] ?? '';
    userId = map?['userId'] ?? '';
    task = map?['task'] ?? '';
    isCompleted = map?['isCompleted'] ?? false;
    userEmail = map?['userEmail'] ?? '';
    selectedStartDay = _parseTimestamp(map?['selectedStartDay']) ?? DateTime.now();
    selectedEndDay = _parseTimestamp(map?['selectedEndDay']) ?? DateTime.now();
    repetitionCount = map?['repetitionCount'] ?? 0;
    videoDownloadUrl = map?['videoDownloadUrl'] ?? '';
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
      'videoDownloadUrl': videoDownloadUrl,
    };
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null; // or throw an exception, depending on your logic
  }
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final FirebaseHelper _firebaseHelper = FirebaseHelper();
  int selectedRepetitionCount = 7;
  List<int> repetitionCountOptions = [7, 10, 15, 20, 25, 30];

  DateTime _selectedStartDay = DateTime.now();
  DateTime _selectedEndDay = DateTime.now();
  final TextEditingController _taskController = TextEditingController();
  String selectedUserId = '';
  String selectedUserEmail = '';
  late String _downloadURL = '';
  List<DropdownMenuItem<String>> dropdownItemsForUsers = [];

  File? _videoFile;
  Uint8List? _videoBytes;
  File? _uploadedVideoFile;

  @override
  void initState() {
    super.initState();

    // Fetch users and update dropdown
    _fetchUsersAndUpdateDropdown().then((_) {
      selectedUserId = dropdownItemsForUsers.isNotEmpty ? dropdownItemsForUsers.first.value ?? '' : '';
    });
  }

  Future<void> _pickVideo() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: true,
      );

      if (result != null) {
        setState(() {
          _videoBytes = result.files.single.bytes;
          _videoFile = null; // Clear video file if bytes are selected
        });
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: true,
      );

      if (result != null) {
        setState(() {
          _videoFile = File(result.files.single.path!);
          _videoBytes = null; // Clear video bytes if a file is selected
        });
      }
    }
  }

  Future<void> _uploadVideoToFirebaseStorage() async {
    try {
      if (_videoFile != null || (_videoBytes != null && _videoBytes!.isNotEmpty)) {
        // Compress video if it's a file
        if (_videoFile != null) {
          _videoFile = (await VideoCompress.compressVideo(
            _videoFile!.path,
            quality: VideoQuality.DefaultQuality,
          )) as File?;
        }

        Reference storageReference = FirebaseStorage.instance.ref().child('videos/${Uuid().v4()}.mp4');
        UploadTask uploadTask;

        if (_videoFile != null) {
          uploadTask = storageReference.putFile(_videoFile!);
        } else if (_videoBytes != null) {
          uploadTask = storageReference.putData(_videoBytes!);
        } else {
          print('No valid video file or bytes to upload');
          return;
        }

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) async {
          if (snapshot.state == TaskState.success) {
            print('Upload complete!');
            // Retrieve download URL here
            _downloadURL = await snapshot.ref.getDownloadURL();

            setState(() {
              if (_videoFile != null) {
                _uploadedVideoFile = _videoFile; // Store the reference before setting to null
              }
              _videoFile = null;
              _videoBytes = null;
            });
            print('Download URL: $_downloadURL');

            _addTaskToFirestore();
          } else if (snapshot.state == TaskState.running) {
            print('Upload is still in progress...');
          } else if (snapshot.state == TaskState.error) {
            print('Error during upload: ${snapshot.storage}');
          }
        });
        await uploadTask;
      } else {
        print('No valid video file or bytes to upload');
      }
    } catch (e) {
      print('Error uploading video: $e');
      // Handle the error appropriately
    }
  }


  void _addTaskToFirestore() async {
    try {
      if (_taskController.text.isNotEmpty && selectedUserId.isNotEmpty && _downloadURL.isNotEmpty) {
        await _firebaseHelper.addTask(
          Task(
            '', // Leave it empty, Firestore will generate the ID
            selectedUserId,
            _taskController.text.trim(),
            false,
            selectedUserEmail,
            _selectedStartDay,
            _selectedEndDay,
            selectedRepetitionCount,
            _downloadURL,
          ),
          selectedUserId,
          selectedStartDay: _selectedStartDay,
          selectedEndDay: _selectedEndDay,
          repetitionCount: selectedRepetitionCount,
          videoDownloadUrl: _downloadURL,
        );
        _taskController.clear();
      }
    } catch (e) {
      print('Error adding task: $e');
      // Handle the error appropriately
    }
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
            SizedBox(height: 8.0),
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
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () async {
                await _uploadVideoToFirebaseStorage();
                String task = _taskController.text.trim();
                if (task.isNotEmpty && selectedUserId.isNotEmpty && _downloadURL.isNotEmpty) {
                  await _firebaseHelper.addTask(
                    Task(
                      '', // Leave it empty, Firestore will generate the ID
                      selectedUserId,
                      task,
                      false,
                      selectedUserEmail,
                      _selectedStartDay,
                      _selectedEndDay,
                      selectedRepetitionCount,
                      _downloadURL,
                    ),
                    selectedUserId,
                    selectedStartDay: _selectedStartDay,
                    selectedEndDay: _selectedEndDay,
                    repetitionCount: selectedRepetitionCount,
                    videoDownloadUrl: _downloadURL,
                  );
                  _taskController.clear();
                }
              },
              child: Text('Add Task'),
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
              onPressed: _pickVideo,
              child: Text('Pick Video'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _selectDuration(context);
              },
              child: Text('Select Duration'),
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

  void navigateToChecklistScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityScreen(), // Make sure ActivityScreen is imported correctly
        settings: RouteSettings(arguments: _firebaseHelper),
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

  Future<void> _selectDuration(BuildContext context) async {
    int initialDays = (_selectedEndDay.difference(_selectedStartDay).inDays + 1).clamp(1, 365);

    int? pickedDays = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Duration in Days'),
          children: [5, 10, 15, 30, 60, 90].map((days) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, days);
              },
              child: Text('$days day${days == 1 ? '' : 's'}'),
            );
          }).toList(),
        );
      },
    );

    if (pickedDays != null) {
      setState(() {
        _selectedEndDay = _selectedStartDay.add(Duration(days: pickedDays));
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
      {required DateTime selectedStartDay,
        required DateTime selectedEndDay,
        required int repetitionCount,
        required String videoDownloadUrl}) async {
    try {
      String userEmail = await getUserEmail(userId);
      await tasksCollection.add({
        'userId': userId,
        'task': task.task,
        'isCompleted': task.isCompleted,
        'userEmail': userEmail,
        'selectedStartDay': selectedStartDay,
        'selectedEndDay': selectedEndDay,
        'repetitionCount': repetitionCount,
        'videoDownloadUrl': videoDownloadUrl,
      });
    } catch (e) {
      print('Error adding task: $e');
    }
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
