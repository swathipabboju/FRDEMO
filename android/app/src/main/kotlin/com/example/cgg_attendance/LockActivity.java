package com.example.cgg_attendance;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.databinding.DataBindingUtil;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Outline;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.YuvImage;
import android.graphics.drawable.ColorDrawable;
import android.media.Image;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.util.Size;
import android.view.View;
import android.view.ViewOutlineProvider;
import android.view.Window;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.SimpleTarget;
import com.bumptech.glide.request.transition.Transition;
import com.example.cgg_attendance.databinding.ActivityLockBinding;
import com.example.cgg_attendance.facerecog.Api.APIClient;
import com.example.cgg_attendance.facerecog.Api.ApiInterface;
import com.example.cgg_attendance.facerecog.Api.FacenotMatched;
import com.example.cgg_attendance.facerecog.Api.ImageResponse;
import com.example.cgg_attendance.facerecog.Api.LoginErrorResponse;
import com.example.cgg_attendance.facerecog.CustomProgressDialog;
import com.example.cgg_attendance.facerecog.modules.FaceAntiSpoofing;
import com.example.cgg_attendance.facerecog.modules.MobileFaceNet;
import com.example.cgg_attendance.facerecog.modules.Utils;
import com.google.android.gms.tasks.Task;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceDetection;
import com.google.mlkit.vision.face.FaceDetector;
import com.google.mlkit.vision.face.FaceDetectorOptions;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ReadOnlyBufferException;
import java.nio.file.Files;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;


public class LockActivity extends AppCompatActivity {
    private ActivityLockBinding binding;
    FaceDetector detector;

    private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;
    FaceAntiSpoofing fas;
    CameraSelector cameraSelector;
    boolean flipX = false;
    int cam_face = CameraSelector.LENS_FACING_FRONT;

    ProcessCameraProvider cameraProvider;
    private static final int MY_CAMERA_REQUEST_CODE = 100;
    int loop = 0;

    MobileFaceNet mobileFaceNet;
    CustomProgressDialog customProgressDialog;

    Task<List<Face>> result;

    private SharedPreferences sharedPreferences;
    private SharedPreferences.Editor editor;
    String InOUTVALUE="";


    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = DataBindingUtil.setContentView(this, R.layout.activity_lock);
        Intent intent = getIntent(); // assuming you are inside an Activity
        InOUTVALUE = intent.getStringExtra("INOUT");

        if (InOUTVALUE != null) {
            Log.d("Inout",""+InOUTVALUE);
            // ...
        } else {
            Log.d("Inout",""+InOUTVALUE);

        }
        binding.header.headerTitle.setText("Face Recognition");
        binding.header.backBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent resultIntent = new Intent();
                resultIntent.putExtra("resultData", "onback");
                setResult(
                        RESULT_OK
                        , resultIntent);
                finish();
            }
        });


        customProgressDialog = new CustomProgressDialog(this);
        fas = new FaceAntiSpoofing(getAssets());
        mobileFaceNet = new MobileFaceNet(getAssets());


        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.CAMERA}, MY_CAMERA_REQUEST_CODE);
        }
        cam_face = CameraSelector.LENS_FACING_FRONT;
        flipX = false;

        FaceDetectorOptions highAccuracyOpts = new FaceDetectorOptions.Builder().setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE).setMinFaceSize(1.5f).build();
        detector = FaceDetection.getClient(highAccuracyOpts);
        cameraBind();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == MY_CAMERA_REQUEST_CODE) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "camera permission granted", Toast.LENGTH_LONG).show();
            } else {
                Toast.makeText(this, "camera permission denied", Toast.LENGTH_LONG).show();
            }
        }
    }


    private void cameraBind() {
        cameraProviderFuture = ProcessCameraProvider.getInstance(this);
        binding.cameraPreview.setOutlineProvider(new ViewOutlineProvider() {
            @Override
            public void getOutline(View view, Outline outline) {
                int diameter = Math.min(view.getWidth(), view.getHeight());
                outline.setOval(0, 0, diameter, diameter);
            }
        });
        binding.cameraPreview.setClipToOutline(true);

        cameraProviderFuture.addListener(() -> {
            try {
                cameraProvider = cameraProviderFuture.get();
                bindPreview(cameraProvider);
            } catch (ExecutionException | InterruptedException e) {
                e.fillInStackTrace();

            }
        }, ContextCompat.getMainExecutor(this));
    }

    void bindPreview(@NonNull ProcessCameraProvider cameraProvider) {
        Preview preview = new Preview.Builder().build();
        cameraSelector = new CameraSelector.Builder().requireLensFacing(cam_face).build();
        preview.setSurfaceProvider(binding.cameraPreview.getSurfaceProvider());
        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder().setTargetResolution(new Size(1080, 1920)).setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST) //Latest frame is shown
                .build();
        Executor executor = Executors.newSingleThreadExecutor();
        imageAnalysis.setAnalyzer(executor, imageProxy -> {
            try {
                Thread.sleep(0);
            } catch (InterruptedException e) {
                e.fillInStackTrace();
            }
            InputImage image = null;
            @SuppressLint({"UnsafeExperimentalUsageError", "UnsafeOptInUsageError"})
            Image mediaImage = imageProxy.getImage();
            if (mediaImage != null) {
                image = InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());
            }
            assert image != null;
            result = detector.process(image).addOnSuccessListener(faces -> {
                        if (!faces.isEmpty()) {
                            Face face = faces.get(0);
                            Bitmap frame_bmp = toBitmap(mediaImage);
                            int rot = imageProxy.getImageInfo().getRotationDegrees();
                            Bitmap frame_bmp1 = rotateBitmap(frame_bmp, rot, false);
                            RectF boundingBox = new RectF(face.getBoundingBox());
                            Bitmap cropped_face = getCropBitmapByCPU(frame_bmp1, boundingBox);
                            if(cropped_face!=null) {

                                if (flipX) cropped_face = rotateBitmap(cropped_face, 0, true);
                                int width = cropped_face.getWidth();
                                if (width > 0) {
                                    Bitmap scaled = getResizedBitmap(cropped_face, 256, 300);

                                    int laplace1 = fas.laplacian(scaled);

                                    Log.e("laplace..", laplace1 + "");
                                    if (laplace1 < FaceAntiSpoofing.LAPLACIAN_THRESHOLD && laplace1 > 100) {
                                        File filename = new File(getExternalFilesDir(null), "image.jpg");

                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

                                            try (OutputStream outputStream = Files.newOutputStream(filename.toPath())) {
                                                if (scaled != null) {
                                                    scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                    outputStream.flush();
                                                    outputStream.close();
                                                } else {

                                                }

                                            } catch (IOException e) {

                                            }
                                        } else {
                                            try {

                                                BufferedOutputStream outputStream = new BufferedOutputStream(new FileOutputStream(filename));
                                                scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                outputStream.flush();
                                                outputStream.close();
                                            } catch (IOException e) {

                                            }
                                        }

                                    } else {
                                        float score1 = fas.antiSpoofing(scaled);
                                        Log.e("threshold", score1 + "");
                                        if (score1 < FaceAntiSpoofing.THRESHOLD) {
                                            runOnUiThread(() -> {
                                                Log.e("threshold", score1 + "");
                                                //    binding.tvstatus.setText(R.string.recognising);
                                                if (loop == 0) {
                                                    loop = 1;
                                                    binding.progressBar.setProgress(50);
                                                }
                                                if (loop == 1) {
                                                    binding.progressBar.setProgress(100);
                                                    cameraProvider.unbindAll();
                                                    customProgressDialog.show();
                                                    File profile = new File(getExternalFilesDir(null), "profile.jpg");
                                                    if (profile.exists()) {
                                                        Bitmap profilebitmap = BitmapFactory.decodeFile(String.valueOf(profile));
                                                        int width1 = profilebitmap.getWidth();
                                                        if (width1 > 0) {

                                                            float same = mobileFaceNet.compare(profilebitmap, scaled);
                                                            File filename = new File(getExternalFilesDir(null), "image.jpg");
                                                            try (OutputStream outputStream = new FileOutputStream(filename)) {
                                                                scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                                outputStream.flush();
                                                            } catch (IOException e) {
                                                                e.fillInStackTrace();
                                                            }
                                                            if (same > MobileFaceNet.THRESHOLD) {
                                                                Log.e("thresholdface", same + "");
                                                                customProgressDialog.dismiss();
                                                                Intent resultIntent = new Intent();
                                                                resultIntent.putExtra("resultData", "true" + InOUTVALUE);
                                                                setResult(
                                                                        RESULT_OK
                                                                        , resultIntent);
                                                                finish();


//                                                            Intent intent = new Intent(FaceRecognition.this, AttendanceActivity.class);
//                                                            if (getIntent().getStringExtra("punchin") != null && Objects.requireNonNull(getIntent().getStringExtra("punchin")).equalsIgnoreCase("previousday")) {
//                                                                intent.putExtra("punchin", "previousday");
//                                                                intent.putExtra("office", getIntent().getStringExtra("office"));
//                                                            } else if (getIntent().getStringExtra("punchin") != null && Objects.requireNonNull(getIntent().getStringExtra("punchin")).equalsIgnoreCase("true")) {
//                                                                intent.putExtra("punchin", "true");
//                                                                intent.putExtra("office", getIntent().getStringExtra("office"));
//                                                            } else if (getIntent().getStringExtra("punchin") != null && Objects.requireNonNull(getIntent().getStringExtra("punchin")).equalsIgnoreCase("false")) {
//                                                                intent.putExtra("punchin", "false");
//                                                                intent.putExtra("office", getIntent().getStringExtra("office"));
//                                                            }
//                                                            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
//                                                            startActivity(intent);
                                                            } else {
//campreefee
                                                                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

                                                                    try (OutputStream outputStream = Files.newOutputStream(filename.toPath())) {
                                                                        if (scaled != null) {
                                                                            scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                                            outputStream.flush();
                                                                            outputStream.close();
                                                                        } else {

                                                                        }

                                                                    } catch (IOException e) {

                                                                    }
                                                                } else {
                                                                    try {

                                                                        BufferedOutputStream outputStream = new BufferedOutputStream(new FileOutputStream(filename));
                                                                        scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                                        outputStream.flush();
                                                                        outputStream.close();
                                                                    } catch (IOException e) {

                                                                    }
                                                                }

                                                                File file = new File(filename.getAbsolutePath());
                                                                Log.d("fileprofile11", "" + file.getAbsolutePath());
                                                                Log.d("fileprofile222", "" + profile.getAbsolutePath());
                                                                File fileprofile = new File(profile.getAbsolutePath());
                                                                RequestBody requestFile = RequestBody.create(MediaType.parse("multipart/form-data"), file);
                                                                RequestBody requestFileprofile = RequestBody.create(MediaType.parse("multipart/form-data"), fileprofile);
                                                                MultipartBody.Part source_image = MultipartBody.Part.createFormData("source_image", file.getName(), requestFile);
                                                                MultipartBody.Part target_image = MultipartBody.Part.createFormData("target_image", fileprofile.getName(), requestFileprofile);
                                                                ApiInterface client = APIClient.getClient().create(ApiInterface.class);
                                                                Call<ImageResponse> users = client.login("c359dd17-0389-4704-8365-3845a9012bed", source_image, target_image);
                                                                users.enqueue(new Callback<ImageResponse>() {
                                                                    @Override
                                                                    public void onResponse(@NonNull Call<ImageResponse> call, @NonNull Response<ImageResponse> response) {
                                                                        if (response.body() != null && response.code() == 200 && response.isSuccessful()) {
                                                                            customProgressDialog.dismiss();
                                                                            ImageResponse imageResponse = response.body();


                                                                            if (imageResponse.getResult() != null) {
                                                                                if (imageResponse.getResult().get(0).getFace_matches().get(0).getSimilarity() > 0.92) {

                                                                                    Intent resultIntent = new Intent();
                                                                                    resultIntent.putExtra("resultData", "true" + InOUTVALUE);
                                                                                    setResult(
                                                                                            RESULT_OK
                                                                                            , resultIntent);
                                                                                    finish();
                                                                                } else {

                                                                                    Utils.customErrorAlert(LockActivity.this, getString(R.string.app_name), "Face not matched", true);
                                                                                }
                                                                            } else {
// // 2 senario if result null and if more than one face
                                                                                Utils.customErrorAlert(LockActivity.this, getString(R.string.app_name), "Server not responding, please try again", true);
                                                                            }


                                                                        } else {
                                                                            //0.1% incase image size is more than 1mb
                                                                            Gson gson = new GsonBuilder().create();
                                                                            LoginErrorResponse pojo = new LoginErrorResponse();
                                                                            try {
                                                                                pojo = gson.fromJson(response.errorBody().string(), LoginErrorResponse.class);
                                                                            } catch (
                                                                                    IOException e) {
                                                                                e.printStackTrace();
                                                                            }
                                                                            Utils.customErrorAlert(LockActivity.this, getString(R.string.app_name), pojo.getMessage(), true);

                                                                        }
                                                                    }

                                                                    @Override
                                                                    public void onFailure(@NonNull Call<ImageResponse> call, @NonNull Throwable t) {
                                                                        // if not conncted to campreefee api or more than time connection timeout
                                                                        Log.e("Error", t.getMessage());
                                                                        customProgressDialog.dismiss();

                                                                        try {
                                                                            final Dialog dialog = new Dialog(LockActivity.this);
                                                                            dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                                                                            if (dialog.getWindow() != null && dialog.getWindow().getAttributes() != null) {
                                                                                dialog.getWindow().getAttributes().windowAnimations = R.style.exitdialog_animation1;
                                                                                dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
                                                                                dialog.setContentView(R.layout.custom_alert_error);
                                                                                dialog.setCancelable(false);
                                                                                TextView versionTitle = dialog.findViewById(R.id.version_tv);
                                                                                versionTitle.setText("Version: " + Utils.getVersionName(LockActivity.this));
                                                                                TextView dialogTitle = dialog.findViewById(R.id.dialog_title);
                                                                                dialogTitle.setText(getString(R.string.app_name));
                                                                                TextView dialogMessage = dialog.findViewById(R.id.dialog_message);
                                                                                dialogMessage.setText("server not responding please try again");
                                                                                Button btnOK = dialog.findViewById(R.id.btDialogYes);
                                                                                btnOK.setOnClickListener(new View.OnClickListener() {
                                                                                    @Override
                                                                                    public void onClick(View v) {
                                                                                        if (dialog.isShowing()) {
                                                                                            dialog.dismiss();
                                                                                            Intent resultIntent = new Intent();
                                                                                            resultIntent.putExtra("resultData", "failure");
                                                                                            setResult(
                                                                                                    RESULT_OK
                                                                                                    , resultIntent);
                                                                                            finish();
                                                                                        }
                                                                                    }
                                                                                });
                                                                                if (!dialog.isShowing()) {
                                                                                    if (isFinishing()) {
                                                                                        dialog.dismiss();
                                                                                    } else {
                                                                                        dialog.show();
                                                                                    }
                                                                                }


                                                                            }
                                                                        } catch (
                                                                                Resources.NotFoundException e) {
                                                                            e.printStackTrace();
                                                                        }
                                                                    }
                                                                });


                                                            }
                                                        }
                                                    } else {
                                                        Utils.customErrorAlert(LockActivity.this, getString(R.string.app_name), "profile imsge not exist", true);
                                                    }


                                                }
                                            });
                                        } else {
                                            Utils.customErrorAlert(LockActivity.this, getString(R.string.app_name), "Server not responding, please try again", true);

                                            File filename = new File(getExternalFilesDir(null), "image.jpg");

                                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

                                                try (OutputStream outputStream = Files.newOutputStream(filename.toPath())) {
                                                    if (scaled != null) {
                                                        scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                        outputStream.flush();
                                                        outputStream.close();
                                                    } else {

                                                    }

                                                } catch (IOException e) {

                                                }
                                            } else {
                                                try {

                                                    BufferedOutputStream outputStream = new BufferedOutputStream(new FileOutputStream(filename));
                                                    scaled.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                                    outputStream.flush();
                                                    outputStream.close();
                                                } catch (IOException e) {

                                                }
                                            }
                                        }

                                    }
                                }
                            }
                        }
                    }).

                    addOnFailureListener(e -> {

                    }).

                    addOnCompleteListener(task -> imageProxy.close());
        });


        cameraProvider.bindToLifecycle(this, cameraSelector, imageAnalysis, preview);
    }

    private void failure(MultipartBody.Part target_image, Map<String, RequestBody> map) {
        ApiInterface client = APIClient.getClient().create(ApiInterface.class);
        Call<FacenotMatched> users = client.facenotmatched(target_image, map);
        users.enqueue(new Callback<FacenotMatched>() {
            @Override
            public void onResponse(@NonNull Call<FacenotMatched> call, @NonNull Response<FacenotMatched> response) {
                if (response.body() != null && response.code() == 200 && response.isSuccessful()) {
                    customProgressDialog.dismiss();
                    FacenotMatched imageResponse = response.body();
                } else {

                }
            }

            @Override
            public void onFailure(@NonNull Call<FacenotMatched> call, @NonNull Throwable t) {
                Log.e("Error", t.getMessage());
            }
        });
    }

    public Bitmap getResizedBitmap(Bitmap bm, int newWidth, int newHeight) {
        int width = bm.getWidth();
        int height = bm.getHeight();
        float scaleWidth = ((float) newWidth) / width;
        float scaleHeight = ((float) newHeight) / height;
        Matrix matrix = new Matrix();
        matrix.postScale(scaleWidth, scaleHeight);
        Bitmap resizedBitmap = Bitmap.createBitmap(bm, 0, 0, width, height, matrix, false);
        bm.recycle();
        return resizedBitmap;
    }

    private static Bitmap getCropBitmapByCPU(Bitmap source, RectF originalFaceRect) {
        // Increase the size of the bounding box (adjust the values as needed)
        float scaleFactor = 1.3f; // Increase by 50%, you can adjust this value
        float newWidth = originalFaceRect.width() * scaleFactor;
        float newHeight = originalFaceRect.height() * scaleFactor;

        // Calculate the new coordinates for the top-left corner of the bounding box
        float newLeft = originalFaceRect.left - (newWidth - originalFaceRect.width()) / 2;
        float newTop = originalFaceRect.top - (newHeight - originalFaceRect.height()) / 2;

        // Ensure the new coordinates are within the bounds of the image
        newLeft = Math.max(0, newLeft);
        newTop = Math.max(0, newTop);
        float newRight = Math.min(source.getWidth(), newLeft + newWidth);
        float newBottom = Math.min(source.getHeight(), newTop + newHeight);

        // Create the new RectF with the adjusted coordinates
        RectF newFaceRect = new RectF(newLeft, newTop, newRight, newBottom);

        // Create the result bitmap with the adjusted bounding box
        Bitmap resultBitmap = Bitmap.createBitmap((int) newFaceRect.width(), (int) newFaceRect.height(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(resultBitmap);
        Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG);
        paint.setColor(Color.WHITE);
        canvas.drawRect(new RectF(0, 0, newFaceRect.width(), newFaceRect.height()), paint);
        Matrix matrix = new Matrix();
        matrix.postTranslate(-newFaceRect.left, -newFaceRect.top);
        canvas.drawBitmap(source, matrix, paint);

        // Recycle the original bitmap if it's not null and not recycled
        if (source != null && !source.isRecycled()) {
            source.recycle();
        }

        return resultBitmap;
    }

    private static Bitmap getCropBitmapByCPU1(Bitmap source, RectF cropRectF) {
        Bitmap resultBitmap = Bitmap.createBitmap((int) cropRectF.width(), (int) cropRectF.height(), Bitmap.Config.ARGB_8888);
        Canvas cavas = new Canvas(resultBitmap);
        Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG);
        paint.setColor(Color.WHITE);
        cavas.drawRect(new RectF(0, 0, cropRectF.width(), cropRectF.height()), paint);
        Matrix matrix = new Matrix();
        matrix.postTranslate(-cropRectF.left, -cropRectF.top);
        cavas.drawBitmap(source, matrix, paint);
        if (!source.isRecycled()) {
            source.recycle();
        }
        return resultBitmap;
    }

    private static Bitmap rotateBitmap(Bitmap bitmap, int rotationDegrees, boolean flipX) {
        Matrix matrix = new Matrix();
        matrix.postRotate(rotationDegrees);
        matrix.postScale(flipX ? -1.0f : 1.0f, 1.0f);
        Bitmap rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
        if (rotatedBitmap != bitmap) {
            bitmap.recycle();
        }
        return rotatedBitmap;
    }

    private static byte[] YUV_420_888toNV21(Image image) {

        int width = image.getWidth();
        int height = image.getHeight();
        int ySize = width * height;
        int uvSize = width * height / 4;

        byte[] nv21 = new byte[ySize + uvSize * 2];

        ByteBuffer yBuffer = image.getPlanes()[0].getBuffer(); // Y
        ByteBuffer uBuffer = image.getPlanes()[1].getBuffer(); // U
        ByteBuffer vBuffer = image.getPlanes()[2].getBuffer(); // V

        int rowStride = image.getPlanes()[0].getRowStride();
        assert (image.getPlanes()[0].getPixelStride() == 1);

        int pos = 0;

        if (rowStride == width) { // likely
            yBuffer.get(nv21, 0, ySize);
            pos += ySize;
        } else {
            long yBufferPos = -rowStride; // not an actual position
            for (; pos < ySize; pos += width) {
                yBufferPos += rowStride;
                yBuffer.position((int) yBufferPos);
                yBuffer.get(nv21, pos, width);
            }
        }

        rowStride = image.getPlanes()[2].getRowStride();
        int pixelStride = image.getPlanes()[2].getPixelStride();

        assert (rowStride == image.getPlanes()[1].getRowStride());
        assert (pixelStride == image.getPlanes()[1].getPixelStride());

        if (pixelStride == 2 && rowStride == width && uBuffer.get(0) == vBuffer.get(1)) {
            byte savePixel = vBuffer.get(1);
            try {
                vBuffer.put(1, (byte) ~savePixel);
                if (uBuffer.get(0) == (byte) ~savePixel) {
                    vBuffer.put(1, savePixel);
                    vBuffer.position(0);
                    uBuffer.position(0);
                    vBuffer.get(nv21, ySize, 1);
                    uBuffer.get(nv21, ySize + 1, uBuffer.remaining());
                    return nv21;
                }
            } catch (ReadOnlyBufferException ex) {
                ex.fillInStackTrace();
            }
            vBuffer.put(1, savePixel);
        }
        for (int row = 0; row < height / 2; row++) {
            for (int col = 0; col < width / 2; col++) {
                int vuPos = col * pixelStride + row * rowStride;
                nv21[pos++] = vBuffer.get(vuPos);
                nv21[pos++] = uBuffer.get(vuPos);
            }
        }
        return nv21;
    }

    private Bitmap toBitmap(Image image) {
        byte[] nv21 = YUV_420_888toNV21(image);
        YuvImage yuvImage = new YuvImage(nv21, ImageFormat.NV21, image.getWidth(), image.getHeight(), null);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        yuvImage.compressToJpeg(new Rect(0, 0, yuvImage.getWidth(), yuvImage.getHeight()), 75, out);
        byte[] imageBytes = out.toByteArray();
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
    }








    @Override
    public void onBackPressed() {

        super.onBackPressed();
        Intent resultIntent = new Intent();
        resultIntent.putExtra("resultData", "onback");
        setResult(
                RESULT_OK
                , resultIntent);
        finish();
    }
}