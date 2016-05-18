#ks265codec

#ENCODER

Usage: command line examples

AppEncoder_x64.exe -i pku_parkwalk_3840x2160_50.yuv -preset veryfast -wdt 3840 -hgt 2160 -fr 50 -rc 1 -br 20000 -iper 128 -b test.265

AppEncoder_x64.exe -i pku_parkwalk_3840x2160_50.yuv -preset veryfast -wdt 3840 -hgt 2160 -fr 50 -rc 0 -qp 27 -iper 128 -b test.265
 
##Basic parameters:

-v or -V [version]

which specifies the encoder version and copyright.

-preset [preset_value], 

which specifies the encoder speed by on of the character string: superfast veryfast fast medium slow veryslow.

-i [input_filename], 

which specifies the address of the input YUV file in 4:2:0 sampling format by a character string input_filename.

-wdt [width], 

which specifies the image width of the input video by a positive integer value width. 

-hgt [height], 

which specifies the image height of the input video by a positive integer value height.

-fr [framerate], 

which specifies the frame rate of the input video by a positive integer value framerate.

-iper [intraperiod], 

which specifies the maximum distances between consecutive I picture by a positive integer value intraperiod.

-psnr [psnr calculation]

which specifies psnr calculation method.
* 0 means disable psnr calculation,
* 1 means enable psnr calculation and output the overall psnr result. 
* 2 means enable psnr calculation and output psnr info for each frame.

-rc [rctype], 

which specifies the rate control type by the positive integer value rctype valuing among values 0 and 1. There are two cases:
* -br [bitrate] should be followed. If rctype equals to 1, a parameter -br [bitrate] should be followed and specifies the target encoding bit-rate by the positive value bitrate (kbps,kilo bit rate per second). 
* -qp [qp_value] should be followed. If rctype equals to 0, a parameter -qp [qp_value] should be followed and specifies the target encoding quantization parameter by the positive value qp_value (0~51). 

-b [stream_filename], 

which specifies the address of the output stream file in HEVC/H.265 format by a character string [stream_filename]. Default: no stream is output.


##Optional parameters:

-o [reconstructYUV], 

which specifies the address of the reconstrcuted yuv file in 4:2:0 format by a character string [reconstructYUV]. Default: no reconstructed YUV file is output.

-frms [frame_no], 

which specifies the number of frames to be encoded for the input video by a positive integer value frame_no. Default: frame_no = -1, when all input frames are encoded.

-threads [thread_no], 

which specifies the number of threads used to encode the input video by a non-negative value thread_no. Default: thread_no = 0, when all available threads can be utilized.

#DECODER

AppDecoder_x64.exe -b test.265 -o test.yuv -threads 2

##Basic parameters:

-v or -V [version]

which specifies the decoder version and copyright.

-b [bitstream],

which specifies input bitstream file.


##Optional parameters:

-o [output]

which specifies output yuv file.

-threads [threadnum]
which specifies how many threads are used for decoding process. same as encoder


