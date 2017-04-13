//
//  MoviePlayer.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "KSYMovieEncoder.h"
#include <stdint.h>
#include <stdio.h>
#include <qy265enc.h>
#include <sys/time.h>
#include "qy265def.h"

void logPrint(const char* msg){
    if(strncmp(msg, "\n", sizeof("\n"))){
        NSString * message = [[NSString alloc]initWithUTF8String:msg];
        NSLog(@"message:%@",message);
        NSString *regulaStr = @"\\d+\\.\\d+";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSArray *arrayOfAllMatches = [regex matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        if(arrayOfAllMatches.count >= 4){
            float Y_PSNR = [[message substringWithRange:((NSTextCheckingResult *)arrayOfAllMatches[1]).range] floatValue];
            float U_PSNR = [[message substringWithRange:((NSTextCheckingResult *)arrayOfAllMatches[2]).range] floatValue];
            float V_PSNR = [[message substringWithRange:((NSTextCheckingResult *)arrayOfAllMatches[3]).range] floatValue];
            float PSNR = (6* Y_PSNR + U_PSNR + V_PSNR)/8;
            NSString *stringPSNR = [NSString stringWithFormat:@"%.2f",PSNR];
            [[NSUserDefaults standardUserDefaults] setValue:stringPSNR forKey:@"psnr"];
        }
    
    }
    return;
};


@implementation KSYMovieEncoder

{
    NSString *moviePath;
    FILE *in_file;
}

- (id) init
{
    self = [super init];

    QY265SetLogPrintf(logPrint);
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

    _out_file_string = [NSString stringWithFormat:@"%@.265", moviePath];
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
    if( QY265ConfigDefaultPreset( &param, [profile UTF8String], NULL, [delayed UTF8String]) < 0 )
        goto fail;
    
    param.picWidth = [arrayofRes[0] intValue];
    param.picHeight = [arrayofRes[1] intValue];
    param.threads = [threads intValue];
    param.frameRate = [fps floatValue];
    if([bitRate intValue])
        param.bitrateInkbps = [bitRate intValue];
    param.calcPsnr = 1;

    yuv.pData[0] = (unsigned char *)malloc(param.picWidth * param.picHeight * 3/2);
    yuv.pData[1] = yuv.pData[0] + param.picWidth * param.picHeight;
    yuv.pData[2] = yuv.pData[0] + param.picWidth * param.picHeight * 5/4;
    yuv.iWidth = param.picWidth;
    yuv.iHeight = param.picHeight;
    yuv.iStride[0] = yuv.iWidth;
    yuv.iStride[1] = yuv.iStride[2] = yuv.iWidth/2;
    
    h = QY265EncoderOpen( &param, &errorCode );
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
        if( fread( pic.yuv->pData[0], 1, luma_size, in_file ) != luma_size )
            break;
        if( fread( pic.yuv->pData[1], 1, chroma_size, in_file ) != chroma_size )
            break;
        if( fread( pic.yuv->pData[2], 1, chroma_size, in_file ) != chroma_size )
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

    self.width = param.picWidth;
    self.height = param.picHeight;
    self.frameNum = i_frame;
    self.realFPS = realFPS;
    self.real_time = real_time;
    
    QY265EncoderClose( h );
    
    free(yuv.pData[0]);
    fclose(in_file);
    fclose(out_file);
    return 0;
    
fail:
    fclose(in_file);
    fclose(out_file);
    return -1;
}

@end
