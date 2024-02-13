import 'package:cgg_attendance/const/colors.dart';
import 'package:flutter/material.dart';


class AppInputButtonComponent extends StatelessWidget {
  AppInputButtonComponent({
    super.key,
    required this.onPressed,
    required this.buttonText, this.width, this.height,
  });
  final void Function() onPressed;
  final String buttonText;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? MediaQuery.of(context).size.width * 0.4,
      height: height ?? MediaQuery.of(context).size.height * 0.05,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          gradient: LinearGradient(colors: [
            AppColors.primaryDark,
          AppColors.primaryDark
          ])),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.transparent,
        ),
        onPressed: onPressed,
        child: Text(

          buttonText,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16,color: AppColors.white),
        ),
      ),
    );
  }
}
