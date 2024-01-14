import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:messagepart/register_page.dart';

class AuthService with ChangeNotifier {
  static const Map<int, UserType> userTypeMapping = {
    0: UserType.trainee,
    1: UserType.trainer,
    2:UserType.waittrainer
  };

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<UserType?> getUserType() async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user != null) {
        DocumentSnapshot userSnapshot =
        await _firebaseFirestore.collection('users').doc(user.uid).get();

        if (userSnapshot.exists) {
          int? userTypeValue = userSnapshot['userType'] as int?;
          print('UserTypeValue: $userTypeValue');

          // Convert the int value to UserType enum using the mapping
          UserType? userType = userTypeMapping[userTypeValue];
          return userType;
        } else {
          // Handle the case where the user document doesn't exist
          return null;
        }
      } else {
        // Handle the case where there is no authenticated user
        return null;
      }
    } catch (e) {
      // Handle any errors that might occur during the fetch
      print('Error fetching user type: $e');
      return null;
    }
  }

  Future<void> signInWithEmailandPassword(
      String email,
      String password,

      ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot userSnapshot = await _firebaseFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      int userTypeValue = userSnapshot['userType'] as int;
      print(userTypeValue);


    } catch (e) {
      throw e;
    }
  }


  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<UserCredential> signUpWithEmailandPassword(
      String email,
      String password,
      FilePickerResult? certificationFileResult,
      String name,
      String surname,
      String phoneNumber,
      int age,
      UserType userType,
      BuildContext context,
      ) async {
    try {
      UserCredential userCredential =
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set user data in Firestore
      await _firebaseFirestore.collection('users').doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'surname': surname,
          'phoneNumber': phoneNumber,
          'age': age,
          'userType': userType.index,
        },
        SetOptions(merge: true),
      );

      // Upload certification file if available
      if (certificationFileResult != null) {
        String certificationFileURL = await uploadCertificationFile(
          userCredential.user!.uid,
          certificationFileResult,
        );

        // Update certificationFileURL in Firestore
        await _firebaseFirestore.collection('users').doc(userCredential.user!.uid).update(
          {'certificationFileURL': certificationFileURL},
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<String> uploadCertificationFile(String userId, FilePickerResult? result) async {
    try {
      if (result == null) {
        // Handle the case where the user canceled the file picker
        return ''; // You can return an empty string or throw an exception, based on your requirement
      }

      final storage = firebase_storage.FirebaseStorage.instance;
      final storageRef = storage.ref().child('certifications').child('$userId.pdf');

      if (kIsWeb) {
        // For web, use the bytes property
        final bytes = result.files!.first.bytes!;
        await storageRef.putData(bytes);
      } else {
        // For mobile, use the paths property
        final filePath = result.paths!.first;
        final certificationFile = File(filePath!);
        await storageRef.putFile(certificationFile);
      }

      final fileURL = await storageRef.getDownloadURL();
      return fileURL;
    } catch (e) {
      print('Error uploading certification file: $e');
      throw e;
    }
  }
}