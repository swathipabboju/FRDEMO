import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DisplayImages extends StatefulWidget {
  DisplayImages({
    super.key,
    required this.localImage,
    required this.capturedImage,
  });
  final File localImage;
  final File capturedImage;

  @override
  State<DisplayImages> createState() => _DisplayImagesState();
}

class _DisplayImagesState extends State<DisplayImages> {
  Uint8List? bytes;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      bytesconvert();
      setState(() {});
    });
    setState(() {});
  }

  bytesconvert() async {
    String base64Image = await base(widget.capturedImage);
    bytes = base64Decode(base64Image);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              },
              child: Icon(Icons.home))
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
            ),
            Text("Local image is......."),
            Image.file(
              widget.localImage,
              height: 200,
              width: 200,
            ),
            SizedBox(
              height: 100,
            ),
            Text("Captured image is......."),
            Image.memory(
              bytes ?? Uint8List(0),
              height: 200,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Future<String> base(file) async {
    String base64File = await fileToBase64(file);
    // Remove the data header before decoding
    final RegExp regex = RegExp(r'^data:image\/\w+;base64,');
    String base64Image = base64File.replaceFirst(regex, '');
    //print("base64Image $base64Image");
    return base64Image;
  }

  Future<String> fileToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }
}
