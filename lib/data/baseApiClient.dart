import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class BaseApiClient {
  final Dio _client = Dio(
    BaseOptions(
      baseUrl: "https://facialrecognition.cgg.gov.in/",
    ),
  )..interceptors.addAll([
      CustomInterceptor(),
      LoggingInterceptor(),
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.badResponse) {
            // Show an alert to the user that the server is not responding
            print('Server is not responding --${error.type}');
          }
          // Pass the error to the next interceptor
          handler.next(error);
        },
      ),
    ]);
  Future<dynamic> getCall(String url, BuildContext context) async {
    try {
      final response = await _client.get(url);
      if (response.data == null || response.data.isEmpty) {
        // Handle empty or null response
        throw DioException(
          response: response,
          error: 'Empty or null response',
          requestOptions: response.requestOptions,
        );
      }
      return response.data;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout) {
        // Handle connection timeout error
        /*  String errorMessage = "Connection timeout occurred.";
        ErrorHandlingUtils().showErrorDialog(context, errorMessage); */
      } else if (error.type == DioExceptionType.receiveTimeout) {
        //Handle receive timeout error
        /*  String errorMessage = "Receive timeout occurred.";
        ErrorHandlingUtils().showErrorDialog(context, errorMessage); */
      } else {
        // Handle other Dio errors
        // String errorMessage = ErrorHandlingUtils.handleError(error, context);
        //  ErrorHandlingUtils().showErrorDialog(context, errorMessage);
      }
    } catch (error) {
      // Handle other errors
      //  String errorMessage = ErrorHandlingUtils.handleError(error, context);
      // ErrorHandlingUtils().showErrorDialog(context, errorMessage);
      return null;
    }
  }

  Future<dynamic> postCall(
      BuildContext context, String url, FormData payload) async {
    try {
      final response = await _client.post(
        url,
        data: payload,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      print("responseeeeeeeeeeeee ${response.data}");
      return response.data;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout) {
        // Handle connection timeout error
        // String errorMessage = "Connection timeout occurred.";
        //  ErrorHandlingUtils().showErrorDialog(context, errorMessage);
      } else if (error.type == DioExceptionType.receiveTimeout) {
        // Handle receive timeout error
        // String errorMessage = "Receive timeout occurred.";
        //  ErrorHandlingUtils().showErrorDialog(context, errorMessage);
      } else {
        // Handle other Dio errors
        /*  String errorMessage = ErrorHandlingUtils.handleError(error, context);
         ErrorHandlingUtils().showErrorDialog(context, errorMessage); */
      }
      // return error.response?.data;
    } catch (error) {
      print("error in api clinet ${error}");
      // Handle other errors
      /*   String errorMessage = ErrorHandlingUtils.handleError(error, context);
       ErrorHandlingUtils().showErrorDialog(context, errorMessage); */
      // return error;
    }
  }
  
}

// CustomInterceptor adds a custom header to every request
class CustomInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // add custom header to request
    options.headers['Custom-Header'] = 'custom value';
    super.onRequest(options, handler);
  }
}

// LoggingInterceptor logs the request and response data
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('Sending request: ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('Received response: ${response.data}');
    super.onResponse(response, handler);
  }
}
