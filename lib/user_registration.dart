import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cgg_attendance/const/colors.dart';
import 'package:cgg_attendance/const/image_constants.dart';
import 'package:cgg_attendance/takePicture.dart';
import 'package:cgg_attendance/takepicture_ios.dart';
import 'package:flutter/cupertino.dart';
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
  String savedProfilePath = "";
  File? savedFileImage;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        
        body: Stack(
          
           children: <Widget>[
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(ImageConstants.bg ), fit: BoxFit.fill),
          ),
        ),
      
            
            Center(
              child: Container(
                width: 300,
                height: 400,
            
                color: Colors.white,
                child: Column(
            
                  children: [
                    
                    Text("User Registration",style: TextStyle(fontSize: 21,color: Colors.black),),
                    SizedBox(width: 20, height: 20,),
                    Image.asset(ImageConstants.logo,width: 100, height: 100,),
              
                    SizedBox(width: 20, height: 20,),
                    TextButton(
                       style: ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(AppColors.primaryDark),
    shape: MaterialStateProperty.all<OutlinedBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0), // Adjust the borderRadius as needed
      ),
    ),
  ),


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
                        child: Text("REGISTER",style: TextStyle(color: Colors.white),))
                  ],
                ),
              ),
            ),
          ],

        ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final cameras = await availableCameras();
      loadImage();
      // Get a specific camera from the list of available cameras.
      setState(() {
        firstCamera = cameras.last;
      });
    });
  }

  Future<void> loadImage() async {
    try {
      // Get the application documents directory
      Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();

      // Create a File object for the saved image
      String imageName = 'profile.jpg'; // Replace with the actual image name
      File imageFile = File('${appDocumentsDirectory.path}/images/$imageName');
      savedFileImage = imageFile;
      // Check if the image file exists
      if (await imageFile.exists()) {
        setState(() {
          print(imageFile.path);
          savedProfilePath = imageFile.path;

          print("imagefile path retrived");
          //  savedImage = imageFile;
        });
      } else {
        print('Image not found');
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> deleteImage(BuildContext context) async {
    try {
      if (savedFileImage != null) {
        await savedFileImage!.delete();
        savedFileImage = null;
        print('Image deleted successfully');
        // ignore: use_build_context_synchronously
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                  title: const Text('CGG Attendance'),
                  content: const Text('Deleted  Successfully'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.pushNamed(
                            context, AppRoutes.registration); // Close the alert
                      },
                    ),
                  ]);
            });
      } else {
        print('No image to delete');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
