package com.example.cgg_attendance.facerecog.Api;

public class Box {
    private String probability;

    private String y_min;

    private String x_max;

    private String y_max;

    private String x_min;

    public String getProbability ()
    {
        return probability;
    }

    public void setProbability (String probability)
    {
        this.probability = probability;
    }

    public String getY_min ()
    {
        return y_min;
    }

    public void setY_min (String y_min)
    {
        this.y_min = y_min;
    }

    public String getX_max ()
    {
        return x_max;
    }

    public void setX_max (String x_max)
    {
        this.x_max = x_max;
    }

    public String getY_max ()
    {
        return y_max;
    }

    public void setY_max (String y_max)
    {
        this.y_max = y_max;
    }

    public String getX_min ()
    {
        return x_min;
    }

    public void setX_min (String x_min)
    {
        this.x_min = x_min;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [probability = "+probability+", y_min = "+y_min+", x_max = "+x_max+", y_max = "+y_max+", x_min = "+x_min+"]";
    }
}
