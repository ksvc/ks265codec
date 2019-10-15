package com.ksyun.media.ksy265codec.demo.encoder;

import android.content.Context;

import com.ksyun.media.ksy265codec.demo.ui.EncoderSettings;

/**
 * Created by sujia on 2017/3/29.
 */

public class Encoder {
    private EncoderWrapper mWrapper;

    public Encoder(EncoderSettings settings) {
        mWrapper = new EncoderWrapper(settings);
    }

    //return -1 if failed
    public int open(String path) {
        if (mWrapper != null) {
            return mWrapper.open(path);
        }
        return -1;
    }

    //return -1 if failed
    public int encode(Context context) {
        if (mWrapper != null) {
            return mWrapper.encode(context);
        }
        return -1;
    }

    public int getEncodedFrameNum() {
        if (mWrapper != null) {
            return mWrapper.getEncodedFrameNum();
        }
        return 0;
    }

    public float getEncodeFPS() {
        if (mWrapper != null) {
            return mWrapper.getEncodeFPS();
        }
        return 0;
    }

    public float getCompressRatio() {
        if (mWrapper != null) {
            return mWrapper.getCompressRatio();
        }
        return 1;
    }

    public float getEncodeTime() {
        if (mWrapper != null) {
            return mWrapper.getEncodeTime();
        }
        return 0;
    }

    public double getPSNR() {
        if (mWrapper != null) {
            return mWrapper.getPSNR();
        }
        return 0;
    }

    public String getVersion() {
        if (mWrapper != null) {
            return mWrapper.getVersion();
        }
        return "0.1";
    }

    public float getEncodeBitrate() {
        if (mWrapper != null) {
            return mWrapper.getEncodeBitrate();
        }
        return 0;
    }

    public float getDuration() {
        if (mWrapper != null) {
            return mWrapper.getDuration();
        }
        return 0;
    }

    public String getInputFilePath() {
        if (mWrapper != null) {
            return mWrapper.getInputFilePath();
        }
        return null;
    }

    public String getOutputFilePath() {
        if (mWrapper != null) {
            return mWrapper.getOutputFilePath();
        }
        return null;
    }
}
