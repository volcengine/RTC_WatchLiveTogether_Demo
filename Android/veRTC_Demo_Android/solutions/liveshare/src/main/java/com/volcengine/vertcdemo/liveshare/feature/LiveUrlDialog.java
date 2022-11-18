package com.volcengine.vertcdemo.liveshare.feature;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleEventObserver;

import com.ss.video.rtc.demo.basic_module.adapter.TextWatcherAdapter;
import com.ss.video.rtc.demo.basic_module.utils.IMEUtils;
import com.ss.video.rtc.demo.basic_module.utils.SafeToast;
import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.databinding.DialogLiveUrlBinding;
import com.volcengine.vertcdemo.liveshare.utils.Util;
import com.volcengine.vertcdemo.utils.DebounceClickListener;

import java.net.URI;

/**
 * 输入直播网址对话框
 */
public class LiveUrlDialog extends Dialog {
    private String mLiveUrl;
    private boolean mIsLandscape = true;
    private final TriggerLiveShareListener mTriggerLiveShareListener;
    private DialogLiveUrlBinding mViewBinding;

    public LiveUrlDialog(@NonNull Context context,
                         @NonNull TriggerLiveShareListener listener,
                         @NonNull Lifecycle lifecycle) {
        super(context);
        mTriggerLiveShareListener = listener;
        lifecycle.addObserver((LifecycleEventObserver) (source, event) -> {
            if (event == Lifecycle.Event.ON_DESTROY) {
                dismiss();
            }
        });
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mViewBinding = DialogLiveUrlBinding.inflate(getLayoutInflater());
        setContentView(mViewBinding.getRoot());
        setLayout();
        initUI();
    }

    private void setLayout() {
        Window window = getWindow();
        window.setBackgroundDrawableResource(android.R.color.transparent);
        window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.WRAP_CONTENT);
        window.setGravity(Gravity.BOTTOM);
        window.setDimAmount(0);
    }

    private void initUI() {
        mViewBinding.liveUrlEt.addTextChangedListener(new TextWatcherAdapter() {
            @Override
            public void afterTextChanged(Editable s) {
                mLiveUrl = s.toString();
            }
        });
        mViewBinding.screenOrientationRg.setOnCheckedChangeListener((group, checkedId) -> {
            mIsLandscape = checkedId == R.id.screen_orientation_landscape_rb;
        });
        mViewBinding.triggerLiveShareBtn.setOnClickListener(DebounceClickListener.create(v -> {
            if (TextUtils.isEmpty(mLiveUrl)) {
                SafeToast.show(Util.getString(R.string.live_url_empty_hint));
                return;
            }
            URI uri = null;
            try {
                uri = URI.create(mLiveUrl);
            } catch (IllegalArgumentException exception) {
                //Ignore
            }
            if (uri == null || TextUtils.isEmpty(uri.getScheme())) {
                SafeToast.show(Util.getString(R.string.paring_url_failed));
                return;
            }
            IMEUtils.closeIME(v);
            if (mTriggerLiveShareListener == null) {
                return;
            }
            dismiss();
            mTriggerLiveShareListener.triggerLiveShare(mLiveUrl, mIsLandscape);
        }));
    }

    public interface TriggerLiveShareListener {
        /**
         * @param liveUrl     直播地址
         * @param isLandscape 是否横屏播放
         */
        void triggerLiveShare(String liveUrl, boolean isLandscape);
    }
}
