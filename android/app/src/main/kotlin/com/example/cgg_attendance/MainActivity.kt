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
            val profile = File(getExternalFilesDir(null), "profile.jpg")
            if (profile.exists()) {
                val profilebitmap = BitmapFactory.decodeFile(profile.toString())
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

//            when (call.method) {
//
//                "faceRecogPunchIn" -> {
//
//                    navigateToVideoController { resultData ->
//
//                        result.success(resultData)
//
//                    }
//
//                }
//                "faceRecogPunchIn" -> {
//
//                    navigateToVideoController { resultData ->
//
//                        result.success(resultData)
//
//                    }
//
//                }
//
//                else -> {
//
//                    result.notImplemented()
//
//                }
//
//            }


        }

    }




    private fun navigateToVideoControllerIN(completion: (result: Any) -> Unit) {


        val intent = Intent(this@MainActivity, LockActivity::class.java)
        intent.putExtra("INOUT", "IN")

        startActivityForResult(intent, NEXT_ACTIVITY_REQUEST_CODEIN)


    }

    private fun navigateToVideoControllerOUT(completion: (result: Any) -> Unit) {


        val intent = Intent(this@MainActivity, LockActivity::class.java)
        intent.putExtra("INOUT", "OUT")

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
















