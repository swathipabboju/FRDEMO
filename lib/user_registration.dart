import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cgg_attendance/const/colors.dart';
import 'package:cgg_attendance/const/image_constants.dart';
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

      // Get a specific camera from the list of available cameras.
      setState(() {
        firstCamera = cameras.last;
      });
    });
  }
}
