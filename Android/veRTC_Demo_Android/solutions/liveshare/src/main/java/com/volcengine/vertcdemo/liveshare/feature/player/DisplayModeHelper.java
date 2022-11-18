/*
 * Copyright (C) 2021 bytedance
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Create Date : 2021/12/3
 */

package com.volcengine.vertcdemo.liveshare.feature.player;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.FrameLayout.LayoutParams;

import androidx.annotation.IntDef;

import com.volcengine.vertcdemo.liveshare.utils.Util;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

public class DisplayModeHelper {
    private static final String TAG = "DisplayModeHelper";

    @IntDef({DISPLAY_MODE_DEFAULT,
            DISPLAY_MODE_ASPECT_FILL_X,
            DISPLAY_MODE_ASPECT_FILL_Y,
            DISPLAY_MODE_ASPECT_FIT,
            DISPLAY_MODE_ASPECT_FILL})
    @Retention(RetentionPolicy.SOURCE)
    public @interface DisplayMode {
    }

    /**
     * 画面宽高都充满控件，可能会变形
     */
    public static final int DISPLAY_MODE_DEFAULT = 0;
    /**
     * 画面宽充满控件，高按视频比例适配
     */
    public static final int DISPLAY_MODE_ASPECT_FILL_X = 1;
    /**
     * 画面高充满控件，宽按视频比例适配
     */
    public static final int DISPLAY_MODE_ASPECT_FILL_Y = 2;
    /**
     * 画面长边充满控件，短边按比例适配。保证画面不被裁剪，可能有黑边
     */
    public static final int DISPLAY_MODE_ASPECT_FIT = 3;
    /**
     * 画面短边充满控件，长边按比例适配。画面可能会被裁剪，没有黑边
     */
    public static final int DISPLAY_MODE_ASPECT_FILL = 4;

    private int mVideoWidth;
    private int mVideoHeight;
    @DisplayMode
    private int mDisplayMode = DISPLAY_MODE_ASPECT_FIT;

    private FrameLayout mContainerView;
    private View mDisplayView;

    public static String map(@DisplayMode int displayMode) {
        switch (displayMode) {
            case DISPLAY_MODE_DEFAULT:
                return "default";
            case DISPLAY_MODE_ASPECT_FILL_X:
                return "aspect_fill_x";
            case DISPLAY_MODE_ASPECT_FILL_Y:
                return "aspect_fill_y";
            case DISPLAY_MODE_ASPECT_FIT:
                return "aspect_fit";
            case DISPLAY_MODE_ASPECT_FILL:
                return "aspect_fill";
            default:
                throw new IllegalArgumentException("unsupported displayMode! " + displayMode);
        }
    }

    public void setVideoSize(int videoWidth, int videoHeight) {
        mVideoWidth = videoWidth;
        mVideoHeight = videoHeight;
        apply();
    }

    public void setDisplayMode(@DisplayMode int displayMode) {
        mDisplayMode = displayMode;
        apply();
    }

    @DisplayMode
    public int getDisplayMode() {
        return mDisplayMode;
    }

    public void setContainerView(FrameLayout containerView) {
        mContainerView = containerView;
        apply();
    }

    public void setDisplayView(View displayView) {
        mDisplayView = displayView;
        apply();
    }

    public void apply() {
        if (mDisplayView == null) return;
        mDisplayView.removeCallbacks(applyDisplayMode);
        mDisplayView.postOnAnimation(applyDisplayMode);
    }

    private final Runnable applyDisplayMode = this::applyDisplayMode;

    private void applyDisplayMode() {
        final View containerView = mContainerView;
        if (containerView == null) return;
        int containerWidth = containerView.getWidth();
        int containerHeight = containerView.getHeight();
        Activity activity = Util.scanForActivity(containerView.getContext());
        if (activity == null) return;
        int screenOrientation = activity.getRequestedOrientation();
        int newContainerWidth = containerWidth;
        int newContainerHeight = containerHeight;
        if (screenOrientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
            newContainerWidth = Math.max(containerHeight, containerWidth);
            newContainerHeight = Math.min(containerHeight, containerWidth);
        } else if (screenOrientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT) {
            newContainerWidth = Math.min(containerHeight, containerWidth);
            newContainerHeight = Math.max(containerHeight, containerWidth);
        }
        containerWidth = newContainerWidth;
        containerHeight = newContainerHeight;
        final View displayView = mDisplayView;
        if (displayView == null) return;
        final int displayMode = mDisplayMode;
        //displayAspectRatio: > 1 横版视频  < 1 竖版视屏
        float displayAspectRatio = calDisplayAspectRatio();
        if (displayAspectRatio < 0) return;
        //containerRatio: > 1 手机横屏  < 1 手机竖屏
        final float containerRatio = containerWidth / (float) containerHeight;

        int displayGravity = Gravity.CENTER;
        int displayWidth;
        int displayHeight;

        switch (displayMode) {
            case DISPLAY_MODE_DEFAULT:
                displayWidth = containerWidth;
                displayHeight = containerHeight;
                break;
            case DISPLAY_MODE_ASPECT_FILL_X:
                displayWidth = containerWidth;
                displayHeight = (int) (containerWidth / displayAspectRatio);
                break;
            case DISPLAY_MODE_ASPECT_FILL_Y:
                displayWidth = (int) (containerHeight * displayAspectRatio);
                displayHeight = containerHeight;
                break;
            case DISPLAY_MODE_ASPECT_FIT:
                displayHeight = containerHeight;
                displayWidth = containerWidth;
                if (displayAspectRatio > containerRatio) {
                    displayHeight = (int) (containerWidth / displayAspectRatio);
                } else {
                    displayWidth = (int) (containerHeight * displayAspectRatio);
                }
                break;
            case DISPLAY_MODE_ASPECT_FILL:
                if (displayAspectRatio >= containerRatio) {
                    displayWidth = (int) (containerHeight * displayAspectRatio);
                    displayHeight = containerHeight;
                } else {
                    displayWidth = containerWidth;
                    displayHeight = (int) (containerWidth / displayAspectRatio);
                }
                break;
            default:
                throw new IllegalArgumentException("unknown displayMode = " + displayMode);
        }

        final LayoutParams displayLP = (LayoutParams) displayView.getLayoutParams();
        if (displayLP == null) return;
        if (displayLP.height != displayHeight
                || displayLP.width != displayWidth
                || displayLP.gravity != displayGravity) {
            displayLP.gravity = displayGravity;
            displayLP.width = displayWidth;
            displayLP.height = displayHeight;
            displayView.requestLayout();
        }
    }

    private float calDisplayAspectRatio() {
        float displayAspectRatio = -1;
        float pixelAspectRatio = -1;
        final int videoWidth = mVideoWidth;
        final int videoHeight = mVideoHeight;
        if (videoWidth > 0 && videoHeight > 0) {
            pixelAspectRatio = videoWidth / (float) videoHeight;
        }
        if (pixelAspectRatio > 0) {
            displayAspectRatio = pixelAspectRatio;
        }
        return displayAspectRatio;
    }
}
