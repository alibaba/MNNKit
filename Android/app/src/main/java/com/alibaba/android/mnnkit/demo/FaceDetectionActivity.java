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
import android.widget.Switch;
import android.widget.TextView;

import com.alibaba.android.mnnkit.actor.FaceDetector;
import com.alibaba.android.mnnkit.demo.utils.Common;
import com.alibaba.android.mnnkit.demo.view.CameraView;
import com.alibaba.android.mnnkit.entity.FaceDetectConfig;
import com.alibaba.android.mnnkit.entity.FaceDetectionReport;
import com.alibaba.android.mnnkit.entity.MNNCVImageFormat;
import com.alibaba.android.mnnkit.entity.MNNFlipType;
import com.alibaba.android.mnnkit.intf.InstanceCreatedListener;
import com.tsia.example.mnnkitdemo.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class FaceDetectionActivity extends VideoBaseActivity {

    private SurfaceHolder mDrawSurfaceHolder;
    protected CameraView mCameraView;

    private Switch mOrderSwitch;
    private TextView mTimeCost;
    private TextView mFaceAction;
    private TextView mYPR;

    // 当前渲染画布的尺寸
    protected int mActualPreviewWidth;
    protected int mActualPreviewHeight;

    private FaceDetector mFaceDetector;

    private Paint KeyPointsPaint = new Paint();
    private Paint PointOrderPaint = new Paint();
    private Paint ScorePaint = new Paint();

    private final static int MAX_RESULT = 10;
    private float[] scores = new float[MAX_RESULT];// 置信度
    private float[] rects = new float[MAX_RESULT * 4];// 矩形区域
    private float[] keypts = new float[MAX_RESULT * 2 * 106];// 脸106关键点

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        KeyPointsPaint.setColor((Color.WHITE));
        KeyPointsPaint.setStyle(Paint.Style.FILL);
        KeyPointsPaint.setStrokeWidth(2);

        PointOrderPaint.setColor(Color.GREEN);
        PointOrderPaint.setStyle(Paint.Style.STROKE);
        PointOrderPaint.setStrokeWidth(2f);
        PointOrderPaint.setTextSize(18);

        ScorePaint.setColor(Color.WHITE);
        ScorePaint.setStrokeWidth(2f);
        ScorePaint.setTextSize(40);

    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {
            case R.id.action_switch_camera:
                mCameraView.switchCamera();
                break;

            case R.id.action_image:
                startActivity(new Intent(this, FaceDetectionImageActivity.class));
                break;

            default:
                break;
        }

        return super.onOptionsItemSelected(item);
    }


    @Override
    void createKitInstance() {

        FaceDetector.FaceDetectorCreateConfig createConfig = new FaceDetector.FaceDetectorCreateConfig();
        createConfig.mode = FaceDetector.FaceDetectMode.MOBILE_DETECT_MODE_VIDEO;
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
    String actionBarTitle() {
        return getString(R.string.face_detection);
    }

    @Override
    void doRun() {

        ViewStub stub = findViewById(R.id.viewStub);
        stub.setLayoutResource(R.layout.activity_face_detection);
        stub.inflate();

        // point view
        SurfaceView drawView = findViewById(R.id.points_view);
        drawView.setZOrderOnTop(true);
        drawView.getHolder().setFormat(PixelFormat.TRANSPARENT);
        mDrawSurfaceHolder = drawView.getHolder();

        // Order
        mOrderSwitch = findViewById(R.id.swPointOrder);
        mTimeCost = findViewById(R.id.costTime);
        mFaceAction = findViewById(R.id.faceAction);
        mYPR = findViewById(R.id.ypr);

        mCameraView = findViewById(R.id.camera_view);

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

                RelativeLayout layoutVideo = findViewById(R.id.videoLayout);
                FrameLayout frameLayout = layoutVideo.findViewById(R.id.videoContentLayout);
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

                    // re layout
                    RelativeLayout.LayoutParams componentLayoutParams = new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
                    componentLayoutParams.addRule(RelativeLayout.RIGHT_OF, R.id.videoContentLayout);

                    RelativeLayout componentLayout  = findViewById(R.id.componentLayout);
                    componentLayout.setLayoutParams(componentLayoutParams);

                    RelativeLayout.LayoutParams yprLayoutParams = new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
                    yprLayoutParams.addRule(RelativeLayout.BELOW, R.id.costTime);
                    mYPR.setPadding(24,0,0,0);
                    mYPR.setLayoutParams(yprLayoutParams);

                    RelativeLayout.LayoutParams faceActionLayoutParams = new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
                    faceActionLayoutParams.addRule(RelativeLayout.BELOW, R.id.ypr);
                    mFaceAction.setPadding(24,0,0,0);
                    mFaceAction.setLayoutParams(faceActionLayoutParams);
                }

            }

            @Override
            public void onPreviewFrame(byte[] data, int width, int height, int cameraOrientation) {
                if (mFaceDetector==null) {
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
                long detectConfig = FaceDetectConfig.ACTIONTYPE_EYE_BLINK| FaceDetectConfig.ACTIONTYPE_MOUTH_AH|FaceDetectConfig.ACTIONTYPE_HEAD_YAW|FaceDetectConfig.ACTIONTYPE_HEAD_PITCH|FaceDetectConfig.ACTIONTYPE_BROW_JUMP;
                FaceDetectionReport[] results = mFaceDetector.inference(data, width, height, MNNCVImageFormat.YUV_NV21, detectConfig, inAngle, outAngle, mCameraView.isFrontCamera()? MNNFlipType.FLIP_Y:MNNFlipType.FLIP_NONE);

                String timeCostText = "0 ms";
                String yprText = "";
                String faceActionText = "";

                int faceCount = 0;
                if (results!=null && results.length>0) {
                    faceCount = results.length;

                    // time cost
                    long eltime = (System.currentTimeMillis() - start);
                    String tmpeltime = "";
                    if (eltime != 0) {
                        tmpeltime = +1000 / eltime + "fps ";
                    }
                    timeCostText = eltime + "ms " + tmpeltime;
                    // ypr
                    FaceDetectionReport firstReport = results[0];
                    yprText =
                            "yaw: " + firstReport.yaw + "\npitch: " + firstReport.pitch + "\nroll: " + firstReport.roll + "\n";

                    for (int i = 0; i < results.length && i < MAX_RESULT; i++) {
                        // key points
                        System.arraycopy(results[i].keyPoints, 0, keypts, i * 106 * 2, 106 * 2);
                        // face rect
                        rects[i * 4] = results[i].rect.left;
                        rects[i * 4 + 1] = results[i].rect.top;
                        rects[i * 4 + 2] = results[i].rect.right;
                        rects[i * 4 + 3] = results[i].rect.bottom;
                        // score
                        scores[i] = results[i].score;
                    }

                    faceActionText = faceActionDesc(firstReport.faceActionMap);

                }

                mTimeCost.setText(timeCostText);
                mYPR.setText(yprText);
                mFaceAction.setText(faceActionText);

                DrawResult(scores, rects, keypts, faceCount, cameraOrientation, rotateDegree);
            }

        });

    }

    private String faceActionDesc(Map<String, Boolean> faceActionMap) {

        String desc = "";
        if (faceActionMap.size()==0) {
            return desc;
        }

        List<String> actions = new ArrayList<>();

        for (Map.Entry<String, Boolean> entry : faceActionMap.entrySet()) {
            System.out.println("Key = " + entry.getKey() + ", Value = " + entry.getValue());

            Boolean bActing = entry.getValue();
            if (!bActing) continue;

            if (entry.getKey().equals("HeadYaw")) {
                actions.add("HeadYaw");
            }
            if (entry.getKey().equals("BrowJump")) {
                actions.add("BrowJump");
            }
            if (entry.getKey().equals("EyeBlink")) {
                actions.add("EyeBlink");
            }
            if (entry.getKey().equals("MouthAh")) {
                actions.add("MouthAh");
            }
            if (entry.getKey().equals("HeadPitch")) {
                actions.add("HeadPitch");
            }
        }

        for (int i=0; i<actions.size(); i++) {
            String action = actions.get(i);
            if (i>0) {
                desc += "、"+action;
                continue;
            }
            desc = action;
        }

        return desc;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (mFaceDetector!=null) {
            mFaceDetector.release();
        }
    }

    private void DrawResult(float[] scores, float[] rects, float[] facePoints,
                            int faceCount , int cameraOrientation, int rotateDegree) {
        Canvas canvas = null;
        try {
            canvas = mDrawSurfaceHolder.lockCanvas();
            if (canvas == null) {
                return;
            }
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);

            float kx = 0.0f, ky = 0.0f;

            // 这里只写了摄像头正向为90/270度的一般情况，如果有other情况，自行枚举
            if(90 == cameraOrientation || 270 == cameraOrientation){

                if (!screenAutoRotate()) {
                    kx = ((float) mActualPreviewWidth)/mCameraView.getPreviewSize().height;
                    ky = (float) mActualPreviewHeight/mCameraView.getPreviewSize().width;
                } else {

                    if ((0 == rotateDegree) || (180 == rotateDegree)) {// 屏幕竖直方向翻转
                        kx = ((float) mActualPreviewWidth)/mCameraView.getPreviewSize().height;
                        ky = ((float) mActualPreviewHeight)/mCameraView.getPreviewSize().width;
                    } else if(90 == rotateDegree || 270 == rotateDegree){// 屏幕水平方向翻转
                        kx = ((float) mActualPreviewWidth)/mCameraView.getPreviewSize().width;
                        ky = ((float) mActualPreviewHeight)/mCameraView.getPreviewSize().height;
                    }
                }
            }

            // 绘制人脸关键点
            for (int i=0; i<faceCount; i++) {
                for (int j=0; j<106; j++) {
                    float keyX = facePoints[i*106*2 + j*2];
                    float keyY = facePoints[i*106*2 + j*2 + 1];
                    canvas.drawCircle(keyX * kx, keyY * ky, 4.0f, KeyPointsPaint);
                    if (mOrderSwitch.isChecked()) {
                        canvas.drawText(j+"", keyX * kx, keyY * ky, PointOrderPaint); //标注106点的索引位置
                    }
                }

                float left = rects[0];
                float top = rects[1];
                float right = rects[2];
                float bottom = rects[3];
                canvas.drawLine(left * kx, top * ky,
                        right * kx, top * ky, KeyPointsPaint);
                canvas.drawLine(right * kx, top * ky,
                        right * kx, bottom * ky, KeyPointsPaint);
                canvas.drawLine(right * kx, bottom * ky,
                        left * kx, bottom * ky, KeyPointsPaint);
                canvas.drawLine(left * kx, bottom * ky,
                        left * kx, top * ky, KeyPointsPaint);


                canvas.drawText(scores[i]+"", left * kx, top * ky-10, ScorePaint);
            }

        } catch (Throwable t) {
            Log.e(Common.TAG, "Draw result error: %s", t);
        } finally {
            if (canvas != null) {
                mDrawSurfaceHolder.unlockCanvasAndPost(canvas);
            }
        }
    }

}
