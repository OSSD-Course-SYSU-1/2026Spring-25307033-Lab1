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

#include "avplayer_playing.h"
#include <cstdint>
#include <multimedia/player_framework/avplayer.h>
#include <multimedia/player_framework/native_averrors.h>
#include <hilog/log.h>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "AVPLAYER_PLAYING"

// [Start OHAVPlayerOnStateChange]
// On player state change and process it
static void OHAVPlayerOnStateChange(OH_AVPlayer *player, int32_t playerState) {
    AVPlayer::GetInstance().PlayerState = playerState;
    switch (playerState) {
    case AV_IDLE:
        OH_LOG_INFO(LOG_APP, "playerState: AV_IDLE.");
        break;
    case AV_INITIALIZED:
        // [StartExclude OHAVPlayerOnStateChange]
        OH_LOG_INFO(LOG_APP, "playerState: AV_INITIALIZED.");
        {
            // Set audio renderer info
            auto ret = OH_AVPlayer_SetAudioRendererInfo(player, AUDIOSTREAM_USAGE_MUSIC);
            if (ret != AV_ERR_OK) {
                OH_LOG_ERROR(LOG_APP, "Set audio renderer info failed, ret: %{public}d", ret);
                (void)OH_AVPlayer_Release(player);
                player = nullptr;
                break;
            }
            // [Start Prepare]
            // [EndExclude OHAVPlayerOnStateChange]
            // Prepare player
            ret = OH_AVPlayer_Prepare(player);
            // [StartExclude OHAVPlayerOnStateChange]
            if (ret != AV_ERR_OK) {
                OH_LOG_ERROR(LOG_APP, "Prepare player failed, ret: %{public}d", ret);
                (void)OH_AVPlayer_Release(player);
                player = nullptr;
            }
            // [End Prepare]
        }
        // [EndExclude OHAVPlayerOnStateChange]
        break;
    case AV_PREPARED:
        OH_LOG_INFO(LOG_APP, "playerState: AV_PREPARED.");
        // [StartExclude OHAVPlayerOnStateChange]
        {
            // Set audio volume mode
            auto ret = OH_AVPlayer_SetVolumeMode(player, AUDIOSTREAM_VOLUMEMODE_APP_INDIVIDUAL);
            if (ret != AV_ERR_OK) {
                OH_LOG_ERROR(LOG_APP, "Set audio volume mode failed, ret: %{public}d", ret);
                (void)OH_AVPlayer_Release(player);
                player = nullptr;
                break;
            }
            // Set audio interrupt mode
            ret = OH_AVPlayer_SetAudioInterruptMode(player, AUDIOSTREAM_INTERRUPT_MODE_SHARE);
            if (ret != AV_ERR_OK) {
                OH_LOG_ERROR(LOG_APP, "Set audio interrupt mode failed, ret: %{public}d", ret);
                (void)OH_AVPlayer_Release(player);
                player = nullptr;
                break;
            }
            // Set audio effect mode
            ret = OH_AVPlayer_SetAudioEffectMode(player, EFFECT_DEFAULT);
            if (ret != AV_ERR_OK) {
                OH_LOG_ERROR(LOG_APP, "Set audio effect mode failed, ret: %{public}d", ret);
                (void)OH_AVPlayer_Release(player);
                player = nullptr;
            }
            // [EndExclude OHAVPlayerOnStateChange]
            if (AVPlayer::GetInstance().WaitPlay) {
                AVPlayer::GetInstance().PlaySong();
            }
            // [StartExclude OHAVPlayerOnStateChange]
        }
        // [EndExclude OHAVPlayerOnStateChange]
        break;
        // [StartExclude OHAVPlayerOnStateChange]
    case AV_PLAYING:
        OH_LOG_INFO(LOG_APP, "playerState: AV_PLAYING.");
        break;
    case AV_PAUSED:
        OH_LOG_INFO(LOG_APP, "playerState: AV_PAUSED.");
        break;
    case AV_STOPPED:
        OH_LOG_INFO(LOG_APP, "playerState: AV_STOPPED.");
        break;
    case AV_COMPLETED:
        OH_LOG_INFO(LOG_APP, "playerState: AV_COMPLETED.");
        break;
    case AV_ERROR:
        OH_LOG_INFO(LOG_APP, "playerState: AV_ERROR.");
        break;
    case AV_RELEASED:
        OH_LOG_INFO(LOG_APP, "playerState: AV_RELEASED.");
        break;
         // [EndExclude OHAVPlayerOnStateChange]
    default:
        break;
    }
}
// [End OHAVPlayerOnStateChange]

// On player interrupt event and process it
static void OHAVPlayerOnInterruptEvent(OH_AVPlayer *player, int32_t interruptForce, int32_t interruptHint) {
    if ((interruptForce == 1) && (interruptHint == 1)) {
        auto ret = OH_AVPlayer_Play(player);
        if (ret != AV_ERR_OK) {
            OH_LOG_ERROR(LOG_APP, "Resume play song failed, ret: %{public}d", ret);
            return;
        }
        OH_LOG_INFO(LOG_APP, "Resume play song successfully.");
        AVPlayer::GetInstance().PlayStatusCallback(AVPlayer::GetInstance().PlayStatusCallbackContext, PlayStatus::Play);
    } else if (interruptHint == AUDIOSTREAM_INTERRUPT_HINT_PAUSE || interruptHint == AUDIOSTREAM_INTERRUPT_HINT_STOP) {
        AVPlayer::GetInstance().PlayStatusCallback(AVPlayer::GetInstance().PlayStatusCallbackContext,
                                                   PlayStatus::Pause);
    }
}

// [Start OHAVPlayerOnInfoCallback]
// Define OHAVPlayerOnInfoCallback function
static void OHAVPlayerOnInfoCallback(OH_AVPlayer *player, AVPlayerOnInfoType type, OH_AVFormat *infoBody,
                                     [[maybe_unused]] void *userData) {
    if (player == nullptr) {
        OH_LOG_ERROR(LOG_APP, "OHAVPlayerOnInfoCallback: the player is null.");
        return;
    }
    switch (type) {
    case AV_INFO_TYPE_STATE_CHANGE: {
        int32_t playerState = 0;
        int32_t stateChangeReason = 0;
        OH_AVFormat_GetIntValue(infoBody, OH_PLAYER_STATE, &playerState);
        OH_AVFormat_GetIntValue(infoBody, OH_PLAYER_STATE_CHANGE_REASON, &stateChangeReason);
        OH_LOG_INFO(LOG_APP, "The player state has been changed, state: %{public}d, reason: %{public}d.", playerState,
                    stateChangeReason);
        OHAVPlayerOnStateChange(player, playerState);
    } break;
     // [StartExclude OHAVPlayerOnInfoCallback]   
    case AV_INFO_TYPE_INTERRUPT_EVENT: {
        int32_t interruptType = 0;
        int32_t interruptForce = 0;
        int32_t interruptHint = 0;
        OH_AVFormat_GetIntValue(infoBody, OH_PLAYER_AUDIO_INTERRUPT_TYPE, &interruptType);
        OH_AVFormat_GetIntValue(infoBody, OH_PLAYER_AUDIO_INTERRUPT_FORCE, &interruptForce);
        OH_AVFormat_GetIntValue(infoBody, OH_PLAYER_AUDIO_INTERRUPT_HINT, &interruptHint);
        OH_LOG_INFO(LOG_APP, "interruptType: %{public}d, interruptForce: %{public}d, interruptHint: %{public}d",
                    interruptType, interruptForce, interruptHint);
        OHAVPlayerOnInterruptEvent(player, interruptForce, interruptHint);
    } break;
    default:
        break;
    }
    // [EndExclude OHAVPlayerOnInfoCallback]   
}
// [End OHAVPlayerOnInfoCallback]

// [Start OHAVPlayerOnErrorCallback]
// Define OHAVPlayerOnErrorCallback function
static void OHAVPlayerOnErrorCallback([[maybe_unused]] OH_AVPlayer *player, int32_t errCode, const char *errMsg,
                                      [[maybe_unused]] void *userData) {
    OH_LOG_ERROR(LOG_APP, "OHAVPlayerOnErrorCallback, errCode: %{public}d, errMsg: %{public}s.", errCode, errMsg);
}
// [End OHAVPlayerOnErrorCallback]

// [Start InitPlayer]
void AVPlayer::InitPlayer() {
    // Check the residual status of the previous player
    if (ohAVPlayer != nullptr) {
        OH_LOG_INFO(LOG_APP, "Previous audio player remained and release it.");
        ReleasePlayer();
    }

    ohAVPlayer = OH_AVPlayer_Create();
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "Create AVPlayer instance failed.");
        return;
    }
    // [StartExclude InitPlayer]
    // Set OH_AVPlayerOnInfoCallback
    auto ret = OH_AVPlayer_SetOnInfoCallback(ohAVPlayer, OHAVPlayerOnInfoCallback, nullptr);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Set OH_AVPlayerOnInfoCallback failed, ret: %{public}d", ret);
        ReleasePlayer();
        return;
    }
    // Set OH_AVPlayerOnErrorCallback
    ret = OH_AVPlayer_SetOnErrorCallback(ohAVPlayer, OHAVPlayerOnErrorCallback, nullptr);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Set OH_AVPlayerOnErrorCallback failed, ret: %{public}d", ret);
        ReleasePlayer();
        return;
    }
    // [EndExclude InitPlayer]

    OH_LOG_INFO(LOG_APP, "Init player successfully.");
}
// [End InitPlayer]

// [Start LoadSongInfo]
void AVPlayer::LoadSongInfo(uint32_t songFd, uint32_t songFileSize, uint32_t songFileOffset) {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }

    AVPlayerState playerState = AV_IDLE;

    auto ret = OH_AVPlayer_GetState(ohAVPlayer, &playerState);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Get player state failed, ret: %{public}d", ret);
        return;
    }

    // When the application loads or plays the first song for the first time, the player does not need to be reset
    // In addition, the player cannot be reset in idle state, otherwise an error will be reported
    // When playing for the first time, the player is in idle state after creation.
    if (playerState != AV_IDLE) {
        // [Start reset]
        ret = OH_AVPlayer_Reset(ohAVPlayer);
        if (ret != AV_ERR_OK) {
            OH_LOG_ERROR(LOG_APP, "Reset player failed, ret: %{public}d", ret);
            return;
        }
        // [End reset]
    }

    ret = OH_AVPlayer_SetFDSource(ohAVPlayer, songFd, songFileOffset, songFileSize);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Load song information failed, ret: %{public}d", ret);
        return;
    }

    OH_LOG_INFO(LOG_APP,
                "Load song information successfully. "
                "Song fd: %{public}d, "
                "file size: %{public}d, "
                "file offset: %{public}d.",
                songFd, songFileSize, songFileOffset);
}
// [End LoadSongInfo]

// [Start PlaySong]
void AVPlayer::PlaySong() {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    if (PlayerState != AV_PREPARED && PlayerState != AV_PAUSED && PlayerState != AV_STOPPED &&
        PlayerState != AV_COMPLETED) {
        WaitPlay = true;
        return;
    }
    auto ret = OH_AVPlayer_Play(ohAVPlayer);
    WaitPlay = false;
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Play song failed, ret: %{public}d", ret);
        return;
    }
    OH_LOG_INFO(LOG_APP, "Play song successfully.");
}
// [End PlaySong]

// [Start GetProgress]
int32_t AVPlayer::GetProgress() {
    int32_t currentTime;
    auto ret = OH_AVPlayer_GetCurrentTime(ohAVPlayer, &currentTime);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Get CurrentTime Fail, ret: %{public}d", ret);
        return 0;
    }
    return currentTime;
}
// [End GetProgress]

// [Start PauseSong]
void AVPlayer::PauseSong() {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    auto ret = OH_AVPlayer_Pause(ohAVPlayer);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Pause song failed, ret: %{public}d", ret);
        return;
    }

    OH_LOG_INFO(LOG_APP, "Pause song successfully.");
}
// [End PauseSong]

// [Start StopSong]
void AVPlayer::StopSong() {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    auto ret = OH_AVPlayer_Stop(ohAVPlayer);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Stop song failed, ret: %{public}d", ret);
        return;
    }
    OH_LOG_INFO(LOG_APP, "Stop song successfully.");
}
// [End StopSong]

// [Start SeekPlaySong]
void AVPlayer::SeekPlaySong(uint32_t timeStamp) {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    auto ret = OH_AVPlayer_Seek(ohAVPlayer, timeStamp, AV_SEEK_CLOSEST);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Seek song failed, ret: %{public}d", ret);
        return;
    }
    OH_LOG_INFO(LOG_APP, "Seek song successfully.");
}
// [End SeekPlaySong]

// [Start SetPlayingSpeed]
void AVPlayer::SetPlayingSpeed(float speed) {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    auto ret = OH_AVPlayer_SetPlaybackRate(ohAVPlayer, speed);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Set playing speed failed, ret: %{public}d", ret);
        return;
    }
    OH_LOG_INFO(LOG_APP, "Set playing speed successfully.");
}
// [End SetPlayingSpeed]

// [Start SetPlayingVolume]
void AVPlayer::SetPlayingVolume(float volume) {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    auto ret = OH_AVPlayer_SetVolume(ohAVPlayer, volume, volume);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Set app volume failed, ret: %{public}d", ret);
        return;
    }
    lastVolume = volume;
    OH_LOG_INFO(LOG_APP, "Set app volume successfully.");
}
// [End SetPlayingVolume]

// [Start SetSilentMode]
void AVPlayer::SetSilentMode(bool isSilentMode) {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    // If the isSilentMode is true, set the volume to 0; Otherwise, restore the latest volume value
    float volume = isSilentMode ? 0 : lastVolume;
    auto ret = OH_AVPlayer_SetVolume(ohAVPlayer, volume, volume);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "SetSilentMode: set app volume failed, ret: %{public}d", ret);
        return;
    }
    OH_LOG_INFO(LOG_APP, "Set silent mode successfully.");
}
// [End SetSilentMode]

// [Start ReleasePlayer]
void AVPlayer::ReleasePlayer() {
    if (ohAVPlayer == nullptr) {
        OH_LOG_ERROR(LOG_APP, "The ohAVPlayer is null.");
        return;
    }
    auto ret = OH_AVPlayer_Release(ohAVPlayer);
    if (ret != AV_ERR_OK) {
        OH_LOG_ERROR(LOG_APP, "Release player failed, ret: %{public}d", ret);
        return;
    }
    ohAVPlayer = nullptr;
    OH_LOG_INFO(LOG_APP, "Release player successfully.");
}
// [End ReleasePlayer]