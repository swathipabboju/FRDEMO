package com.example.cgg_attendance;

import android.content.Intent
import android.graphics.BitmapFactory

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File


class MainActivity : FlutterActivity() {
    private val CHANNEL = "example.com/channel" // Replace with your channel name
    val NEXT_ACTIVITY_REQUEST_CODEIN = 1
    val NEXT_ACTIVITY_REQUEST_CODEOUT = 2
    var INOUT = ""


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(FlutterEngine(this))


        MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            "example.com/channel"
        ).setMethodCallHandler { call, result ->
             if (call.method == "callRegistration") {
                call.arguments
                navigateToCamera { resultData ->
                    result.success(resultData)
                }
             }
            if (call.method == "faceRecogPunchIn") {


                navigateToVideoControllerIN{ resultData ->
                    result.success(resultData)
                }
            } else if (call.method == "faceRecogPunchOut") {

                navigateToVideoControllerOUT { resultData ->
                    result.success(resultData)
                }
            } else {
                result.notImplemented()
            }




        }

    }




    private fun navigateToVideoControllerIN(completion: (result: Any) -> Unit) {


        val intent = Intent(this@MainActivity, FaceRecognition::class.java)
        intent.putExtra("INOUT", "IN")

        startActivityForResult(intent, NEXT_ACTIVITY_REQUEST_CODEIN)


    }

    private fun navigateToVideoControllerOUT(completion: (result: Any) -> Unit) {


        val intent = Intent(this@MainActivity, FaceRecognition::class.java)
        intent.putExtra("INOUT", "OUT")

        startActivityForResult(intent, NEXT_ACTIVITY_REQUEST_CODEIN)


    }
     private fun navigateToCamera(completion: (result: Any) -> Unit) {

        val intent = Intent(this@MainActivity, CameraActivity::class.java)
        intent.putExtra("camera", "IN")


        startActivityForResult(intent, NEXT_ACTIVITY_REQUEST_CODEIN)

    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {

        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == NEXT_ACTIVITY_REQUEST_CODEIN) {

            if (resultCode == RESULT_OK) {

                val resultData = data?.getStringExtra("resultData")

                resultData?.let {

                    try {

                        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)

                            .invokeMethod("onResultFromAndroidIN", it)
                        Log.d("android printIN", "" + it)


                    } catch (e: Exception) {

                        e.printStackTrace()

                    }

                }

                // Close the VideoActivity after getting the result


            }
                    // Close the VideoActivity after getting the result






        }


    }
}
















