package com.ksyun.media.ksy265codec.demo.ui;

import android.app.Application;

/**
 * Created by sujia on 2017/3/28.
 */

public class KSY265CodecDemoApp extends Application {
    @Override
    public void onCreate() {

        super.onCreate();

        Settings.getInstance().init(this);
    }
}
