package com.alibaba.android.mnnkit.demo.view;

import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.Camera;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.alibaba.android.mnnkit.demo.utils.Common;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class CameraView extends SurfaceView implements SurfaceHolder.Callback, Camera.PreviewCallback {

    private static final int MINIMUM_PREVIEW_SIZE = 320;

    static private Camera mCamera;
    private static int mCameraId = Camera.CameraInfo.CAMERA_FACING_FRONT;
    private Camera.Parameters mParams;
    private Camera.Size mPreviewSize;
    private PreviewCallback mPreviewCallback;
    private int mOrientationAngle;

    public int previewCallbackFrequence;// frame callback frequence
    private int previewCallbackCount;

    private int minPreviewWidth;
    private int minPreviewHeight;

    private int mDeviecAutoRotateAngle;

    public static void resetCameraId() {
        releaseCamera();
        mCameraId = Camera.CameraInfo.CAMERA_FACING_FRONT;
    }

    public CameraView(Context context) {
        this(context, null);
    }

    public CameraView(Context context, AttributeSet attrs) {
        super(context, attrs);

//        mCameraId = Camera.CameraInfo.CAMERA_FACING_FRONT;
        previewCallbackFrequence = 1;

        minPreviewWidth = 800;
        minPreviewHeight = 800;

        SurfaceHolder holder = getHolder();
        holder.addCallback(this);
    }

    public void setPreviewCallback(CameraView.PreviewCallback previewCallback) {
        mPreviewCallback = previewCallback;
    }

    public void setMinPreviewSize(int minWidth, int minHeight) {

        minPreviewWidth = minWidth;
        minPreviewHeight = minHeight;
    }

    public Camera.Size getPreviewSize() {
        return mPreviewSize;
    }

    private void openCamera(SurfaceHolder holder) {
        // release Camera, if not release camera before call camera, it will be locked
        releaseCamera();

        mCamera = Camera.open(mCameraId);

        // set camera front/back
        setCameraDisplayOrientation((Activity) getContext(), mCameraId, mCamera);

        // set preview size
        mParams = mCamera.getParameters();
        mPreviewSize = getPropPreviewSize(mParams.getSupportedPreviewSizes(), minPreviewWidth, minPreviewHeight);
        mParams.setPreviewSize(mPreviewSize.width, mPreviewSize.height);

        // set format
        mParams.setPreviewFormat(ImageFormat.NV21);
        if (mCameraId == Camera.CameraInfo.CAMERA_FACING_BACK) {
            mParams.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO);
        }

        mCamera.setParameters(mParams);

        if (mPreviewCallback != null) {
            mPreviewCallback.onGetPreviewOptimalSize(mPreviewSize.width, mPreviewSize.height, mOrientationAngle, mDeviecAutoRotateAngle);
        }

        try {
            mCamera.setPreviewDisplay(holder);
        } catch (IOException e) {
            e.printStackTrace();
        }
        mCamera.setPreviewCallback(this);
        mCamera.startPreview();
    }

    static private synchronized void releaseCamera() {
        if (mCamera != null) {
            try {
                mCamera.setPreviewCallback(null);
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                mCamera.stopPreview();
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                mCamera.release();
            } catch (Exception e) {
                e.printStackTrace();
            }
            mCamera = null;
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder surfaceHolder) {
        Log.i(Common.TAG, "surfaceCreated");

        openCamera(surfaceHolder);
    }

    @Override
    public void surfaceChanged(SurfaceHolder surfaceHolder, int i, int i1, int i2) {
        Log.i(Common.TAG, "surfaceChanged");
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder surfaceHolder) {
        Log.i(Common.TAG, "surfaceDestroyed");
    }

    public void switchCamera() {
        mCameraId = mCameraId==Camera.CameraInfo.CAMERA_FACING_FRONT ? Camera.CameraInfo.CAMERA_FACING_BACK : Camera.CameraInfo.CAMERA_FACING_FRONT;
        openCamera(getHolder());
    }

    public boolean isFrontCamera() {
        return Camera.CameraInfo.CAMERA_FACING_FRONT==mCameraId;
    }

    public void setCameraDisplayOrientation(Activity activity, int cameraId, Camera camera) {
        Camera.CameraInfo info =
                new Camera.CameraInfo();
        Camera.getCameraInfo(cameraId, info);
        int rotation = activity.getWindowManager().getDefaultDisplay()
                .getRotation();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0:
                degrees = 0;
                break;
            case Surface.ROTATION_90:
                degrees = 90;
                break;
            case Surface.ROTATION_180:
                degrees = 180;
                break;
            case Surface.ROTATION_270:
                degrees = 270;
                break;
            default:
                degrees = 0;
                break;
        }

        mDeviecAutoRotateAngle = degrees;

        mOrientationAngle = info.orientation;

        int result;
        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (info.orientation + degrees) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (info.orientation - degrees + 360) % 360;
        }
        camera.setDisplayOrientation(result);
    }

    public void onResume() {
        openCamera(getHolder());
    }

    public void onPause() {
        releaseCamera();
    }

    @Override
    public void onPreviewFrame(byte[] bytes, Camera camera) {

        previewCallbackCount++;
        if (previewCallbackCount % previewCallbackFrequence != 0) {
            return;
        }
        previewCallbackCount = 0;

        if (mPreviewCallback!=null) {
            mPreviewCallback.onPreviewFrame(bytes, mPreviewSize.width, mPreviewSize.height, mOrientationAngle);
        }
    }

    /**
     * Given choices supported by a camera, chooses the smallest one whose
     * width and height are at least as large as the minimum of both, or an exact match if possible.
     *
     * @param choices   The list of sizes that the camera supports for the intended output class
     * @param minWidth  The minimum desired width
     * @param minHeight The minimum desired height
     * @return The optimal size, or an arbitrary one if none were big enough
     */
    private Camera.Size getPropPreviewSize(List<Camera.Size> choices, int minWidth, int minHeight) {
        final int minSize = Math.max(Math.min(minWidth, minHeight), MINIMUM_PREVIEW_SIZE);

        final List<Camera.Size> bigEnough = new ArrayList<Camera.Size>();
        final List<Camera.Size> tooSmall = new ArrayList<Camera.Size>();

        for (Camera.Size option : choices) {
            if (option.width == minWidth && option.height == minHeight) {
                return option;
            }

            if (option.height >= minSize && option.width >= minSize) {
                bigEnough.add(option);
            } else {
                tooSmall.add(option);
            }
        }

        if (bigEnough.size() > 0) {
            Camera.Size chosenSize = Collections.min(bigEnough, new CompareSizesByArea());
            return chosenSize;
        } else {
            return choices.get(0);
        }
    }


    public interface PreviewCallback {
        // preview size callback when created
        void onGetPreviewOptimalSize(int optimalWidth, int optimalHeight, int cameraOrientation, int deviecAutoRotateAngle);
        // preview callback
        void onPreviewFrame(byte[] data, int width, int height, int cameraOrientation);
    }

    // Compares two size based on their areas.
    static class CompareSizesByArea implements Comparator<Camera.Size> {
        @Override
        public int compare(final Camera.Size lhs, final Camera.Size rhs) {
            return Long.signum(
                    (long) lhs.width * lhs.height - (long) rhs.width * rhs.height);
        }
    }

}
