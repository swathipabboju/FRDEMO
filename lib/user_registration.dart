import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cgg_attendance/takePicture.dart';
import 'package:cgg_attendance/takepicture_ios.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class UserRegistration extends StatefulWidget {
  const UserRegistration({super.key});

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  CameraDescription? firstCamera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Registration"),
        ),
        body: Column(
          children: [
            TextButton(
                onPressed: () {
                  if (firstCamera != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                          camera: firstCamera!,
                        ),
                      ),
                    );
                  }
                },
                child: Text("Register"))
          ],
        ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final cameras = await availableCameras();

      // Get a specific camera from the list of available cameras.
      setState(() {
        firstCamera = cameras.last;
      });
    });
  }
}
