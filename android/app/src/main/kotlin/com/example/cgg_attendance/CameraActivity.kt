package com.example.cgg_attendance;

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.Dialog
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.res.Resources
import android.graphics.*
import android.graphics.drawable.ColorDrawable
import android.media.Image
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.util.Base64
import android.util.Log
import android.view.View
import android.view.ViewOutlineProvider
import android.view.Window
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import com.example.cgg_attendance.databinding.ActivityLockBinding
import com.example.cgg_attendance.facerecog.Api.LoginErrorResponse
import com.example.cgg_attendance.facerecog.CustomProgressDialog
import com.example.cgg_attendance.facerecog.modules.FaceAntiSpoofing
import com.example.cgg_attendance.facerecog.modules.MobileFaceNet
import com.example.cgg_attendance.facerecog.modules.Utils


import com.google.android.gms.tasks.Task
import com.google.common.util.concurrent.ListenableFuture
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.*
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import org.tensorflow.lite.support.common.ops.NormalizeOp
import org.tensorflow.lite.support.image.ImageProcessor
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.support.image.ops.ResizeOp
import org.tensorflow.lite.support.image.ops.ResizeWithCropOrPadOp
import org.tensorflow.lite.support.label.TensorLabel
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer
import java.io.*
import java.nio.ReadOnlyBufferException
import java.nio.file.Files
import java.util.*
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import kotlin.experimental.inv
import kotlin.math.max
import kotlin.math.min


class CameraActivity : AppCompatActivity(), TextToSpeech.OnInitListener {
    lateinit var binding: ActivityLockBinding
    private var detector: FaceDetector? = null
    private lateinit var cameraProviderFuture: ListenableFuture<ProcessCameraProvider>
    private var fas: FaceAntiSpoofing? = null
    private lateinit var cameraSelector: CameraSelector
    private lateinit var cameraProvider: ProcessCameraProvider
    lateinit var result: Task<List<Face>>
    lateinit var sharedPreferences: SharedPreferences
    lateinit var editor: SharedPreferences.Editor
    lateinit var loginResponse: LoginErrorResponse
    lateinit var customProgressDialog: CustomProgressDialog
    private var loop = 0
    private lateinit var mobileFaceNet: MobileFaceNet
    private lateinit var textToSpeech: TextToSpeech
    private var encodeString = ""
    private var InOUTVALUE= ""
    private var base64String= ""

    @RequiresApi(Build.VERSION_CODES.M)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView(this, R.layout.activity_lock)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        textToSpeech = TextToSpeech(this, this)

        val intent = intent // assuming you are inside an Activity

        InOUTVALUE = intent.getStringExtra("camera").toString()

        if (InOUTVALUE != null) {
            Log.d("cameraInOut", "" + InOUTVALUE)
            // ...
        }else {
            Log.d("cameraInOut", "" + InOUTVALUE)
        }
        //sharedPreferences = VirtuoApplication.get(Objects.requireNonNull(this)).getPreferences()
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                arrayOf(Manifest.permission.CAMERA), 100
            )
        }
        try {
            fas = FaceAntiSpoofing(assets)
            mobileFaceNet = MobileFaceNet(assets)
        } catch (e: IOException) {
            e.fillInStackTrace()
        }

        val highAccuracyOpts = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE).setMinFaceSize(0.15f)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            .setContourMode(FaceDetectorOptions.CONTOUR_MODE_ALL).build()


        detector = FaceDetection.getClient(highAccuracyOpts)
        cameraBind()

        binding.header.headerTitle.text = getString(R.string.face_recognition)


        binding.header.backBtn.setOnClickListener { onBackPressed() }
//        binding.header.ivHome.setOnClickListener {
//            val intent = Intent(this@CameraActivity, DashboardActivity::class.java)
//            startActivity(intent)
//        }
//        try {
//            val sharedPreferences =
//                VirtuoApplication.get(Objects.requireNonNull(this@CameraActivity)).getPreferences()
//            editor = sharedPreferences.edit()
//            val gson = Gson()
//            val data = sharedPreferences.getString(AppConstants.LOGIN_RESPONSE, "")
//            loginResponse = gson.fromJson(data, LoginResponse::class.java)
//        } catch (e: Exception) {
//            e.fillInStackTrace()
//        }


        customProgressDialog = CustomProgressDialog(this)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String?>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "camera permission granted", Toast.LENGTH_LONG).show()
            } else {
                Toast.makeText(this, "camera permission denied", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun cameraBind() {
        cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        binding.cameraPreview.outlineProvider = object : ViewOutlineProvider() {
            override fun getOutline(view: View, outline: Outline) {
                val diameter = min(view.width.toDouble(), view.height.toDouble()).toInt()
                outline.setOval(0, 0, diameter, diameter)
            }
        }
        binding.cameraPreview.setClipToOutline(true)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindPreview(cameraProvider)
            } catch (e: ExecutionException) {
                e.fillInStackTrace()
            } catch (e: InterruptedException) {
                e.fillInStackTrace()
            }
        }, ContextCompat.getMainExecutor(this))
    }


    private fun bindPreview(cameraProvider: ProcessCameraProvider) {
        val preview = Preview.Builder().build()
        cameraSelector =
            CameraSelector.Builder().requireLensFacing(CameraSelector.LENS_FACING_FRONT).build()
        preview.setSurfaceProvider(binding.cameraPreview.getSurfaceProvider())
        val imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        val executor: Executor = Executors.newSingleThreadExecutor()
        imageAnalysis.setAnalyzer(executor) { imageProxy: ImageProxy ->
            try {
                Thread.sleep(0)
            } catch (e: InterruptedException) {
                e.fillInStackTrace()
            }
            var image: InputImage? = null

            @SuppressLint(
                "UnsafeExperimentalUsageError", "UnsafeOptInUsageError"
            ) val mediaImage = imageProxy.image
            if (mediaImage != null) {
                image = InputImage.fromMediaImage(
                    mediaImage, imageProxy.imageInfo.rotationDegrees
                )
            }
            assert(image != null)


            result = detector!!.process(image!!).addOnSuccessListener { faces: List<Face> ->
                faces.forEach { face ->

                }
                if (faces.isNotEmpty()) {




                    val face = faces[0]
                    if(face.rightEyeOpenProbability!=null){
                        Log.e(
                            "fhgjjgjgg",
                            ":" + face.rightEyeOpenProbability
                        )
                    }

                   // var adsfdgopen=extractLeftEyeRegion(face)


//                    Log.e(
//                        "faceRemarkfacenew111::$adsfdgopen", "nm,."
//                    )

                    if (faces.size == 1) {

                       // if (face.rightEyeOpenProbability!=null && face.leftEyeOpenProbability!=null) {
                            if(face.rightEyeOpenProbability!!<0.8f &&face.leftEyeOpenProbability!!<0.8f ){
                                Log.e(
                                    "please open eye",
                                    ":" + face.headEulerAngleX
                                )
                                if (textToSpeech.isSpeaking) {
                                    Log.e("speeking", "true")
                                } else {
                                    textToSpeech.speak(
                                        "please open eye",
                                        TextToSpeech.QUEUE_FLUSH,
                                        null,
                                        null
                                    )
                                }

                            }



                       // }

                       else if (face.headEulerAngleX > 7.0f) {

//                            Log.e(
//                                "please check the face is upwards",
//                                ":" + face.headEulerAngleX
//                            )
                            if (textToSpeech.isSpeaking) {
                                Log.e("speeking", "true")
                            } else {
                                textToSpeech.speak(
                                    "please check the face is upwards",
                                    TextToSpeech.QUEUE_FLUSH,
                                    null,
                                    null
                                )
                            }

                        }

                        else if (face.headEulerAngleX <-7.0f) {
//                            Log.e(
//                                "please check the face is downards",
//                                ":" + face.headEulerAngleX
//                            )
                            if (textToSpeech.isSpeaking) {
                                Log.e("speeking", "true")
                            } else {
                                textToSpeech.speak(
                                    "please check the face is downards",
                                    TextToSpeech.QUEUE_FLUSH,
                                    null,
                                    null
                                )
                            }
                        }
                        else if (face.headEulerAngleY > 11.8f) {
//                            Log.e(
//                                "please check the face is rotated towards  left side",
//                                ":" + face.headEulerAngleY
//                            )
                            if (textToSpeech.isSpeaking) {
                                Log.e("speeking", "true")
                            } else {
                                textToSpeech.speak(
                                    "please check the face is rotated towards  left side",
                                    TextToSpeech.QUEUE_FLUSH,
                                    null,
                                    null
                                )
                            }


                        }
                        else if (face.headEulerAngleY <-11.8f) {
//                            Log.e(
//                                "please check the face is rotated towards  right side",
//                                ":" + face.headEulerAngleY
//                            )
                            if (textToSpeech.isSpeaking) {
                                Log.e("speeking", "true")
                            } else {
                                textToSpeech.speak(
                                    "please check the face is rotated towards  right side",
                                    TextToSpeech.QUEUE_FLUSH,
                                    null,
                                    null
                                )
                            }

                        }else if (face.headEulerAngleZ >2.5f||face.headEulerAngleZ <-2.5f) {
//                            Log.e(
//                                "'please check the face  having side view",
//                                ":" + face.headEulerAngleY
//                            )
                            if (textToSpeech.isSpeaking) {
                                Log.e("speeking", "true")
                            } else {
                                textToSpeech.speak(
                                    "'please check the face  having side view",
                                    TextToSpeech.QUEUE_FLUSH,
                                    null,
                                    null
                                )
                            }

                        }


                        else {





                        //  }
//                    face.headEulerAngleZ < 7.78f && face.headEulerAngleZ > -7.78f
//                            && face.headEulerAngleY < 11.8f && face.headEulerAngleY > -11.8f
//                            && face.headEulerAngleX < 19.8f && face.headEulerAngleX > -19.8f

                        //  val face = faces[0]
//                    if (face.headEulerAngleZ < 7.78f && face.headEulerAngleZ > -7.78f
//                        && face.headEulerAngleY < 11.8f && face.headEulerAngleY > -11.8f
//                        && face.headEulerAngleX < 19.8f && face.headEulerAngleX > -19.8f
//                    ) {
                        Log.e(
                            "print facesxyz",
                            ":" + face.headEulerAngleZ + ":" + face.headEulerAngleY + ":" + face.headEulerAngleX
                        )
                        val facebitmap: Bitmap = toBitmap(mediaImage)
                        val rot = imageProxy.imageInfo.rotationDegrees
                        val facerotate = rotateBitmap(facebitmap, rot)
                        val boundingBox = RectF(face.boundingBox)
                        val facecroped: Bitmap = getCropBitmapByCPU1(
                            facerotate, boundingBox
                        )
                        // val scaled: Bitmap = getResizedBitmap(facecroped, 256, 256)


                        val laplacespoof = fas!!.laplacian(facecroped)

                        if (laplacespoof < FaceAntiSpoofing.LAPLACIAN_THRESHOLD) {
                            if (laplacespoof == 0) {
                                Log.e("laplace..0", "0")
                                binding.tvstatus?.text = "spoofing detected"
                                if (textToSpeech.isSpeaking) {
                                    Log.e("speeking", "true")
                                } else {
                                    textToSpeech.speak(
                                        "spoofing detected",
                                        TextToSpeech.QUEUE_FLUSH,
                                        null,
                                        null
                                    )
                                }
                            } else if (laplacespoof < 150) {
                                binding.tvstatus.text = "Please bring mobile closer to the face"
                                if (textToSpeech.isSpeaking) {
                                    Log.e("speaking", "true")
                                } else {
                                    textToSpeech.speak(
                                        "Please bring mobile closer to the face",
                                        TextToSpeech.QUEUE_FLUSH,
                                        null,
                                        null
                                    )
                                }


                            } else if (laplacespoof < 200) {
                                Log.e("laplace..spoofing", laplacespoof.toString() + "")
                                binding.tvstatus.text =
                                    "Your camera is dusty Please clean your camera"
                                if (textToSpeech.isSpeaking) {
                                    Log.e("speaking", "true")
                                } else {
                                    textToSpeech.speak(
                                        "Your camera is dusty Please clean your camera",
                                        TextToSpeech.QUEUE_FLUSH,
                                        null,
                                        null
                                    )
                                }
//

                            } else if (laplacespoof < 250) {
                                Log.e("laplace..spoofing", laplacespoof.toString() + "")
                                binding.tvstatus.text =
                                    "You are in the light environment"
                                if (textToSpeech.isSpeaking) {
                                    Log.e("speaking", "true")
                                } else {
                                    textToSpeech.speak(
                                        "You are in light environment",
                                        TextToSpeech.QUEUE_FLUSH,
                                        null,
                                        null
                                    )
                                }
//

                            }
                        } else {
                            val label = predict(facecroped)
                            val with = label["with_mask"] ?: 0F
                            val without = label["without_mask"] ?: 0F
                            if (with > without) {
                                if (textToSpeech.isSpeaking) {
                                    Log.e("speeking", "true")
                                } else {
                                    textToSpeech.speak(
                                        "Please remove mask",
                                        TextToSpeech.QUEUE_FLUSH,
                                        null,
                                        null
                                    )
                                }
                            } else {
                                textToSpeech.stop()
                                val score1 = fas!!.antiSpoofing(facecroped)
                                Log.e("threshold", score1.toString() + "")
                                if (score1 < FaceAntiSpoofing.THRESHOLD) {
                                    binding.tvstatus.text =
                                        resources.getString(R.string.recognising)
                                    runOnUiThread {
                                        Log.e("threshold", score1.toString() + "")
                                        binding.tvstatus.setText(R.string.recognising)
                                        if (loop == 0) {
                                            loop++
                                            binding.progressBar.progress = 50
                                        } else if (loop == 1) {
                                            if (textToSpeech.isSpeaking) {
                                                Log.e("speeking", "true")
                                            } else {
                                                textToSpeech.speak(
                                                    "Captured",
                                                    TextToSpeech.QUEUE_FLUSH,
                                                    null,
                                                    null
                                                )
                                            }
                                            binding.progressBar.progress = 100
                                            cameraProvider.unbindAll()


                                            val filename =
                                                File(
                                                    getExternalFilesDir(null),
                                                    "profile.jpg"
                                                )



                                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                                try {
                                                    Files.newOutputStream(filename.toPath())
                                                        .use { outputStream ->
                                                            facecroped.compress(
                                                                Bitmap.CompressFormat.JPEG,
                                                                100,
                                                                outputStream
                                                            )
                                                            outputStream.flush()
                                                            outputStream.close()


                                                        }
                                                } catch (e: IOException) {
                                                    e.fillInStackTrace()
                                                }
                                            } else {
                                                try {
                                                    val outputStream =
                                                        BufferedOutputStream(
                                                            FileOutputStream(filename)
                                                        )
                                                    facecroped.compress(
                                                        Bitmap.CompressFormat.JPEG,
                                                        100,
                                                        outputStream
                                                    )
                                                    outputStream.flush()
                                                    outputStream.close()
                                                } catch (e: IOException) {
                                                    e.fillInStackTrace()
                                                }
                                            }

                                            customImageAlertcamera(
                                                "Profile",
                                                "Please check your profile image to update",
                                                facecroped, filename
                                            )
                                        }
                                    }

                                }
                            }
                        }
                    }
                }
                    else {
                        Log.e(
                            "print facesxyz",
                            ":" + face.headEulerAngleZ + ":" + face.headEulerAngleY + ":" + face.headEulerAngleX
                        )

                        binding.tvstatus.text =
                            resources.getString(R.string.please_place_face_within_the_circle)
                    }

                }

                else if(faces.size>1) {
                    binding.tvstatus.text = resources.getString(R.string.more_than)
                    if (textToSpeech.isSpeaking) {
                        //Log.e("More than one face detected", "true")
                    }
                    else {
                        textToSpeech.speak(
                            "More than one face detected",
                            TextToSpeech.QUEUE_FLUSH,
                            null,
                            null
                        )
                    }

                }
                else {
                    binding.tvstatus.text = resources.getString(R.string.no_face_detected)
                    if (textToSpeech.isSpeaking) {
                        Log.e("No face detected", "true")
                    } else {
                        textToSpeech.speak(
                            "No face detected",
                            TextToSpeech.QUEUE_FLUSH,
                            null,
                            null
                        )
                    }

                }
            }.addOnFailureListener { }.addOnCompleteListener { imageProxy.close() }
        }
        cameraProvider.bindToLifecycle(this, cameraSelector, imageAnalysis, preview)
    }

    fun fileToBase64(file: File): String{
        try {
            val fileInputStream = FileInputStream(file)
            val bytes = ByteArray(file.length().toInt())
            fileInputStream.read(bytes)
            fileInputStream.close()

            return Base64.encodeToString(bytes, Base64.DEFAULT)
        } catch (e: IOException) {
            e.printStackTrace()
            return ""
        }
    }
    private fun toBitmap(image: Image?): Bitmap {
        val nv21: ByteArray = yuv(image)
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, image!!.width, image.height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, yuvImage.width, yuvImage.height), 75, out)
        val imageBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    private fun rotateBitmap(bitmap: Bitmap, rotationDegrees: Int): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(rotationDegrees.toFloat())
        matrix.postScale(-1.0f, 1.0f)
        val rotatedBitmap =
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true)
        if (rotatedBitmap != bitmap) {
            bitmap.recycle()
        }
        return rotatedBitmap
    }


    private fun yuv(image: Image?): ByteArray {
        val width = image!!.width
        val height = image.height
        val ySize = width * height
        val uvSize = width * height / 4
        val nv21 = ByteArray(ySize + uvSize * 2)
        val yBuffer = image.planes[0].buffer // Y
        val uBuffer = image.planes[1].buffer // U
        val vBuffer = image.planes[2].buffer // V
        var rowStride = image.planes[0].rowStride
        assert(image.planes[0].pixelStride == 1)
        var pos = 0
        if (rowStride == width) { // likely
            yBuffer[nv21, 0, ySize]
            pos += ySize
        } else {
            var yBufferPos = -rowStride.toLong() // not an actual position
            while (pos < ySize) {
                yBufferPos += rowStride.toLong()
                yBuffer.position(yBufferPos.toInt())
                yBuffer[nv21, pos, width]
                pos += width
            }
        }
        rowStride = image.planes[2].rowStride
        val pixelStride = image.planes[2].pixelStride
        assert(rowStride == image.planes[1].rowStride)
        assert(pixelStride == image.planes[1].pixelStride)
        if (pixelStride == 2 && rowStride == width && uBuffer[0] == vBuffer[1]) {
            val savePixel = vBuffer[1]
            try {
                vBuffer.put(1, savePixel.inv())
                if (uBuffer[0] == savePixel.inv()) {
                    vBuffer.put(1, savePixel)
                    vBuffer.position(0)
                    uBuffer.position(0)
                    vBuffer[nv21, ySize, 1]
                    uBuffer[nv21, ySize + 1, uBuffer.remaining()]
                    return nv21
                }
            } catch (ex: ReadOnlyBufferException) {
                ex.fillInStackTrace()
            }
            vBuffer.put(1, savePixel)
        }
        for (row in 0 until height / 2) {
            for (col in 0 until width / 2) {
                val vuPos = col * pixelStride + row * rowStride
                nv21[pos++] = vBuffer[vuPos]
                nv21[pos++] = uBuffer[vuPos]
            }
        }
        return nv21
    }
    fun extractLeftEyeRegion(face: Face): Rect? {
        val landmarks = face.allLandmarks
        return if (landmarks.size >= 2) {
            val leftEyeLandmark = landmarks[FaceLandmark.LEFT_EYE]
            val leftEyeX: Float = leftEyeLandmark.position.x
            val leftEyeY: Float = leftEyeLandmark.position.y
            Rect(
                leftEyeX.toInt() - 50,
                leftEyeY.toInt() - 30,
                leftEyeX.toInt() + 50,
                leftEyeY.toInt() + 30
            ) // Adjust width and height as needed
        } else {
            // Handle case where left eye landmark is not available
            null
        }
    }

    fun extractRightEyeRegion(face: Face): Rect? {
        val landmarks = face.allLandmarks
        return if (landmarks.size >= 2) {
            val rightEyeLandmark = landmarks[FaceLandmark.RIGHT_EYE]
            val rightEyeX: Float = rightEyeLandmark.position.x
            val rightEyeY: Float = rightEyeLandmark.position.y
            Rect(
                rightEyeX.toInt() - 50,
                rightEyeY.toInt() - 30,
                rightEyeX.toInt() + 50,
                rightEyeY.toInt() + 30
            ) // Adjust width and height as needed
        } else {
            // Handle case where right eye landmark is not available
            null
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = textToSpeech.setLanguage(Locale.US)
            if (result == TextToSpeech.LANG_MISSING_DATA ||
                result == TextToSpeech.LANG_NOT_SUPPORTED
            ) {
                Log.e("TextToSpeech", "Language not supported")
            }
        } else {
            Log.e("TextToSpeech", "Initialization failed")
        }
    }

    private fun getCropBitmapByCPU1(source: Bitmap, originalFaceRect: RectF): Bitmap {
        // Increase the size of the bounding box (adjust the values as needed)
        val scaleFactor = 1.5f // Increase by 50%, you can adjust this value
        val newWidth = originalFaceRect.width() * scaleFactor
        val newHeight = originalFaceRect.height() * scaleFactor

        // Calculate the new coordinates for the top-left corner of the bounding box
        var newLeft = originalFaceRect.left - (newWidth - originalFaceRect.width()) / 2
        var newTop = originalFaceRect.top - (newHeight - originalFaceRect.height()) / 2

        // Ensure the new coordinates are within the bounds of the image
        newLeft = max(0.0, newLeft.toDouble()).toFloat()
        newTop = max(0.0, newTop.toDouble()).toFloat()
        val newRight =
            min(source.getWidth().toDouble(), (newLeft + newWidth).toDouble()).toFloat()
        val newBottom =
            min(source.getHeight().toDouble(), (newTop + newHeight).toDouble()).toFloat()

        // Create the new RectF with the adjusted coordinates
        val newFaceRect = RectF(newLeft, newTop, newRight, newBottom)

        // Create the result bitmap with the adjusted bounding box
        val resultBitmap = Bitmap.createBitmap(
            newFaceRect.width().toInt(),
            newFaceRect.height().toInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(resultBitmap)
        val paint = Paint(Paint.FILTER_BITMAP_FLAG)
        paint.setColor(Color.WHITE)
        canvas.drawRect(RectF(0f, 0f, newFaceRect.width(), newFaceRect.height()), paint)
        val matrix = Matrix()
        matrix.postTranslate(-newFaceRect.left, -newFaceRect.top)
        canvas.drawBitmap(source, matrix, paint)

        // Recycle the original bitmap if it's not null and not recycled
        if (!source.isRecycled) {
            source.recycle()
        }
        return resultBitmap
    }

    companion object {
        fun customSuccessAlert(
            activity: Activity, title: String?, msg: String?,
            flag: Boolean
        ) {
            try {
                val dialog = Dialog(activity)
                dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
                if (dialog.window != null && dialog.window!!.attributes != null) {
                    dialog.window!!.attributes.windowAnimations = R.style.exitdialog_animation1
                    dialog.window!!.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
                    dialog.setContentView(R.layout.custom_alert_success)
                    dialog.setCancelable(false)
                    val versionTitle = dialog.findViewById<TextView>(R.id.version_tv)

                    versionTitle.text = "Version: " + Utils.getVersionName(activity)
                    val dialogTitle = dialog.findViewById<TextView>(R.id.dialog_title)
                    dialogTitle.text = title
                    val dialogMessage = dialog.findViewById<TextView>(R.id.dialog_message)

                        dialogMessage.visibility = View.VISIBLE

                    dialogMessage.text = msg
                    val btDialogYes = dialog.findViewById<Button>(R.id.btDialogYes)
                    btDialogYes.setOnClickListener {
                        if (dialog.isShowing) {
                            dialog.dismiss()
                            activity.onBackPressed()
                        }
                    }
                    if (!dialog.isShowing) dialog.show()
                }
            } catch (e: Resources.NotFoundException) {
                e.fillInStackTrace();
            }
        }
    }

    fun customImageAlertcamera(
        title: String?,
        msg: String?,
        b1: Bitmap?,
        filename: File,
    )
    {


            val dialog = Dialog(this@CameraActivity)
            dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
            if (dialog.window != null && dialog.window!!.attributes != null) {
                dialog.window!!.attributes.windowAnimations = R.style.exitdialog_animation1
                dialog.window!!.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
                dialog.setContentView(R.layout.custom_alert_showimage)
                dialog.setCancelable(false)
                val versionTitle = dialog.findViewById<TextView>(R.id.version_tv)
                versionTitle.text = "Version: " + Utils.getVersionName(this@CameraActivity)
                val dialogTitle = dialog.findViewById<TextView>(R.id.dialog_title)
                dialogTitle.text = title
                val dialogMessage = dialog.findViewById<TextView>(R.id.dialog_message)
                dialogMessage.text = msg
                val exit = dialog.findViewById<Button>(R.id.btDialogExit)
                val iv1 = dialog.findViewById<ImageView>(R.id.iv1)
                iv1.setImageBitmap(b1)
                exit.setOnClickListener {
                    if (dialog.isShowing) {
                        dialog.dismiss()
                    }

                    val bmp: Bitmap?
                    val bos: ByteArrayOutputStream?
                    val bt: ByteArray?
                    try {
                        bmp = b1
                        bos = ByteArrayOutputStream()
                        bmp!!.compress(Bitmap.CompressFormat.PNG, 100, bos)
                        bt = bos.toByteArray()
                       // encodeString = Base64.encodeToString(bt, Base64.DEFAULT)

                        base64String = fileToBase64(filename)
                       // Log.e("base64String","$base64String")
                        val resultIntent = Intent()
                        resultIntent.putExtra(
                            "resultData",
                            base64String
                        )
                        setResult(
                            Activity.RESULT_OK, resultIntent
                        )
                        finish()
//                        customProgressDialog.show()
//                        val client = BaseApiClient.getClient1().create(
//                            APIInter::class.java
//                        )///
//                        val name: RequestBody = RequestBody.create(
//                            "text/plain".toMediaTypeOrNull(),
//                            "test"
//                        )
//                        val mobilenumber: RequestBody = RequestBody.create(
//                            "text/plain".toMediaTypeOrNull(),
//                            "9640396367"
//                        )
//
//                        val map: MutableMap<String, RequestBody> = HashMap()
//                        map["mobileNo"] = mobilenumber
//                        map["deviceId"] = name
//                        map["empID"] = name
//                        map["empName"] = name
//                        map["designation"] = name
//                        map["role"] = name
//                        map["userid"] = name
//                        map["ipAddress"] = name
//                        val filelive = File(filename.absolutePath)
//                        val requestFile =
//                            filelive.asRequestBody("multipart/form-data".toMediaTypeOrNull())
//                        val sourceimage =
//                            MultipartBody.Part.createFormData(
//                                "imagePath",
//                                filelive.name,
//                                requestFile
//                            )
//                        val users = client.userRegistration(
//                            sourceimage, map
//                        )
//                        users
//                            .enqueue(object : Callback<RegistrationResponse?> {
//                                override fun onResponse(
//                                    call: Call<RegistrationResponse?>,
//                                    response: Response<RegistrationResponse?>
//                                ) {
//                                    if (response.isSuccessful && response.body() != null && response.code() == 200) {
//                                        customProgressDialog.dismiss()
//                                        customSuccessAlert(
//                                            this@CameraActivity,
//                                            getString(R.string.app_name),
//                                            "Image Upload Successfully",
//                                            true
//                                        )
//
//                                    }
//                                    else if(response.isSuccessful && response.body() != null){
//                                        Utils.customErrorAlert(
//                                            this@CameraActivity,
//                                            getString(R.string.app_name),
//                                            "Something went wrong try again",
//                                            true
//                                        )
//                                    }
//                                        else {
//                                        customProgressDialog.dismiss()
//                                        Utils.customErrorAlert(
//                                            this@CameraActivity,
//                                            getString(R.string.app_name),
//                                            application.getString(R.string.server_error),
//                                            true
//                                        )
//                                    }
//                                }
//
//                                override fun onFailure(
//                                    call: Call<RegistrationResponse?>,
//                                    t: Throwable
//                                ) {
//                                    customProgressDialog.dismiss()
//                                    Utils.customErrorAlert(
//                                        this@CameraActivity,
//                                        getString(R.string.app_name),
//                                        application.getString(R.string.server_error)
//                                    ,true
//                                    )
//                                }
//                            })
                }catch (e:Exception){

                }
                }




                val cancel = dialog.findViewById<Button>(R.id.btDialogCancel)
                cancel.setOnClickListener {
                    if (dialog.isShowing) {
                        dialog.dismiss()
                        onBackPressed()
                    }
                }
                if (!dialog.isShowing) dialog.show()
            }

    }

    private fun predict(input: Bitmap): MutableMap<String, Float> {
        // load model
        val modelFile = FileUtil.loadMappedFile(this, "mask.tflite")
        val model = Interpreter(modelFile, Interpreter.Options())
        val labels = FileUtil.loadLabels(this, "masklabel.txt")


        // data type
        val imageDataType = model.getInputTensor(0).dataType()
        val inputShape = model.getInputTensor(0).shape()

        val outputDataType = model.getOutputTensor(0).dataType()
        val outputShape = model.getOutputTensor(0).shape()

        var inputImageBuffer = TensorImage(imageDataType)
        val outputBuffer = TensorBuffer.createFixedSize(outputShape, outputDataType)

        // preprocess
        val cropSize = min(input.width, input.height)
        val imageProcessor = ImageProcessor.Builder()
            .add(ResizeWithCropOrPadOp(cropSize, cropSize))
            .add(ResizeOp(inputShape[1], inputShape[2], ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
            .add(NormalizeOp(127.5f, 127.5f))
            .build()

        // load image
        inputImageBuffer.load(input)
        inputImageBuffer = imageProcessor.process(inputImageBuffer)

        // run model
        model.run(inputImageBuffer.buffer, outputBuffer.buffer.rewind())

        // get output
        val labelOutput = TensorLabel(labels, outputBuffer)

        val label = labelOutput.mapWithFloatValue
        return label
    }
}