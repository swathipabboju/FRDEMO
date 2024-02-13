import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.blue;
   static const Color white = Colors.white;
   static const Color transparent= Colors.transparent;
  static const Color primaryDark = const Color(0xFF161733);
  static const Color footerColor = const Color(0xFF161733);
  static const Color black = Color.fromARGB(255, 11, 11, 12);
  static const Color grey = const Color(0xFF767676);
  static const Color red = const Color(0xFFD42C39);
  static const Color maroon = Color.fromARGB(255, 178, 27, 16);
  static const Color green = Color.fromARGB(255, 9, 84, 39);
  //static const Color appbarcolor = const Color(0xFF51696B);
  static const Color ash = const Color(0xFF51696B);
    static const Color appbarcolor = const Color(0xFF00BCAA);
  static const Color bgcolor = const Color(0xFF0c8069);
  static const Color buttoncolor = const Color(0xFF51696B);
 // static const Color btngreen = const Color(0xFF629b58);
 static const Color btngreen = const Color(0xFF51696B);
    static const Color btnpink = const Color(0xFFb73766);
      static const Color btnblue = const Color(0xFF1b6aaa);
   static const LinearGradient reusableGradient = LinearGradient(
  colors: [ Color(0xFF0c8069), Color(0xFF03979A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

static const LinearGradient sampleGradient = LinearGradient(
  colors: [ Color.fromARGB(255, 182, 160, 223), Color.fromARGB(182, 2, 4, 37)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

  
}
