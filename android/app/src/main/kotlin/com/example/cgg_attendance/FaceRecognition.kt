package com.example.cgg_attendance

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.Dialog
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Resources
import android.graphics.*
import android.graphics.drawable.ColorDrawable
import android.media.Image
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.util.Log
import android.view.View
import android.view.ViewOutlineProvider
import android.view.Window
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil

import com.example.cgg_attendance.databinding.ActivityLockBinding
import com.example.cgg_attendance.facerecog.Api.APIClient
import com.example.cgg_attendance.facerecog.Api.ApiInterface
import com.example.cgg_attendance.facerecog.Api.ImageResponse
import com.example.cgg_attendance.facerecog.Api.LoginErrorResponse
import com.example.cgg_attendance.facerecog.CustomProgressDialog
import com.example.cgg_attendance.facerecog.modules.FaceAntiSpoofing
import com.example.cgg_attendance.facerecog.modules.MobileFaceNet
import com.example.cgg_attendance.facerecog.modules.Utils

import com.google.android.gms.tasks.Task
import com.google.common.util.concurrent.ListenableFuture
import com.google.gson.GsonBuilder
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody.Part.Companion.createFormData
import okhttp3.RequestBody.Companion.asRequestBody

import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import java.io.*
import java.nio.ReadOnlyBufferException
import java.nio.file.Files
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import kotlin.experimental.inv
import kotlin.math.min


class FaceRecognition : AppCompatActivity(), TextToSpeech.OnInitListener {
    lateinit var binding: ActivityLockBinding
    private var detector: FaceDetector? = null
    private lateinit var cameraProviderFuture: ListenableFuture<ProcessCameraProvider>
    private var fas: FaceAntiSpoofing? = null
    private var InOUTVALUE = ""
    private lateinit var cameraSelector: CameraSelector
    private lateinit var cameraProvider: ProcessCameraProvider

    lateinit var result: Task<List<Face>>

    lateinit var customProgressDialog: CustomProgressDialog
    private var loop = 0
    private lateinit var mobileFaceNet: MobileFaceNet
    private lateinit var textToSpeech: TextToSpeech
    private var movements = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView(this, R.layout.activity_lock)
        binding.header.headerTitle.text = getString(R.string.face_recognition)

        binding.header.backBtn.setOnClickListener {
            val resultIntent = Intent()
            resultIntent.putExtra("resultData", "onback")
            setResult(
                Activity.RESULT_OK, resultIntent
            )
            finish()
        }

        val intent = intent // assuming you are inside an Activity

        InOUTVALUE = intent.getStringExtra("INOUT").toString()

        Log.d("Inout", "" + InOUTVALUE)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        textToSpeech = TextToSpeech(this, this)
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                arrayOf(Manifest.permission.CAMERA), 100
            )
        }
        try {
            fas = FaceAntiSpoofing(assets)
            mobileFaceNet = MobileFaceNet(assets)
            // mask = FacMaskDetection(assets)
        } catch (e: IOException) {
            e.fillInStackTrace()
        }

        val highAccuracyOpts = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE).setMinFaceSize(0.15f)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setContourMode(FaceDetectorOptions.CONTOUR_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL).build()

        detector = FaceDetection.getClient(highAccuracyOpts)
        cameraBind()





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


    @SuppressLint("SetTextI18n")
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
                if (faces.isNotEmpty() && faces.size == 1) {

                    val face = faces[0]
                    if (face.headEulerAngleZ < 7.78f && face.headEulerAngleZ > -7.78f
                        && face.headEulerAngleY < 11.8f && face.headEulerAngleY > -11.8f
                        && face.headEulerAngleX < 19.8f && face.headEulerAngleX > -19.8f
                    ) {
                        Log.e(
                            "print facesxyz",
                            ":" + face.headEulerAngleZ + ":" + face.headEulerAngleY + ":" + face.headEulerAngleX
                        )
                        val facebitmap: Bitmap = toBitmap(mediaImage)
                        val rot = imageProxy.imageInfo.rotationDegrees
                        val facerotate = rotateBitmap(facebitmap, rot)
                        val boundingBox = RectF(face.boundingBox)
                        val facecroped: Bitmap = getCropBitmapByCPU(
                            facerotate, boundingBox
                        )
                        //detectFaceMovements(facecroped)
//                        leftEye = face.getLandmark(FaceLandmark.LEFT_EYE)
//                         rightEye = face.getLandmark(FaceLandmark.RIGHT_EYE)
//
//                        if (leftEye != null && rightEye != null) {
//                            val leftEyeX: Float = leftEye!!.position.x
//                            val rightEyeX: Float = rightEye!!.position.y
//                            val distanceBetweenEyes =
//                                abs((leftEyeX - rightEyeX).toDouble()).toFloat()
//                            // You can use this distance to detect various face movements
//                        //    Log.d("distancebe", "Distance between eyes: $distanceBetweenEyes")
//                        }

                        val leftEye = face.leftEyeOpenProbability
                        val rightEye = face.rightEyeOpenProbability
                        Log.e(
                            "eyeblink",
                            leftEye.toString() + ":" + rightEye.toString()
                        )
                        val threshold = 0.7

                        // Check if both eyes are opened (below the threshold)
                        val isLeftEyeClosed = leftEye != null && leftEye > threshold
                        val isRightEyeClosed = rightEye != null && rightEye > threshold

                        // If both eyes are closed, consider it as an eye blink
                        if (isLeftEyeClosed && isRightEyeClosed && movements < 3 && movements > 0) {
                            movements++
                        } else if (!isLeftEyeClosed && !isRightEyeClosed && movements < 1) {
                            movements = 1
                            binding.tvstatus.text =
                                resources.getString(R.string.please_make_some_movements)
                        } else if (movements == 3) {
                            binding.tvstatus.text =
                                resources.getString(R.string.please_place_face_within_the_circle)
                            Log.e(
                                "print facesxyz",
                                ":" + face.headEulerAngleZ + ":" + face.headEulerAngleY + ":" + face.headEulerAngleX
                            )
                            val laplacespoof = fas!!.laplacian(facecroped)
                            Log.e("laplace", laplacespoof.toString())
                            if (laplacespoof < FaceAntiSpoofing.LAPLACIAN_THRESHOLD) {
                                if (laplacespoof == 0) {
                                    Log.e("laplace..0", "0")
                                    binding.tvstatus.text = resources.getString(R.string.spooing)
//                                if (textToSpeech.isSpeaking) {
//                                    Log.e("speeking", "true")
//                                } else {
//                                    textToSpeech.speak(
//                                        "spoofing detected",
//                                        TextToSpeech.QUEUE_FLUSH,
//                                        null,
//                                        null
//                                    )
//                                }
                                } else if (laplacespoof < 150) {

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

                                    if (textToSpeech.isSpeaking) {
                                        Log.e("speaking", "true")
                                    } else {
                                        textToSpeech.speak(
                                            "Please clean your camera",
                                            TextToSpeech.QUEUE_FLUSH,
                                            null,
                                            null
                                        )
                                    }
                                } else if (laplacespoof < 250) {
                                    Log.e("laplace..spoofing", laplacespoof.toString() + "")
                                    if (textToSpeech.isSpeaking) {
                                        Log.e("speaking", "true")
                                    } else {
                                        textToSpeech.speak(
                                            "you are in light environment",
                                            TextToSpeech.QUEUE_FLUSH,
                                            null,
                                            null
                                        )
                                    }
                                }
                                spoof(laplacespoof, facecroped, "0", "Face lighting issue")
                            } else {
//                                val label = predict(facecroped)
//                                val with = label["WithMask"] ?: 0F
//                                val without = label["WithoutMask"] ?: 0F
//                                if (with > without) {
//                                    binding.tvstatus.text =
//                                        resources.getString(R.string.please_remove_mask)
//                                    if (textToSpeech.isSpeaking) {
//                                        Log.e("speaking", "true")
//                                    } else {
//                                        textToSpeech.speak(
//                                            "Please remove mask",
//                                            TextToSpeech.QUEUE_FLUSH,
//                                            null,
//                                            null
//                                        )
//                                    }
//                                } else {
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
                                                Log.e("speaking", "true")
                                            } else {
                                                textToSpeech.speak(
                                                    "Recognising",
                                                    TextToSpeech.QUEUE_FLUSH,
                                                    null,
                                                    null
                                                )
                                            }
                                            binding.progressBar.progress = 100
                                            cameraProvider.unbindAll()
                                            customProgressDialog.show()
                                            val profile =
                                                File(getExternalFilesDir(null), "profile.jpg")
                                            val profilebitmap =
                                                BitmapFactory.decodeFile(profile.toString())
                                            val width1 = profilebitmap.getWidth()
                                            if (width1 > 0) {
                                                val same: Float =
                                                    mobileFaceNet.compare(
                                                        profilebitmap,
                                                        facecroped
                                                    )
                                                if (same > MobileFaceNet.THRESHOLD) {
                                                    Log.e(
                                                        "threshold offline",
                                                        same.toString() + ""
                                                    )
                                                    facematch(
                                                        laplacespoof,
                                                        String.format("%.2f", same)
                                                                + " offline"
                                                    )
                                                } else {
                                                    val filename =
                                                        File(
                                                            getExternalFilesDir(null),
                                                            "image.jpg"
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


                                                    val filelive = File(filename.absolutePath)
                                                    val fileprofile = File(profile.absolutePath)


                                                    val requestFile =
                                                        filelive.asRequestBody("multipart/form-data".toMediaTypeOrNull())
                                                    val sourceimage =
                                                        createFormData(
                                                            "file",
                                                            filelive.name,
                                                            requestFile
                                                        )

                                                    val requestFileprofile =
                                                        fileprofile.asRequestBody("multipart/form-data".toMediaTypeOrNull())
                                                    val targetimage = createFormData(
                                                        "file",
                                                        fileprofile.name,
                                                        requestFileprofile
                                                    )


                                                    val client = APIClient.getClient().create(
                                                        ApiInterface::class.java
                                                    )
                                                    val users = client.login(
                                                        "c359dd17-0389-4704-8365-3845a9012bed",
                                                        sourceimage,
                                                        targetimage
                                                    )
                                                    users.enqueue(object :
                                                        Callback<ImageResponse?> {
                                                        override fun onResponse(
                                                            call: Call<ImageResponse?>,
                                                            response: Response<ImageResponse?>
                                                        ) {
                                                            if (response.body() != null && response.code() == 200 && response.isSuccessful) {
                                                                customProgressDialog.dismiss()
                                                                val imageResponse =
                                                                    response.body()
                                                                if (imageResponse!!.result != null) {
                                                                    if (imageResponse.result[0].face_matches[0].similarity > 0.92) {
                                                                        facematch(
                                                                            laplacespoof,
                                                                            String.format(
                                                                                "%.2f",
                                                                                imageResponse.result[0].face_matches[0].similarity.toFloat()
                                                                            ) + "online"
                                                                        )
                                                                    } else {
                                                                        spoof(
                                                                            laplacespoof,
                                                                            facecroped,
                                                                            imageResponse.result[0].face_matches[0].similarity.toString(),
                                                                            "Face Not matched"
                                                                        )
                                                                        Utils.customErrorAlertcamera(
                                                                            this@FaceRecognition,
                                                                            getString(R.string.app_name),
                                                                            "Face not matched",
                                                                            true,
                                                                            profilebitmap,
                                                                            facecroped
                                                                        )
                                                                    }
                                                                } else {
                                                                    spoof(
                                                                        laplacespoof,
                                                                        facecroped,
                                                                        "0",
                                                                        imageResponse.message!!
                                                                    )
                                                                    Utils.customErrorAlertcamera(
                                                                        this@FaceRecognition,
                                                                        getString(R.string.app_name),
                                                                        imageResponse.message!!,
                                                                        true,
                                                                        profilebitmap,
                                                                        facecroped
                                                                    )
                                                                }
                                                            } else {
                                                                val gson =
                                                                    GsonBuilder().create()
                                                                var pojo = LoginErrorResponse()
                                                                try {
                                                                    pojo = gson.fromJson(
                                                                        response.errorBody()!!
                                                                            .string(),
                                                                        LoginErrorResponse::class.java
                                                                    )
                                                                } catch (e: IOException) {
                                                                    e.fillInStackTrace()
                                                                }
                                                                Utils.customErrorAlertcamera(
                                                                    this@FaceRecognition,
                                                                    getString(R.string.app_name),
                                                                    pojo.message!!,
                                                                    true,
                                                                    profilebitmap,
                                                                    facecroped
                                                                )
                                                                spoof(
                                                                    laplacespoof,
                                                                    facecroped,
                                                                    "0",
                                                                    pojo.message!!
                                                                )
                                                            }
                                                        }

                                                        override fun onFailure(
                                                            call: Call<ImageResponse?>,
                                                            t: Throwable
                                                        ) {
                                                            Log.e("Error", t.message!!)
                                                            customProgressDialog.dismiss()
                                                            spoof(
                                                                laplacespoof,
                                                                facecroped,
                                                                "0",
                                                                t.message.toString()
                                                            )
                                                            networkdialog()
                                                        }
                                                    })
                                                }
                                            }
                                        }
                                    }

                                } else {
                                    binding.tvstatus.text =
                                        resources.getString(R.string.spooing)
                                }
                                //}
                            }
                        } else {
                            binding.tvstatus.text =
                                resources.getString(R.string.please_make_some_movements)
                        }

                    } else {
                        binding.tvstatus.text =
                            resources.getString(R.string.please_place_face_within_the_circle)
                        Log.e(
                            "print facesxyz",
                            ":" + face.headEulerAngleZ + ":" + face.headEulerAngleY + ":" + face.headEulerAngleX
                        )
                    }
                } else if (faces.size > 1) {
                    binding.tvstatus.text = resources.getString(R.string.more_than_one_face)
                } else {
                    binding.tvstatus.text = resources.getString(R.string.no_face_detected)

                }
            }.addOnFailureListener { }.addOnCompleteListener { imageProxy.close() }
        }
        cameraProvider.bindToLifecycle(this, cameraSelector, imageAnalysis, preview)
    }


    private fun facematch(laplace: Int, same: String) {
        customProgressDialog.dismiss()

        val resultIntent = Intent()
        resultIntent.putExtra(
            "resultData",
            "true$InOUTVALUE"
        )
        setResult(
            Activity.RESULT_OK, resultIntent
        )
        finish()
    }

    private fun spoof(laplace1: Int, facecroped: Bitmap, matchpercentage: String, reason: String) {

        val filename = File(getExternalFilesDir(null), "image.jpg")
        try {
            Files.newOutputStream(filename.toPath()).use { outputStream ->
                facecroped.compress(
                    Bitmap.CompressFormat.JPEG, 100, outputStream
                )
                outputStream.flush()
                outputStream.close()
            }
        } catch (e: IOException) {
            e.fillInStackTrace()
        }

    }

    private fun networkdialog() {
        try {
            val dialog =
                Dialog(this@FaceRecognition)
            dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
            if (dialog.window != null && dialog.window!!.attributes != null) {
                dialog.window!!.attributes.windowAnimations =
                    R.style.exitdialog_animation1
                dialog.window!!.setBackgroundDrawable(
                    ColorDrawable(Color.TRANSPARENT)
                )
                dialog.setContentView(R.layout.custom_alert_error)
                dialog.setCancelable(false)
                val versionTitle =
                    dialog.findViewById<TextView>(R.id.version_tv)
                versionTitle.text =
                    buildString {
                        append("Version: ")
                        append(
                            Utils.getVersionName(
                                this@FaceRecognition
                            )
                        )
                    }
                val currentDateAndTime = getCurrentDateAndTime()
                val dialogTitle =
                    dialog.findViewById<TextView>(R.id.dialog_title)
                dialogTitle.text =
                    getString(R.string.app_name)
                val dialogMessage =
                    dialog.findViewById<TextView>(R.id.dialog_message)
                dialogMessage.text =
                    resources.getString(R.string.server_error) + "\n" + currentDateAndTime

                val btnOK =
                    dialog.findViewById<Button>(R.id.btDialogYes)
                btnOK.setOnClickListener {
                    if (dialog.isShowing) {
                        dialog.dismiss()
                        val resultIntent = Intent()
                        resultIntent.putExtra("resultData", "onback")
                        setResult(
                            Activity.RESULT_OK, resultIntent
                        )
                        finish()
                    }
                }
                if (!dialog.isShowing) {
                    if (isFinishing) {
                        dialog.dismiss()
                    } else {
                        dialog.show()
                    }
                }
            }
        } catch (e: Resources.NotFoundException) {
            e.printStackTrace()
        }
    }


    private fun getCurrentDateAndTime(): String {
        val dateFormat = SimpleDateFormat(" dd-MM-yyyy HH:mm", Locale.getDefault())
        val currentDateAndTime = Date()
        return dateFormat.format(currentDateAndTime)
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
        matrix.postScale(1.0f, 1.0f)
        val rotatedBitmap =
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true)
        if (rotatedBitmap != bitmap) {
            bitmap.recycle()
        }
        return rotatedBitmap
    }


    private fun getCropBitmapByCPU(source: Bitmap, cropRectF: RectF): Bitmap {
        val resultBitmap = Bitmap.createBitmap(
            cropRectF.width().toInt(), cropRectF.height().toInt(), Bitmap.Config.ARGB_8888
        )
        val cavas = Canvas(resultBitmap)
        val paint = Paint(Paint.FILTER_BITMAP_FLAG)
        paint.setColor(Color.WHITE)
        cavas.drawRect(RectF(0f, 0f, cropRectF.width(), cropRectF.height()), paint)
        val matrix = Matrix()
        matrix.postTranslate(-cropRectF.left, -cropRectF.top)
        cavas.drawBitmap(source, matrix, paint)
        if (!source.isRecycled) {
            source.recycle()
        }
        return resultBitmap
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

//    private fun getResizedBitmap(bm: Bitmap, newWidth: Int, newHeight: Int): Bitmap {
//        val width = bm.getWidth()
//        val height = bm.getHeight()
//        val scaleWidth = newWidth.toFloat() / width
//        val scaleHeight = newHeight.toFloat() / height
//        val matrix = Matrix()
//        matrix.postScale(scaleWidth, scaleHeight)
//        val resizedBitmap = Bitmap.createBitmap(bm, 0, 0, width, height, matrix, false)
//        if (!bm.isRecycled) {
//            bm.recycle()
//        }
//        return resizedBitmap
//    }


}