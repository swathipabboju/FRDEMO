import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class UserRegistration extends StatefulWidget {
  const UserRegistration({super.key});

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  XFile pic = XFile("");

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller?.initialize();
  }

  Future<void> _takeSelfie() async {
    try {
      await _initializeControllerFuture;

      // Get the directory for saving images
      final Directory? appDir = await getExternalStorageDirectory();
      final String appDirPath = appDir!.path;

      // Create a unique filename for the image
      //final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '$appDirPath/profile.jpg';

      // Take the picture and save it to the specified file path
      await _controller?.takePicture();

      // Display a success message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Selfie Captured'),
            content: Text('Selfie saved to: $filePath'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error taking selfie: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registration"),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          print("snaptshot${snapshot.connectionState}");
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller!);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takeSelfie,
        child: Icon(Icons.camera),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      // Get the directory for saving images
      final Directory? appDir = await getExternalStorageDirectory();
      final String appDirPath = appDir!.path;

      // Create a unique filename for the image
      // final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = path.join(appDirPath, 'profile.jpg');

      // Take the picture and save it to the specified file path
      await _controller?.takePicture();

      // Display a success message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Image Captured'),
            content: Text('Image saved to: $filePath'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }
}
