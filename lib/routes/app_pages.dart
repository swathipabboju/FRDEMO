import 'package:cgg_attendance/attendance.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/user_registration.dart';
import 'package:flutter/material.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.registration: (context) => UserRegistration(),
      AppRoutes.attendance: (context) => Attendance(),
    };
  }
}
