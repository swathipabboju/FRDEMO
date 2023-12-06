import 'dart:io';
import 'package:cgg_attendance/data/baseApiClient.dart';
import 'package:cgg_attendance/model/faceMatchingResponse.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class FaceMatchingRepository {
  final _baseClient = BaseApiClient();
  Future<FaceMatchingResponse> FaceMatchingInfoNew(
      File sourceImageFile, File targetImageFile, BuildContext context) async {
    print("repositoryyy file ${sourceImageFile.path}, ${targetImageFile.path}");
    FormData? formData;

    try {
      formData = FormData.fromMap(
        {
          'source_image': await MultipartFile.fromFile(
            sourceImageFile.path,
            filename: sourceImageFile.path.split('/').last,
          ),
          'target_image': await MultipartFile.fromFile(
            targetImageFile.path,
            filename: targetImageFile.path.split('/').last,
          ),
        },
      );
      // checkFileExistence(targetImageFile);
    } catch (e) {
      print("Error creating FormData: $e");
    }
    if (formData != null) {
      final faceMatchResponse =
          await _baseClient.postCall(context, "Face/Facematch", formData);

      return FaceMatchingResponse.fromJson(faceMatchResponse);
    } else {
      print("formdata is null");
    }
    return FaceMatchingResponse();
  }
}
