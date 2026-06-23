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

import { resourceManager } from '@kit.LocalizationKit';
import Logger from '../Logger';
import avPlayer from 'libentry.so'
import { MediaControlCenterCallbackAction } from './MediaControlCenterCallbackAction';
import { PreferencesUtil } from '../PreferencesUtil';
import { DEFAULT_VOLUME, SILENT_ID, VOLUME_ID } from '../../constants/PlayerConstants';

const TAG = 'MediaControlCenterHandle'

export class MediaControlCenterHandle {
  private interval = -1;
  private isPlaying = false;
  private static mediaControlCenterHandle: MediaControlCenterHandle;

  public static getInstance(): MediaControlCenterHandle {
    if (!MediaControlCenterHandle.mediaControlCenterHandle) {
      Logger.info(TAG, 'no mediaControlCenterHandle')
      MediaControlCenterHandle.mediaControlCenterHandle = new MediaControlCenterHandle();
    }
    return MediaControlCenterHandle.mediaControlCenterHandle;
  }

  async init() {
    // Initialize the playback instance class and place it in this method.
    avPlayer.initPlayer();
  }

  async loadSongAssent(songRawFileDescriptor: resourceManager.RawFileDescriptor) {
    // Load the current song information. The song information can be obtained from this interface, including fd length offset.
    avPlayer.loadSongInfo(songRawFileDescriptor.fd, songRawFileDescriptor.length, songRawFileDescriptor.offset)
    this.registerCallback();
  }

  onProgress() {
    clearInterval(this.interval);
    this.interval = setInterval(() => {
      if (!this.isPlaying) {
        return;
      }
      let progress = avPlayer.getProgress();
      Logger.info(TAG, `current progress is ${progress}`)
      MediaControlCenterCallbackAction.getInstance().doUpdateProgressAction(progress);
      let duration = Math.floor(AppStorage.get('totalMsTime')!);
      Logger.info(TAG, `duration is ${duration}`)
      if (this.isPlaying && Math.floor(progress) === duration) {
        MediaControlCenterCallbackAction.getInstance().doPlayNextAction();
      }
    }, 1000)
  }

  registerCallback() {
    avPlayer.onPlayStatus((state) => {
      Logger.info(TAG, `onPlayStateChange is ${state}`)
      if (state === 2) {
        MediaControlCenterCallbackAction.getInstance().doPauseAction();
      }
      if (state === 1) {
        MediaControlCenterCallbackAction.getInstance().doPlayAction();
      }
    })
    this.onProgress();
  }

  // Execute play
  play() {
    avPlayer.playSong();
    this.isPlaying = true;
  }

  // Set speed
  setSpeed(speed: number) {
    avPlayer.setPlayingSpeed(speed);
  }

  // Set whether to mute
  setSilentMode(isSilentMode: boolean) {
    avPlayer.setSilentMode(isSilentMode);
    PreferencesUtil.getInstance().preferencesPut(SILENT_ID, isSilentMode);
  }

  // Execute pause
  pause() {
    avPlayer.pauseSong();
    this.isPlaying = false;
  }

  // Execute seek
  seek(ms: number) {
    avPlayer.seekPlaySong(ms);
  }

  // Execute stop
  async stop() {
    avPlayer.stopSong();
    this.isPlaying = false;
  }

  // Set Volume
  setVolume(volume: number) {
    avPlayer.setPlayingVolume(volume);
    if (!AppStorage.get('isSilentMode') || volume !== 0) {
      PreferencesUtil.getInstance().preferencesPut(VOLUME_ID, volume);
    }
    Logger.info(TAG, `setVolume is ${volume}`)
  }

  // Get Volume
  getVolume() {
    let volume: number | undefined;
    volume = PreferencesUtil.getInstance().getValue(VOLUME_ID) as number;
    if (volume === undefined) {
      return DEFAULT_VOLUME;
    } else {
      return volume
    }
  }

  // Execute release
  release() {
    avPlayer.releasePlayer();
  }
}