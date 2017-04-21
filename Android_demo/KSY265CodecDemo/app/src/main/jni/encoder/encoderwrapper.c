#include <jni.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include "x264.h"
#include "qy265enc.h"
#include "qy265def.h"
#include "encoderwrapper.h"
#include "log.h"

#define LOG_TAG "encoder"

typedef struct Encoder {
    FILE* in_file;
    float real_fps;
    float real_time;
    double avg_psnr;
    int frame_num;
} Encoder;

static inline Encoder* getInstance(jlong ptr)
{
    return (Encoder*)(intptr_t) ptr;
}

jlong Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1init
        (JNIEnv *env,
         jobject instance) {

    Encoder* thiz = (Encoder*)calloc(1, sizeof(Encoder));
    thiz->real_fps = 0;
    thiz->frame_num = 0;
    thiz->avg_psnr = 0;
    thiz->real_time =0;

    return (jlong)(intptr_t)thiz;
}

jint Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1open
        (JNIEnv *env,
         jobject instance,
         jlong ptr,
         jstring path_) {
    const char *path = (*env)->GetStringUTFChars(env, path_, 0);

    Encoder* thiz = getInstance(ptr);
    thiz->in_file = fopen(path, "r");
    if (NULL == thiz->in_file) {
        LOGD("open file failed with %d", errno);
        (*env)->ReleaseStringUTFChars(env, path_, path);
        return -1;
    }
    thiz->real_fps = 0;
    thiz->frame_num = 0;
    thiz->avg_psnr = 0;
    thiz->real_time =0;

    (*env)->ReleaseStringUTFChars(env, path_, path);
    return 0;
}

jint Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1x264_1encode
        (JNIEnv *env,
         jobject instance,
         jlong ptr,
         jstring path_,
         jstring profile_,
         jstring delay_,
         jint width,
         jint height,
         jobject fps,
         jint bitrate,
         jint threads) {
    const char *path = (*env)->GetStringUTFChars(env, path_, 0);
    const char *profile = (*env)->GetStringUTFChars(env, profile_, 0);
    const char *delay = (*env)->GetStringUTFChars(env, delay_, 0);

    Encoder* thiz = getInstance(ptr);

    x264_param_t param;
    x264_picture_t pic;
    x264_picture_t pic_out;
    x264_t *h;

    int i_frame = 0;
    int i_frame_size;
    x264_nal_t *nal;
    int i_nal;
    clock_t clock_start, clock_end, clock_used;
    struct timeval tv_start, tv_end;
    double real_time;
    int64_t ms_used;
    FILE *out_file;

    double sum_psnr_y = 0.0;
    double sum_psnr_u = 0.0;
    double sum_psnr_v = 0.0;

    if ( NULL != path ) {
        out_file = fopen(path, "wb");
        if ( NULL == out_file ) {
            LOGE("open output file failed with %d", errno);
            fclose(thiz->in_file);

            (*env)->ReleaseStringUTFChars(env, path_, path);
            (*env)->ReleaseStringUTFChars(env, profile_, profile);
            (*env)->ReleaseStringUTFChars(env, delay_, delay);
            return -1;
        }
    }

    LOGD("profile %s", profile);
    /* Get default params for preset/tuning */
    if (strlen(delay) == 11 && strncmp(delay, "zerolatency", 11)) {
        if( x264_param_default_preset( &param, profile, "zerolatency" ) < 0 )
        goto fail;
    } else {
        if( x264_param_default_preset( &param, profile, NULL ) < 0 )
        goto fail;
    }

    /* Configure non-default params */
    param.i_csp = X264_CSP_I420;
    param.i_width  = width;
    param.i_height = height;
    param.b_vfr_input = 0;
    param.b_repeat_headers = 1;
    param.b_annexb = 1;

    if (strlen(delay) == 11 && strncmp(delay, "zerolatency", 11)) {
        param.i_bframe = 0;
    } else if (strlen(delay) == 13 && strncmp(delay, "livestreaming", 13)) {
        param.i_bframe = 3;
    } else if (strlen(delay) == 7 && strncmp(delay, "offline", 7)) {
        param.i_bframe = 7;
    }

    param.i_threads = threads;
    jclass floatClass = (*env)->FindClass(env, "java/lang/Float");
    jmethodID floatMethod = (*env)->GetMethodID(env, floatClass, "floatValue", "()F");
    jfloat val = (*env)->CallFloatMethod(env, fps, floatMethod);
    LOGD("x264 fps %.6f", val);
    param.i_fps_num = val;
    param.i_fps_den = 1;
    param.rc.i_bitrate = bitrate;
    param.rc.i_rc_method = X264_RC_ABR;

    param.analyse.b_psnr = 1;

    /* Apply profile restrictions. */
    if( x264_param_apply_profile( &param, "high" ) < 0 )
        goto fail;

    if( x264_picture_alloc( &pic, param.i_csp, param.i_width, param.i_height ) < 0 )
        goto fail;

    h = x264_encoder_open( &param );
    if( !h )
        goto fail;

    int luma_size = param.i_width * param.i_height;
    int chroma_size = luma_size / 4;
    gettimeofday(&tv_start, NULL);
    clock_start = clock();
    /* Encode frames */
    for( ;; i_frame++ )
    {
        /* Read input frame */
        if( fread( pic.img.plane[0], 1, luma_size, thiz->in_file ) != luma_size )
            break;
        if( fread( pic.img.plane[1], 1, chroma_size, thiz->in_file ) != chroma_size )
            break;
        if( fread( pic.img.plane[2], 1, chroma_size, thiz->in_file ) != chroma_size )
            break;

        pic.i_pts = i_frame;
        i_frame_size = x264_encoder_encode( h, &nal, &i_nal, &pic, &pic_out );
        if( i_frame_size < 0 )
            goto fail;
        else if( i_frame_size )
        {
            if (param.analyse.b_psnr){
                sum_psnr_y += pic_out.prop.f_psnr[0];
                sum_psnr_u += pic_out.prop.f_psnr[1];
                sum_psnr_v += pic_out.prop.f_psnr[2];
            }

            if( !fwrite( nal->p_payload, i_frame_size, 1, out_file ) )
                goto fail;
        }
    }

    /* Flush delayed frames */
    while( x264_encoder_delayed_frames( h ) )
    {
        i_frame_size = x264_encoder_encode( h, &nal, &i_nal, NULL, &pic_out );
        if( i_frame_size < 0 )
            goto fail;
        else if( i_frame_size )
        {
            if (param.analyse.b_psnr){
                sum_psnr_y += pic_out.prop.f_psnr[0];
                sum_psnr_u += pic_out.prop.f_psnr[1];
                sum_psnr_v += pic_out.prop.f_psnr[2];
            }

            if( !fwrite( nal->p_payload, i_frame_size, 1, out_file ) )
                goto fail;
        }
    }

    clock_end = clock();
    gettimeofday(&tv_end, NULL);
    clock_used = clock_end - clock_start;
    ms_used = (int64_t)(clock_used * 1000.0 / CLOCKS_PER_SEC);
    real_time = (tv_end.tv_sec + (tv_end.tv_usec / 1000000.0)) - (tv_start.tv_sec + (tv_start.tv_usec / 1000000.0));
    float realFPS = i_frame / real_time;
    double avg_psnr = (6*sum_psnr_y+sum_psnr_u+sum_psnr_v)/(8*i_frame);

    thiz->frame_num = i_frame;
    thiz->real_fps = realFPS;
    thiz->real_time = real_time;
    thiz->avg_psnr = avg_psnr;

    x264_encoder_close( h );
    x264_picture_clean( &pic );
    fclose(thiz->in_file);
    fclose(out_file);
    (*env)->ReleaseStringUTFChars(env, path_, path);
    (*env)->ReleaseStringUTFChars(env, profile_, profile);
    (*env)->ReleaseStringUTFChars(env, delay_, delay);
    return 0;

    fail:
    fclose(thiz->in_file);
    fclose(out_file);
    (*env)->ReleaseStringUTFChars(env, path_, path);
    (*env)->ReleaseStringUTFChars(env, profile_, profile);
    (*env)->ReleaseStringUTFChars(env, delay_, delay);
    return -1;

}

static double ksy265_psnr = 0;

void ksy265log(const char* msg) {
    LOGD("ksy265 log: %s", msg);
    //psnr值出现在编码器的log中，形如"bitrate, psnr: 503.1069	40.4723	47.0057	45.9163"
    char* psnr = strstr(msg, "psnr");
    if (psnr != NULL) {
        psnr += 4;

        char *p;
        const char* d = " :\t";
        p = strtok(psnr, d);

        double y =0, u = 0, v = 0;
        //skip bitrate
        p = strtok(NULL, d);
        if (p != NULL)
            y = strtod(p, NULL);

        p = strtok(NULL, d);
        if (p != NULL)
            u = strtod(p, NULL);

        p = strtok(NULL, d);
        if (p != NULL)
            v = strtod(p, NULL);

        ksy265_psnr = (y*6 + u + v) / 8;
        LOGD("psnr %f, y %f , u %f, v %f \n", ksy265_psnr, y, u, v);
    }
}

jint Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1ksy265_1encoder
        (JNIEnv *env,
         jobject instance,
         jlong ptr,
         jstring path_,
         jstring profile_,
         jstring delay_,
         jint width,
         jint height,
         jobject fps,
         jint bitrate,
         jint threads) {
    const char *path = (*env)->GetStringUTFChars(env, path_, 0);
    const char *profile = (*env)->GetStringUTFChars(env, profile_, 0);
    const char *delay = (*env)->GetStringUTFChars(env, delay_, 0);

    QY265EncConfig param;
    QY265YUV yuv;
    QY265Picture pic;
    QY265Picture pic_out;
    QY265Nal *nal;
    void *h;
    int i_frame = 0;
    int i_frame_size;
    int i_nal;
    clock_t clock_start, clock_end, clock_used;
    struct timeval tv_start, tv_end;
    double real_time;
    int64_t ms_used;
    FILE *out_file;
    int errorCode;

    Encoder *thiz = getInstance(ptr);

    if (NULL != path) {
        out_file = fopen(path, "w");
        if (NULL == out_file) {
            perror("open output file");
            fclose(thiz->in_file);
            (*env)->ReleaseStringUTFChars(env, path_, path);
            (*env)->ReleaseStringUTFChars(env, profile_, profile);
            (*env)->ReleaseStringUTFChars(env, delay_, delay);
            return -1;
        }
    }

    /* Get default params for preset/tuning */
    if (QY265ConfigDefaultPreset(&param, profile, NULL, delay) < 0)
        goto fail;

    param.picWidth = width;
    param.picHeight = height;
    param.threads = threads;

    jclass floatClass = (*env)->FindClass(env, "java/lang/Float");
    jmethodID floatMethod = (*env)->GetMethodID(env, floatClass, "floatValue", "()F");
    jfloat val = (*env)->CallFloatMethod(env, fps, floatMethod);
    LOGD("265 fps %.6f", val);
    param.frameRate = val;
    param.bitrateInkbps = bitrate;

    param.calcPsnr = 1;
    QY265SetLogPrintf(ksy265log);

    yuv.pData[0] = (unsigned char *)malloc(param.picWidth * param.picHeight * 3/2);
    yuv.pData[1] = yuv.pData[0] + param.picWidth * param.picHeight;
    yuv.pData[2] = yuv.pData[0] + param.picWidth * param.picHeight * 5/4;
    yuv.iWidth = param.picWidth;
    yuv.iHeight = param.picHeight;
    yuv.iStride[0] = yuv.iWidth;
    yuv.iStride[1] = yuv.iStride[2] = yuv.iWidth/2;

    h = QY265EncoderOpen( &param , &errorCode);
    if( !h )
        goto fail;

    pic.yuv = &yuv;
    memset(&pic_out,0,sizeof(pic_out));

    int luma_size = param.picWidth * param.picHeight;
    int chroma_size = luma_size / 4;
    gettimeofday(&tv_start, NULL);
    clock_start = clock();
    /* Encode frames */
    for( ;; i_frame++ )
    {
        /* Read input frame */
        if( fread( pic.yuv->pData[0], 1, luma_size, thiz->in_file ) != luma_size )
            break;
        if( fread( pic.yuv->pData[1], 1, chroma_size, thiz->in_file ) != chroma_size )
            break;
        if( fread( pic.yuv->pData[2], 1, chroma_size, thiz->in_file ) != chroma_size )
            break;

        pic.pts = i_frame;
        i_frame_size = QY265EncoderEncodeFrame( h, &nal, &i_nal, &pic, &pic_out, 0 );
        if( i_frame_size < 0 )
            goto fail;

        for(int i = 0; i < i_nal; i++){
            if( !fwrite(  nal[i].pPayload, nal[i].iSize, 1, out_file ) )
                goto fail;
        }
    }
    /* Flush delayed frames */
    while( QY265EncoderDelayedFrames( h ) )
    {
        i_frame_size = QY265EncoderEncodeFrame( h, &nal, &i_nal, NULL, &pic_out, 0 );
        if( i_frame_size < 0 )
            goto fail;

        for(int i = 0; i < i_nal; i++){
            if( !fwrite(  nal[i].pPayload, nal[i].iSize, 1, out_file ) )
                goto fail;
        }
    }
    clock_end = clock();
    gettimeofday(&tv_end, NULL);
    clock_used = clock_end - clock_start;
    ms_used = (int64_t)(clock_used * 1000.0 / CLOCKS_PER_SEC);
    real_time = (tv_end.tv_sec + (tv_end.tv_usec / 1000000.0)) - (tv_start.tv_sec + (tv_start.tv_usec / 1000000.0));
    float realFPS = i_frame / real_time;
    printf("%d frame encoded\n"
                   "\ttime\tfps\n"
                   "CPU\t%lldms\t%.2f\n"
                   "Real\t%.3fs\t%.2f.\n",
           i_frame,
           ms_used, i_frame * 1000.0 / ms_used,
           real_time, realFPS);

    QY265EncoderClose( h );

    thiz->frame_num = i_frame;
    thiz->real_fps = realFPS;
    thiz->real_time = real_time;
    thiz->avg_psnr = ksy265_psnr;

    free(yuv.pData[0]);
    fclose(thiz->in_file);
    fclose(out_file);
    (*env)->ReleaseStringUTFChars(env, path_, path);
    (*env)->ReleaseStringUTFChars(env, profile_, profile);
    (*env)->ReleaseStringUTFChars(env, delay_, delay);
    return 0;

    fail:
    fclose(thiz->in_file);
    fclose(out_file);
    (*env)->ReleaseStringUTFChars(env, path_, path);
    (*env)->ReleaseStringUTFChars(env, profile_, profile);
    (*env)->ReleaseStringUTFChars(env, delay_, delay);
    return -1;
}

jfloat Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1get_1real_1fps
        (JNIEnv *env,
         jobject instance,
         jlong ptr) {
    Encoder* thiz = getInstance(ptr);
    return thiz->real_fps;
}

jint Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1get_1encoded_1frame_1num
        (JNIEnv *env,
         jobject instance,jlong ptr) {
    Encoder* thiz = getInstance(ptr);
    return thiz->frame_num;
}

JNIEXPORT jstring JNICALL
Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1get_1x264_1version(
        JNIEnv *env, jobject instance) {
    return (*env)->NewStringUTF(env, X264_POINTVER);
}

JNIEXPORT jstring JNICALL
Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1get_1ksy265_1version(
        JNIEnv *env, jobject instance) {
    return (*env)->NewStringUTF(env, strLibQy265Version);
}

JNIEXPORT jfloat JNICALL
Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1get_1real_1time(JNIEnv *env,
                                                                                       jobject instance,
                                                                                       jlong ptr) {
    Encoder* thiz = getInstance(ptr);
    return thiz->real_time;
}

JNIEXPORT jfloat JNICALL
Java_com_ksyun_media_ksy265codec_demo_encoder_EncoderWrapper_native_1get_1psnr(JNIEnv *env,
                                                                                 jobject instance,
                                                                                 jlong ptr) {
    Encoder* thiz = getInstance(ptr);
    return thiz->avg_psnr;
}