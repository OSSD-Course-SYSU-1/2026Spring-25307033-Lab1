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

#include "napi/native_api.h"
#include "avplayer_playing.h"

struct PlayStatusCallbackContext {
    napi_env env = nullptr;
    napi_ref callbackRef = nullptr;
    int32_t playStatus = 1;
};

void PlayStateCallback(void *asyncContext, PlayStatus playStatus) {
    uv_loop_s *loop = nullptr;
    PlayStatusCallbackContext *context = (PlayStatusCallbackContext *)asyncContext;
    napi_get_uv_event_loop(context->env, &loop);
    uv_work_t *work = new uv_work_t;
    context->playStatus = playStatus;
    work->data = context;
    uv_queue_work(
        loop, work, [](uv_work_t *work) {},
        [](uv_work_t *work, int status) {
            PlayStatusCallbackContext *context = (PlayStatusCallbackContext *)work->data;
            napi_handle_scope scope = nullptr;
            // Manage napi_value lifeCycle，avoid memory leaks.
            napi_open_handle_scope(context->env, &scope);
            napi_value callback = nullptr;
            napi_value ms;
            napi_create_int32(context->env, context->playStatus, &ms);
            napi_value args[1] = {ms};
            napi_get_reference_value(context->env, context->callbackRef, &callback);
            // CallBack to UI side.
            napi_call_function(context->env, nullptr, callback, 1, args, nullptr);
            napi_close_handle_scope(context->env, scope);
            delete context;
            delete work;
        });
}

// Initialize player
static napi_value InitPlayerNDK(napi_env env, napi_callback_info info) {
    AVPlayer::GetInstance().InitPlayer();
    return nullptr;
}

// Load song information
static napi_value LoadSongInfoNDK(napi_env env, napi_callback_info info) {
    size_t argCount = 3;
    napi_value argValues[3] = {nullptr};
    napi_get_cb_info(env, info, &argCount, argValues, nullptr, nullptr);
    uint32_t songFd = -1;
    napi_get_value_uint32(env, argValues[0], &songFd);
    uint32_t songFileSize = 0;
    napi_get_value_uint32(env, argValues[1], &songFileSize);
    uint32_t songFileOffset = 0;
    napi_get_value_uint32(env, argValues[2], &songFileOffset);
    AVPlayer::GetInstance().LoadSongInfo(songFd, songFileSize, songFileOffset);
    return nullptr;
}

// Start to play song
static napi_value PlaySongNDK(napi_env env, napi_callback_info info) {
    AVPlayer::GetInstance().PlaySong();
    return nullptr;
}

// Pause to play song
static napi_value PauseSongNDK(napi_env env, napi_callback_info info) {
    AVPlayer::GetInstance().PauseSong();
    return nullptr;
}

// Stop to play song
static napi_value StopSongNDK(napi_env env, napi_callback_info info) {
    AVPlayer::GetInstance().StopSong();
    return nullptr;
}

// Seek to play song
static napi_value SeekPlaySongNDK(napi_env env, napi_callback_info info) {
    size_t argCount = 1;
    napi_value argValues[1] = {nullptr};
    napi_get_cb_info(env, info, &argCount, argValues, nullptr, nullptr);
    uint32_t timeStamp = 0;
    napi_get_value_uint32(env, argValues[0], &timeStamp);
    AVPlayer::GetInstance().SeekPlaySong(timeStamp);
    return nullptr;
}

static napi_value OnPlayStatusNDK(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    auto asyncContext = new PlayStatusCallbackContext();
    asyncContext->env = env;
    napi_create_reference(env, args[0], 1, &asyncContext->callbackRef);
    AVPlayer::GetInstance().PlayStatusCallback = &PlayStateCallback;
    AVPlayer::GetInstance().PlayStatusCallbackContext = asyncContext;
    return nullptr;
}



static napi_value GetProgressNDK(napi_env env, napi_callback_info info) {
    int32_t currentProgress = AVPlayer::GetInstance().GetProgress();
    napi_value napiProgress = nullptr;
    napi_create_int32(env, currentProgress, &napiProgress);
    return napiProgress;
}

// Set playing speed
static napi_value SetPlayingSpeedNDK(napi_env env, napi_callback_info info) {
    size_t argCount = 1;
    napi_value argValues[1] = {nullptr};
    napi_get_cb_info(env, info, &argCount, argValues, nullptr, nullptr);
    double speed = 1;
    napi_get_value_double(env, argValues[0], &speed);
    AVPlayer::GetInstance().SetPlayingSpeed(speed);
    return nullptr;
}

// Set playing volume
static napi_value SetPlayingVolumeNDK(napi_env env, napi_callback_info info) {
    size_t argCount = 1;
    napi_value argValues[1] = {nullptr};
    napi_get_cb_info(env, info, &argCount, argValues, nullptr, nullptr);
    double volume = 1.0;
    napi_get_value_double(env, argValues[0], &volume);
    AVPlayer::GetInstance().SetPlayingVolume(volume);
    return nullptr;
}

// Set silent mode to player
static napi_value SetSilentModeNDK(napi_env env, napi_callback_info info) {
    size_t argCount = 1;
    napi_value argValues[1] = {nullptr};
    napi_get_cb_info(env, info, &argCount, argValues, nullptr, nullptr);
    bool isSilentMode = false;
    napi_get_value_bool(env, argValues[0], &isSilentMode);
    AVPlayer::GetInstance().SetSilentMode(isSilentMode);
    return nullptr;
}

// Release player
static napi_value ReleasePlayerNDK(napi_env env, napi_callback_info info) {
    AVPlayer::GetInstance().ReleasePlayer();
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"initPlayer", nullptr, InitPlayerNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"loadSongInfo", nullptr, LoadSongInfoNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"playSong", nullptr, PlaySongNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pauseSong", nullptr, PauseSongNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopSong", nullptr, StopSongNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"seekPlaySong", nullptr, SeekPlaySongNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setPlayingSpeed", nullptr, SetPlayingSpeedNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setPlayingVolume", nullptr, SetPlayingVolumeNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSilentMode", nullptr, SetSilentModeNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onPlayStatus", nullptr, OnPlayStatusNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getProgress", nullptr, GetProgressNDK, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"releasePlayer", nullptr, ReleasePlayerNDK, nullptr, nullptr, nullptr, napi_default, nullptr}};
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&demoModule); }
