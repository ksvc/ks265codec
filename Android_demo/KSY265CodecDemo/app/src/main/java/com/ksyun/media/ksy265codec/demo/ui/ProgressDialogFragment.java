package com.ksyun.media.ksy265codec.demo.ui;

import android.app.Dialog;
import android.app.ProgressDialog;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;

/**
 * Created by sujia on 2017/4/7.
 */

public class ProgressDialogFragment extends DialogFragment
{
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setCancelable(false);
    }

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState)
    {
        ProgressDialog dialog = new ProgressDialog(getActivity());
        dialog.setTitle("请等待");
        dialog.setMessage("编码中...");
        dialog.setIndeterminate(true);
        dialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
        return dialog;
    }
}