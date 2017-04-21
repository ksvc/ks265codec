package com.ksyun.media.ksy265codec.demo.ui;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.ipaulpro.afilechooser.FileChooserActivity;
import com.ipaulpro.afilechooser.utils.FileUtils;
import com.ksyun.media.ksy265codec.demo.R;

import static android.app.Activity.RESULT_OK;
import static android.content.ContentValues.TAG;

/**
 * Created by sujia on 2017/3/27.
 */

public class BaseFragment extends Fragment {
    private static final int REQUEST_CODE = 6384; // onActivityResult request code

    protected Button mSettingButton;
    protected Button mHelpButton;
    protected Button mNavButton;
    protected Button mStartButton;

    private ButtonObserver mButtonObserver;

    protected EditText mFilePathEditTxt;
    protected String mInputFilePath;
    protected String mOutputFilePath;

    protected TextView mTitleText;
    protected TextView mInfoText;

    protected SurfaceView mSurfaceView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_item, null);

        mTitleText =  (TextView) view.findViewById(R.id.title_txt);
        mInfoText = (TextView) view.findViewById(R.id.info_txt);
        mInfoText.setMovementMethod(ScrollingMovementMethod.getInstance());

        mButtonObserver = new ButtonObserver();

        mSettingButton = (Button) view.findViewById(R.id.settings);
        mSettingButton.setOnClickListener(mButtonObserver);

        mHelpButton = (Button) view.findViewById(R.id.help);
        mHelpButton.setOnClickListener(mButtonObserver);

        mNavButton = (Button) view.findViewById(R.id.nav);
        mNavButton.setOnClickListener(mButtonObserver);

        mStartButton = (Button) view.findViewById(R.id.start);
        mStartButton.setOnClickListener(mButtonObserver);

        mFilePathEditTxt = (EditText) view.findViewById(R.id.filepath);

        mSurfaceView = (SurfaceView) view.findViewById(R.id.surface_view);
        mSurfaceView.setVisibility(View.GONE);
        return view;
    }

    private class ButtonObserver implements View.OnClickListener {
        @Override
        public void onClick(View view) {
            switch (view.getId()) {
                case R.id.settings:
                    onSettingsClicked();
                    break;
                case R.id.help:
                    onHelpClicked();
                    break;
                case R.id.nav:
                    onNavClicked();
                    break;
                case R.id.start:
                    onStartClicked();
                    break;
                default:
                    break;
            }
        }
    }

    protected void onSettingsClicked() {
    }

    protected void onHelpClicked() {
    }

    protected void onNavClicked() {
        showChooser();
    }

    private void showChooser() {
        //set file filter
        FileUtils.setFileFilter(new FileUtils.FileFilterBySuffixs("yuv|264|h264|avc|265|hevc|h265|hm91|hm10|bit|hvc"));
        Intent intent = new Intent(getContext(), FileChooserActivity.class);
        startActivityForResult(intent, REQUEST_CODE);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
            case REQUEST_CODE:
                // If the file selection was successful
                if (resultCode == RESULT_OK) {
                    if (data != null) {
                        // Get the URI of the selected file
                        final Uri uri = data.getData();
                        Log.i(TAG, "Uri = " + uri.toString());
                        try {
                            // Get the file path from the URI
                            mInputFilePath = FileUtils.getPath(getContext(), uri);
                            mFilePathEditTxt.setText(mInputFilePath);

                        } catch (Exception e) {
                            Log.e(TAG, "File select error: " + e);
                        }
                    }
                }
                break;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    protected void onStartClicked() {
    }

    protected void toggleView(boolean enable) {
        mSettingButton.setEnabled(enable);
        mNavButton.setEnabled(enable);
        mStartButton.setEnabled(enable);
        mHelpButton.setEnabled(enable);
    }
}
