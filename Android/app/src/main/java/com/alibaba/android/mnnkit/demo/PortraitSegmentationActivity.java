package com.alibaba.android.mnnkit.demo;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.view.ViewStub;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.alibaba.android.mnnkit.actor.PortraitSegmentor;
import com.alibaba.android.mnnkit.demo.utils.Common;
import com.alibaba.android.mnnkit.demo.view.CameraView;
import com.alibaba.android.mnnkit.entity.MNNCVImageFormat;
import com.alibaba.android.mnnkit.entity.MNNFlipType;
import com.alibaba.android.mnnkit.intf.InstanceCreatedListener;
import com.tsia.example.mnnkitdemo.R;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

public class PortraitSegmentationActivity extends VideoBaseActivity {

    public static final float MASK_WIDTH = 216.f;
    public static final float MASK_HEIGHT = 384.f;

    protected CameraView mCameraView;
    private TextView mTimeCost;

    PortraitSegmentor mPortraitSegmentor;

    private SurfaceHolder mDrawSurfaceHolder;

    protected int mActualPreviewWidth;
    protected int mActualPreviewHeight;

    static {
        try {
            System.loadLibrary("kitdemo-lib");
        } catch (Throwable e) {
            Log.e("AliNNDemo", "load native-lib.so exception=%s", e);
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        setContentView(R.layout.activity_portrait_segmentation);

    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {
            case R.id.action_switch_camera:
                mCameraView.switchCamera();
                break;

            case R.id.action_image:
                startActivity(new Intent(this, PortraitSegmentationImageActivity.class));
                break;

            default:
                break;
        }

        return super.onOptionsItemSelected(item);
    }


    @Override
    void createKitInstance() {

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

    @Override
    void doRun() {

        ViewStub stub = findViewById(R.id.viewStub);
        stub.setLayoutResource(R.layout.activity_portrait_segmentation);
        stub.inflate();

        final SurfaceView drawView = findViewById(R.id.mask_view);
        drawView.setZOrderOnTop(true);
        drawView.getHolder().setFormat(PixelFormat.TRANSPARENT);
        mDrawSurfaceHolder = drawView.getHolder();

        mCameraView = findViewById(R.id.camera_view);
        mCameraView.setMinPreviewSize(600, 600);

        mTimeCost = findViewById(R.id.costTime);

        mCameraView.setPreviewCallback(new CameraView.PreviewCallback() {
            @Override
            public void onGetPreviewOptimalSize(int optimalWidth, int optimalHeight, int cameraOrientation, int deviecAutoRotateAngle) {

                // w为图像短边，h为长边
                int w = optimalWidth;
                int h = optimalHeight;
                if (cameraOrientation==90 || cameraOrientation==270) {
                    w = optimalHeight;
                    h = optimalWidth;
                }

                // 屏幕长宽
                DisplayMetrics metric = new DisplayMetrics();
                getWindowManager().getDefaultDisplay().getMetrics(metric);
                int screenW = metric.widthPixels;

                int fixedVideoHeight = screenW * h / w;

                RelativeLayout layoutVideo = findViewById(R.id.portraitVideoLayout);
                FrameLayout frameLayout = layoutVideo.findViewById(R.id.portraitVideoContentLayout);
                ViewGroup.LayoutParams params = frameLayout.getLayoutParams();
                params.height = fixedVideoHeight;
                frameLayout.setLayoutParams(params);

                mActualPreviewWidth = metric.widthPixels;
                mActualPreviewHeight = fixedVideoHeight;
            }

            @Override
            public void onPreviewFrame(byte[] data, int width, int height, int cameraOrientation) {
                if (mPortraitSegmentor == null) {
                    return;
                }

                // 输入角度
                int inAngle = mCameraView.isFrontCamera() ? (cameraOrientation + 360 - rotateDegree) % 360 : (cameraOrientation + rotateDegree) % 360;

                long start = System.currentTimeMillis();
                float[] maskResults = mPortraitSegmentor.inference(data, width, height, MNNCVImageFormat.YUV_NV21, inAngle, mCameraView.isFrontCamera() ? MNNFlipType.FLIP_Y : MNNFlipType.FLIP_NONE);
                long eltime = (System.currentTimeMillis() - start);
                String tmpeltime = "";
                if (eltime != 0) {
                    tmpeltime = +1000 / eltime + "fps ";
                }
                mTimeCost.setText((eltime)+" ms" + tmpeltime);

                if (maskResults==null || maskResults.length!=MASK_WIDTH*MASK_HEIGHT) {
                    return;
                }

                int[] pixels = nativeConvertMaskToPixels(maskResults, maskResults.length);
                Bitmap maskbmp = Bitmap.createBitmap(pixels, 0, (int)MASK_WIDTH, (int)MASK_WIDTH, (int)MASK_HEIGHT, Bitmap.Config.ARGB_8888);

                drawMaskBitmap(maskbmp);
            }
        });

    }

    @Override
    String actionBarTitle() {
        return getString(R.string.portrait_segmentation);
    }


    void drawMaskBitmap(Bitmap bmp) {

        Canvas canvas = null;

        try {
            canvas = mDrawSurfaceHolder.lockCanvas();
            if (canvas == null) {
                return;
            }
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);

            Matrix matrix = new Matrix();
            matrix.postScale(mActualPreviewWidth/MASK_WIDTH, mActualPreviewHeight/MASK_HEIGHT);

            Paint paint = new Paint();
            paint.setColor((Color.WHITE));

            canvas.drawBitmap(bmp, matrix, paint);

        } catch (Throwable t) {
            Log.e(Common.TAG, "Draw result error:" + t);
        } finally {
            if (canvas != null) {
                mDrawSurfaceHolder.unlockCanvasAndPost(canvas);
            }
        }

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (mPortraitSegmentor!=null) {
            mPortraitSegmentor.release();
        }
    }

    native static int[] nativeConvertMaskToPixels(float[] mask, int length);
}
