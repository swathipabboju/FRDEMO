import 'dart:convert';
import 'dart:io';

import 'package:cgg_attendance/const/colors.dart';
import 'package:cgg_attendance/const/image_constants.dart';
import 'package:cgg_attendance/res/appAlerts/customErrorAlert.dart';
import 'package:cgg_attendance/res/components/appInputButtonComponent.dart';
import 'package:cgg_attendance/res/components/appInputText.dart';
import 'package:cgg_attendance/res/components/appInputTextfield.dart';
import 'package:cgg_attendance/res/components/appToast.dart';
import 'package:cgg_attendance/res/constants/appStrings.dart';
import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/sharedpreferences/share_pref_constants.dart';
import 'package:cgg_attendance/utils/internetCheck.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  String? savedProfilePath = "";
  File? savedFileImage;
  String base64File = "";
  String base64Image = "", random = "";
  Uint8List? bytes;

  File? savedImage;
  // method channel
  MethodChannel platform = const MethodChannel('example.com/channel');
  MethodChannel platformChannelIOS =
      const MethodChannel("FlutterFramework/swift_native");
  // to call android platform
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  Future<void> cameraScreen() async {
    try {
      random = await platform.invokeMethod('callRegistration');
    } on PlatformException catch (e1) {
      random = "";
      debugPrint("resultINvalue1111 $e1");
    }
  }

// to get result from Android platform to flutter
  Future<void> handleResultFromAndroidIn(
    dynamic result,
    BuildContext context,
  ) async {
    print("result in registration ${result}");
    debugPrint("resultOUT111111 $result");
    //bytes = base64.decode(result);
    final Directory? appDir = await getExternalStorageDirectory();
    File imageFile = File('${appDir?.path}/profile.jpg');
    print("image  file path::${imageFile.path}");
    if (await imageFile.exists()) {
      setState(() {
        savedProfilePath = imageFile.path;

        print("imagefile path retrived :: $savedProfilePath");
      });
      bytes = await baseImage(savedProfilePath);
      await loadImagePath(File(savedProfilePath!));

      // imageFile.delete();
    } else {
      print('Image not found');
    }

    setState(() {
      // print("objectAndroid$bytes");
      // final RegExp regex = RegExp(r'^data:image\/\w+;base64,');
      // String base64Image = result.replaceFirst(regex, '');
      // bytes = base64Decode(base64Image);
    });

    // print("Received result from iOS IN: $result");
  }

  Future<void> ProfileRegistartIOS() async {
    try {
      await platformChannelIOS.invokeMethod('getRegistartionIOS');
      //  print("Method invoked successfully");
    } on PlatformException catch (e) {
      //  print("Error invoking method: ${e.message}");
    }
  }

  Future<void> _handlProfileRegstrationResultiOS(
      dynamic result, BuildContext context) async {
    // print("Received result from iOS: $result");
// Assuming result is a Map
    if (result is Map) {
      String status = result['status'];
      String profileBase64 = result['result'];
      // print('Status: $status');
      // print('fr : $profileBase64');
      String attendancestatus = status;
      String profileBase64String = profileBase64;
      if (attendancestatus == "captured profile image") {
        //  registrationProvider.setIsLoadingStatus(true);
        bytes = base64.decode(profileBase64String);

        Uint8List compressedBytes =
            await compressBase64Image(profileBase64String);
        print('Compressed bytes: $compressedBytes');
        print("image in bytes$bytes");
        if (bytes != null) {
          // Create a temporary file
          // Get the application documents directory
          savedProfilePath =
              await saveImageToDocumentsDirectoryIOS(compressedBytes);
          if (savedProfilePath != null) {
            print('Image saved to: $savedProfilePath');
            // Use the saveImagePath as needed
          } else {
            print('Failed to save image.');
          }
        }
        setState(() {});
        // print("profileBase64String$profileBase64String");
        // print("bytesIOS$bytes");
      } else {
        Navigator.pushNamed(context, AppRoutes.registration);
      }
    }
  }

  Future<Uint8List> compressBase64Image(String base64String) async {
    Uint8List bytes = base64.decode(base64String);
    List<int> compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      // Optional: set the minimum width of the output image
      quality: 0, // Optional: set the quality of the output image (0 - 100)
    );
    return Uint8List.fromList(compressedBytes);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      platform.setMethodCallHandler((call) async {
        print("call in regidtration $call");
        switch (call.method) {
          case 'onResultFromAndroidIN':
            handleResultFromAndroidIn(
              call.arguments,
              context,
            );
            debugPrint("call.arguments${call.arguments}");
        }
      });
    } else if (Platform.isIOS) {
      platformChannelIOS.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onResultFromProfileRegistation':
            // print("punch in result");
            _handlProfileRegstrationResultiOS(call.arguments, context);
            break;
        }
      });
    }

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
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      } else if (Platform.isIOS) {
                        exit(1);
                      }
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
      child: Stack(
        children: [
          Scaffold(
              appBar: AppBar(
                iconTheme: IconThemeData(),
                title: Text("Update Profile",
                    style: TextStyle(color: AppColors.white)),
                leading: IconButton(
                    onPressed: () async {
                      showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CupertinoAlertDialog(
                            title: const Text('Exit App'),
                            content: const Text(
                                'Are you sure you want to exit the app?'),
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
                      /*   File file1 = File("");
                      await saveImageToDocumentsDirectory(file1);
                      setState(() {});
                      Navigator.pop(context); */
                      // Navigator.pushReplacementNamed(context, AppRoutes.registration);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    )),
                centerTitle: true,
                backgroundColor: AppColors.primaryDark,
              ),
              body: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(ImageConstants.bg),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      color: Colors.white,
                      elevation: 5,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  height:
                                      MediaQuery.of(context).size.height * 0.14,
                                  child: (bytes != null)
                                      ? Image.memory(
                                          bytes ?? Uint8List(0),
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return SvgPicture.asset(
                                              ImageConstants.appIcon,
                                              width: 100,
                                              height: 100,
                                            );
                                          },
                                          // Adjust the BoxFit as needed
                                        )
                                      : Image.asset(
                                          ImageConstants.appIcon,
                                          width: 100,
                                          height: 100,
                                        ),
                                ),
                                SizedBox(
                                  height: 50,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                AppInputButtonComponent(
                                  buttonText: "Upload Image ",
                                  //color: Color.fromARGB(255, 63, 16, 10),
                                  onPressed: () async {
                                    if (Platform.isIOS) {
                                      ProfileRegistartIOS();
                                    } else {
                                      cameraScreen();
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                AppInputButtonComponent(
                                  buttonText: AppStrings.register,
                                  //color: Color.fromARGB(255, 63, 16, 10),
                                  onPressed: () async {
                                    if (mobileValidations()) {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      prefs.setString(
                                          SharedConstants.profilePath,
                                          savedProfilePath ?? "");
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CustomErrorAlert(
                                                Buttontext: "OK",
                                                descriptions: "Profile Updated",
                                                Img: ImageConstants.correct,
                                                onPressed: () {
                                                  Navigator
                                                      .pushReplacementNamed(
                                                          context,
                                                          AppRoutes.dashboard);
                                                  /*  Navigator.pushNamed(
                                                      context, AppRoutes.dashboard); */
                                                },
                                                imagebg: Colors.white,
                                                bgColor: AppColors.green);
                                          });
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> saveImageToDocumentsDirectory(File imageFile) async {
    // try {
    try {
      // Get the application documents directory
      Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();

      // Specify the image directory path
      String imagesDirectoryPath = '${appDocumentsDirectory.path}/images/';

      // Specify the image file name
      String imageName = 'profile.jpg';

      // Form the complete path of the image file
      String imagePath = '$imagesDirectoryPath$imageName';

      // Check if the directory exists before deleting
      Directory imagesDirectory = Directory(imagesDirectoryPath);
      if (imagesDirectory.existsSync()) {
        // Delete the image file
        File imageFile = File(imagePath);
        if (imageFile.existsSync()) {
          imageFile.deleteSync();
        }

        // Delete the entire directory
        imagesDirectory.deleteSync(recursive: true);
      }

      debugPrint("Directory and file deleted successfully");
    } catch (e) {
      debugPrint('Error deleting directory: $e');
    }
  }

  baseImage(savedProfilePath) async {
    if (savedProfilePath != null && savedProfilePath.isNotEmpty) {
      print("savedProfilePath:::$savedProfilePath");
      base64File = await fileToBase64(File(savedProfilePath));
      await loadImagePath(File(savedProfilePath));
      //img.Image? lapimage = await loadImagePath(File(savedProfilePath));
      //faceLightValue = laplacianWithImage(lapimage!);
      // print('lapvalue1:::$faceLightValue');
      setState(() {});

      //  await morethanTwoFace(File(savedProfilePath), context);
      // Remove the data header before decoding
      final RegExp regex = RegExp(r'^data:image\/\w+;base64,');
      String base64Image = base64File.replaceFirst(regex, '');
      Uint8List? bytes = base64Decode(base64Image);
      return bytes;

      //print("base64Image $base64Image");
    } else {
      bytes = null;
    }
  }

  Future<String?> saveImageToDocumentsDirectoryIOS(Uint8List bytes) async {
    try {
      String dir = (await getApplicationDocumentsDirectory()).path;
      String subDir = '$dir/images';
      String fullPath = '$subDir/profile.jpg';

      // Ensure the subdirectory exists
      Directory(subDir).createSync(recursive: true);

      //String fullPath = '$dir/images/profileregister.jpg';
      print("local file full path ${fullPath}");
      File file = File(fullPath);
      await file.writeAsBytes(bytes);
      print(file.path);
      //savedProfilePath = file.path;
      // final result = await ImageGallerySaver.saveImage(bytes);
      // print(result);

      return file.path;
    } catch (e) {
      print('Error saving image: $e');
    }
    return null;
  }

  Future<String> fileToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<img.Image?> loadImagePath(File imageFile) async {
    if (!imageFile.existsSync()) {
      // Handle the case where the file doesn't exist
      return null;
    }

    List<int> bytes = await imageFile.readAsBytes();
    return img.decodeImage(Uint8List.fromList(bytes));
  }

  bool mobileValidations() {
    if (Platform.isAndroid) {
      if (savedProfilePath!.isEmpty) {
        AppToast().showToast(AppStrings.plz_update_profile);
        return false;
      }
    } else if (Platform.isIOS) {
      if (bytes == null) {
        AppToast().showToast(AppStrings.plz_update_profile);
        return false;
      }
    }
    return true;
  }
}
