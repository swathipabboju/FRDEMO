import 'package:flutter/material.dart';

class AppInputText extends StatelessWidget {
  const AppInputText({super.key, required this.text, required this.fontsize, this.fontweight, this.color, this.textAlign});
  final String text;
  final double fontsize;
  final FontWeight? fontweight;
  final Color? color;
  final TextAlign? textAlign; 
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontsize,
        fontWeight: fontweight ?? FontWeight.normal,
        color: color ?? Color.fromARGB(255, 63, 16, 10),
      ),
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
