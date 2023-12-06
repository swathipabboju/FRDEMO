package com.example.cgg_attendance.facerecog.modules;

import static android.app.Activity.RESULT_OK;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.location.Address;
import android.location.Geocoder;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.Uri;

import android.view.Window;
import android.widget.Button;
import android.widget.TextView;

import com.example.cgg_attendance.R;


public class Utils {
    public static String getVersionName(Context context) {
        String version;
        try {
            PackageInfo pInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
            version = pInfo.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            version = "";
            e.printStackTrace();
        }
        return version;
    }




      public static void customErrorAlert(Activity activity, String title, String msg,boolean flag) {
          try {
              final Dialog dialog = new Dialog(activity);
              dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
              if (dialog.getWindow() != null && dialog.getWindow().getAttributes() != null) {
                  if (dialog.isShowing()) {
                      dialog.dismiss();
                  }
                  dialog.getWindow().getAttributes().windowAnimations = R.style.exitdialog_animation1;
                  dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
                  dialog.setContentView(R.layout.custom_alert_error);
                  dialog.setCancelable(false);
                  // TextView versionTitle = dialog.findViewById(R.id.version_tv);
                  // versionTitle.setText("Version: " + Utils.getVersionName(activity));
                  TextView dialogTitle = dialog.findViewById(R.id.dialog_title);
                  dialogTitle.setText(title);
                  TextView dialogMessage = dialog.findViewById(R.id.dialog_message);
                  dialogMessage.setText(msg);
                  Button btnOK = dialog.findViewById(R.id.btDialogYes);
                  btnOK.setOnClickListener(v -> {
                      if (dialog.isShowing()) {
                          dialog.dismiss();
                          if(flag)
                          {
                              Intent resultIntent = new Intent();
                              resultIntent.putExtra("resultData", msg);
                              activity.setResult(
                                      RESULT_OK
                                      , resultIntent);
                              activity.finish();


                              //activity.onBackPressed();
                          }
                      }


                  });
                  if (!dialog.isShowing())
                      dialog.show();
              }


          } catch (Resources.NotFoundException e) {
              e.printStackTrace();
          }
      }


}
