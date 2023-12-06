import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TakePictureScreenIOS extends StatefulWidget {
  const TakePictureScreenIOS({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenIOSState createState() => TakePictureScreenIOSState();
}

class TakePictureScreenIOSState extends State<TakePictureScreenIOS> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late final String appDirPath;
  File? savedImage;
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
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            File file = File(image.path); // Convert XFile to File
            // Get the original file path
            //  String originalPath = file.path;
            saveImageToDocumentsDirectory(file);

            // If the picture was taken, display it on a new screen.
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Future<void> saveImageToDocumentsDirectory(File imageFile) async {
    try {
      // Get the application documents directory
      Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();

      // Create a new directory within the documents directory
      Directory imagesDirectory =
          Directory('${appDocumentsDirectory.path}/images/');
      if (!imagesDirectory.existsSync()) {
        imagesDirectory.createSync(recursive: true);
      }

      // Copy the image file to the documents directory
      String imageName = 'profile.jpg'; // Provide a unique name for your image
       savedImage =
          await imageFile.copy('${imagesDirectory.path}/$imageName');

     // print('Image saved to: ${savedImage.path}');
    //  loadImage();
      _showAlertDialog(context);
     // List<int> imageBytes = await savedImage.readAsBytes();
//print(imageBytes);
    } catch (e) {
      print('Error saving image: $e');
    }
  }
// Future<void> loadImage() async {
//     try {
//       // Get the application documents directory
//       Directory appDocumentsDirectory =
//           await getApplicationDocumentsDirectory();

//       // Create a File object for the saved image
//       String imageName =
//           'profile.jpg'; // Replace with the actual image name
//       File imageFile = File('${appDocumentsDirectory.path}/images/$imageName');

//       // Check if the image file exists
//       if (await imageFile.exists()) {
//         setState(() {
//           print(imageFile.path);
//             print("imagefile path retrived");
//         //  savedImage = imageFile;
//         });
//       } else {
//         print('Image not found');
//       }
//     } catch (e) {
//       print('Error loading image: $e');
//     }
    
//   }
  
  void _showAlertDialog(BuildContext context) {
    // Create the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text('CGG ATTENDANCE'),
      content: const Text('Image is succuessfully captured and savesd in device'),
      actions: [
        // OK Button
        TextButton(
          onPressed: () {
            Platform.isIOS
                ? Navigator.pushNamed(context, AppRoutes.attendanceIOS , arguments: savedImage)
                : Navigator.pushNamed(context, AppRoutes.attendance);
          },
          child: GestureDetector(child: const Text('OK')),
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
