package com.example.cgg_attendance.facerecog;


import android.app.Dialog;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;

import com.example.cgg_attendance.R;


public class CustomProgressDialog extends Dialog {
    private CustomProgressDialog mDialog;

    public CustomProgressDialog(Context context) {
        super(context);
        try {
            requestWindowFeature(Window.FEATURE_NO_TITLE);
            View view = LayoutInflater.from(context).inflate(R.layout.custom_progress_layout, null);
            setContentView(view);
            if (getWindow() != null)
                this.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
            setCancelable(false);
            setCanceledOnTouchOutside(false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
