//
//  MoviePlayer.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "KSYMoviePlayer.h"
#import "GLRenderer.h"
#include "lenthevcdec.h"
#include <sys/sysctl.h>
#include <sys/time.h>
#include "qy265dec.h"

#define AU_COUNT_MAX (1024 * 256)
#define AU_BUF_SIZE_MAX (1024 * 1024 * 128)

static inline int next_p2(int a) {
    int rval=1;
    while(rval<a) rval<<=1;
    return rval;
}

@interface KSYMoviePlayer() {
    void * _ksydec;
    BOOL  _skipRender;
}

@end

@implementation KSYMoviePlayer 
{
    NSString *moviePath;
    NSThread *decodeThread;
    BOOL isBusy, stopRender;
    unsigned char * pData[3];
    int exit_decode_thread;
    uint32_t au_pos[AU_COUNT_MAX];
    uint32_t au_count, au_buf_size;
    uint8_t *au_buf;
    struct VideoFrame frame;
    QY265Frame decframe;
    int frames;
    int frames_sum;
    double tstart, tlast;
    uint64_t renderInterval;
    struct timeval timeStart;
    FILE *out_file;
}

@synthesize renderer;

- (id) init
{
    self = [super init];
    
    exit_decode_thread = 0;
    frames_sum = 0;
    tstart = 0;
    frames = 0;
    tlast = 0;
    renderInterval = 0;
    
    isBusy = NO;
    stopRender = NO;
    _skipRender = NO;
    self.decodeEnd = 0;

    return self;
}

- (void) setupRenderer {
    [self.renderer setRenderStateListener:self];
}

- (void) bufferDone {
    isBusy = NO;
}

- (void) renderFrame:(struct VideoFrame *) vf
{
    if (_skipRender) {
        return;
    }
    //int frames = 0;
    uint8_t *dst[3] = {frame.yuv_data[0], frame.yuv_data[1], frame.yuv_data[2]};
    uint8_t *src[3] = {decframe.pData[0], decframe.pData[1], decframe.pData[2]};
    for (int j = 0; j < frame.height/2; ++j) {
        memcpy(dst[0], src[0], frame.linesize_y);
        dst[0] += frame.linesize_y;
        src[0] += decframe.iStride[0];
        memcpy(dst[0], src[0], frame.linesize_y);
        dst[0] += frame.linesize_y;
        src[0] += decframe.iStride[0];
        memcpy(dst[1], src[1], frame.linesize_uv);
        dst[1] += frame.linesize_uv;
        src[1] += decframe.iStride[1];
        memcpy(dst[2], src[2], frame.linesize_uv);
        dst[2] += frame.linesize_uv;
        src[2] += decframe.iStride[2];
    }
    vf = &frame;
	struct timeval timeNow;
	gettimeofday(&timeNow, NULL);
	int64_t timePassed = ((int64_t)(timeNow.tv_sec - timeStart.tv_sec))*1000000 + (timeNow.tv_usec - timeStart.tv_usec);
	int64_t delay = vf->pts - timePassed;
	if (delay > 0) {
		usleep(delay);
	}
    
	gettimeofday(&timeNow, NULL);
	double tnow = timeNow.tv_sec + (timeNow.tv_usec / 1000000.0);
	if (tlast == 0) tlast = tnow;
	if (tstart == 0) tstart = tnow;
	if (tnow > tlast + 1) {
		double avg_fps;
		printf("Video Display FPS:%i\n", (int)frames);
		frames_sum += frames;
		avg_fps = frames_sum / (tnow - tstart);
		printf("Video AVG FPS:%.2lf\n", avg_fps);
        
        //self.infoString = [NSString stringWithFormat:@"size:%dx%d, fps:%d", vf->width, vf->height, frames];
        
		tlast = tlast + 1;
		frames = 0;
	}
	frames++;
    while(isBusy && !stopRender) usleep(50);
    isBusy = YES;
    [renderer render:vf];
}

static int lent_hevc_get_sps(uint8_t* buf, int size, uint8_t** sps_ptr)
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

static int lent_hevc_get_frame(uint8_t* buf, int size, int *is_idr)
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

- (int) ksy_hevc_prepare:(int) thread_num
{
    // open hevc decoder
    int hr = QY_OK;
    QY265DecConfig ksycfg ={0};
    ksycfg.threads = thread_num;
    _ksydec = QY265DecoderCreate(&ksycfg, &hr );
    if ( NULL == _ksydec ) {
        fprintf(stderr, "call QY265DecoderCreate failed!\n");
        return -1;
    }
    fflush(stdout);
    FILE *in_file = fopen([moviePath UTF8String], "rb");
    if ( NULL == in_file ) {
        fprintf(stderr, " failed! can not open input file '%s'!\n",
                [moviePath UTF8String]);
        return -1;
    }
    fseek(in_file, 0, SEEK_END);
    au_buf_size = ftell(in_file);
    fseek(in_file, 0, SEEK_SET);
    printf("(%d bytes) ... ", au_buf_size);
    if ( au_buf_size > AU_BUF_SIZE_MAX )
        au_buf_size = AU_BUF_SIZE_MAX;
    au_buf = (uint8_t*)malloc(au_buf_size);
    if ( NULL == au_buf ) {
        perror("allocate AU buffer");
        fclose(in_file);
        return -1;
    }
    if ( fread(au_buf, 1, au_buf_size, in_file) != au_buf_size ) {
        perror("read intput file failed");
        fclose(in_file);
        return -1;
    }
    fclose(in_file);
    printf("done. %d bytes read.\n", au_buf_size);
    
    // find all AUs
	au_count = 0;
	for (int i = 0; i < au_buf_size && au_count < (AU_COUNT_MAX - 1); i+=3 ) {
		i += lent_hevc_get_frame(au_buf + i, au_buf_size - i, NULL);
		au_pos[au_count++] = i;
	}
	au_pos[au_count] = au_buf_size; // include last AU
    printf("found %d AUs\n", au_count);
    
    int ret;
    uint8_t *sps;
    int sps_len = lent_hevc_get_sps(au_buf, au_buf_size, &sps);
    if ( sps_len > 0 ) {
        lenthevcdec_ctx one_thread_ctx = lenthevcdec_create(1, INT32_MAX, NULL);
        lenthevcdec_frame out_frame;
        memset(&out_frame, 0, sizeof(lenthevcdec_frame));
        out_frame.size = sizeof(lenthevcdec_frame);
        ret = lenthevcdec_decode_frame(one_thread_ctx, sps, sps_len, 0, &out_frame);
        if ( 0 != out_frame.width && 0 != out_frame.height ) {
            //printf("Video dimensions is %dx%d\n", out_frame.width, out_frame.height);
            // initialization that depends on width and heigt
            //frame.width = out_frame.width;
            //frame.height = out_frame.height;
        }
        lenthevcdec_destroy(one_thread_ctx);
        frame.linesize_y = next_p2(out_frame.width);
        frame.linesize_uv = next_p2(out_frame.width/2);
        frame.yuv_data[0] = malloc( frame.linesize_y * out_frame.height);
        frame.yuv_data[1] = malloc( frame.linesize_uv * out_frame.height/2);
        frame.yuv_data[2] = malloc( frame.linesize_uv * out_frame.height/2);
    }
    return 0;
}

- (int) openMovie:(NSString*) path
{
    moviePath = path;
	if(!fopen([moviePath UTF8String], "rb")) {
		printf("can not open input file '%s'!\n", [moviePath UTF8String]);
        return -1;
	}
    
    return 0;
}

- (int) play
{
    // prepare decoder
    float renderFPS = 0;
    NSString *num = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
    int thread_num = [num integerValue];
    
    NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
    renderFPS = [fps floatValue];
    if ([fps isEqualToString:@"-1 (off)"]) {
        _skipRender = YES;
    }
    if (renderFPS == 0) {
        renderInterval = 1;
    }
	else {
		renderInterval = 1.0 / renderFPS * 1000000; // us
	}
    
    printf("will play with decoding thread number: %d, and FPS: %.2f", thread_num, renderFPS);
    
    /* open output file */
    out_file = NULL;
    _out_file_string = NULL;
    NSString *flag = [[NSUserDefaults standardUserDefaults] valueForKey:@"outputFlag"];
    if ([flag isEqualToString:@"YES"]) {
        _out_file_string = [NSString stringWithFormat:@"%@.ksc.yuv", moviePath];
        if ( NULL != _out_file_string ) {
            out_file = fopen([_out_file_string UTF8String], "wb");
            if ( NULL == out_file ) {
                perror("open output file");
                return -1;
            }
        }
    }

    int ret = [self ksy_hevc_prepare:thread_num];
    if (ret < 0) {
        if (au_buf != NULL) {
            free(au_buf);
        }
        if (_ksydec != NULL) {
            QY265DecoderDestroy(_ksydec);
            _ksydec = NULL;
        }
        return ret;
    }
    decodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(ksydecodeVideo) object:nil];
    [decodeThread start];
    return 0;
}

- (int) stop {
	exit_decode_thread = 1;
    stopRender = YES;
    return 0;
}

- (void) ksydecodeVideo {
    exit_decode_thread = 0;
    [self setupRenderer];
    // decode video
    int64_t pts, ms_used;
    clock_t clock_start, clock_end, clock_used;
    struct timeval tv_start, tv_end;
    double real_time;
    int ret;
    int frame_count = 0;
    gettimeofday(&tv_start, NULL);
    clock_start = clock();
    for (int i = 0; i < au_count; i++ ) {
        if (exit_decode_thread) {
            break;
        }
        pts = i * 40;
        unsigned char*  pD = au_buf + au_pos[i];
        int len = au_pos[i + 1] - au_pos[i];
        if (len > 0) {
            QY265DecodeFrame(_ksydec, pD, len, &ret, 0);
            if ( ret < 0 ) {
                fprintf(stderr, "decode_frame failed[%d]\n", ret);
                return ;
            }
        }
        QY265DecoderGetDecodedFrame(_ksydec, &decframe, &ret, 0);
        if (ret == 0 && decframe.bValid) {
            frame.width = decframe.frameinfo.nWidth;
            frame.height = decframe.frameinfo.nHeight;
            frame.pts = frame_count * renderInterval;
            if (out_file){
                ret = write_pic_yv12(decframe.frameinfo.nWidth, decframe.frameinfo.nHeight, (UInt8 **)decframe.pData, decframe.iStride, out_file);
                if ( ret < 0 ) {
                    perror("write output file");
                    return;
                }
            }
            if (frame_count == 0) {
                gettimeofday(&timeStart, NULL);
            }
            frame_count++;
            [self renderFrame:&frame];
            QY265DecoderReturnDecodedFrame(_ksydec, &decframe);
        }
    }
    printf("========== %d ========\n", frame_count);
    // flush decoder
    while (1){
        if (exit_decode_thread) {
            break;
        }
        QY265DecoderGetDecodedFrame(_ksydec, &decframe, &ret, 0);
        if (ret == 0 && frame_count < au_count - 1) {
            if (decframe.bValid){
                frame.pts = frame_count * renderInterval;
                if (out_file){
                    ret = write_pic_yv12(decframe.frameinfo.nWidth, decframe.frameinfo.nHeight, (UInt8 **)decframe.pData, decframe.iStride, out_file);
                    if ( ret < 0 ) {
                        perror("write output file");
                        return;
                    }
                }
                frame_count++;
                [self renderFrame:&frame];
                QY265DecoderReturnDecodedFrame(_ksydec, &decframe);
            }
        }
        else {
            if (out_file){
                ret = write_pic_yv12(decframe.frameinfo.nWidth, decframe.frameinfo.nHeight, (UInt8 **)decframe.pData, decframe.iStride, out_file);
                if ( ret < 0 ) {
                    perror("write output file");
                    return;
                }
            }
            break;
        }
    }
    
    
    clock_end = clock();
    gettimeofday(&tv_end, NULL);
    clock_used = clock_end - clock_start;
    ms_used = (int64_t)(clock_used * 1000.0 / CLOCKS_PER_SEC);
    real_time = (tv_end.tv_sec + (tv_end.tv_usec / 1000000.0)) - (tv_start.tv_sec + (tv_start.tv_usec / 1000000.0));
   
    float realFPS = frame_count / real_time;
    printf("%d frame decoded\n"
           "\ttime\tfps\n"
           "CPU\t%lldms\t%.2f\n"
           "Real\t%.3fs\t%.2f.\n",
           frame_count,
           ms_used, frame_count * 1000.0 / ms_used,
           real_time, realFPS);
    self.width = frame.width;
    self.height = frame.height;
    self.frameNum = frame_count;
    self.realFPS = realFPS;
    self.real_time = real_time;

    self.decodeEnd = 1;
    free(au_buf);
    au_buf = NULL;
    free(frame.yuv_data[0]);
    free(frame.yuv_data[1]);
    free(frame.yuv_data[2]);
    if (_ksydec) {
        QY265DecoderDestroy(_ksydec);
        _ksydec = NULL;
    }
    if (out_file)
        fclose(out_file);
    exit_decode_thread = 0;
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

- (int)test:(int) thread_num{
    return 0;
}

@end
