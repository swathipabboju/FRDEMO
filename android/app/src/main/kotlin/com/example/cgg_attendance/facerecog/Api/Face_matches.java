package com.example.cgg_attendance.facerecog.Api;

public class Face_matches {

    private Double similarity;

    private Box box;

    public Double getSimilarity ()
    {
        return similarity;
    }

    public void setSimilarity (Double similarity)
    {
        this.similarity = similarity;
    }

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
        return "ClassPojo [similarity = "+similarity+", box = "+box+"]";
    }
}
