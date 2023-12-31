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
  List<int> completedDays = [];

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
      ) : completedDays = [];

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
    completedDays = List<int>.from(map?['completedDays'] ?? []);
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
      'completedDays': completedDays,
    };
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
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
          print('Video yüklemek için geçerli bir dosya veya veri yok');
          // Video eklemek istemiyor, bu durumu atla
          _addTaskToFirestore(); // Video seçilmemişse sadece görev bilgilerini ekleyin
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
        print('Video yüklemek için geçerli bir dosya veya veri yok');
        _addTaskToFirestore();
      }
    } catch (e) {
      print('Video yüklerken hata oluştu: $e');
    }
  }

  void _addTaskToFirestore() async {
    try {
      if (_taskController.text.isNotEmpty && selectedUserId.isNotEmpty) {
        Task newTask = Task(
          '', // Firestore will generate the ID
          selectedUserId,
          _taskController.text.trim(),
          false,
          selectedUserEmail,
          _selectedStartDay,
          _selectedEndDay,
          selectedRepetitionCount,
          _downloadURL,
        );

        // Check if a video is selected
        if (_videoFile != null || (_videoBytes != null && _videoBytes!.isNotEmpty)) {
          newTask.videoDownloadUrl = _downloadURL;
        }

        await _firebaseHelper.addTask(
          newTask,
          selectedUserId,
          selectedStartDay: _selectedStartDay,
          selectedEndDay: _selectedEndDay,
          repetitionCount: selectedRepetitionCount,
          videoDownloadUrl: _downloadURL,
        );

        // Increment completed days count for the user
        await _incrementCompletedDays(selectedUserId, _selectedStartDay);

        _taskController.clear();
      } else {
        print('Error: Task or User is empty.');
      }
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> _incrementCompletedDays(String userId, DateTime completedDay) async {
    try {
      // Fetch the current completed days count for the user
      DocumentSnapshot userDoc = await _firebaseHelper.usersCollection.doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, int> completedDaysCount = Map<String, int>.from(userData['completedDaysCount'] ?? {});

      // Increment the count for the completed day
      String formattedDay = _formatDateTime(completedDay);
      completedDaysCount[formattedDay] = (completedDaysCount[formattedDay] ?? 0) + 1;

      // Update the user document with the new completed days count
      await _firebaseHelper.updateUserCompletedDays(userId, completedDaysCount);
    } catch (e) {
      print('Error incrementing completed days count: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Format DateTime to a string that can be used as a key in the completedDaysCount map
    return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Give task your traniee'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: 'Enter task',
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
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
              decoration: InputDecoration(
                labelText: 'Select User',
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<int>(
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
              decoration: InputDecoration(
                labelText: 'Select Repetition Count',
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                _pickVideo();
              },
              icon: Icon(Icons.video_library), // Video ikonu
              label: Text('Pick Video'),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _selectNewDay(context, true);
              },
              child: Text('Select Start Day'),
              style: ElevatedButton.styleFrom(
                primary: Colors.orange, // İsteğe bağlı: Buton rengi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),


            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _selectDuration(context);
              },
              child: Text('Select Duration'),
              style: ElevatedButton.styleFrom(
                primary: Colors.cyan, // İsteğe bağlı: Buton rengi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await _uploadVideoToFirebaseStorage();
                String task = _taskController.text.trim();
                if (task.isNotEmpty && selectedUserId.isNotEmpty && _downloadURL.isNotEmpty) {
                  Task newTask = Task(
                    '', // Leave it empty, Firestore will generate the ID
                    selectedUserId,
                    task,
                    false,
                    selectedUserEmail,
                    _selectedStartDay,
                    _selectedEndDay,
                    selectedRepetitionCount,
                    _downloadURL,
                  );

                  await _firebaseHelper.addTask(
                    newTask,
                    selectedUserId,
                    selectedStartDay: _selectedStartDay,
                    selectedEndDay: _selectedEndDay,
                    repetitionCount: selectedRepetitionCount,
                    videoDownloadUrl: _downloadURL,
                  );

                  _taskController.clear();
                }
              },
              child: Text(
                'Add Task',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
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
  Future<void> updateUserCompletedDays(String userId, Map<String, int> completedDaysCount) async {
    try {
      await usersCollection.doc(userId).update({
        'completedDaysCount': completedDaysCount,
      });
    } catch (e) {
      print('Error updating user completed days: $e');
    }
  }
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
