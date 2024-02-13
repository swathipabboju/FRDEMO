import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppInputTextfield extends StatelessWidget {
  const AppInputTextfield(
      {super.key,
      this.maxlength,
      this.obsecuretext,
      this.inputFormatters,
      this.onEditingComplete,
      required this.texteditingcontroller,
      required this.labeltext,
      this.prefixIcon,
      this.suffixIcon,
      required this.input_type, this.onChanged});
  final int? maxlength;
  final bool? obsecuretext;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onEditingComplete;
  final TextEditingController texteditingcontroller;
  final String labeltext;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType input_type;
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      maxLength: maxlength,
      inputFormatters: inputFormatters,
      obscureText: obsecuretext ?? false,
      textInputAction: TextInputAction.done,
      onEditingComplete: onEditingComplete,
      style: const TextStyle(color: Colors.black),
      controller: texteditingcontroller,
      cursorColor: Color.fromARGB(255, 146, 71, 62),
      decoration: InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 146, 71, 62),),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        //hintText: hintText,
        counterText: '',
        //hintStyle: TextStyle(color: Colors.white),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
        labelText: labeltext,
      ),
      keyboardType: input_type,
    );
  }
}
