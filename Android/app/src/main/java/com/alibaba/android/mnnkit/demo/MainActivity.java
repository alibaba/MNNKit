package com.alibaba.android.mnnkit.demo;

import android.content.Intent;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;

import com.tsia.example.mnnkitdemo.R;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ActionBar actionBar = getSupportActionBar();
        if(actionBar != null){
            actionBar.setTitle("MNNKit Demo");
        }

    }

    public void onFaceDetection(View v) {
        startActivity(new Intent(MainActivity.this, FaceDetectionActivity.class));
    }

    public void onHandGestureDetection(View v) {
        startActivity(new Intent(MainActivity.this, HandGestureDetectionActivity.class));
    }

    public void onPortraitSegmentation(View v) {
        startActivity(new Intent(MainActivity.this, PortraitSegmentationActivity.class));
    }

}
