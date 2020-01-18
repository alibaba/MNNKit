
#include <jni.h>
#include <unistd.h>
#include <iostream>
#include <memory>
#include <stdio.h>


extern "C"

JNIEXPORT jintArray JNICALL
Java_com_alibaba_android_mnnkit_demo_PortraitSegmentationActivity_nativeConvertMaskToPixels(JNIEnv *env, jclass jclazz, jfloatArray jmaskarray, jint length){

    float *scores = env->GetFloatArrayElements(jmaskarray, 0);

    int dst32[length];
    for(int x = 0; x < length; x++) {
        unsigned a = (unsigned)(255.f-(scores[x]*255.f));
        unsigned r = 255;
        unsigned g = 255;
        unsigned b = 255;
        // ARGB
        dst32[x] = a << 24 | r << 16 | g << 8 | b;
    }

    jintArray pixels = env->NewIntArray(length);
    env->SetIntArrayRegion(pixels, 0, length, dst32);

    env->ReleaseFloatArrayElements(jmaskarray, scores, 0);

    return pixels;
}
