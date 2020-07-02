package com.alibaba.android.mnnkit.demo;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.widget.ImageView;
import android.widget.Toast;

import com.alibaba.android.mnnkit.actor.HandGestureDetector;
import com.alibaba.android.mnnkit.demo.utils.Common;
import com.alibaba.android.mnnkit.entity.HandGestureDetectionReport;
import com.alibaba.android.mnnkit.entity.MNNFlipType;
import com.alibaba.android.mnnkit.intf.InstanceCreatedListener;
import com.tsia.example.mnnkitdemo.R;

public class HandGestureDetectionImageActivity extends AppCompatActivity {

    Paint LinePaint = new Paint();
    Paint LablePaint = new Paint();
    Paint TextPaint = new Paint();

    private SurfaceHolder mDrawSurfaceHolder;

    private HandGestureDetector mHandGestureDetector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hand_gesture_detection_image);

        ActionBar actionBar = getSupportActionBar();
        if(actionBar != null){
            actionBar.setTitle(R.string.gesture_detection_pictures);
            actionBar.setHomeButtonEnabled(true);
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        LinePaint.setColor((Color.WHITE));
        LinePaint.setStyle(Paint.Style.FILL);
        LinePaint.setStrokeWidth(2);

        LablePaint.setColor(Color.WHITE);
        LablePaint.setStrokeWidth(2f);
        LablePaint.setTextSize(40);

        TextPaint.setColor(Color.DKGRAY);
        TextPaint.setStrokeWidth(2f);
        TextPaint.setTextSize(58);

        SurfaceView drawView = findViewById(R.id.points_view);
        drawView.setZOrderOnTop(true);
        drawView.getHolder().setFormat(PixelFormat.TRANSPARENT);
        mDrawSurfaceHolder = drawView.getHolder();

        ImageView imageView = findViewById(R.id.imageView);
        imageView.setImageResource(R.mipmap.face_img);

        HandGestureDetector.HandCreateConfig createConfig = new HandGestureDetector.HandCreateConfig();
        createConfig.mode = HandGestureDetector.HandDetectMode.HAND_DETECT_MODE_VIDEO;
        HandGestureDetector.createInstanceAsync(this, createConfig, new InstanceCreatedListener<HandGestureDetector>() {
            @Override
            public void onSucceeded(HandGestureDetector handGestureDetector) {
                mHandGestureDetector = handGestureDetector;
            }

            @Override
            public void onFailed(int i, Error error) {
                Log.e(Common.TAG, "create hand gesture detector failed: " + error);
            }
        });

    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                this.finish();
                return true;

            case R.id.action_start:
                doDetect();
                return true;

            default:
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    void doDetect() {
        if (mHandGestureDetector == null) {
            Toast.makeText(this, R.string.initializing, Toast.LENGTH_LONG).show();
            return;
        }

        Bitmap bitmap = BitmapFactory.decodeResource(HandGestureDetectionImageActivity.this.getResources(), R.mipmap.face_img);

        long start = System.currentTimeMillis();
        HandGestureDetectionReport[] reports = mHandGestureDetector.inference(bitmap, 0, 0, MNNFlipType.FLIP_NONE);
        drawLines(reports, bitmap, System.currentTimeMillis() - start);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.menu_hand_image, menu);
        return super.onCreateOptionsMenu(menu);
    }

    void drawLines(HandGestureDetectionReport[] reports, Bitmap bitmap, long timeCost) {

        Canvas canvas = null;
        try {
            canvas = mDrawSurfaceHolder.lockCanvas();
            if (canvas == null) {
                return;
            }
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);

            // 屏幕长宽
            DisplayMetrics metric = new DisplayMetrics();
            getWindowManager().getDefaultDisplay().getMetrics(metric);
            int screenW = metric.widthPixels;

            int imgW = bitmap.getWidth();
            int imgH = bitmap.getHeight();

            int previewWidth = screenW;
            int previewHeight  = (int) (screenW*imgH/(float)imgW);

            float kx = ((float) previewWidth)/imgW;
            float ky = (float) previewHeight/imgH;

            for (int i=0; i<reports.length; i++) {
                HandGestureDetectionReport report = reports[i];
                float left = report.rect.left;
                float top = report.rect.top;
                float right = report.rect.right;
                float bottom = report.rect.bottom;

                canvas.drawLine(left * kx, top * ky,
                        right * kx, top * ky, LinePaint);
                canvas.drawLine(right * kx, top * ky,
                        right * kx, bottom * ky, LinePaint);
                canvas.drawLine(right * kx, bottom * ky,
                        left * kx, bottom * ky, LinePaint);
                canvas.drawLine(left * kx, bottom * ky,
                        left * kx, top * ky, LinePaint);

                canvas.drawText(labelDesp(report.type) + report.score, left * kx, top * ky-10, LablePaint);
            }

            canvas.drawText(timeCost+" ms", 20, previewHeight+70, TextPaint);

        } catch (Throwable t) {
            Log.e(Common.TAG, "Draw result error:" + t);
        } finally {
            if (canvas != null) {
                mDrawSurfaceHolder.unlockCanvasAndPost(canvas);
            }
        }

    }

    String labelDesp(HandGestureDetectionReport.HandGestureType type) {

        String desc = getString(R.string.other);

        switch (type) {
            case HAND_GESTURE_TYPE_FINGER_HEART:
                desc = getString(R.string.love);
                break;
            case HAND_GESTURE_TYPE_HAND_OPEN:
                desc = getString(R.string.open_hand);
                break;
            case HAND_GESTURE_TYPE_INDEX_FINGER:
                desc = getString(R.string.index_finger);
                break;
            case HAND_GESTURE_TYPE_FIST:
                desc = getString(R.string.fist);
                break;
            case HAND_GESTURE_TYPE_THUMB_UP:
                desc = getString(R.string.thumbs_up);
                break;
            case HAND_GESTURE_TYPE_OTHER:
                desc = getString(R.string.other);
                break;

            default:
                break;
        }

        return desc;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (mHandGestureDetector!=null) {
            mHandGestureDetector.release();
        }
    }

}
