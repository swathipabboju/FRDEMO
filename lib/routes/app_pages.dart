import 'package:camera/camera.dart';
import 'package:cgg_attendance/attendance.dart';
import 'package:cgg_attendance/attendanceios.dart';
import 'package:cgg_attendance/dashboard.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/splash.dart';
import 'package:cgg_attendance/takePicture.dart';
import 'package:cgg_attendance/takepicture_ios.dart';
import 'package:cgg_attendance/user_registration.dart';
import 'package:cgg_attendance/view/faceRecognitionView.dart';
import 'package:cgg_attendance/view/registrationLive.dart';
import 'package:flutter/material.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.registration: (context) => UpdateProfileScreen(),
      // AppRoutes.registration: (context) => UserRegistration(),
      AppRoutes.splash: (context) => SplashSCreen(),
      AppRoutes.attendance: (context) => Attendance(),
      AppRoutes.attendanceIOS: (context) => AttendanceIOS(),
      AppRoutes.dashboard: (context) => DashboardScreen(),
      // AppRoutes.FaceRecognitionView: ((context) => FaceRecognitionView()),

      // AppRoutes.takecameraIOS: (context) => TakePictureScreenIOS(),
    };
  }
}
