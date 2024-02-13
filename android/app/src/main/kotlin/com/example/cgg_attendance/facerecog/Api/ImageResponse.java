package com.example.cgg_attendance.facerecog.Api;
import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

import java.util.List;

public class ImageResponse {


    @SerializedName("result")
    @Expose
    private List<Result> result;

    @SerializedName("message")
    @Expose
    private String message;

    public List<Result> getResult ()
    {
        return result;
    }

    public void setResult (List<Result> result)
    {
        this.result = result;
    }



    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}

