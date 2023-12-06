package com.example.cgg_attendance.facerecog.Api;

public class LoginErrorResponse {
    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    private String message;

    private String code;
}
