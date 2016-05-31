#ks265codec

#ENCODER

Usage: command line examples

AppEncoder_x64.exe -i pku_parkwalk_3840x2160_50.yuv -preset veryfast -wdt 3840 -hgt 2160 -fr 50 -rc 1 -br 20000 -iper 128 -b test.265

AppEncoder_x64.exe -i pku_parkwalk_3840x2160_50.yuv -preset veryfast -wdt 3840 -hgt 2160 -fr 50 -rc 0 -qp 27 -iper 128 -b test.265
 
##Basic parameters:

-preset [preset_value], 

which specifies the encoding speed by the character string [preset_value], among strings of "superfast", "veryfast", "fast", "medium", "slow", "veryslow" and "placebo".

-i [input_filename], 

which specifies the address of the input YUV file in 4:2:0 sampling format by a character string [input_filename].

-wdt [width], 

which specifies the image width of the input video by a positive integer value [width]. 

-hgt [height], 

which specifies the image height of the input video by a positive integer value [height].

-fr [framerate], 

which specifies the frame rate of the input video by a positive integer value [framerate].

-iper [intraperiod], 

which specifies the maximum distances between consecutive I pictures by a positive integer value [intraperiod].

-rc [rctype], 

which specifies the rate control type by the positive integer value [rctype] valuing among values 0 and 1. There are two cases:
* -br [bitrate] should be followed. If [rctype] equals to 1, a parameter -br [bitrate] should be followed and specifies the target encoding bit-rate by the positive value [bitrate] (kbps,kilo bit rate per second). 
* -qp [qp_value] should be followed. If [rctype] equals to 0, a parameter -qp [qp_value] should be followed and specifies the target encoding quantization parameter by the positive value [qp_value] ranging from 0 to 51. 

-b [stream_filename], 

which specifies the address of the output stream file in HEVC/H.265 format by a character string [stream_filename]. Default: no stream is output.


##Optional parameters:

-v or -V [version],

which is utilized to print the version and copyright of the encoder.

-psnr [psnrcalc],

which specifies psnr calculation method by a non-negative value [psnrcalc], and
* 0 (as a default value) means disabling psnr calculation,
* 1 means enabling psnr calculation and outputing the overall psnr result. 
* 2 means enabling psnr calculation and outputing psnr info for each frame.

-o [reconstructYUV], 

which specifies the address of the reconstrcuted yuv file in 4:2:0 format by a character string [reconstructYUV]. Default: no reconstructed YUV file is output.

-frms [frame_no], 

which specifies the number of frames to be encoded for the input video by a positive integer value [frame_no]. Default: [frame_no] = -1, when all input frames are encoded.

-threads [thread_no], 

which specifies the number of threads used to encode the input video by a non-negative value [thread_no]. Default: [thread_no] = 0, when all available threads can be utilized.

#DECODER

AppDecoder_x64.exe -b test.265 -o test.yuv -threads 2

##Basic parameters:

-v or -V [version]

which specifies the decoder version and copyright.

-b [bitstream],

which specifies input bit-stream file by a character string [bitstream].


##Optional parameters:

-o [output],

which specifies the decoded yuv file name by a character string [output].

-threads [threadnum],

which specifies the number of threads used for decoding process by a non-negative value [threadnum]. Default: [threadnum] = 0, when all available threads can be utilized.


#Performance

On test sequences of JCTVC CLASS-A ~ CLASS-E, compared to x264(20151215) and 265-v1.9 in the speed form of encoded frames per second (fps), the average performance of KS265 is shown as follows:


##Real-Time Broadcasting

When 1 thread is utilized, KSC265@veryfast achieves 47.9% BDRate savings with only 1.3% speed decrease over X264@veryfast, and 34.3% BDRate savings with 71.8% speed up over X265@ultrafast

When all threads(24) are utilized, KSC265@veryfast achieves 47.9% BDRate savings with only 11.7% speed decrease over X264@veryfast, and 35.7% BDRate savings with 53.6% speed up over X265@ultrafast


##Offline Transcoding

When 1 thread is utilized, KSC265@slow achieves 38.7% BDRate savings with only 10.7% speed decrease over X264@slow, and 17.2% BDRate savings with 155.0% speed up over X265@slow

When all threads(24) are utilized, KSC265@slow achieves 38.7% BDRate savings with only 11.4% speed decrease over X264@slow, and 16.4% BDRate savings with 168.0% speed up over X265@slow


##Highest Compression ratio

When all threads(24) are utilized, KSC265@veryslow achieves 36.4% BDRate savings with only 39.9% speed up over X264@placebo, and 11.5% BDRate savings with 203.6% speed up over X265@placebo
