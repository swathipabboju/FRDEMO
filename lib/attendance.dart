import 'dart:io';

import 'package:cgg_attendance/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  MethodChannel platform = MethodChannel('example.com/channel');

  Future<void> _faceRecogPunchIn() async {
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
  }

  Future<void> _faceRecogPunchOut() async {
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
  }

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
  Widget build(BuildContext context) {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onResultFromAndroidIN':
          _handleResultFromAndroidIn(
            call.arguments,
            context,
          );
          break;

        // ... other cases ...q
      }
    });

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print("_selectedIndex$_selectedIndex");
      if (_selectedIndex == 0) {
        if (Platform.isIOS) {
          // _faceRecogPunchIn();
        } else if (Platform.isAndroid) {
          _faceRecogPunchIn();
        }
      } else if (_selectedIndex == 1) {
        if (Platform.isIOS) {
          // _faceRecogPunchIn();
        } else if (Platform.isAndroid) {
          _faceRecogPunchOut();
        }
      }
    });
  }
}
