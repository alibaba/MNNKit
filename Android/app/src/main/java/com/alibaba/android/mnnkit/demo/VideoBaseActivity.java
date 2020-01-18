package com.alibaba.android.mnnkit.demo;

import android.Manifest;
import android.content.pm.PackageManager;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.view.Menu;
import android.view.MenuItem;
import android.view.OrientationEventListener;
import android.widget.Toast;

import com.alibaba.android.mnnkit.demo.utils.PermissionUtils;
import com.alibaba.android.mnnkit.demo.view.CameraView;
import com.tsia.example.mnnkitdemo.R;

public abstract class VideoBaseActivity extends AppCompatActivity {

    private OrientationEventListener mOrientationListener;
    protected int rotateDegree;// 设备旋转角度：0/90/180/360

    abstract void createKitInstance();
    abstract void doRun();
    abstract String actionBarTitle();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_video_base);

        // 监听屏幕旋转
        detectScreenRotate();

        ActionBar actionBar = getSupportActionBar();
        if(actionBar != null){
            actionBar.setTitle(actionBarTitle());
            actionBar.setHomeButtonEnabled(true);
            actionBar.setDisplayHomeAsUpEnabled(true);
        }


        // 创建Kit实例
        createKitInstance();

        // Android M动态申请权限，摄像头+存储访问
        PermissionUtils.askPermission(this,new String[]{Manifest.permission.CAMERA, Manifest
                .permission.WRITE_EXTERNAL_STORAGE},10, initViewRunnable);
    }

    /**
     * 监听屏幕旋转
     */
    private void detectScreenRotate() {
        mOrientationListener = new OrientationEventListener(this,
                SensorManager.SENSOR_DELAY_NORMAL) {
            @Override
            public void onOrientationChanged(int orientation) {

                if (orientation == OrientationEventListener.ORIENTATION_UNKNOWN) {
                    return;  //手机平放时，检测不到有效的角度
                }

                //可以根据不同角度检测处理，这里只检测四个角度的改变
                orientation = (orientation + 45) / 90 * 90;

                if (screenAutoRotate() && orientation%360==180) {
                    return;
                }

                rotateDegree = orientation%360;
            }
        };

        if (mOrientationListener.canDetectOrientation()) {
            mOrientationListener.enable();
        } else {
            mOrientationListener.disable();
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {
            case android.R.id.home:
                this.finish();
                CameraView.resetCameraId();
                return true;

            default:
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.menu_video, menu);
        return super.onCreateOptionsMenu(menu);
    }

    // 系统是否开启自动旋转
    protected boolean screenAutoRotate() {

        boolean autoRotate = false;
        try {
            autoRotate = 1== Settings.System.getInt(getContentResolver(), Settings.System.ACCELEROMETER_ROTATION);
        } catch (Settings.SettingNotFoundException e) {
            e.printStackTrace();
        }

        return autoRotate;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (10==requestCode) {
            if (grantResults.length>0 && PackageManager.PERMISSION_GRANTED==grantResults[0]) {
                initViewRunnable.run();
            } else {
                Toast.makeText(this, "没有获得必要的权限", Toast.LENGTH_SHORT).show();
                finish();
            }
        }

    }

    private Runnable initViewRunnable = new Runnable() {
        @Override
        public void run() {

            doRun();
        }
    };

}
