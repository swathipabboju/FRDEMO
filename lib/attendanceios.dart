import 'dart:io';

import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/takepicture_ios.dart';
import 'package:cgg_attendance/user_registration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class AttendanceIOS extends StatefulWidget {
  const AttendanceIOS({super.key});

  @override
  State<AttendanceIOS> createState() => _AttendanceState();
}

class _AttendanceState extends State<AttendanceIOS> {
  MethodChannel channel = MethodChannel("FlutterFramework/swift_native");

  Future<void> _handlePunchResultFromiOS(
    dynamic result,
    BuildContext context,
  ) async {
    print("Received result from iOS: $result");
// Assuming result is a Map
    if (result is Map) {
      // Access the "status" key and save it in a variable
      String status = result['status'];
      String fr = result['result'];

      // Now you can use the 'status' variable as needed in your Flutter class
      print('Status: $status');

      // Save the status to a class variable if needed
      String attendancestatus = status;
      String frResult = fr;
      if (attendancestatus == "punchIn" && frResult == "face Matched") {
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text('Attendance'),
                content: Text('Punch In Successfully'),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pushNamed(
                          context, AppRoutes.registration); // Close the alert
                    },
                  ),
                ],
              );
            });
        //  else if (attendancestatus == "punchOut" && frResult == "face Matched") {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedImage = ModalRoute.of(context)!.settings.arguments as File?;
    Future<void> faceRecogPunchOut() async {
      try {
        await channel.invokeMethod('getPunchOutIOS');
        print("Method invoked successfully");
      } on PlatformException catch (e) {
        print("Error invoking method: ${e.message}");
      }
    }

    Future<void> faceRecogPunchIn() async {
      try {
        await channel.invokeMethod('getPunchInIOS');
        print("Method invoked successfully");
      } on PlatformException catch (e) {
        print("Error invoking method: ${e.message}");
      }
    }

    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onResultFromPunchIniOS':
          print("punch in result");
          _handlePunchResultFromiOS(call.arguments, context);
          break;
        case 'onResultFromPunchOutiOS':
          print("punch out result");
          _handlePunchResultFromiOS(call.arguments, context);
          break;
        // ... other cases ...
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: savedImage != null
                  ? Image.file(savedImage) // Display the saved image
                  : Text('Image not found'),
              //Text('Your content goes here'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle button click here
                // Handle button click based on platform
                if (Platform.isIOS) {
                  faceRecogPunchIn();
                } else if (Platform.isAndroid) {
                  // Code specific to Android
                  print('Button Clicked on Android');
                }
              },
              child: const Text('Punch In'),
            ),
          ],
        ),
      ),
    );
  }
}
