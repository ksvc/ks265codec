// jniplayer.cpp : decode H.265/HEVC video data in separate native thread
//
// Copyright (c) 2013 Strongene Ltd. All Right Reserved.
// http://www.strongene.com
//
// Contributors:
// Shengbin Meng <shengbinmeng@gmail.com>
// James Deng <hugeice@gmail.com>
//
// You are free to re-use this as the basis for your own application
// in source and binary forms, with or without modification, provided
// that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright
// notice and this list of conditions.
//  * Redistributions in binary form must reproduce the above
// copyright notice and this list of conditions in the documentation
// and/or other materials provided with the distribution.



#include <android/log.h>
#include <android/bitmap.h>
#include <stdio.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>
#include "jniplayer.h"
#include "jni_utils.h"
#include "yuv2rgb565.h"
#include "gl_renderer.h"

#ifdef __cplusplus
	#define __STDC_CONSTANT_MACROS
	#define __STDC_LIMIT_MACROS
	#ifdef _STDINT_H
		#undef _STDINT_H
	#endif
	#include <stdint.h>
	#define __STDC_FORMAT_MACROS
#endif

extern "C" {
#include "lenthevcdec.h"
#include "qy265dec.h"
#include "qyauth_env.h"
}

#define LOG_TAG    "jniplayer"

#define ENABLE_LOGD 0
#if ENABLE_LOGD
#define LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)
#else
#define LOGD(...)
#endif
#define LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)

#ifndef _countof
#define _countof(a) (sizeof(a) / sizeof((a)[0]))
#endif

#define LOOP_PLAY 0

#if ARCH_ARM
#define USE_SWSCALE 0
#else
#define USE_SWSCALE 0
#endif

struct MediaInfo
{
	int width;
	int height;
	char data_src[1024];
	int raw_bs;
};

VideoFrame gVF = {0, 0, 0, 0, 0, {NULL, NULL, NULL}};
pthread_mutex_t gVFMutex = PTHREAD_MUTEX_INITIALIZER;

static MediaInfo media;

static pthread_t decode_thread;

static struct SwsContext   *p_sws_ctx;

static const char* const kClassPathName = "com/ksyun/media/ksy265codec/demo/decoder/hevdecoder/NativeMediaPlayer";

// for lenthevcdec
static const uint32_t AU_COUNT_MAX = 1024 * 1024;
static const uint32_t AU_BUF_SIZE_MAX = 1024 * 1024 * 80;
static uint32_t au_pos[AU_COUNT_MAX];	// too big array, use static to save stack space
static uint32_t au_count, au_buf_size;
static uint8_t *au_buf = NULL;
static lenthevcdec_ctx lent_ctx = NULL;

static volatile int exit_decode_thread = 0;
static volatile int is_playing = 0;


static int frames_sum = 0;
static double tstart = 0;

static int frames = 0;
static double tlast = 0;

static float renderFPS = 0;
static double avg_fps = 0;
static uint64_t renderInterval = 0;
static struct timeval timeStart;

static int frame_count = 0;
static double real_time = 0;
static float real_fps = 0;

static int use_ksy = 0;
static void* ksydec_ctx = NULL;
static QY265Frame decframe;

static int disable_render = 0;

static bool enable_output_yuv = 0;
static char output_path[1024];

typedef struct Context {
    jobject obj;
    jmethodID	drawFrame;
    jmethodID   postEvent;
} Context;

static Context *ctx;

static void freeContext(void* opaque) {
    Context* ctx = (Context*) opaque;
    if (ctx && ctx->obj) {
        JNIEnv *env = NULL;
        env = getJNIEnv();
        env->DeleteGlobalRef(ctx->obj);
    }
    free(ctx);
}

static void postEventToJava(void *opaque, int msg, int ext1, int ext2)
{
    Context* ctx = (Context*) opaque;
    if (ctx == NULL) {
        return;
    }

    int isAttached = 0;
    JNIEnv *env = NULL;

    env = getJNIEnv();
    if (env == NULL) {
        return;
    }

    env->CallVoidMethod(ctx->obj, ctx->postEvent, msg, ext1, ext2);

    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
    }
}

static int callJavaDrawFrame(void* opaque, int width, int height)
{
    Context* ctx = (Context*) opaque;
    if (ctx == NULL) {
        return 0;
    }

    int isAttached = 0;
    JNIEnv *env = NULL;

    env = getJNIEnv();
    if (env == NULL) {
        return 0;
    }
    int ret =  env->CallIntMethod(ctx->obj, ctx->drawFrame, width, height);

    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
    }

    return ret;
}

uint32_t getms()
{
	struct timeval t;
	gettimeofday(&t, NULL);
	return (t.tv_sec * 1000) + (t.tv_usec / 1000);
}

int drawFrame(VideoFrame * vf)
{
    int64_t timePassed, delay;
	LOGD("enter drawFrame:%u (%f)", getms(), vf->pts);

	if(disable_render)
	    goto show_display;

	// copy decode frame to global buffer
	pthread_mutex_lock(&gVFMutex);
	if ( gVF.linesize_y != vf->linesize_y || gVF.linesize_uv != vf->linesize_uv || gVF.height != vf->height ) {
		if ( NULL != gVF.yuv_data[0] )
			free(gVF.yuv_data[0]);
		gVF.yuv_data[0] = gVF.yuv_data[1] = gVF.yuv_data[2] = NULL;
		gVF.yuv_data[0] = (uint8_t*)malloc(vf->linesize_y * vf->height + vf->linesize_uv * vf->height );
		if ( NULL == gVF.yuv_data[0] ) {
			LOGE("malloc failed!\n");
			return -1;
		}
		gVF.yuv_data[1] = gVF.yuv_data[0] + vf->linesize_y*vf->height;
		gVF.yuv_data[2] = gVF.yuv_data[1] + vf->linesize_uv*vf->height/2;
	}
	gVF.width = vf->width;
	gVF.height = vf->height;
	gVF.linesize_y = vf->linesize_y;
	gVF.linesize_uv = vf->linesize_uv;
	gVF.pts = vf->pts;
	memcpy(gVF.yuv_data[0], vf->yuv_data[0], vf->linesize_y*vf->height);
	memcpy(gVF.yuv_data[1], vf->yuv_data[1], vf->linesize_uv*vf->height/2);
	memcpy(gVF.yuv_data[2], vf->yuv_data[2], vf->linesize_uv*vf->height/2);
	pthread_mutex_unlock(&gVFMutex);

	// wait for display
	struct timeval timeNow;
	gettimeofday(&timeNow, NULL);
	timePassed = ((int64_t)(timeNow.tv_sec - timeStart.tv_sec))*1000000 + (timeNow.tv_usec - timeStart.tv_usec);
	delay = vf->pts - timePassed;
	if (delay > 0) {
		usleep(delay);
	}

show_display:
	// update information
	gettimeofday(&timeNow, NULL);
	double tnow = timeNow.tv_sec + (timeNow.tv_usec / 1000000.0);
	if (tlast == 0) tlast = tnow;
	if (tstart == 0) tstart = tnow;
	if (tnow > tlast + 1) {
		LOGI("Video Display FPS:%i", (int)frames);
		frames_sum += frames;
		avg_fps = frames_sum / (tnow - tstart);
		LOGI("Video AVG FPS:%.2lf", avg_fps);
        postEventToJava(ctx, 900, int(frames), int(avg_fps * 4096));
		tlast = tlast + 1;
		frames = 0;
	}
	frames++;

	// request display
	LOGD("before request draw:%u (%f)", getms(), vf->pts);
    if (disable_render) {
        return 0;
    } else {
        return callJavaDrawFrame(ctx, vf->width, vf->height);
    }
}

int lent_hevc_get_sps(uint8_t* buf, int size, uint8_t** sps_ptr)
{
	int i, nal_type, sps_pos;
	sps_pos = -1;
	for ( i = 0; i < (size - 4); i++ ) {
		if ( 0 == buf[i] && 0 == buf[i+1] && 1 == buf[i+2] ) {
			nal_type = (buf[i+3] & 0x7E) >> 1;
			if ( 33 != nal_type && sps_pos >= 0 ) {
				break;
			}
			if ( 33 == nal_type ) { // sps
				sps_pos = i;
			}
			i += 2;
		}
	}
	if ( sps_pos < 0 )
		return 0;
	if ( i == (size - 4) )
		i = size;
	*sps_ptr = buf + sps_pos;
	return i - sps_pos;
}

int lent_hevc_get_frame(uint8_t* buf, int size, int *is_idr)
{
	static int seq_hdr = 0;
	int i, nal_type, idr = 0;
	for ( i = 0; i < (size - 6); i++ ) {
		if ( 0 == buf[i] && 0 == buf[i+1] && 1 == buf[i+2] ) {
			nal_type = (buf[i+3] & 0x7E) >> 1;
			if ( nal_type <= 21 ) {
				if ( buf[i+5] & 0x80 ) { /* first slice in pic */
					if ( !seq_hdr )
						break;
					else
						seq_hdr = 0;
				}
			}
			if ( nal_type >= 32 && nal_type <= 34 ) {
				if ( !seq_hdr ) {
					seq_hdr = 1;
					idr = 1;
					break;
				}
				seq_hdr = 1;
			}
			i += 2;
		}
	}
	if ( i == (size - 6) )
		i = size;
	if ( NULL != is_idr )
		*is_idr = idr;
	return i;
}

static int write_pic_yv12(int w, int h, uint8_t* buf[3], short stride[3], FILE *fp)
{
    uint8_t *line;
    int line_len, line_count, i, j, pitch;
    for ( i = 0; i < 3; i++ ) {
        line = buf[i];
        pitch = stride[i];
        line_len = (0 == i) ? w : (w / 2);
        line_count = (0 == i) ? h : (h / 2);
        for ( j = 0; j < line_count; j++ ) {
            if ( fwrite(line, 1, line_len, fp) != line_len )
                return -1;
            line += pitch;
        }
    }
    return 0;
}

void* rawbs_runDecoder(void *p)
{
	int32_t got_frame, width, height, stride[3];
	uint8_t* pixels[3];
	int64_t pts, got_pts;
	int ret, i;
    struct timeval tv_start, tv_end;

	if ( NULL == lent_ctx || NULL == au_buf )
		return NULL;

    FILE* out_file = NULL;
    if (enable_output_yuv) {
        out_file = fopen(output_path, "wb");
        if (out_file == NULL) {
            LOGE("open outout file %s faile", output_path);
            goto exit;
        }
    }

decode:
	// decode all AUs
    frame_count = 0;
    real_time = 0;
    gettimeofday(&tv_start, NULL);

	LOGD("dec %d\n",  au_count);
	for ( i = 0; i < au_count && !exit_decode_thread; i++ ) {
		pts = i * 40;
		got_frame = 0;
		uint32_t start_time = getms();
		LOGD("before decode: %u", start_time);

		if(use_ksy) {
		    QY265DecodeFrame(ksydec_ctx, au_buf + au_pos[i], au_pos[i + 1] - au_pos[i], &ret, 0);
            if ( ret < 0 ) {
                LOGE("call QY265DecodeFrame failed! ret = %d   i: %d /%d\n", ret, i, au_count);
            }

            QY265DecoderGetDecodedFrame(ksydec_ctx, &decframe, &ret, 0);
            if ( ret == 0 && decframe.bValid ) {
                got_frame = 1;
                width = decframe.frameinfo.nWidth;
                height = decframe.frameinfo.nHeight;
                stride[0] = decframe.iStride[0];
                stride[1] = decframe.iStride[1];
                pixels[0] = decframe.pData[0];
                pixels[1] = decframe.pData[1];
                pixels[2] = decframe.pData[2];
            }
		} else {
		    ret = lenthevcdec_decode_frame(lent_ctx, au_buf + au_pos[i], au_pos[i + 1] - au_pos[i], pts,
					       &got_frame, &width, &height, stride, (void**)pixels, &got_pts);
		    if ( ret < 0 ) {
			    LOGE("call lenthevcdec_decode_frame failed! ret = %d\n", ret);
			    goto exit;
		    }
		}

		uint32_t end_time = getms();
		LOGD("after decode: %u", end_time);
		uint32_t dec_time = end_time - start_time;
		if ( got_frame > 0 ) {
			LOGD("decoding time: %u - %u = %u\n", end_time, start_time, dec_time);
			LOGD("decode frame: pts = %" PRId64 ", linesize = {%d,%d,%d}\n", got_pts, stride[0], stride[1], stride[2]);
			if ( media.width != width || media.height != height ) {
				LOGD("Video dimensions change! %dx%d -> %dx%d\n", media.width, media.height, width, height);
				media.width = width;
				media.height = height;
			}
			// draw frame to screen
			VideoFrame vf;
			vf.width = width;
			vf.height = height;
			vf.linesize_y = stride[0];
			vf.linesize_uv = stride[1];
			vf.pts = renderInterval * frame_count;
			vf.yuv_data[0] = pixels[0];
			vf.yuv_data[1] = pixels[1];
			vf.yuv_data[2] = pixels[2];

            if (enable_output_yuv &&
                    out_file != NULL) {
                write_pic_yv12(decframe.frameinfo.nWidth, decframe.frameinfo.nHeight,
                               (uint8_t**)decframe.pData, decframe.iStride, out_file);
            }

			if (frame_count == 0) {
				gettimeofday(&timeStart, NULL);
			}
			drawFrame(&vf);
            if(use_ksy)
			    QY265DecoderReturnDecodedFrame(ksydec_ctx, &decframe);
			frame_count++;
		}
	}

#if LOOP_PLAY
	if (!exit_decode_thread) {
		LOGI("automatically play again\n");
		goto decode;
	}
#endif

    LOGE("flush  %d + %d /%d \n", i,frame_count, au_count);
	// flush decoder
	while ( !exit_decode_thread ) {
		got_frame = 0;
        if(use_ksy) {
            QY265DecoderGetDecodedFrame(ksydec_ctx, &decframe, &ret, 0);
            if ( ret == 0 && frame_count < au_count){
                if (decframe.bValid) {
                    got_frame = 1;
                    width = decframe.frameinfo.nWidth;
                    height = decframe.frameinfo.nHeight;
                    stride[0] = decframe.iStride[0];
                    stride[1] = decframe.iStride[1];
                    pixels[0] = decframe.pData[0];
                    pixels[1] = decframe.pData[1];
                    pixels[2] = decframe.pData[2];
                }
            }
            else {
                break;
            }
		} else {
		    ret = lenthevcdec_decode_frame(lent_ctx, NULL, 0, pts,
					       &got_frame, &width, &height, stride, (void**)pixels, &got_pts);
		    if ( ret < 0 || got_frame <= 0)
			    break;
		}

		if ( got_frame > 0 ) {
			if ( media.width != width || media.height != height ) {
				LOGD("Video dimensions change! %dx%d -> %dx%d\n", media.width, media.height, width, height);
				media.width = width;
				media.height = height;
			}
			// draw frame to screen
			VideoFrame vf;
			vf.width = width;
			vf.height = height;
			vf.linesize_y = stride[0];
			vf.linesize_uv = stride[1];
			vf.pts = renderInterval * frame_count;
			vf.yuv_data[0] = pixels[0];
			vf.yuv_data[1] = pixels[1];
			vf.yuv_data[2] = pixels[2];

            if (enable_output_yuv &&
                out_file != NULL) {
                write_pic_yv12(decframe.frameinfo.nWidth, decframe.frameinfo.nHeight,
                               (uint8_t**)decframe.pData, decframe.iStride, out_file);
            }

			drawFrame(&vf);
            if(use_ksy)
			    QY265DecoderReturnDecodedFrame(ksydec_ctx, &decframe);
			frame_count++;
		}
	}

exit:
	if ( NULL != au_buf )
		free(au_buf);
	au_buf = NULL;
	au_buf_size = 0;
	if ( NULL != lent_ctx )
		lenthevcdec_destroy(lent_ctx);
	lent_ctx = NULL;
	if ( NULL != ksydec_ctx )
    	QY265DecoderDestroy(ksydec_ctx);
    ksydec_ctx = NULL;

    gettimeofday(&tv_end, NULL);
    real_time = (tv_end.tv_sec + (tv_end.tv_usec / 1000000.0)) - (tv_start.tv_sec + (tv_start.tv_usec / 1000000.0));
    real_fps = frame_count / real_time;

    postEventToJava(ctx, 909, int(frame_count), 0);// end of file
	detachJVM();
	is_playing = 0;
	LOGI("decode thread exit\n");
	exit_decode_thread = 0;

    if (out_file != NULL) {
        fclose(out_file);
    }

	return NULL;
}



static int
MediaPlayer_setDataSource(JNIEnv *env, jobject thiz, jstring path)
{
	const char *pathStr = env->GetStringUTFChars(path, NULL);
	memset(&media, 0, sizeof(media));
	strcpy(media.data_src, pathStr);
	// Make sure that local ref is released before a potential exception
	env->ReleaseStringUTFChars(path, pathStr);
	// is raw HEVC bitstream file ?
	static const char * hevc_raw_bs_ext[] = {".hevc", ".hm91", ".hm10", ".bit", ".hvc", ".h265", ".265"};
	char * ext = strrchr(media.data_src, '.');
	if ( NULL != ext ) {
		int i;
		for ( i = 0; i < _countof(hevc_raw_bs_ext); i++ ) {
			if ( strcasecmp(hevc_raw_bs_ext[i], ext) == 0 )
				break;
		}
		if ( i < _countof(hevc_raw_bs_ext) )
			media.raw_bs = 1;
	}
	return 0;
}

static int rawbs_prepare(JNIEnv *env, jobject context, int threads)
{
	FILE *in_file;
	int32_t got_frame, width, height, stride[3];
	uint8_t* pixels[3];
	int64_t pts, got_pts;
	uint8_t *sps;
	lenthevcdec_ctx one_thread_ctx;
	int compatibility, frame_count, sps_len, ret, i;

	in_file = NULL;
	au_buf = NULL;
	lent_ctx = NULL;
	one_thread_ctx = NULL;

	// get compatibility version
	compatibility = 0x7fffffff;
	if ( strncasecmp(".hm91", media.data_src + (strlen(media.data_src) - 5), 5) == 0 )
		compatibility = 91;
	else if ( strncasecmp(".hm10", media.data_src + (strlen(media.data_src) - 5), 5) == 0 )
		compatibility = 100;

	// read file
	in_file = fopen(media.data_src, "rb");
	if ( NULL == in_file ) {
		LOGE("Can not open input file '%s'\n", media.data_src);
		goto error_exit;
	}
	fseek(in_file, 0, SEEK_END);
	au_buf_size = ftell(in_file);
	fseek(in_file, 0, SEEK_SET);
	LOGD("file size is %d bytes\n", au_buf_size);
	if ( au_buf_size > AU_BUF_SIZE_MAX )
		au_buf_size = AU_BUF_SIZE_MAX;
	au_buf = (uint8_t*)malloc(au_buf_size);
	if ( NULL == au_buf ) {
		LOGE("call malloc failed! size is %d\n", au_buf_size);
		goto error_exit;
	}
	if ( fread(au_buf, 1, au_buf_size, in_file) != au_buf_size ) {
		LOGE("call fread failed!\n");
		goto error_exit;
	}
	fclose(in_file);
	in_file = NULL;
	LOGD("%d bytes read to address %p\n", au_buf_size, au_buf);

	// find all AU
	au_count = 0;
	for ( i = 0; i < au_buf_size && au_count < (AU_COUNT_MAX - 1); i+=3 ) {
		i += lent_hevc_get_frame(au_buf + i, au_buf_size - i, NULL);
		if (i < au_buf_size) {
			au_pos[au_count++] = i;
		}
		LOGD("AU[%d] = %d\n", au_count - 1, au_pos[au_count - 1]);
	}
	au_pos[au_count] = au_buf_size; // include last AU
	LOGD("found %d AUs\n", au_count);

    if(use_ksy) {
        int hr = QY_OK;
        QY265DecConfig config = {0};

        config.threads = threads;
        config.bEnableOutputRecToFile = 0;
        config.strRecYuvFileName = NULL;
		TCounterEnv* tCounterEnv = (TCounterEnv*) malloc(sizeof(TCounterEnv));
		tCounterEnv->context = context;
		env->GetJavaVM(&tCounterEnv->jvm);
		config.pAuth = tCounterEnv;

        ksydec_ctx = QY265DecoderCreate(&config, &hr);
        if(ksydec_ctx == NULL) {
            LOGE("call QY265DecoderCreate fail..");
            goto error_exit;
        }
        LOGD("call QY265DecoderCreate Succeed..");
    }
	// open lentoid HEVC decoder
	LOGI("create lentoid decoder: compatibility = %d, threads = %d\n", compatibility, threads);
	lent_ctx = lenthevcdec_create(threads, compatibility, NULL);
	if ( NULL == lent_ctx ) {
		LOGE("call lenthevcdec_create failed!\n");
		goto error_exit;
	}
	LOGD("get decoder %p\n", lent_ctx);

    // find sps, decode it and get video resolution
    sps_len = lent_hevc_get_sps(au_buf, au_buf_size, &sps);
    if ( sps_len > 0 ) {
        // get a one-thread decoder to decode SPS
        one_thread_ctx = lenthevcdec_create(1, compatibility, NULL);
        if ( NULL == lent_ctx )
            goto error_exit;
        width = 0;
        height = 0;
        ret = lenthevcdec_decode_frame(one_thread_ctx, sps, sps_len, 0, &got_frame, &width, &height, stride, (void**)pixels, &pts);
        if ( 0 != width && 0 != height ) {
            media.width = width;
            media.height = height;
            LOGD("Video dimensions is %dx%d\n", width, height);
        }
        lenthevcdec_destroy(one_thread_ctx);
        one_thread_ctx = NULL;
    }
    return 0;

error_exit:
	if ( NULL != in_file )
		fclose(in_file);
	in_file = NULL;
	if ( NULL != au_buf )
		free(au_buf);
	au_buf = NULL;
	au_buf_size = 0;
	if ( NULL != lent_ctx )
		lenthevcdec_destroy(lent_ctx);
	lent_ctx = NULL;
	if ( NULL != one_thread_ctx )
		lenthevcdec_destroy(one_thread_ctx);
	one_thread_ctx = NULL;
	if ( NULL != ksydec_ctx )
	    QY265DecoderDestroy(ksydec_ctx);
	ksydec_ctx = NULL;

	return -1;
}


static int
MediaPlayer_prepare(JNIEnv *env, jobject thiz, jobject context, jint decoderType, jint render, jint threadNumber, jfloat fps) {
    LOGD("MediaPlayer_prepare: %d threads, fps %f\n", threadNumber, fps);
    renderFPS = fps;
    if (fps == 0) {
        renderInterval = 1;
    } else {
        renderInterval = 1.0 / fps * 1000000; // us
    }

    if (decoderType == 0) {
        use_ksy = 1;
    } else {
        use_ksy = 0;
    }

    disable_render = render;

	return rawbs_prepare(env, context, threadNumber);

}

static int
MediaPlayer_start(JNIEnv *env, jobject thiz)
{
	LOGI("start decoding thread");

	pthread_create(&decode_thread, NULL, rawbs_runDecoder, NULL);

	return 0;
}

static int
MediaPlayer_pause(JNIEnv *env, jobject thiz)
{
	return 0;
}

static int
MediaPlayer_go(JNIEnv *env, jobject thiz)
{
	return 0;
}


static int
MediaPlayer_stop(JNIEnv *env, jobject thiz)
{
	void* result;
	exit_decode_thread = 1;
	pthread_join(decode_thread, &result);
	exit_decode_thread = 0;
	if (p_sws_ctx != NULL) {
//		sws_freeContext(p_sws_ctx);
		p_sws_ctx = NULL;
	}
	if ( NULL != gVF.yuv_data[0] )
		free(gVF.yuv_data[0]);
	memset(&gVF, 0, sizeof(gVF));
	LOGI("media player stopped\n");
	return 0;
}

static bool
MediaPlayer_isPlaying(JNIEnv *env, jobject thiz)
{
    return is_playing;
}

static int
MediaPlayer_seekTo(JNIEnv *env, jobject thiz, jint msec)
{
	return 0;
}

static int
MediaPlayer_getVideoWidth(JNIEnv *env, jobject thiz)
{
    int w = media.width;
    return w;
}

static int
MediaPlayer_getVideoHeight(JNIEnv *env, jobject thiz)
{
    int h = media.height;
    return h;
}


static int
MediaPlayer_getCurrentPosition(JNIEnv *env, jobject thiz)
{
    int msec = 0;
    return msec;
}

static jfloat
MediaPlayer_getDuration(JNIEnv *env, jobject thiz)
{
    //TODO: 通过视频实际帧率计算
    return frame_count / renderFPS;
}

static jfloat
MediaPlayer_getDecodeTime(JNIEnv *env, jobject thiz)
{
    return real_time;
}

static jfloat
MediaPlayer_getDecodeFPS(JNIEnv *env, jobject thiz)
{
    return real_fps;
}

// ----------------------------------------------------------------------------

static void MediaPlayer_native_init(JNIEnv *env, jobject thiz)
{
    jclass clazz;
    clazz = env->FindClass("com/ksyun/media/ksy265codec/demo/decoder/hevdecoder/NativeMediaPlayer");
    if (clazz == NULL) {
        jniThrowException(env, "java/lang/RuntimeException", "Can't find MediaPlayer");
        return;
    }
	p_sws_ctx = NULL;

	frames_sum = 0;
	tstart = 0;

	frames = 0;
	tlast = 0;

	renderFPS = 0;
	renderInterval = 0;

	disable_render = 0;
    use_ksy = 0;

    if (thiz) {
        ctx = (Context *) calloc(1, sizeof(Context));
        if (ctx == NULL) {
            return;
        }
        jclass clazz = env->GetObjectClass(thiz);
        ctx->obj = env->NewGlobalRef(thiz);

        ctx->postEvent = env->GetMethodID(clazz, "postEventFromNative", "(III)V");
        if (ctx->postEvent == NULL) {
            jniThrowException(env, "java/lang/RuntimeException", "Can't find MediaPlayer.postEventFromNative");
            return;
        }
        ctx->drawFrame = env->GetMethodID(clazz, "drawFrame", "(II)I");
        if (ctx->drawFrame == NULL) {
            jniThrowException(env, "java/lang/RuntimeException", "Can't find MediaPlayer.drawFrame");
            return;
        }
    }
}

static void
MediaPlayer_renderBitmap(JNIEnv *env, jobject  obj, jobject bitmap)
{
	void*              pixels;
	int                ret;

	if ((ret = AndroidBitmap_lockPixels(env, bitmap, &pixels)) < 0) {
		LOGE("AndroidBitmap_lockPixels() failed ! error=%d", ret);
	}

	// Convert the image from its native format to RGB565
	uint32_t start_time = getms();
	LOGD("before scale: %d", getms());
#if USE_SWSCALE
	// use swscale, which may be optimized with SSE for x86 arch
	if (p_sws_ctx == NULL) {
		p_sws_ctx = sws_getContext( gVF.width,
									gVF.height,
									PIX_FMT_YUV420P,
									gVF.width,
									gVF.height,
									PIX_FMT_RGB565, SWS_BICUBIC|SWS_CPU_CAPS_MMX|SWS_CPU_CAPS_MMX2|SWS_CPU_CAPS_SSE2, NULL, NULL, NULL);
	}
	if (p_sws_ctx != NULL) {
		unsigned char *src[4];
		int src_stride[4];
		unsigned char *dst[4];
		int dst_stride[4];

		src_stride[0] = gVF.linesize_y;
		src_stride[1] = src_stride[2] = gVF.linesize_uv;
		dst[0] = (unsigned char*)pixels;
		dst_stride[0] = gVF.width * 2;
		sws_scale(p_sws_ctx, (const uint8_t * const *)gVF.yuv_data, src_stride, 0, gVF.height, dst, dst_stride);
	}
#else
	ConvertYCbCrToRGB565(		gVF.yuv_data[0],
								gVF.yuv_data[1],
								gVF.yuv_data[2],
								(uint8_t*)pixels,
								gVF.width,
								gVF.height,
								gVF.linesize_y,
								gVF.linesize_uv,
								gVF.width * 2,
								420  );
#endif

	uint32_t end_time = getms();
	LOGD("after scale: %d", getms());
	LOGD("scale time: %dms", end_time - start_time);

	AndroidBitmap_unlockPixels(env, bitmap);
}


static void MediaPlayer_set_output(JNIEnv *env, jobject thiz, jstring path) {
    const char *pathStr = env->GetStringUTFChars(path, NULL);

    enable_output_yuv = true;
    strcpy(output_path, pathStr);

    // Make sure that local ref is released before a potential exception
    env->ReleaseStringUTFChars(path, pathStr);
}

static jstring MediaPlayer_getVersion(JNIEnv *env, jobject thiz) {
    if (use_ksy) {
        return env->NewStringUTF(strLibQy265Version);
    } else {
		char version[20];
		sprintf(version, "%d", lenthevcdec_version());
        return env->NewStringUTF(version);
    }
}

// ----------------------------------------------------------------------------

static JNINativeMethod gMethods[] = {
    { "setDataSource", "(Ljava/lang/String;)I", (void *) MediaPlayer_setDataSource },
    { "native_prepare", "(Landroid/content/Context;IIIF)I", (void *) MediaPlayer_prepare },
    { "native_start", "()I", (void *) MediaPlayer_start },
    { "native_stop", "()I", (void *) MediaPlayer_stop },
    { "getVideoWidth", "()I", (void *) MediaPlayer_getVideoWidth },
    { "getVideoHeight", "()I", (void *) MediaPlayer_getVideoHeight },
    { "native_seekTo", "(I)I", (void *) MediaPlayer_seekTo },
    { "native_pause", "()I", (void *) MediaPlayer_pause },
    { "native_go", "()I", (void *) MediaPlayer_go },
    { "isPlaying", "()Z", (void *) MediaPlayer_isPlaying },
    { "getCurrentPosition", "()I", (void *) MediaPlayer_getCurrentPosition },
    { "getDuration", "()F", (void *) MediaPlayer_getDuration },
    { "getDecodeTime", "()F", (void *) MediaPlayer_getDecodeTime },
    { "getDecodeFPS", "()F", (void *)  MediaPlayer_getDecodeFPS },
    { "native_init", "()V", (void *) MediaPlayer_native_init },
    { "renderBitmap", "(Landroid/graphics/Bitmap;)V", (void *) MediaPlayer_renderBitmap },
    { "native_set_output", "(Ljava/lang/String;)V", (void *) MediaPlayer_set_output },
    { "getVersion", "()Ljava/lang/String;", (jstring*) MediaPlayer_getVersion },
};

int register_player(JNIEnv *env) {
	return jniRegisterNativeMethods(env, kClassPathName, gMethods, sizeof(gMethods) / sizeof(gMethods[0]));
}
