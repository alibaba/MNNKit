package com.alibaba.android.mnnkit.demo;

import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.view.ViewStub;
import android.view.Window;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.alibaba.android.mnnkit.actor.HandGestureDetector;
import com.alibaba.android.mnnkit.demo.utils.Common;
import com.alibaba.android.mnnkit.demo.view.CameraView;
import com.alibaba.android.mnnkit.entity.HandGestureDetectionReport;
import com.alibaba.android.mnnkit.entity.MNNCVImageFormat;
import com.alibaba.android.mnnkit.entity.MNNFlipType;
import com.alibaba.android.mnnkit.intf.InstanceCreatedListener;
import com.tsia.example.mnnkitdemo.R;

public class HandGestureDetectionActivity extends VideoBaseActivity {

    HandGestureDetector mHandGestureDetector;

    protected CameraView mCameraView;

    protected int mActualPreviewWidth;
    protected int mActualPreviewHeight;

    private SurfaceHolder mDrawSurfaceHolder;

    Paint LinePaint = new Paint();
    Paint LablePaint = new Paint();

    private TextView mTimeCost;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        setContentView(R.layout.activity_hand_gesture_detection);

        LinePaint.setColor((Color.WHITE));
        LinePaint.setStyle(Paint.Style.FILL);
        LinePaint.setStrokeWidth(2);

        LablePaint.setColor(Color.WHITE);
        LablePaint.setStrokeWidth(2f);
        LablePaint.setTextSize(40);
    }


    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {
            case R.id.action_switch_camera:
                mCameraView.switchCamera();
                break;

            case R.id.action_image:
                startActivity(new Intent(this, HandGestureDetectionImageActivity.class));
                break;

            default:
                break;
        }

        return super.onOptionsItemSelected(item);
    }


    @Override
    void createKitInstance() {

        HandGestureDetector.HandCreateConfig createConfig = new HandGestureDetector.HandCreateConfig();
        createConfig.mode = HandGestureDetector.HandDetectMode.HAND_DETECT_MODE_VIDEO;
        HandGestureDetector.createInstanceAsync(this, createConfig, new InstanceCreatedListener<HandGestureDetector>() {
            @Override
            public void onSucceeded(HandGestureDetector handGestureDetector) {
                mHandGestureDetector = handGestureDetector;
            }

            @Override
            public void onFailed(int i, Error error) {
                Log.e(Common.TAG, "create hand gesture detetector failed: " + error);
            }
        });
    }

    @Override
    void doRun() {
        ViewStub stub = findViewById(R.id.viewStub);
        stub.setLayoutResource(R.layout.activity_hand_gesture_detection);
        stub.inflate();

        mCameraView = findViewById(R.id.camera_view);

        final SurfaceView drawView = findViewById(R.id.points_view);
        drawView.setZOrderOnTop(true);
        drawView.getHolder().setFormat(PixelFormat.TRANSPARENT);
        mDrawSurfaceHolder = drawView.getHolder();

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
                int screenH = metric.heightPixels;

                int contentTop = getWindow().findViewById(Window.ID_ANDROID_CONTENT).getTop();
                Rect frame = new Rect();
                getWindow().getDecorView().getWindowVisibleDisplayFrame(frame);
                int statusBarHeight = frame.top;

                RelativeLayout layoutVideo = findViewById(R.id.handVideoLayout);
                FrameLayout frameLayout = layoutVideo.findViewById(R.id.handVideoContentLayout);

                if (deviecAutoRotateAngle==0 || deviecAutoRotateAngle==180) {

                    int fixedScreenH = screenW * h / w;// 宽度不变，等比缩放的高度

                    ViewGroup.LayoutParams params = frameLayout.getLayoutParams();
                    params.height = fixedScreenH;
                    frameLayout.setLayoutParams(params);

                    mActualPreviewWidth = screenW;
                    mActualPreviewHeight = fixedScreenH;
                } else {

                    int previewHeight = screenH-contentTop-statusBarHeight;
                    int fixedScreenW = previewHeight * h / w;// 高度不变，等比缩放的宽

                    ViewGroup.LayoutParams params = frameLayout.getLayoutParams();
                    params.width = fixedScreenW;
                    frameLayout.setLayoutParams(params);

                    mActualPreviewWidth = fixedScreenW;
                    mActualPreviewHeight = previewHeight;
                }

            }

            @Override
            public void onPreviewFrame(byte[] data, int width, int height, int cameraOrientation) {
                if (mHandGestureDetector==null) {
                    return;
                }

                // 输入角度
                int inAngle = mCameraView.isFrontCamera()?(cameraOrientation+360-rotateDegree)%360:(cameraOrientation+rotateDegree)%360;
                // 输出角度
                int outAngle = 0;
                if (!screenAutoRotate()) {
                    outAngle = mCameraView.isFrontCamera()?(360-rotateDegree)%360:rotateDegree%360;
                }

                long start = System.currentTimeMillis();
                HandGestureDetectionReport[] results = mHandGestureDetector.inference(data, width, height, MNNCVImageFormat.YUV_NV21, inAngle, outAngle, mCameraView.isFrontCamera()? MNNFlipType.FLIP_Y:MNNFlipType.FLIP_NONE);

                String timeCostText = "0 ms";
                if (results!=null && results.length>0) {
                    long eltime = (System.currentTimeMillis() - start);
                    String tmpeltime = "";
                    if (eltime != 0) {
                        tmpeltime = +1000 / eltime + "fps ";
                    }
                    timeCostText = (eltime)+" ms" + tmpeltime;
                }

                mTimeCost.setText(timeCostText);

                drawLines(results, cameraOrientation);
            }
        });

    }

    @Override
    String actionBarTitle() {
        return getString(R.string.gesture_detection);
    }

    void drawLines(HandGestureDetectionReport[] reports, int cameraOrientation) {

        Canvas canvas = null;
        try {
            canvas = mDrawSurfaceHolder.lockCanvas();
            if (canvas == null) {
                return;
            }
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);

            for (int i=0;i<reports.length;i++) {
                HandGestureDetectionReport report = reports[i];
                float left = report.rect.left;
                float top = report.rect.top;
                float right = report.rect.right;
                float bottom = report.rect.bottom;

                float kx = 0.0f, ky = 0.0f;

                // 这里只写了摄像头正向为90/270度的一般情况，如果有other情况，自行枚举
                if(90 == cameraOrientation || 270 == cameraOrientation){

                    if (!screenAutoRotate()) {
                        kx = (float) mActualPreviewWidth/mCameraView.getPreviewSize().height;
                        ky = (float) mActualPreviewHeight/mCameraView.getPreviewSize().width;
                    } else {

                        if ((0 == rotateDegree) || (180 == rotateDegree)) {// 屏幕竖直方向翻转
                            kx = (float) mActualPreviewWidth/mCameraView.getPreviewSize().height;
                            ky = (float) mActualPreviewHeight/mCameraView.getPreviewSize().width;
                        } else if(90 == rotateDegree || 270 == rotateDegree){// 屏幕水平方向翻转
                            kx = (float) mActualPreviewWidth/mCameraView.getPreviewSize().width;
                            ky = (float) mActualPreviewHeight/mCameraView.getPreviewSize().height;
                        }
                    }
                }

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

        if (mHandGestureDetector!=null) {
            mHandGestureDetector.release();
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

}
