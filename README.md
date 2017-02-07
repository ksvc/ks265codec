#ks265codec

#ENCODER

Usage: command line examples

AppEncoder_x64.exe -i pku_parkwalk_3840x2160_50.yuv -preset veryfast -latency offline -wdt 3840 -hgt 2160 -fr 50 -rc 1 -br 20000 -iper 128 -b test.265

AppEncoder_x64.exe -i pku_parkwalk_3840x2160_50.yuv -preset veryfast -latency offline -wdt 3840 -hgt 2160 -fr 50 -rc 0 -qp 27 -iper 128 -b test.265
 
##Basic parameters:

-preset [preset_value], 

which specifies the encoding speed by the character string [preset_value], among strings of "superfast", "veryfast", "fast", "medium", "slow", "veryslow" and "placebo".

-latency [latency_value],

which specifies the encoding latency by the character string [lactency_value], among strings of "zerolatency", "livestreaming", "offline".

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

which specifies the rate control type by the positive integer value [rctype] valuing among values 0(fixed qp), 1(cbr), 2(abr) and 3(crf). There are four cases:
* -br [bitrate] should be followed. If [rctype] equals to 1 or 2, a parameter -br [bitrate] should be followed and specifies the target encoding bit-rate by the positive value [bitrate] (kbps,kilo bit rate per second). 
* -qp [qp_value] should be followed. If [rctype] equals to 0, a parameter -qp [qp_value] should be followed and specifies the target encoding quantization parameter by the positive value [qp_value] ranging from 0 to 51. 
* -crf [crf_value] should be followed. If [rctype] equals to 3, a parameter -crf [crf_value] should be followed and specifies the target crf parameter by the positive value [crf_value] ranging from 0 to 51. 

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

-bframes[value1], -vbv-maxrate [value2] , -vbv-bufsize[value3],
which specifies similar meanings as similar values defined in x264

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


#Performance of decoder

KSC265 decoder is compared with openHEVC in ffmpeg on ARM32@andriod, ARM64@andriod and ARM64@IOS.

On average, results show that,

KC265 decoder can achieve more than two times the speed of openHEVC in ffmpeg, and details can be found in the excels for decoding performance. 

#Performance of encoder

KSC265 encoder is compared with X265 and QY265 on Win7@i5-4670 using following parameters:

Case for low latency:

x264.exe -o out.264 BQSquare_416x240_60.yuv --input-res 416x240 --preset veryfast --fps [framerate] --profile high --aq-mode 0 --no-psy --tune zerolatency  --psnr  --bitrate [btrNumber] --threads 1/0 --keyint [framerate * 10] --frames 1000000

AppEncoder_x64.exe -b out.265 -i BQSquare_416x240_60.yuv -preset veryfast-tune default -latency  zerolatency -threads 1/0 -psnr 2 -rc 1 -br [btrNumber] -frms 1000000 -iper [framerate * 10]

x265.exe -o out.265 --input BQSquare_416x240_60.yuv --input-res 416x240 --preset ultrafast --fps [framerate] --aq-mode 0 --no-psy-rd --no-psy-rdoq --rc-lookahead 0 --bframes 0  --psnr  --bitrate [btrNumber] --frame-threads 1/0 --no-wpp/--wpp --keyint [framerate * 10] --frames 1000000

Case for larger latency:

x264.exe -o out.264 BQSquare_416x240_60.yuv --input-res 416x240 --preset veryfast/slow/placebo --fps [framerate] --profile high --aq-mode 0 --no-psy --tune offline  --psnr  --bitrate [btrNumber] --threads 1/0 --keyint [framerate * 10] --frames 1000000

AppEncoder_x64.exe -b out.265 -i BQSquare_416x240_60.yuv -preset veryfast/slow/veryslow -tune default -latency  offline -threads 1/0 -psnr 2 -rc 1 -br [btrNumber] -frms 1000000 -iper [framerate * 10]

x265.exe -o out.265 --input BQSquare_416x240_60.yuv --input-res 416x240 --preset ultrafast/slow/veryslow --fps [framerate] --aq-mode 0 --no-psy-rd --no-psy-rdoq  --psnr  --bitrate [btrNumber] --frame-threads 1/0 --no-wpp/--wpp --keyint [framerate * 10] --frames 1000000

Then on test sequences of JCTVC CLASS-A ~ CLASS-E, compared to x264(20151215) and 265-v2.1 in the speed form of encoded frames per second (fps), the average performance of KS265 is shown as follows:


##Low-latency Streaming

When 1 thread is utilized, KSC265@veryfast achieves 39.3% BDRate savings with only 13.5% speed decrease over X264@veryfast, and 30.8% BDRate savings with 132.7% speed up over X265@ultrafast

When all threads(4) are utilized, KSC265@veryfast achieves 40.8% BDRate savings with only 11.2% speed decrease over X264@veryfast, and 31.7% BDRate savings with 61.1% speed up over X265@ultrafast


##Real-Time Broadcasting

When 1 thread is utilized, KSC265@veryfast achieves 47.4% BDRate savings with 8.0% speed up over X264@veryfast, and 32.1% BDRate savings with 81.3% speed up over X265@ultrafast

When all threads(4) are utilized, KSC265@veryfast achieves 47.6% BDRate savings with 6.3% speed decrease over X264@veryfast, and 33.5% BDRate savings with 61.8% speed up over X265@ultrafast


##Offline Transcoding

When 1 thread is utilized, KSC265@slow achieves 38.2% BDRate savings with 2.0% speed up over X264@slow, and 9.8% BDRate savings with 184.4% speed up over X265@slow

When all threads(4) are utilized, KSC265@slow achieves 38.2% BDRate savings with 2.0% speed up over X264@slow, and 8.5% BDRate savings with 197.8% speed up over X265@slow


##Highest Compression ratio

When all threads(4) are utilized, KSC265@veryslow achieves 35.8% BDRate savings with 47.3% speed up over X264@placebo, and 6.4% BDRate savings with 53.7% speed up over X265@veryslow
