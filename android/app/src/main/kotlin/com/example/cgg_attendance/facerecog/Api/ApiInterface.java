package com.example.cgg_attendance.facerecog.Api;




import java.util.Map;

import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import retrofit2.Call;
import retrofit2.http.Header;
import retrofit2.http.Multipart;
import retrofit2.http.POST;
import retrofit2.http.Part;
import retrofit2.http.PartMap;

public interface ApiInterface {
    @Multipart
    @POST("Facematch")
    Call<ImageResponse> login(@Header("x-api-key") String x_api_key, @Part MultipartBody.Part source_image,@Part MultipartBody.Part target_image);

    @Multipart
    @POST("FailureCount")
    Call<FacenotMatched> facenotmatched(@Part MultipartBody.Part source_image,@PartMap Map<String, RequestBody> map);


}