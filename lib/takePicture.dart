import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Image')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          if (Platform.isIOS) {
          } else if (Platform.isAndroid) {
            // Take the Picture in a try / catch block. If anything goes wrong,
            // catch the error.
            try {
              // Ensure that the camera is initialized.
              await _initializeControllerFuture;

              // Attempt to take a picture and get the file image
              // where it was saved.
              final image = await _controller.takePicture();

              File file = File(image.path); // Convert XFile to File
              // Get the original file path
              String originalPath = file.path;
              final Directory? appDir = await getExternalStorageDirectory();
              final String appDirPath = appDir!.path;
              File file1 = File('${appDir.path}');

              // Create a unique filename for the image
              //final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
              //  final String filePath = '$appDirPath/profile.jpg';

              // Extract the directory path
              String directoryPath = path.dirname(file1.path);
              print("directoryPath $directoryPath");

              // Extract the file extension
              String fileExtension = path.extension(originalPath);
              print("fileExtension $fileExtension");

              // Define the new file name (you can modify it as needed)
              String newFileName = 'profile';

              // Create the new file path by combining the directory path, new file name, and file extension
              String newPath = path.join(
                  directoryPath, 'files', '$newFileName$fileExtension');

              try {
                // ... (previous code)

                // Copy the file to the desired directory
                await file.copy(newPath);

                // Delete the original file if needed
                await file.delete();

                print("New Captured image path: $newPath");

                // ... (remaining code)
              } catch (e) {
                // ... (previous error handling)
              }

              // Rename the file by moving it to the new path
              //  File newFile = File(newPath);
              //  file.renameSync(newPath);

              //  print("New Captured image path: ${newFile.path}");
              print("imageee2345${image.path}");

              if (!mounted) return;
              if (image.path.isNotEmpty) {
                _showAlertDialog(context);
              }

              // If the picture was taken, display it on a new screen.
            } catch (e) {
              // If an error occurs, log the error to the console.
              print(e);
            }
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  void _showAlertDialog(BuildContext context) {
    // Create the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text('CGG ATTENDANCE'),
      content: Text('Image is succuessfully captured and savesd in device'),
      actions: [
        // OK Button
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.attendance);
          },
          child: Text('OK'),
        ),
      ],
    );

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
