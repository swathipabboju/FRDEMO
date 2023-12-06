package com.example.cgg_attendance.facerecog.Api;
import java.util.List;

public class ImageResponse {


    private List<Result> result;

    public List<Result> getResult ()
    {
        return result;
    }

    public void setResult (List<Result> result)
    {
        this.result = result;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [result = "+result+"]";
    }


}
