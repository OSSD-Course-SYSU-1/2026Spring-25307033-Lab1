/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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
 */

#ifndef AVPLAYING_PLAYING_H
#define AVPLAYING_PLAYING_H

#include <cstdint>
#include <multimedia/player_framework/avplayer_base.h>
#include <uv.h>

enum PlayStatus { Play = 1, Pause = 2 };

class AVPlayer {
private:
    AVPlayer() = default;
    AVPlayer(const AVPlayer &) = delete;            // Forbid copying construction
    AVPlayer &operator=(const AVPlayer &) = delete; // Forbid assignment construction
    // In singleton mode, local static singletons will release memory when the program ends.
    ~AVPlayer() { ReleasePlayer(); }

private:
    OH_AVPlayer *ohAVPlayer = nullptr;
    float lastVolume = 1;

public:
    void InitPlayer();
    void LoadSongInfo(uint32_t songFd, uint32_t songFileSize, uint32_t songFileOffset);
    void SetPlayInfo();
    void PlaySong();
    void PauseSong();
    void StopSong();
    int32_t GetProgress();
    void SeekPlaySong(uint32_t timeStamp);
    void SetPlayingSpeed(float speed);
    void SetPlayingVolume(float volume);
    void SetSilentMode(bool isSilentMode);
    void ReleasePlayer();
    void (*PlayStatusCallback)(void *context, PlayStatus playStatus) = nullptr;
    void *PlayStatusCallbackContext = nullptr;
    bool WaitPlay = false;
    int32_t PlayerState = AV_IDLE;


    static AVPlayer &GetInstance() {
        static AVPlayer instance;
        return instance;
    }
};

#endif // AVPLAYING_PLAYING_H