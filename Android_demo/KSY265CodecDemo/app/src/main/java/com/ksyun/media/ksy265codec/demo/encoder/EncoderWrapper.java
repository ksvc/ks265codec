package com.ksyun.media.ksy265codec.demo.encoder;

import com.ksyun.media.ksy265codec.demo.ui.EncoderSettings;

import java.io.File;

/**
 * Created by sujia on 2017/3/29.
 */

public class EncoderWrapper {
    private String mInputFilePath;
    private String mOutputFilePath;

    private EncoderSettings mSettings;

    private long mInstance = 0;

    public EncoderWrapper(EncoderSettings settings) {
        this.mSettings = settings;
        mInstance = native_init();
    }

    //return -1 if failed
    public int open(String path) {
        if (path != null && path.endsWith(".yuv")) {
            mInputFilePath = path;
            return native_open(mInstance, mInputFilePath);
        }
        return -1;
    }

    //return -1 if failed
    public int encode() {
        if (mSettings.getEncoderName().equals(EncoderSettings.Encoders[0])) {//KSC265
            int dotIndex = mInputFilePath.lastIndexOf(".");
            String fileName = mInputFilePath.substring(0, dotIndex);
            mOutputFilePath = fileName + ".265";

            return native_ksy265_encoder(mInstance, mOutputFilePath,
                    mSettings.getProfile(), mSettings.getDelay(),
                    mSettings.getWidth(), mSettings.getHeight(),
                    mSettings.getFps(), mSettings.getBitrate(),
                    mSettings.getThreads());
        } else if(mSettings.getEncoderName().equals(EncoderSettings.Encoders[1])) {//x264
            int dotIndex = mInputFilePath.lastIndexOf(".");
            String fileName = mInputFilePath.substring(0, dotIndex);
            mOutputFilePath = fileName + ".264";

            return native_x264_encode(mInstance, mOutputFilePath,
                    mSettings.getProfile(), mSettings.getDelay(),
                    mSettings.getWidth(), mSettings.getHeight(),
                    mSettings.getFps(), mSettings.getBitrate(),
                    mSettings.getThreads());
        }
        return -1;
    }

    public String getInputFilePath() {
        return mInputFilePath;
    }

    public String getOutputFilePath() {
        return mOutputFilePath;
    }

    public float getEncodeFPS() {
        return native_get_real_fps(mInstance);
    }

    public int getEncodedFrameNum() {
        return native_get_encoded_frame_num(mInstance);
    }

    public float getCompressRatio() {
        if (mInputFilePath == null ||
                mOutputFilePath == null) {
            return 0;
        } else {
            long inFileLength = new File(mInputFilePath).length();
            long outFileLength = new File(mOutputFilePath).length();
            if (outFileLength != 0) {
                return inFileLength / outFileLength;
            } else {
                return 0;
            }
        }
    }

    public float getEncodeTime() {
        return native_get_real_time(mInstance);
    }

    public double getPSNR() {
        return native_get_psnr(mInstance);
    }

    public float getDuration() {
        return getEncodedFrameNum() / mSettings.getFps();
    }

    public float getEncodeBitrate() {
        float encodeTime = getDuration();
        if (mOutputFilePath !=null &&
                encodeTime != 0) {
            long outFileLength = new File(mOutputFilePath).length();
            return (outFileLength * 8) / encodeTime / 1000;
        } else {
            return 0;
        }
    }

    public String getVersion() {
        if (mSettings.getEncoderName().equals(EncoderSettings.Encoders[0])) {//KSC265
            return native_get_ksy265_version();
        } else if (mSettings.getEncoderName().equals(EncoderSettings.Encoders[1])) {//x264
            return native_get_x264_version();
        }
        return "0.1";
    }

    public native long native_init();

    public native int native_open(long ptr, String path);

    public native int native_x264_encode(long ptr, String path,
                                         String profile, String delay,
                                         int width, int height,
                                         Float fps, int bitrate, int threads);

    public native int native_ksy265_encoder(long ptr, String outputFilePath,
                                            String profile, String delay,
                                            int width, int height,
                                            Float fps, int bitrate, int threads);

    public native float native_get_real_fps(long ptr);

    public native int native_get_encoded_frame_num(long ptr);

    public native String native_get_x264_version();

    public native String native_get_ksy265_version();

    public native float native_get_real_time(long ptr);

    public native float native_get_psnr(long ptr);

    static {
        System.loadLibrary("native-lib");
    }
}
