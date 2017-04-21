package com.ksyun.media.ksy265codec.demo.ui;

import android.app.Dialog;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.DialogFragment;
import android.support.v7.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.RadioButton;
import android.widget.Spinner;

import com.ksyun.media.ksy265codec.demo.R;

/**
 * Created by sujia on 2017/3/28.
 */

public class DecoderSettingsFragment extends DialogFragment {
    private Spinner mDecoderSpinner;
    private Spinner mThreadSpinner;
    private Spinner mFpsSpinner;
    private Button mButton;
    private RadioButton mEnableOutputButton;
    private RadioButton mDisableOutputButton;

    private DecoderSettings mSettings;

    public interface OnSettingsChangeListener {
        public void onSettingsChanged(DecoderSettings settings);
    }

    // Use this instance of the interface to deliver action events
    OnSettingsChangeListener mListener;

    public DecoderSettingsFragment() {
        mSettings = Settings.getInstance().getDecoderSettings();
    }

    public void setListener(OnSettingsChangeListener listener) {
        mListener = listener;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        // Get the layout inflater
        LayoutInflater inflater = getActivity().getLayoutInflater();

        // Inflate and set the layout for the dialog
        // Pass null as the parent view because its going in the dialog layout
        View view = inflater.inflate(R.layout.decoder_settings, null);

        mSettings = Settings.getInstance().getDecoderSettings();
        initView(view);

        builder.setView(view);

        return builder.create();
    }

    private void initView(View view) {
        ArrayAdapter<String> decodersAdapter = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, DecoderSettings.Decoders);
        decodersAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mDecoderSpinner = (Spinner) view.findViewById(R.id.decoder_settings_decoder_spinner);
        mDecoderSpinner.setAdapter(decodersAdapter);
        if (mSettings.decoderIndex <= DecoderSettings.Decoders.length) {
            mDecoderSpinner.setSelection(mSettings.decoderIndex);
        }

        ArrayAdapter<String> threadsAdapter = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, DecoderSettings.Threads);
        threadsAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mThreadSpinner = (Spinner) view.findViewById(R.id.decoder_settings_threads_spinner);
        mThreadSpinner.setAdapter(threadsAdapter);
        if (mSettings.threadsIndex <= DecoderSettings.Threads.length) {
            mThreadSpinner.setSelection(mSettings.threadsIndex);
        }

        ArrayAdapter<String> fpsAdapter = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, DecoderSettings.FPS);
        fpsAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mFpsSpinner = (Spinner) view.findViewById(R.id.decoder_settings_fps_spinner);
        mFpsSpinner.setAdapter(fpsAdapter);
        if (mSettings.fpsIndex <= DecoderSettings.FPS.length) {
            mFpsSpinner.setSelection(mSettings.fpsIndex);
        }

        mEnableOutputButton = (RadioButton) view.findViewById(R.id.decoder_settings_enable_yuv_output);
        mDisableOutputButton = (RadioButton) view.findViewById(R.id.decoder_settings_disable_yuv_output);
        if (mSettings.enableYUVOutput) {
            mEnableOutputButton.setChecked(true);
            mDisableOutputButton.setChecked(false);
        } else {
            mEnableOutputButton.setChecked(false);
            mDisableOutputButton.setChecked(true);
        }

        mButton = (Button) view.findViewById(R.id.decoder_settings_sure);
        mButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mSettings.decoderIndex = mDecoderSpinner.getSelectedItemPosition();
                mSettings.threadsIndex = mThreadSpinner.getSelectedItemPosition();
                mSettings.fpsIndex = mFpsSpinner.getSelectedItemPosition();
                mSettings.enableYUVOutput = mEnableOutputButton.isChecked();

                Settings.getInstance().saveDecoderSettings(mSettings);
                if (mListener != null) {
                    mListener.onSettingsChanged(mSettings);
                }

                dismiss();
            }
        });
    }
}
