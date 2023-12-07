import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cgg_attendance/const/colors.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/view/FR%20flutter/appconstants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  String resultvalue = "";
  bool facedetectedIN = false;
  bool facedetectedOUT = false;
  int _selectedIndex = 0;
  File? localImage;
  MethodChannel platform = MethodChannel('example.com/channel');

  /* Future<void> _faceRecogPunchIn() async {
    String random;
    try {
      random = await platform.invokeMethod('faceRecogPunchIn');
    } on PlatformException catch (e) {
      random = "";
      print("resultvalue1111 $e");
    }
    setState(() {
      resultvalue = random;
      print("resultvalue1111 $resultvalue");
    });
  } */

  /* Future<void> _faceRecogPunchOut() async {
    String random;
    try {
      random = await platform.invokeMethod('faceRecogPunchOut');
    } on PlatformException catch (e) {
      random = "";
      print("resultvalue1111e $e");
    }
    setState(() {
      resultvalue = random;
      print("resultvalue1111 $resultvalue");
    });
  } */

  Future<void> _handleResultFromAndroidIn(
    dynamic result,
    BuildContext context,
  ) async {
    print("Received result from iOS IN: $result");
    if (result == "trueIN") {
      //facedetectedIN=true;

      //  _punchInTAP(context);
    } else if (result == "trueOUT") {
      print("Received result from iOS OUT: $result");

      // showFinalDayOutAlert(context, loginUserDetails ?? LoginData());
    }
    setState(() {
      // facedetectedIN;
      print("facedetected $facedetectedIN");
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      localImage = await getImageFile();
      setState(() {
        Appconstants.sourceFile = localImage ?? File("");
      });
      String base64File = await fileToBase64(Appconstants.sourceFile);
      //print("base64File $base64File");
      print("local image is ${localImage?.path}");
      print("Appconstants.sourceFile ${Appconstants.sourceFile.path}");
    });
  }

  Future<String> fileToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  @override
  Widget build(BuildContext context) {
    /* platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onResultFromAndroidIN':
          _handleResultFromAndroidIn(
            call.arguments,
            context,
          );
          break;

        // ... other cases ...q
      }
    }); */

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance"),
      ),
      body: Container(
        color: AppColors.primaryDark,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_forward),
            label: 'Punch In',
            backgroundColor: Colors.lightGreen,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_forward),
            label: 'Punch Out',
            backgroundColor: Colors.red,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) async {
    await availableCameras();
    setState(() {
      _selectedIndex = index;
      print("_selectedIndex$_selectedIndex");
      if (_selectedIndex == 0) {
        Navigator.pushNamed(context, AppRoutes.FaceRecognitionView);
        /* if (Platform.isIOS) {
          print("is iOS 0");
          // _faceRecogPunchIn();
        } else if (Platform.isAndroid) {
          //_faceRecogPunchIn();
        } */
      } else if (_selectedIndex == 1) {
        if (Platform.isIOS) {
          print("is iOS 1");
          // _faceRecogPunchIn();
        } else if (Platform.isAndroid) {
          //_faceRecogPunchOut();
        }
      }
    });
  }

  Future<File?> getImageFile() async {
    try {
      if (Platform.isIOS) {
        return await getImagePathForIOS();
      } else if (Platform.isAndroid) {
        return await getImagePathForAndroid();
      }
      return null;
    } catch (e) {
      print('Error retrieving image: $e');
      return null;
    }
  }

  Future<File?> getImagePathForIOS() async {
    try {
      // Get the application documents directory for iOS
      Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();
      print("ios path is ${appDocumentsDirectory.path}");
      String imagesPath = '${appDocumentsDirectory.path}/images/profile.jpg';

      File imageFile = File(imagesPath);
      if (await imageFile.exists()) {
        return imageFile; // Return the image file if it exists
      }
      return null;
    } catch (e) {
      print('Error retrieving image for iOS: $e');
      return null;
    }
  }

  Future<File?> getImagePathForAndroid() async {
    try {
      // Get the external storage directory for Android
      Directory? appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        String imagesPath = '${appDir.path}/files/profile.jpg';

        File imageFile = File(imagesPath);
        if (await imageFile.exists()) {
          return imageFile; // Return the image file if it exists
        }
      }
      return null;
    } catch (e) {
      print('Error retrieving image for Android: $e');
      return null;
    }
  }
}
