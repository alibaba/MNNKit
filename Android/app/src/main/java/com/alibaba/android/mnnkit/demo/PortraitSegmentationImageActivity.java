package com.alibaba.android.mnnkit.demo;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
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

import com.alibaba.android.mnnkit.actor.PortraitSegmentor;
import com.alibaba.android.mnnkit.demo.utils.Common;
import com.alibaba.android.mnnkit.entity.MNNFlipType;
import com.alibaba.android.mnnkit.intf.InstanceCreatedListener;
import com.tsia.example.mnnkitdemo.R;

public class PortraitSegmentationImageActivity extends AppCompatActivity {

    public static final float MASK_WIDTH = 216.f;
    public static final float MASK_HEIGHT = 384.f;

    private Paint TextPaint = new Paint();

    private SurfaceHolder mDrawSurfaceHolder;

    private PortraitSegmentor mPortraitSegmentor;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_portrait_segmentation_image);

        ActionBar actionBar = getSupportActionBar();
        if(actionBar != null){
            actionBar.setTitle("Portrait segmentation-图片");
            actionBar.setHomeButtonEnabled(true);
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        TextPaint.setColor(Color.DKGRAY);
        TextPaint.setStrokeWidth(2f);
        TextPaint.setTextSize(58);

        SurfaceView drawView = findViewById(R.id.points_view);
        drawView.setZOrderOnTop(true);
        drawView.getHolder().setFormat(PixelFormat.TRANSPARENT);
        mDrawSurfaceHolder = drawView.getHolder();

        ImageView imageView = findViewById(R.id.imageView);
        imageView.setImageResource(R.mipmap.portrait_girl);

        PortraitSegmentor.createInstanceAsync(this, new InstanceCreatedListener<PortraitSegmentor>() {
            @Override
            public void onSucceeded(PortraitSegmentor portraitSegmentor) {
                mPortraitSegmentor = portraitSegmentor;
            }

            @Override
            public void onFailed(int i, Error error) {
                Log.e(Common.TAG, "create portrait segmentor failed: " + error);
            }
        });
    }

    void drawMaskBitmap(Bitmap orgBmp, Bitmap maskBmp, long timeCost) {

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

            int imgW = orgBmp.getWidth();
            int imgH = orgBmp.getHeight();

            int previewWidth = screenW;
            int previewHeight  = (int) (screenW*imgH/(float)imgW);

            Matrix matrix = new Matrix();
            matrix.postScale(previewWidth/MASK_WIDTH, previewHeight/MASK_HEIGHT);

            Paint paint = new Paint();
            paint.setColor((Color.WHITE));

            canvas.drawBitmap(maskBmp, matrix, paint);

            canvas.drawText(timeCost+" ms", 20, previewHeight+70, TextPaint);

        } catch (Throwable t) {
            Log.e(Common.TAG, "Draw result error:" + t);
        } finally {
            if (canvas != null) {
                mDrawSurfaceHolder.unlockCanvasAndPost(canvas);
            }
        }

    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                this.finish();
                return true;

            case R.id.action_start:
                doSegment();
                return true;

            default:
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.menu_portrait_image, menu);
        return super.onCreateOptionsMenu(menu);
    }

    void doSegment() {

        if (mPortraitSegmentor==null) {
            Toast.makeText(this, R.string.initializing, Toast.LENGTH_LONG).show();
            return;
        }

        Bitmap bitmap = BitmapFactory.decodeResource(PortraitSegmentationImageActivity.this.getResources(), R.mipmap.portrait_girl);

        long start = System.currentTimeMillis();
        float[] maskResults = mPortraitSegmentor.inference(bitmap, MNNFlipType.FLIP_NONE);
        long timeCost = System.currentTimeMillis() - start;

        int[] pixels = PortraitSegmentationActivity.nativeConvertMaskToPixels(maskResults, maskResults.length);
        Bitmap maskbmp = Bitmap.createBitmap(pixels, 0, (int)MASK_WIDTH, (int)MASK_WIDTH, (int)MASK_HEIGHT, Bitmap.Config.ARGB_8888);

        drawMaskBitmap(bitmap, maskbmp, timeCost);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (mPortraitSegmentor!=null) {
            mPortraitSegmentor.release();
        }
    }
}
