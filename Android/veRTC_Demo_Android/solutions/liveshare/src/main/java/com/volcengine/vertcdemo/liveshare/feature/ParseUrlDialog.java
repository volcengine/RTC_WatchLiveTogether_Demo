package com.volcengine.vertcdemo.liveshare.feature;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleEventObserver;

import com.volcengine.vertcdemo.liveshare.databinding.DialogParseUrlBinding;
import com.volcengine.vertcdemo.liveshare.utils.Util;
import com.volcengine.vertcdemo.utils.DebounceClickListener;

/**
 * 解析url进度对话框
 */
public class ParseUrlDialog extends Dialog {
    private DialogParseUrlBinding mViewBinding;
    private CancelListener mCancelListener;
    private FailedListener mFailedListener;

    public ParseUrlDialog(@NonNull Context context,
                          @NonNull Lifecycle lifecycle,
                          @NonNull OnDismissListener dismissListener) {
        super(context);
        lifecycle.addObserver((LifecycleEventObserver) (source, event) -> {
            if (event == Lifecycle.Event.ON_DESTROY) {
                dismiss();
            }
        });
        setOnDismissListener(dismissListener);
    }

    public void setCancelListener(CancelListener mCancelListener) {
        this.mCancelListener = mCancelListener;
    }

    public void setFailedListener(FailedListener mFailedListener) {
        this.mFailedListener = mFailedListener;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mViewBinding = DialogParseUrlBinding.inflate(getLayoutInflater());
        setContentView(mViewBinding.getRoot());
        setLayout();
        initUI();
    }

    private void setLayout() {
        Window window = getWindow();
        window.setBackgroundDrawableResource(android.R.color.transparent);
        window.setLayout(Util.dp2px(200), WindowManager.LayoutParams.WRAP_CONTENT);
        window.setGravity(Gravity.CENTER);
        window.setDimAmount(0);
    }

    private void initUI() {
        mViewBinding.cancelButton.setOnClickListener(DebounceClickListener.create(v -> {
            dismiss();
            if (mCancelListener != null) {
                mCancelListener.onCancel();
            }
        }));
        mViewBinding.failedButton.setOnClickListener(DebounceClickListener.create(v -> {
            dismiss();
            if (mFailedListener != null) {
                mFailedListener.onFailed();
            }
        }));
        setCanceledOnTouchOutside(false);
    }

    public void showParseFailed(@Nullable String hintText) {
        if (!TextUtils.isEmpty(hintText)) {
            mViewBinding.failedHintTv.setText(hintText);
        }
        mViewBinding.loadingCl.setVisibility(View.GONE);
        mViewBinding.failedCl.setVisibility(View.VISIBLE);
    }

    public void showParseFailed() {
        showParseFailed(null);
    }

    public interface CancelListener {
        void onCancel();
    }

    public interface FailedListener {
        void onFailed();
    }
}
