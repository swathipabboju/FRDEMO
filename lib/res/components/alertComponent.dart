
import 'package:flutter/material.dart';



class Alerts {
  static showAlertDialog(
    BuildContext context,
    var message, {
    required var Title,
    required Function() onpressed,
    Color? buttoncolor,
    Color? buttontextcolor,
    Function()? onpressingYes,
    String? imagePath,
    String? versiontext,
    required String buttontext,
    String? buttontext2,
    double? textSize,
    Color? titleColor,
    double? titleSize,
  }) {
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * 0.75,
                padding:
                    EdgeInsets.only(left: 10, top: 50, right: 10, bottom: 10),
                margin: EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 10),
                          blurRadius: 10),
                    ]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (versiontext != null)
                      Text(
                        "",
                        textAlign: TextAlign.center,
                        // style: TextStyleConstants.intenetcheckalertversion,
                      ),
                    if (versiontext != null)
                      SizedBox(
                        height: 5,
                      ),
                    Text(
                      Title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: titleSize != null ? titleSize : 17,
                          fontWeight: FontWeight.w700,
                         /*  color: titleColor != null
                              ? titleColor
                              : ColorConstants.alert_title_color */),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      message ,
                      style: TextStyle(
                          fontSize: textSize != null ? textSize : 15,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                            child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.05,
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              color: buttoncolor ??
                                  Color.fromARGB(255, 210, 46, 35)),
                          child: TextButton(
                              onPressed: onpressed,
                              child: Text(
                                buttontext,
                                style: TextStyle(color: Colors.white),
                              )),
                        )),
                        if (onpressingYes != null)
                          Expanded(
                              child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.05,
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: buttoncolor ??
                                    Color.fromARGB(255, 56, 69, 75)),
                            child: TextButton(
                                onPressed: onpressingYes,
                                child: Text(
                                  "$buttontext2",
                                  style: TextStyle(color: Colors.white),
                                )),
                          )),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: Image.asset(imagePath ?? "assets/assets_error.png"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
