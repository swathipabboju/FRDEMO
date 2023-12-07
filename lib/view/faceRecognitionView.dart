import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/view/FR%20flutter/antiSpoofing.dart';
import 'package:cgg_attendance/view/FR%20flutter/appconstants.dart';
import 'package:cgg_attendance/viewModel/faceMatchingViewModel.dart';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class FaceRecognitionView extends StatefulWidget {
  const FaceRecognitionView({super.key});

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  MethodChannel channel = MethodChannel("FlutterFramework/swift_native");

  File? faceRecog;
  Face? detectedFace;
  File? cropSaveFile;
  File? _capturedImage;
  tflite.Interpreter? interpreter;

  static const int INPUT_IMAGE_SIZE = 256;
  static const double THRESHOLD = 0.8;
  static const int LAPLACE_THRESHOLD = 50;
  static const int LAPLACIAN_THRESHOLD = 250;
  double? antiSpoofingScore;
  String base64File = '';
  String base64Image = '';
  File base64toFile = File('');
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //base();
  }

  base() async {
    base64File = await fileToBase64(Appconstants.sourceFile);
    // Remove the data header before decoding
    final RegExp regex = RegExp(r'^data:image\/\w+;base64,');
    base64Image = base64File.replaceFirst(regex, '');
    //print("base64Image $base64Image");
  }

  Future<void> faceRecogPunchIn(local, captured) async {
    try {
      Map<String, dynamic> arguments = {
        'local': local, // Replace with your argument key-value pairs
        'captured': captured,
      };

      await channel.invokeMethod('getPunchInIOS', arguments);
      print("Method invoked successfully");
    } on PlatformException catch (e) {
      print("Error invoking method: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List bytes = base64Decode(base64Image);
    print("cap img is--- $_capturedImage");
    return Scaffold(
        appBar: AppBar(
          title: const Text('FaceCamera example app'),
        ),
        body: Builder(builder: (context) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SmartFaceCamera(
                    showControls: false,
                    autoCapture: true,
                    defaultCameraLens: CameraLens.front,
                    onCapture: (File? image) async {
                      if (image != null) {
                        // Replace the captured image with the new one
                        _capturedImage = image;
                        String base64File = await fileToBase64(_capturedImage!);
                        final RegExp regex =
                            RegExp(r'^data:image\/\w+;base64,');
                        base64Image = base64File.replaceFirst(regex, '');

                        String filePath =
                            'example_image.jpg'; // File path where you want to save the image

                        base64toFile = await createFileFromBase64String(
                            base64Image, filePath);

                        print("captured image path is ${image.path}");
                        //print("base64File $base64File");

                        /*  if (base64toFile != null) {
                          File? localFile = await rotateLocalImageFile(
                              Appconstants.sourceFile.path);
                          File? capturedFile =
                              await rotateLocalImageFile(base64toFile.path);
                          await faceRecogPunchIn(
                              localFile?.path, capturedFile?.path);
                        } */

                        await cropImage(base64toFile, context);

                        setState(() {});
                      }
                      setState(() {});
                    },
                    /* onCapture: (File? image) async {
                      //setState(() => _capturedImage = image);
                      print("captured image path is 111111111111 ${image?.parent}");
                      await cropImage(image, context);
                      print("source image id ${Appconstants.sourceFile}");
                      setState(() {});
                    }, */
                    onFaceDetected: (Face? face) {
                      print("Face detected ${face?.boundingBox}");
                      setState(() {
                        detectedFace = face;
                      });
                      //Do something
                    },
                    messageBuilder: (context, face) {
                      if (face == null) {
                        return _message('Place your face in the camera');
                      }
                      if (!face.wellPositioned) {
                        return _message('Center your face in the square');
                      }
                      return const SizedBox.shrink();
                    }),
                /* Container(
                    child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.file(base64toFile),
                      Image.file(Appconstants.sourceFile),
                      Image.memory(
                        bytes,
                        fit: BoxFit.cover, // Adjust the BoxFit as needed
                      )
                    ],
                  ),
                )) */
              ],
            ),
          );
          /* Container(
                  child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.file(_capturedImage!),
                      Image.file(Appconstants.sourceFile),
                      Image.memory(
                        bytes,
                        fit: BoxFit.cover, // Adjust the BoxFit as needed
                      )
                    ],
                  ),
                )); */
        }));
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );
  cropImage(File? _capturedImage, context) async {
    final faceMatchingProvider =
        Provider.of<FaceMatchingViewModel>(context, listen: false);
    img.Image capturedImage =
        img.decodeImage(File(_capturedImage?.path ?? "").readAsBytesSync())!;
    if (detectedFace != null && detectedFace!.boundingBox != null) {
      /* img.Image faceCrop = img.copyCrop(
        capturedImage,
        x: detectedFace!.boundingBox.left.toInt() - 100,
        y: detectedFace!.boundingBox.top.toInt() - 100,
        width: detectedFace!.boundingBox.width.toInt() + 150,
        height: detectedFace!.boundingBox.height.toInt() + 150,
      );
      final jpg = img.encodeJpg(faceCrop); */
      final jpg = img.encodeJpg(capturedImage);
      cropSaveFile = File(_capturedImage?.path ?? "");
      await cropSaveFile?.writeAsBytes(jpg);
      var laplacianScore = laplacian(cropSaveFile!);
      if (laplacianScore < LAPLACIAN_THRESHOLD) {
        print("Please place your face in the camera");
      } else {
        FaceAntiSpoofing faceAntiSpoofing = FaceAntiSpoofing();
        antiSpoofingScore = await faceAntiSpoofing.loadModel(cropSaveFile);
        print("antiSpoofingScoreeeeeeeeeeeee ${antiSpoofingScore}");
        //setState(() {});
        if (antiSpoofingScore! < THRESHOLD) {
          faceRecog = cropSaveFile;

          print("face recognised!!!!!!!!!!!!!!");
          //

          await faceMatchingProvider.faceMatchingApiCall(
              context, cropSaveFile!);
        } else {
          print("spoofing detected!!!!!!!!!!!!!!!!!");
          return showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text("Spoofing Detected"),
                    content: Text("Please place your face in the camera"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            faceRecog = null;
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.dashboard);
                          },
                          child: Text("OK"))
                    ],
                  ));
        }
      }
    }
  }

  int laplacian(File imageFile) {
    img.Image capturedImage =
        img.decodeImage(File(imageFile.path).readAsBytesSync())!;

    // Size of the Laplacian filter
    int score = 0;
    const List<List<int>> laplace = [
      [0, 1, 0],
      [1, -4, 1],
      [0, 1, 0],
    ];
    int size = laplace.length;
    int height = capturedImage.height;
    int width = capturedImage.width;

    for (int x = 0; x < height - size + 1; x++) {
      for (int y = 0; y < width - size + 1; y++) {
        double result = 0;

        // Convolution operation in the size x size region
        for (int i = 0; i < size; i++) {
          for (int j = 0; j < size; j++) {
            int pixelX = x + i;
            int pixelY = y + j;

            // Check if the pixel coordinates are within bounds
            if (pixelX < 0 ||
                pixelX >= height ||
                pixelY < 0 ||
                pixelY >= width) {
              continue;
            }

            img.Pixel pixelValue = getPixel(capturedImage, pixelX, pixelY);

            // Add print statements for debugging
            //print('Pixel value at $pixelX, $pixelY: $pixelValue');

            result += pixelValue.r * laplace[i][j];
            result += pixelValue.g * laplace[i][j];
            result += pixelValue.b * laplace[i][j];
          }
        }

        // Cast result to int before using it in the comparison
        if (result.toInt() > LAPLACE_THRESHOLD) {
          score++;
        }
      }
    }
    print("scoreeeeeeeeeeeeeeeeeeeeeeeeee ${score}");
    return score;
  }

  img.Pixel getPixel(img.Image image, int x, int y) {
    return image.getPixel(x, y);
  }

  Future<String> fileToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<File> createFileFromBase64String(
      String base64String, String filePath) async {
    Uint8List bytes = base64Decode(base64String);

    // Get the directory for the app's documents directory
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$filePath');

    // Write the file
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File?> rotateLocalImageFile(String filePath) async {
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
  }
}
