package com.example.cgg_attendance.facerecog.Api;

public class Source_image_face {
    private Box box;

    public Box getBox ()
    {
        return box;
    }

    public void setBox (Box box)
    {
        this.box = box;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [box = "+box+"]";
    }
}
