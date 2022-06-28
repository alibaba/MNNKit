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

import com.alibaba.android.mnnkit.actor.FaceDetector;
import com.alibaba.android.mnnkit.demo.utils.Common;
import com.alibaba.android.mnnkit.entity.FaceDetectionReport;
import com.alibaba.android.mnnkit.entity.MNNFlipType;
import com.alibaba.android.mnnkit.intf.InstanceCreatedListener;
import com.tsia.example.mnnkitdemo.R;

public class FaceDetectionImageActivity extends AppCompatActivity {

    private Paint KeyPointsPaint = new Paint();
    private Paint ScorePaint = new Paint();
    private Paint TextPaint = new Paint();

    private SurfaceHolder mDrawSurfaceHolder;

    private FaceDetector mFaceDetector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_face_detection_image);

        ActionBar actionBar = getSupportActionBar();
        if(actionBar != null){
            actionBar.setTitle("Face Detection-图片");
            actionBar.setHomeButtonEnabled(true);
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        KeyPointsPaint.setColor((Color.RED));
        KeyPointsPaint.setStyle(Paint.Style.FILL);
        KeyPointsPaint.setStrokeWidth(2);

        ScorePaint.setColor(Color.RED);
        ScorePaint.setStrokeWidth(2f);
        ScorePaint.setTextSize(40);

        TextPaint.setColor(Color.DKGRAY);
        TextPaint.setStrokeWidth(2f);
        TextPaint.setTextSize(58);

        SurfaceView drawView = findViewById(R.id.points_view);
        drawView.setZOrderOnTop(true);
        drawView.getHolder().setFormat(PixelFormat.TRANSPARENT);
        mDrawSurfaceHolder = drawView.getHolder();

        ImageView imageView = findViewById(R.id.imageView);
        imageView.setImageResource(R.mipmap.face_girl);

        FaceDetector.FaceDetectorCreateConfig createConfig = new FaceDetector.FaceDetectorCreateConfig();
        createConfig.mode = FaceDetector.FaceDetectMode.MOBILE_DETECT_MODE_IMAGE;
        FaceDetector.createInstanceAsync(this, createConfig, new InstanceCreatedListener<FaceDetector>() {
            @Override
            public void onSucceeded(FaceDetector faceDetector) {
                mFaceDetector = faceDetector;
            }

            @Override
            public void onFailed(int i, Error error) {
                Log.e(Common.TAG, "create face detetector failed: " + error);
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
        if (mFaceDetector==null) {
            Toast.makeText(this, R.string.initializing, Toast.LENGTH_LONG).show();
            return;
        }

        Bitmap bitmap = BitmapFactory.decodeResource(FaceDetectionImageActivity.this.getResources(), R.mipmap.face_girl);
        long start = System.currentTimeMillis();
        FaceDetectionReport[] results = mFaceDetector.inference(bitmap, 0, 0, 0, MNNFlipType.FLIP_NONE);

        DrawResult(results, bitmap, System.currentTimeMillis() - start);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.menu_face_image, menu);
        return super.onCreateOptionsMenu(menu);
    }

    private void DrawResult(FaceDetectionReport[] reports, Bitmap bitmap, long timeCost) {

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

            // 绘制人脸关键点
            for (int i=0; i<reports.length; i++) {

                FaceDetectionReport report = reports[i];

                for (int j=0; j<106; j++) {

                    float keyX = report.keyPoints[j*2];
                    float keyY = report.keyPoints[j*2 + 1];
                    canvas.drawCircle(keyX * kx, keyY * ky, 4.0f, KeyPointsPaint);
                }

                float left = report.rect.left;
                float top = report.rect.top;
                float right = report.rect.right;
                float bottom = report.rect.bottom;
                canvas.drawLine(left * kx, top * ky,
                        right * kx, top * ky, KeyPointsPaint);
                canvas.drawLine(right * kx, top * ky,
                        right * kx, bottom * ky, KeyPointsPaint);
                canvas.drawLine(right * kx, bottom * ky,
                        left * kx, bottom * ky, KeyPointsPaint);
                canvas.drawLine(left * kx, bottom * ky,
                        left * kx, top * ky, KeyPointsPaint);

                canvas.drawText(report.score+"", left * kx, top * ky-10, ScorePaint);
            }

            canvas.drawText(timeCost+" ms", 20, previewHeight+70, TextPaint);

        } catch (Throwable t) {
            Log.e(Common.TAG, "Draw result error:");
        } finally {
            if (canvas != null) {
                mDrawSurfaceHolder.unlockCanvasAndPost(canvas);
            }
        }

    }


    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (mFaceDetector!=null) {
            mFaceDetector.release();
        }
    }
}
