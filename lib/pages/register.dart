/// @Author: Raziqrr rzqrdzn03@gmail.com
/// @Date: 2024-09-21 22:35:15
/// @LastEditors: Raziqrr rzqrdzn03@gmail.com
/// @LastEditTime: 2024-09-22 00:25:47
/// @FilePath: lib/pages/register.dart
/// @Description: 这是默认设置,可以在设置》工具》File Description中进行配置

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

//run these commands to install necessary pacakages before developing the app
//
//flutter pub add cloud_firestore
//flutter pub add firebase_auth
//flutter pub add firebase_storage
//flutter pub add firebase_core
//flutter pub add image_picker
//flutter pub add shared_preferences
//flutter pub add google_fonts
//flutter pub add email_validator
//flutter pub get

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  TextEditingController phoneController = TextEditingController();

  Uint8List? userImage;

  String emailErrorMessage = "";

  void PickImage(ImageSource imageSource) async {
    final imagePicker = ImagePicker();
    final choosenImage = await imagePicker.pickImage(source: imageSource);
    if (choosenImage != null) {
      final imageData = await File(choosenImage.path).readAsBytes();
      setState(() {
        userImage = imageData;
      });
    }
  }

  Future<String> UploadImage(String uid) async {
    final imageReference =
        FirebaseStorage.instance.ref("Users/$uid/${DateTime.now()}.jpg");
    await imageReference.putData(userImage!);
    final imageUrl = await imageReference.getDownloadURL();
    return imageUrl;
  }

  void Register() async {
    try {
      //register account
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      //get account id
      final uid = credential.user!.uid;

      //upload image
      final imageUrl = await UploadImage(uid);

      //starting firestore instance
      final db = FirebaseFirestore.instance;

      //prepare data for upload
      final userData = <String, dynamic>{
        "userPhoneNumber": phoneController.text,
        "userEmail": emailController.text,
        "userPassword": passwordController.text,
        "userPhotoUrl": userImage
      };

      //upload using .set
      db.collection("Users").doc(uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Successfully registered your account, please continue to login.')));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('The password provided is too weak.')));
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('The account already exists for that email.')));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
          ),
          Text("Register"),
          SizedBox(
            height: 40,
          ),
          TextField(
            controller: emailController,
            onChanged: (textValue) {
              bool emailIsValid = EmailValidator.validate(textValue);
              if (emailIsValid) {
                emailErrorMessage = "";
              } else {
                emailErrorMessage = "Invalid email format";
              }
              setState(() {});
            },
            decoration: InputDecoration(
                errorText: emailErrorMessage == "" ? null : emailErrorMessage,
                hintText: "Email"),
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(hintText: "Password"),
          ),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(hintText: "Phone Number"),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                image: userImage != null
                    ? DecorationImage(
                        fit: BoxFit.cover, image: MemoryImage(userImage!))
                    : null),
          ),
          ElevatedButton(
              onPressed: () {
                PickImage(ImageSource.camera);
              },
              child: Text("Upload")),
          ElevatedButton(
              onPressed: () {
                Register();
              },
              child: Text("Register"))
        ],
      ),
    );
  }
}
