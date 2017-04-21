package com.ksyun.media.ksy265codec.demo.ui;

import android.content.SharedPreferences;

/**
 * Created by sujia on 2017/3/28.
 */

public class DecoderSettings {
    public final static String DECODER_SETTINGS_DECODER = "decoder_settings_decoder";
    public final static String DECODER_SETTINGS_THREADS = "decoder_settings_threads";
    public final static String DECODER_SETTINGS_FPS = "decoder_settings_fps";
    public final static String DECODER_SETTINGS_RENDER = "decoder_settings_render";
    public final static String DECODER_SETTINGS_OUTPUT = "decoder_settings_output";

    public final static String[] Decoders = new String[] {"KSC265", "lenthevcdec"};
    public final static String[] Threads = new String[] {"0 (auto)", "1", "2",
            "3", "4"};
    public final static String[] FPS = new String[] {"0 (fullspeed)", "24",
            "-1 (off)"};

    public int decoderIndex;
    public int threadsIndex;
    public int fpsIndex;//渲染帧率
    public boolean enableYUVOutput;

    public DecoderSettings() {
        this.decoderIndex = 0;
        this.threadsIndex = 0;
        this.fpsIndex = 0;
        this.enableYUVOutput = false;
    }

    public DecoderSettings(SharedPreferences sharedPreferences) {
        this.decoderIndex = sharedPreferences.getInt(DECODER_SETTINGS_DECODER, 0);
        this.threadsIndex = sharedPreferences.getInt(DECODER_SETTINGS_THREADS, 0);
        this.fpsIndex = sharedPreferences.getInt(DECODER_SETTINGS_FPS, 0);
        this.enableYUVOutput = sharedPreferences.getBoolean(DECODER_SETTINGS_OUTPUT, false);
    }

    public String getDecoderName() {
        if (decoderIndex <= Decoders.length -1) {
            return Decoders[decoderIndex];
        } else {
            return "unknow";
        }
    }

    public int getThreads() {
        return threadsIndex;
    }

    public String getThreadsStr() {
        if (threadsIndex <= Threads.length -1) {
            return Threads[threadsIndex];
        } else {
            return "";
        }
    }

    public int getFPS() {
        switch (fpsIndex) {
            case 0:
                return 0;
            case 1:
                return 24;
            case 2:
                return -1;
            default:
                return 0;
        }
    }

    public String getFPSStr() {
        if (fpsIndex <= FPS.length -1) {
            return FPS[fpsIndex];
        } else {
            return "";
        }
    }
}
