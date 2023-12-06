import 'package:camera/camera.dart';
import 'package:cgg_attendance/attendance.dart';
import 'package:cgg_attendance/attendanceios.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/splash.dart';
import 'package:cgg_attendance/takePicture.dart';
import 'package:cgg_attendance/takepicture_ios.dart';
import 'package:cgg_attendance/user_registration.dart';
import 'package:flutter/material.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.registration: (context) => UserRegistration(),
      AppRoutes.splash: (context) => SplashSCreen(),
      AppRoutes.attendance: (context) => Attendance(),
      AppRoutes.attendanceIOS: (context) => AttendanceIOS(),
     // AppRoutes.takecameraIOS: (context) => TakePictureScreenIOS(),
    };
  }
}
