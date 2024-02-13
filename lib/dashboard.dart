import 'package:cgg_attendance/const/colors.dart';
import 'package:cgg_attendance/const/image_constants.dart';
import 'package:cgg_attendance/res/appAlerts/customErrorAlert.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/sharedpreferences/share_pref_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit the app?'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: const Text('Yes'),
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                  ),
                  CupertinoDialogAction(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                ],
              );
            },
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
                    title: const Text('Exit App'),
                    content:
                        const Text('Are you sure you want to exit the app?'),
                    actions: <Widget>[
                      CupertinoDialogAction(
                        child: const Text('Yes'),
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                      ),
                      CupertinoDialogAction(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          title: const Text('Dashboard'),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ImageConstants.bg),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Column(
              children: [
                Image.asset(
                  ImageConstants.logo,
                  width: 200,
                  height: 200,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.attendance);
                        },
                        child: const Card(
                          elevation: 3.0,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Attendance',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      GestureDetector(
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return CupertinoAlertDialog(
                                title: const Text('Delete User'),
                                content: const Text(
                                    'Are you sure you want to delete this user?'),
                                actions: <Widget>[
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () async {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      prefs.remove('punchRecords');
                                      prefs.remove(SharedConstants.userName);
                                      Navigator.of(context).pop(true);
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CustomErrorAlert(
                                                Buttontext: "OK",
                                                descriptions:
                                                    "User Profile Deleted",
                                                Img: ImageConstants.correct,
                                                onPressed: () {
                                                  Navigator
                                                      .pushReplacementNamed(
                                                          context,
                                                          AppRoutes.registration);
                                                },
                                                imagebg: Colors.white,
                                                bgColor: AppColors.green);
                                          });

                                      // Perform delete operation here
                                      // Navigator.of(context).pop(true);
                                      // Navigator.pushNamed(context, AppRoutes.registration);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Card(
                          elevation: 3.0,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Delete User',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
