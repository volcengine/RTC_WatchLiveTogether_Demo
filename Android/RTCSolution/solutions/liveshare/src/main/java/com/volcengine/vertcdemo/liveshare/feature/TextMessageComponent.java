// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature;

import android.graphics.Rect;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleEventObserver;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.volcengine.vertcdemo.utils.AppUtil;
import com.volcengine.vertcdemo.utils.Utils;
import com.volcengine.vertcdemo.common.InputTextDialogFragment;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.eventbus.SolutionDemoEventManager;
import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.bean.User;
import com.volcengine.vertcdemo.liveshare.bean.inform.JoinRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.LeaveRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.ReceiveMessageInform;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTSClient;
import com.volcengine.vertcdemo.liveshare.databinding.ActivityLiveShareBinding;
import com.volcengine.vertcdemo.liveshare.utils.Util;
import com.volcengine.vertcdemo.utils.DebounceClickListener;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;

public class TextMessageComponent {
    private static final String TAG = "TextMessageComponent";
    private final ActivityLiveShareBinding mHostViewBinding;
    private final LiveShareRTSClient mRTSClient;
    private final String mRoomId;
    private final String mSelfUid;
    private final TextMessageAdapter mTextMessageAdapter;
    private boolean mEnableMessagePrint = true; // 是否打印消息

    public TextMessageComponent(@NonNull ActivityLiveShareBinding hostViewBinding,
                                @NonNull String roomId,
                                @NonNull String selfUid,
                                @NonNull LiveShareRTSClient RTSClient,
                                @NonNull AppCompatActivity activity) {
        mHostViewBinding = hostViewBinding;
        mRoomId = roomId;
        mSelfUid = selfUid;
        mRTSClient = RTSClient;
        activity.getLifecycle().addObserver((LifecycleEventObserver) (source, event) -> {
            if (event.ordinal() == Lifecycle.Event.ON_CREATE.ordinal()) {
                SolutionDemoEventManager.register(TextMessageComponent.this);
            } else if (event.ordinal() == Lifecycle.Event.ON_DESTROY.ordinal()) {
                SolutionDemoEventManager.unregister(TextMessageComponent.this);
            }
        });
        LinearLayoutManager layoutManager = new LinearLayoutManager(mHostViewBinding.getRoot().getContext());
        mHostViewBinding.textMessageRcv.setLayoutManager(layoutManager);
        mTextMessageAdapter = new TextMessageAdapter();
        mHostViewBinding.textMessageRcv.setAdapter(mTextMessageAdapter);
        mHostViewBinding.textMessageRcv.addItemDecoration(new ItemDivider(Util.dp2px(4)));

        mHostViewBinding.triggerInputBtn.setOnClickListener(DebounceClickListener.create(v -> {
            InputTextDialogFragment.showInput(activity.getSupportFragmentManager(), (this::onSendMessage));
        }));
    }

    /**
     * 是否开启消息打印
     * @param enable 表示开始消息的打印
     */
    public void enableMessagePrint(boolean enable) {
        mEnableMessagePrint = enable;
    }

    /**
     * 清除所有文本信息
     */
    public void clearTextMessage() {
        mTextMessageAdapter.clearTextMessage();
    }

    /**
     * 发送消息事件响应
     * @param fragment 输入面板
     * @param message 要发送的消息
     */
    private void onSendMessage(InputTextDialogFragment fragment, String message) {
        if (TextUtils.isEmpty(message)) {
            fragment.dismiss();
            return;
        }
        showTextMessage(message, SolutionDataManager.ins().getUserName());
        try {
            message = URLEncoder.encode(message, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        mRTSClient.sendTextMessage(mRoomId, mSelfUid, message);
        fragment.dismiss();
    }

    /**
     * 业务用户进入入房事件
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onUserJoin(JoinRoomInform inform) {
        User user = inform.user;
        if (user == null) {
            return;
        }
        String userName = user.userName;
        String msg = userName + AppUtil.getApplicationContext().getString(R.string.live_joined_the_room);
        showSystemMessage(msg);
    }

    /**
     * 业务用户离开事件回调
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onUserLeave(LeaveRoomInform inform) {
        User user = inform.user;
        if (user == null) {
            return;
        }
        String userName = user.userName;
        String msg = userName + AppUtil.getApplicationContext().getString(R.string.live_left_room);
        showSystemMessage(msg);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onReceivedTextMessage(ReceiveMessageInform inform) {
        if (inform == null || TextUtils.isEmpty(inform.message)) {
            return;
        }
        String senderUid = inform.sendUser == null ? null : inform.sendUser.userId;
        if (!TextUtils.isEmpty(mSelfUid) && TextUtils.equals(senderUid, mSelfUid)) {
            return;
        }
        try {
            String msg = URLDecoder.decode(inform.message, "UTF-8");
            String sender = inform.sendUser == null ? null : inform.sendUser.userName;
            showTextMessage(msg, sender);
        } catch (UnsupportedEncodingException exception) {
            Log.d(TAG, "onReceivedTextMessage exception:" + exception.getMessage());
        }
    }

    private void showTextMessage(String msg, String senderUsername) {
        StringBuilder sb = new StringBuilder();
        if (!TextUtils.isEmpty(senderUsername)) {
            sb.append(senderUsername).append(":");
        }
        sb.append(msg);
        mTextMessageAdapter.addTextMessage(sb.toString());
        int size = mTextMessageAdapter.getItemCount();
        mHostViewBinding.textMessageRcv.scrollToPosition(size - 1);
    }

    /**
     * 展示系统消息
     * @param msg 消息内容
     */
    private void showSystemMessage(String msg) {
        if (!mEnableMessagePrint) {
            return;
        }
        mTextMessageAdapter.addTextMessage(msg);
        int size = mTextMessageAdapter.getItemCount();
        mHostViewBinding.textMessageRcv.scrollToPosition(size - 1);
    }

    private static class ItemDivider extends RecyclerView.ItemDecoration {
        private final int spacing;

        public ItemDivider(int spacings) {
            spacing = spacings;
        }

        @Override
        public void getItemOffsets(@NonNull Rect outRect, @NonNull View view, @NonNull RecyclerView parent, @NonNull RecyclerView.State state) {
            super.getItemOffsets(outRect, view, parent, state);
            outRect.bottom = spacing;
        }
    }
}
