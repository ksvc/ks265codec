//
//  MoviePlayer.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "MovieEncoder.h"
#include <stdint.h>
#include <stdio.h>
#include <x264.h>
#include <sys/time.h>

@implementation MovieEncoder

{
    NSString *moviePath;
    FILE *in_file;
}

- (id) init
{
    self = [super init];

    return self;
}

- (int) openMovie:(NSString*) path
{
    moviePath = path;
    in_file = fopen([moviePath UTF8String], "rb");
	if(NULL == in_file) {
		printf("can not open input file '%s'!\n", [moviePath UTF8String]);
        return -1;
	}
    
    return 0;
}

- (int) encoder
{
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

    _out_file_string = [NSString stringWithFormat:@"%@.264", moviePath];
    if ( NULL != _out_file_string ) {
        out_file = fopen([_out_file_string UTF8String], "wb");
        if ( NULL == out_file ) {
            perror("open output file");
            fclose(in_file);
            return -1;
        }
    }
    
    NSString *resolution = [[NSUserDefaults standardUserDefaults] valueForKey:@"resolution"];
    NSArray *arrayofRes = [resolution componentsSeparatedByString:@"*"];
    NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"fps"];
    NSString *bitRate = [[NSUserDefaults standardUserDefaults] valueForKey:@"bitRate"];
    NSString *threads = [[NSUserDefaults standardUserDefaults] valueForKey:@"threads"];
    NSString *profile = [[NSUserDefaults standardUserDefaults] valueForKey:@"profile"];
    NSString *delayed = [[NSUserDefaults standardUserDefaults] valueForKey:@"delayed"];
    
    /* Get default params for preset/tuning */
    if ([delayed isEqualToString:@"zerolatency"]) {
        if( x264_param_default_preset( &param, [profile UTF8String], "zerolatency" ) < 0 )
            goto fail;
    }
    else {
        if( x264_param_default_preset( &param, [profile UTF8String], NULL ) < 0 )
            goto fail;
    }
    
    /* Configure non-default params */
    param.i_csp = X264_CSP_I420;
    param.i_width  = [arrayofRes[0] intValue];
    param.i_height = [arrayofRes[1] intValue];
    param.b_vfr_input = 0;
    param.b_repeat_headers = 1;
    param.b_annexb = 1;
    
    if([bitRate intValue]){
        param.rc.i_bitrate = [bitRate intValue];
        param.rc.i_rc_method = X264_RC_ABR;
    }
    
    if ([delayed isEqualToString:@"zerolatency"]) {
        param.i_bframe = 0;
    }
    else if([delayed isEqualToString:@"livestreaming"]){
        param.i_bframe = 3;
    }
    else{
        param.i_bframe = 7;
    }
    
    param.i_threads = [threads intValue];
    param.i_fps_num = [fps floatValue];
    param.i_fps_den = 1;
    
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
        if( fread( pic.img.plane[0], 1, luma_size, in_file ) != luma_size )
            break;
        if( fread( pic.img.plane[1], 1, chroma_size, in_file ) != chroma_size )
            break;
        if( fread( pic.img.plane[2], 1, chroma_size, in_file ) != chroma_size )
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
    printf("%d frame encoded\n"
           "\ttime\tfps\n"
           "CPU\t%lldms\t%.2f\n"
           "Real\t%.3fs\t%.2f.\n"
           "PSNR\t%.2f\n",
           i_frame,
           ms_used, i_frame * 1000.0 / ms_used,
           real_time, realFPS, avg_psnr);
    
    self.width = param.i_width;
    self.height = param.i_height;
    self.frameNum = i_frame;
    self.realFPS = realFPS;
    self.real_time = real_time;
    self.avg_psnr = avg_psnr;
    
    x264_encoder_close( h );
    x264_picture_clean( &pic );
    fclose(in_file);
    fclose(out_file);
    return 0;
    
fail:
    fclose(in_file);
    fclose(out_file);
    return -1;
}

@end
