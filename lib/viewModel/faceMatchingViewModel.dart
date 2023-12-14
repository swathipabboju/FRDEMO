import 'dart:io';
import 'dart:typed_data';

import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/view/FR%20flutter/appconstants.dart';
import 'package:cgg_attendance/view/FR%20flutter/face_matching.dart';
import 'package:cgg_attendance/repository/faceMatchingRepository.dart';
import 'package:cgg_attendance/res/components/alertComponent.dart';
import 'package:cgg_attendance/view/display_images.dart';
import 'package:face_camera/face_camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class FaceMatchingViewModel with ChangeNotifier {
  final _faceMatchingRepository = FaceMatchingRepository();

  File sourceImageFile = File("");
  File targetImageFile = File("");
  Future<void> faceMatchingApiCall(BuildContext context, File file) async {
    File? localFile = await rotateLocalImageFile(Appconstants.sourceFile.path);
    File? capturedFile = await rotateCapturedImageFile(file.path);

    File? croppedLocalFIle = await cropProfile(localFile);

    //Local face matching

    double faceMatchScore =
        await FaceMatching().loadModel(croppedLocalFIle, capturedFile);
    print("faceMatchScore local ${faceMatchScore}");

    if (faceMatchScore > 0.85) {
      Alerts.showAlertDialog(context, "Local Face Matched Successfully.",
          imagePath: "assets/assets_correct.png",
          Title: "Face Recognition", onpressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisplayImages(
                localImage: croppedLocalFIle,
                capturedImage: capturedFile ?? File(""),
              ),
            ));
        //Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }, buttontext: "ok", buttoncolor: Colors.green);
    } else {
      // Campreefee api call

      print("campreefee api call----------------");
      print("local file is $localFile");
      print("capured file is $capturedFile");
      /* final response = await _faceMatchingRepository.FaceMatchingInfoNew(
          localFile!, capturedFile!, context); */
      final response = await _faceMatchingRepository.FaceMatchingInfoNew(
          croppedLocalFIle, capturedFile!, context);
      print("croppedLocalFIle ${croppedLocalFIle.path}");
      print("capturedFile ${capturedFile.path}");
      print(
          "response in view model ${response.result?[0].faceMatches?[0].similarity}");
      if (response != "" || response != []) {
        if (response.result != null) {
          if (response.result != null &&
              response.result!.isNotEmpty &&
              response.result![0].faceMatches != null &&
              response.result![0].faceMatches!.isNotEmpty &&
              response.result![0].faceMatches![0].similarity != null &&
              response.result![0].faceMatches![0].similarity! > 0.98) {
            Alerts.showAlertDialog(context, "Face Matched Successfully.",
                imagePath: "assets/assets_correct.png",
                Title: "Face Recognition", onpressed: () {
              //Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayImages(
                      localImage: croppedLocalFIle,
                      capturedImage: capturedFile,
                    ),
                  ));
            }, buttontext: "ok", buttoncolor: Colors.green);
          } else {
            Alerts.showAlertDialog(context, "Face Not Matched.",
                imagePath: "assets/assets_error.png",
                Title: "Face Recognition", onpressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayImages(
                      localImage: croppedLocalFIle,
                      capturedImage: capturedFile,
                    ),
                  ));
              //Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            }, buttontext: "ok");
          }
        } else {
          Alerts.showAlertDialog(context, response.message,
              imagePath: "assets/assets_error.png",
              Title: "Face Recognition", onpressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayImages(
                    localImage: croppedLocalFIle,
                    capturedImage: capturedFile,
                  ),
                ));
            //Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }, buttontext: "ok");
        }
      } else {
        Alerts.showAlertDialog(
            context, "Something Went Wrong, Please Try Again Later.",
            imagePath: "assets/assets_error.png",
            Title: "Face Recognition", onpressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }, buttontext: "ok");
      }
    }

    /*  } catch (e) {
      Alerts.showAlertDialog(
          context, "Server Not Responding, Please Try Again Later.",
          Title: "Face Recognition", onpressed: () {
        Navigator.pop(context);
      }, buttontext: "ok");
    } */
  }

  bool isLoaderVisible = false;
  changeLoaderState(bool state) {
    isLoaderVisible = state;
    notifyListeners();
  }

  Future<File> urlToFile(String imageUrl) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      File file = File('$tempPath/profile.jpg');
      http.Client client = http.Client();
      http.Response response = await client.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (await isFileReadableAndAccessible(file)) {
          print("readable and accessible ${file.path}");
          img.Image? originalImage = img.decodeImage(file.readAsBytesSync());
          File reducedSizeFile = await compressImage(originalImage, 1000);
          return reducedSizeFile;
        } else {
          print("File not readable or accessible.");
          throw FileSystemException('File not readable or accessible.');
        }
      } else {
        print("Failed to load image, status code ${response.statusCode}");
        throw http.ClientException(
            'Failed to load image, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating file from URL: $e');
      throw e;
    }
  }

  Future<bool> isFileReadableAndAccessible(File file) async {
    try {
      return file.existsSync() && await file.readAsBytes() != null;
    } catch (e) {
      print('Error checking file readability: $e');
      return false;
    }
  }

  Future<File> compressImage(
      img.Image? originalImage, int targetFileSizeKB) async {
    int quality = 90; // Initial quality setting
    List<int> compressedBytes = img.encodeJpg(originalImage!, quality: quality);
    while (compressedBytes.length > targetFileSizeKB * 1024 && quality > 0) {
      quality -= 10;
      compressedBytes = img.encodeJpg(originalImage, quality: quality);
    }
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File compressedFile = File('$tempPath/reduced_size.jpg');
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

  Future<File> cropProfile(File? profileImage) async {
    final FaceDetector _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
      ),
    );
    final inputImage = InputImage.fromFilePath(profileImage?.path ?? "");
    final faces = await _faceDetector.processImage(inputImage);
    Face detectedFace = faces.first;
    File? cropSaveFile;
    img.Image capturedImage =
        img.decodeImage(File(profileImage?.path ?? "").readAsBytesSync())!;
    if (detectedFace != null && detectedFace.boundingBox != null) {
      img.Image faceCrop = img.copyCrop(
        capturedImage,
        x: detectedFace.boundingBox.left.toInt() - 100,
        y: detectedFace.boundingBox.top.toInt() - 100,
        width: detectedFace.boundingBox.width.toInt() + 150,
        height: detectedFace.boundingBox.height.toInt() + 150,
      );
      final jpg = img.encodeJpg(faceCrop);
      cropSaveFile = File(profileImage?.path ?? "");
      await cropSaveFile.writeAsBytes(jpg);
      print("cropped file path ${cropSaveFile.path}");

      //AppConstants.profileImage = cropSaveFile;
      notifyListeners();
    }
    return cropSaveFile!;
  }

  Future<File?> rotateLocalImageFile(String filePath) async {
    File? rotatedFile;

    // Load the image file
    print("filee path ${filePath}");
    File imageFile = File(filePath);
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      // Rotate the image by 90 degrees clockwise
      img.Image rotatedImage = img.copyRotate(image, angle: 0);

      // Get platform-specific directory
      Directory? appDirectory;
      if (Platform.isAndroid) {
        appDirectory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        appDirectory = await getApplicationDocumentsDirectory();
      }

      if (appDirectory != null) {
        // Save the rotated image to the platform-specific directory
        String fileName =
            'rotated_local_image.png'; // Change the file name as needed
        String filePath = '${appDirectory.path}/$fileName';

        rotatedFile = File(filePath);
        await rotatedFile.writeAsBytes(img.encodePng(rotatedImage));
      }
    }

    return rotatedFile;
  }

  /* Future<File?> rotateLocalImageFile(String filePath) async {
    File? rotatedFile;

    // Load the image file
    File imageFile = File(filePath);
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      // Rotate the image by 90 degrees clockwise
      img.Image rotatedImage = img.copyRotate(image, angle: 0);

      // Get platform-specific directory
      Directory? appDirectory;
      if (Platform.isAndroid) {
        appDirectory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        appDirectory = await getApplicationDocumentsDirectory();
      }

      if (appDirectory != null) {
        // Save the rotated image to the platform-specific directory
        String fileName =
            'rotated_local_image.png'; // Change the file name as needed
        String filePath = '${appDirectory.path}/$fileName';

        rotatedFile = File(filePath);
        await rotatedFile.writeAsBytes(img.encodePng(rotatedImage));
      }
    }

    return rotatedFile;
  } */

  Future<File?> rotateCapturedImageFile(String filePath) async {
    File? rotatedFile;

    // Load the image file
    File imageFile = File(filePath);
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      // Rotate the image by 90 degrees clockwise
      img.Image rotatedImage = img.copyRotate(image, angle: 0);

      // Get platform-specific directory
      Directory? appDirectory;
      if (Platform.isAndroid) {
        appDirectory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        appDirectory = await getApplicationDocumentsDirectory();
      }

      if (appDirectory != null) {
        // Save the rotated image to the platform-specific directory
        String fileName =
            'rotated_captured_image.png'; // Change the file name as needed
        String filePath = '${appDirectory.path}/$fileName';

        rotatedFile = File(filePath);
        await rotatedFile.writeAsBytes(img.encodePng(rotatedImage));
      }
    }

    return rotatedFile;
  }

  /* Future<File?> rotateCapturedImageFile(String filePath) async {
    File? rotatedFile;

    // Load the image file
    File imageFile = File(filePath);
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      // Rotate the image by 90 degrees clockwise
      img.Image rotatedImage = img.copyRotate(image, angle: 0);

      // Get platform-specific directory
      Directory? appDirectory;
      if (Platform.isAndroid) {
        appDirectory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        appDirectory = await getApplicationDocumentsDirectory();
      }

      if (appDirectory != null) {
        // Save the rotated image to the platform-specific directory
        String fileName =
            'rotated_captured_image.png'; // Change the file name as needed
        String filePath = '${appDirectory.path}/$fileName';

        rotatedFile = File(filePath);
        await rotatedFile.writeAsBytes(img.encodePng(rotatedImage));
      }
    }

    return rotatedFile;
  } */
}
