package com.ksyun.media.ksy265codec.demo.ui;

import android.content.SharedPreferences;
import android.util.Log;

/**
 * Created by sujia on 2017/3/28.
 */
public class EncoderSettings {
    public final static String TAG = "EncoderSettings";
    public final static String ENCODER_SETTINGS_ENCODER = "encoder_settings_encoder";
    public final static String ENCODER_SETTINGS_PROFILE = "encoder_settings_profile";
    public final static String ENCODER_SETTINGS_DELAY = "encoder_settings_delay";
    public final static String ENCODER_SETTINGS_RESOLUTION = "encoder_settings_resolution";
    public final static String ENCODER_SETTINGS_RESOLUTION_IDX = "encoder_settings_resolution_idx";
    public final static String ENCODER_SETTINGS_FPS = "encoder_settings_fps";
    public final static String ENCODER_SETTINGS_THREADS = "encoder_settings_threads";
    public final static String ENCODER_SETTINGS_BITRATE = "encoder_settings_bitrate";

    public final static String[] Encoders = new String[] {"KSC265", "x264"};
    public final static String[] Profiles = new String[] {"superfast", "veryfast", "fast",
            "medium", "slow", "veryslow", "placebo"};
    public final static String[] Delays = new String[] {"zerolatency", "livestreaming",
            "offline"};
    public final static String[] Resolutions = new String [] {"1280*720", "960*540", "640*360",
    "640*480", "360*640", "368*640", "自定义"};

    public int encoderIndex;
    public int profileIndex;
    public int delayIndex;
    public int resIndex;
    public String bitrate;
    public String resolution;
    public String fps;
    public String threads;

    public EncoderSettings() {
        this.encoderIndex = 0;// ksc265
        this.profileIndex = 1;//veryfast
        this.delayIndex = 2;//offline
        this.resolution =  Resolutions[0];
        this.resIndex = 0;//1280*720
        this.fps = "15";
        this.threads = "1";
        this.bitrate = "500";
    }

    public EncoderSettings(SharedPreferences sharedPreferences) {
        this.encoderIndex = sharedPreferences.getInt(ENCODER_SETTINGS_ENCODER, 0);
        this.profileIndex = sharedPreferences.getInt(ENCODER_SETTINGS_PROFILE, 0);
        this.delayIndex = sharedPreferences.getInt(ENCODER_SETTINGS_DELAY, 0);
        this.resIndex = sharedPreferences.getInt(ENCODER_SETTINGS_RESOLUTION_IDX, 0);
        this.resolution = sharedPreferences.getString(ENCODER_SETTINGS_RESOLUTION, Resolutions[0]);
        this.fps = sharedPreferences.getString(ENCODER_SETTINGS_FPS, "15");
        this.threads = sharedPreferences.getString(ENCODER_SETTINGS_THREADS, "1");
        this.bitrate = sharedPreferences.getString(ENCODER_SETTINGS_BITRATE, "500");
    }

    public String getEncoderName() {
        if (encoderIndex <= Encoders.length -1) {
            return Encoders[encoderIndex];
        } else {
            return "unknow";
        }
    }

    public String getProfile() {
        if (profileIndex <= Profiles.length -1) {
            return Profiles[profileIndex];
        } else {
            return "";
        }
    }

    public String getDelay() {
        if (delayIndex <= Delays.length -1) {
            return Delays[delayIndex];
        } else {
            return "";
        }
    }

    public int getBitrate() {
        return Integer.parseInt(bitrate);
    }

    public String getResolution() {
        if (resIndex < Resolutions.length -1) {
            return Resolutions[resIndex];
        } else {
            return resolution;
        }
    }

    public int getWidth() {
        String[] res = getResolution().split("\\*");
        if (res != null &&
                res.length == 2) {
            return Integer.parseInt(res[0]);
        } else {
            Log.e(TAG, "分辨率解析错误，格式必须为 宽*高");
            return 0;
        }
    }

    public int getHeight() {
        String[] res = getResolution().split("\\*");
        if (res != null &&
                res.length == 2) {
            return Integer.parseInt(res[1]);
        } else {
            Log.e(TAG, "分辨率解析错误，格式必须为 宽*高");
            return 0;
        }
    }

    public Float getFps() {
        return Float.parseFloat(fps);
    }

    public int getThreads() {
        return Integer.parseInt(threads);
    }
}