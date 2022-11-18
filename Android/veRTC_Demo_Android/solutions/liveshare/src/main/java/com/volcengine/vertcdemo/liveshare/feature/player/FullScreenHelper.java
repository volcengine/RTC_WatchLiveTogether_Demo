package com.volcengine.vertcdemo.liveshare.feature.player;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.pm.ActivityInfo;
import android.os.Build;
import android.view.DisplayCutout;
import android.view.Gravity;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.widget.FrameLayout;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;

public class FullScreenHelper {
    private boolean mInFullScreen;
    private final VideoView mVideoView;
    private final TextureView mVideoRenderView;
    private FrameLayout mFullScreenContainer;
    private ViewGroup mNonFullScreenContainer;
    private ViewGroup.LayoutParams mNonFullScreenLp;
    private int mNonFullScreenSuv;
    private WindowManager.LayoutParams mNonFullScreenWlp;

    public FullScreenHelper(@NonNull VideoView videoView) {
        mVideoView = videoView;
        mVideoRenderView = videoView.getVideoRenderView();
    }

    public void setFullScreenContainer(FrameLayout fullScreenContainer) {
        this.mFullScreenContainer = fullScreenContainer;
    }

    /**
     * 当前是否处于全屏状态
     */
    public boolean isInFullScreen() {
        return mInFullScreen;
    }

    /**
     * 进入全屏
     */
    @MainThread
    public void enterFullScreen(Context context) {
        if (mInFullScreen) return;
        Activity activity = scanForActivity(context);
        if (activity == null) return;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (hasDisplayCutout(activity.getWindow())) {
                activity.getWindow().getAttributes().layoutInDisplayCutoutMode =
                        WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            }
        }
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        mNonFullScreenContainer = (ViewGroup) mVideoView.getParent();
        if (mNonFullScreenContainer != null) {
            mNonFullScreenContainer.removeView(mVideoView);
        }
        mNonFullScreenLp = mVideoView.getLayoutParams();
        FrameLayout.LayoutParams clp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER);
        mFullScreenContainer.addView(mVideoView, clp);

        ViewParent oldParent = mVideoRenderView.getParent();
        if (oldParent instanceof ViewGroup) {
            ((ViewGroup) oldParent).removeView(mVideoRenderView);
        }
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER);
        mVideoView.addView(mVideoRenderView, 0, lp);

        final View decorView = activity.getWindow().getDecorView();
        mNonFullScreenSuv = decorView.getSystemUiVisibility();
        decorView.setSystemUiVisibility(getUiOptions(activity));

        mNonFullScreenWlp = getWindowLayoutParams(mVideoView);
        WindowManager.LayoutParams newWindowLp = new WindowManager.LayoutParams();
        newWindowLp.copyFrom(mNonFullScreenWlp);
        activity.getWindow().setAttributes(newWindowLp);

        activity.getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        mInFullScreen = true;
    }

    public static boolean hasDisplayCutout(Window window) {
        DisplayCutout displayCutout;
        View rootView = window.getDecorView();
        WindowInsets insets = null;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            insets = rootView.getRootWindowInsets();
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && insets != null) {
            displayCutout = insets.getDisplayCutout();
            if (displayCutout != null) {
                if (displayCutout.getBoundingRects() != null &&
                        displayCutout.getBoundingRects().size() > 0 &&
                        displayCutout.getSafeInsetTop() > 0) {
                    return true;
                }
            }
        }
        return true;
    }

    private int getUiOptions(Activity activity) {
        final View decorView = activity.getWindow().getDecorView();

        int uiOptions = decorView.getSystemUiVisibility();
        uiOptions |= View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                // Set the content to appear under the system bars so that the
                // content doesn't resize when the system bars hide and show.
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                // Hide the nav bar and status bar
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN;


        return uiOptions;
    }

    public static WindowManager.LayoutParams getWindowLayoutParams(View view) {
        if (view.getContext() instanceof Activity) {
            Activity activity = (Activity) view.getContext();
            if (activity != null) {
                Window window = activity.getWindow();
                if (window != null) {
                    return window.getAttributes();
                }
            }
        }
        return null;
    }

    /**
     * 进入全屏
     */
    @SuppressLint("SourceLockedOrientationActivity")
    @MainThread
    public void exitFullScreen(Context context) {
        if (!mInFullScreen) return;
        Activity activity = scanForActivity(context);
        if (activity == null) return;
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        ViewGroup parent = (ViewGroup) mVideoView.getParent();
        if (parent != null) {
            parent.removeView(mVideoView);
        }
        if (mNonFullScreenContainer != null && mNonFullScreenLp != null) {
            mNonFullScreenContainer.addView(mVideoView, mNonFullScreenLp);
        }
        final View decorView = activity.getWindow().getDecorView();
        decorView.setSystemUiVisibility(mNonFullScreenSuv);
        if (mNonFullScreenWlp != null) {
            activity.getWindow().setAttributes(mNonFullScreenWlp);
        }
        activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        mInFullScreen = false;
    }

    public static Activity scanForActivity(Context context) {
        if (context == null) return null;
        if (context instanceof Activity) {
            return (Activity) context;
        } else if (context instanceof ContextWrapper) {
            return scanForActivity(((ContextWrapper) context).getBaseContext());
        }
        return null;
    }
}
