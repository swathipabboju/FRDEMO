package com.example.cgg_attendance.facerecog.Api;

import java.util.List;

public class Result {
    private List<Face_matches> face_matches;

    private Source_image_face source_image_face;

    public List<Face_matches> getFace_matches ()
    {
        return face_matches;
    }

    public void setFace_matches (List<Face_matches> face_matches)
    {
        this.face_matches = face_matches;
    }

    public Source_image_face getSource_image_face ()
    {
        return source_image_face;
    }

    public void setSource_image_face (Source_image_face source_image_face)
    {
        this.source_image_face = source_image_face;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [face_matches = "+face_matches+", source_image_face = "+source_image_face+"]";
    }
}
