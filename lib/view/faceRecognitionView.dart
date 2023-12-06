import 'dart:io';

import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:cgg_attendance/view/FR%20flutter/antiSpoofing.dart';
import 'package:cgg_attendance/view/FR%20flutter/appconstants.dart';
import 'package:cgg_attendance/viewModel/faceMatchingViewModel.dart';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class FaceRecognitionView extends StatefulWidget {
  const FaceRecognitionView({super.key});

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('FaceCamera example app'),
        ),
        body: Builder(builder: (context) {
          return _capturedImage == null
              ? SmartFaceCamera(
                  showControls: false,
                  autoCapture: true,
                  defaultCameraLens: CameraLens.front,
                  onCapture: (File? image) async {
                    if (image != null) {
                      // Replace the captured image with the new one
                      _capturedImage = image;

                      print("captured image path is ${image.path}");
                      //await cropImage(_capturedImage, context);

                      setState(() {});
                    }
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
                  })
              : Container(
                  child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.file(_capturedImage ?? File("")),
                      Image.file(Appconstants.sourceFile)
                    ],
                  ),
                ));
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
}
