// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

public interface PlayerEvent {
    /**
     * 播放事件代码
     */
    int code();

    class Action {

        public static final int SET_SURFACE = 1001;

        public static final int PREPARE = 1002;

        public static final int START = 1003;

        public static final int PAUSE = 1004;

        public static final int STOP = 1005;

        public static final int RELEASE = 1006;

        public static final int ENTER_FULL_SCREEN = 1007;

        public static final int EXIT_FULL_SCREEN = 1008;
    }


    class State {

        public static final int IDLE = 2001;

        public static final int PREPARING = 2002;
        public static final int PREPARED = 2003;

        public static final int STARTED = 2004;

        public static final int FIRST_FRAME = 2005;

        public static final int VIDEO_SIZE_CHANGED = 2006;

        public static final int PAUSED = 2007;

        public static final int STOPPED = 2008;

        public static final int RELEASED = 2009;

        public static final int COMPLETED = 2010;

        public static final int ERROR = 2011;

    }


    class Info {

        public static final int DATA_SOURCE_REFRESHED = 3001;

        public static final int VIDEO_SIZE_CHANGED = 3002;

        public static final int VIDEO_SAR_CHANGED = 3003;

    }
}
