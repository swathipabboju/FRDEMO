/* import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:face_liveness/res/components/alertComponent.dart';

import 'package:flutter/material.dart';


class ErrorHandlingUtils {
  static String handleError(dynamic e, BuildContext context) {
    String msg = "";
    if (e is DioException) {
      if (e.response?.statusCode == 401) {
        final responseBody = e.response?.data;
        if (responseBody != null) {
          final jsonData = json.encode(responseBody);
          msg = getErrorMessage(jsonData);
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        msg = "Connection timed out";
      } else if (e.type == DioExceptionType.receiveTimeout) {
        msg = "Receive timeout occurred.";
      } else {
        msg = "Server not responding: ${e.message}";
      }
    } else if (e is SocketException) {
      msg = "Something went wrong: ${e.message}";
    } else {
      msg = "Something went wrong: ${e.toString()}";
    }
    return msg;
  }

  static String getErrorMessage(String jsonData) {
    try {
      final parsedJson = json.decode(jsonData);
      return parsedJson['error']['message'];
    } catch (e) {
      return "Something went wrong, Please try again later";
    }
  }

  showErrorDialog(BuildContext context, String errorMessage) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Alerts.showAlertDialog(context,"${errorMessage}",
            //titleColor: ColorConstants.alert_title_color,
            Title: "", onpressed: () {
          Navigator.pop(context);
        }, buttontext: "ok", versiontext: "");
      },
    );
  }
}
 */