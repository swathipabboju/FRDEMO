import 'package:cgg_attendance/const/image_constants.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/sharedpreferences/share_pref_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashSCreen extends StatefulWidget {
  const SplashSCreen({super.key});

  @override
  State<SplashSCreen> createState() => _SplashSCreenState();
}

class _SplashSCreenState extends State<SplashSCreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(ImageConstants.splash_img), fit: BoxFit.fill),
          ),
        )
      ],
    ));
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userLogin = await prefs.getString(SharedConstants.profilePath);
      print("userLogin:$userLogin");

      if (userLogin == null || userLogin == "") {
        Navigator.pushReplacementNamed(context, AppRoutes.registration);
      } else if (userLogin != "" && userLogin != "null") {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.registration);
      }
      ;
    });
  }
}
