import 'package:cgg_attendance/const/image_constants.dart';
import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';




class LoaderComponent extends StatefulWidget {
  const LoaderComponent({super.key});

  @override
  State<LoaderComponent> createState() => _LoaderComponentState();
}

class _LoaderComponentState extends State<LoaderComponent> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            color: Colors.black.withOpacity(0.3),
            child: Lottie.asset(
            ImageConstants.loader,
            height: 50,
            width: 50,
          ),
          ),
        ],
      ),
    );
  }
}
