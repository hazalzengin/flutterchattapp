import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UpdateProfilePage extends StatefulWidget {
  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  File? _image;
  Uint8List? _imageBytes;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        pickImage();
                      },
                      child: _imageBytes == null
                          ? CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.add_a_photo),
                      )
                          : CircleAvatar(
                        radius: 50,
                        backgroundImage: MemoryImage(_imageBytes!),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Update Your Profile',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20.0),
                    _buildTextField('Name', nameController),
                    _buildTextField('Surname', surnameController),
                    _buildTextField('Username', usernameController),
                    _buildTextField('Age', ageController),
                    _buildTextField('Weight (kg)', weightController),
                    _buildTextField('Height (cm)', heightController),
                    SizedBox(height: 32.0),
                    _buildUpdateButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType:
            label == 'Username' ? TextInputType.text : TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            validator: (value) {
              return null; // Allow any input without validation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            updateProfile();
          }
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.blue,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Update Profile',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void updateProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Upload image to Firebase Storage and get the URL
      String imageUrl = '';
      if (_image != null || _imageBytes != null) {
        imageUrl = await uploadImage();
      }

      // Prepare data to update in Firestore
      Map<String, dynamic> updateData = {
        if (nameController.text.isNotEmpty) 'name': nameController.text,
        if (surnameController.text.isNotEmpty) 'surname': surnameController.text,
        if (usernameController.text.isNotEmpty) 'username': usernameController.text,
        if (ageController.text.isNotEmpty) 'age': int.tryParse(ageController.text) ?? 0,
        if (weightController.text.isNotEmpty) 'weight': double.tryParse(weightController.text) ?? 0.0,
        if (heightController.text.isNotEmpty) 'height': double.tryParse(heightController.text) ?? 0.0,
       if (imageUrl.isNotEmpty) 'profileImageUrl': imageUrl,
      };

      // Print debug information
      print('Update Data: $updateData');

      // Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update(updateData);

      // Navigate back to the profile page
      Navigator.pop(context);
    } catch (e) {
      // Handle error
      print('Error updating profile: $e');
    }
  }

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Use _imageBytes for web platform
          _imageBytes = result.files.single.bytes;
        } else {
          // Use _image for non-web platforms
          _image = File(result.files.single.path!);
        }
      });
    } else {
      print('No image selected');
    }
  }

  Future<String> uploadImage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      final Reference storageReference =
      FirebaseStorage.instance.ref().child('profile_images/${user?.uid}.jpg');

      if (kIsWeb) {
        // Handle image upload for web using _imageBytes
        await storageReference.putData(_imageBytes!);
      } else {
        // Handle image upload for non-web using _image
        await storageReference.putFile(_image!);
      }

      return await storageReference.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }
}
