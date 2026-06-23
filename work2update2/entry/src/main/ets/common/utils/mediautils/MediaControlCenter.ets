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

import { songList } from '../../../model/SongListData';
import { SongItem } from '../../../viewmodel/SongData';
import SongItemBuilder from '../../../viewmodel/SongItemBuilder';
import { DEFAULT_VOLUME, MusicPlayMode, SILENT_ID, VOLUME_ID } from '../../constants/PlayerConstants';
import Logger from '../Logger';
import { AVSessionController } from './AVSessionController';
import { resourceManager } from '@kit.LocalizationKit';
import { MediaTools } from './MediaTools';
import { MediaControlCenterHandle } from './MediaControlCenterHandle';
import { BackgroundUtil } from '../BackgroundUtil';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil } from '../PreferencesUtil';
import { audio } from '@kit.AudioKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { media } from '@kit.MediaKit';
import { NotificationManager } from './NotificationManager';
import { SleepTimerManager } from './SleepTimerManager';

const TAG = 'MediaControlCenter';

export class MediaControlCenter {
  private avSessionController: AVSessionController | undefined = undefined;
  private mediaControlCenterHandle: MediaControlCenterHandle | undefined = undefined;
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  private songItemBuilder: SongItemBuilder = new SongItemBuilder();
  private songRawFileDescriptor: resourceManager.RawFileDescriptor | undefined = undefined;
  private playMode: MusicPlayMode = MusicPlayMode.ORDER;
  private songList: SongItem[] = [];
  private musicIndex: number = 0;
  private audioSessionManager: audio.AudioSessionManager | undefined = undefined;
  private avMetadataExtractor: media.AVMetadataExtractor | undefined = undefined;
  private isInitted = false;
  private avMetaData: media.AVMetadata | undefined = undefined;
  private notificationManager: NotificationManager = NotificationManager.getInstance();
  private sleepTimerManager: SleepTimerManager = SleepTimerManager.getInstance();
  private static mediaControlFunction: MediaControlCenter;

  constructor() {
    this.songList = songList;
    AppStorage.setOrCreate('songList', songList);
    this.songItemBuilder = new SongItemBuilder();
  }

  private async loadSongAssent(): Promise<void> {
    this.avMetadataExtractor = await media.createAVMetadataExtractor();
    Logger.info(TAG, `loadSongAssent musicIndex is ${this.musicIndex}`);
    await this.songItemBuilder.build(this.songList[this.musicIndex]);
    this.songRawFileDescriptor = this.songItemBuilder.getRawFileDescriptor();
    if (!this.songRawFileDescriptor) {
      Logger.error(TAG, `loadSongAssent faile : songRawFileDescriptor get failed`);
      return;
    }
    Logger.info(TAG, `get duration is ${this.getDuration()}`)
    this.avMetadataExtractor.fdSrc = this.songRawFileDescriptor;
    this.avMetaData = await this.avMetadataExtractor.fetchMetadata();
    AppStorage.setOrCreate('totalTime', MediaTools.msToCountdownTime(this.getDuration()));
    AppStorage.setOrCreate('totalMsTime', this.getDuration());
    AppStorage.setOrCreate('progressMax', this.getDuration());
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    this.mediaControlCenterHandle.loadSongAssent(this.songRawFileDescriptor);
  }

  private getDuration() {
    if (this.avMetaData) {
      let duration: number = Number(this.avMetaData.duration);
      return duration;
    }
    return 0;
  }

  public static getInstance(): MediaControlCenter {
    if (!MediaControlCenter.mediaControlFunction) {
      MediaControlCenter.mediaControlFunction = new MediaControlCenter();
    }
    return MediaControlCenter.mediaControlFunction;
  }

  private async initAVSession() {
    this.avSessionController = AVSessionController.getInstance();
    await this.avSessionController.initAVSession();
  }

  private async initHandle() {
    this.mediaControlCenterHandle = MediaControlCenterHandle.getInstance();
    await this.mediaControlCenterHandle.init();
  }

  private async initAudioManager() {
    let audioManger = audio.getAudioManager();
    this.audioSessionManager = audioManger.getSessionManager();
    await this.activateAudioSession();
  }

  private async activateAudioSession(concurrencyMode: audio.AudioConcurrencyMode = audio.AudioConcurrencyMode.CONCURRENCY_PAUSE_OTHERS) {
    if (!this.audioSessionManager) {
      return;
    }
    let strategy: audio.AudioSessionStrategy = {
      concurrencyMode: concurrencyMode
    };
    await this.audioSessionManager.activateAudioSession(strategy);
    Logger.info(TAG, 'activateAudioSession SUCCESS');
  }

  private async deactivateAudioSession() {
    if (!this.audioSessionManager) {
      return;
    }
    await this.audioSessionManager.deactivateAudioSession();
    Logger.info(TAG, 'deactivateAudioSession SUCCESS');
  }

  public async init() {
    if (this.isInitted) {
      return;
    }
    await this.initHandle();
    await this.loadSongAssent();
    await this.initAVSession();
    await this.initAudioManager();
    this.setVolumeFromPrefer();
    this.setSilentModeFromPrefer();
    // 初始化通知权限检查
    this.notificationManager.checkNotificationPermission();
    // 初始化定时器管理器，设置定时器到期回调
    this.sleepTimerManager.setTimerExpiredCallback(() => {
      this.pause();
      Logger.info(TAG, 'Sleep timer expired, playback paused');
    });
    
    // 处理跨端迁移数据恢复
    this.handleMigrationData();
    
    this.isInitted = true;
  }

  // 处理跨端迁移数据恢复
  private handleMigrationData(): void {
    const isMigration = AppStorage.get<boolean>('isMigration');
    if (!isMigration) {
      return;
    }
    
    Logger.info(TAG, 'Handling migration data');
    
    const migrationMusicIndex = AppStorage.get<number>('migrationMusicIndex');
    const migrationProgress = AppStorage.get<number>('migrationProgress');
    const migrationIsPlay = AppStorage.get<boolean>('migrationIsPlay');
    const migrationPlayMode = AppStorage.get<MusicPlayMode>('migrationPlayMode');
    const migrationVolume = AppStorage.get<number>('migrationVolume');
    
    // 恢复音量
    if (migrationVolume !== undefined) {
      this.setVolume(migrationVolume);
      AppStorage.setOrCreate('currentVolume', migrationVolume);
    }
    
    // 恢复播放模式
    if (migrationPlayMode !== undefined) {
      this.setPlayModel(migrationPlayMode);
    }
    
    // 恢复播放位置和进度
    if (migrationMusicIndex !== undefined && migrationMusicIndex !== this.musicIndex) {
      // 切换到迁移的歌曲
      this.updateMusicIndex(migrationMusicIndex);
      this.loadSongAssent().then(() => {
        // 恢复播放进度
        if (migrationProgress !== undefined && migrationProgress > 0) {
          this.seek(migrationProgress);
        }
        
        // 恢复播放状态
        if (migrationIsPlay === true) {
          this.play();
        }
        
        // 清除迁移标记
        AppStorage.setOrCreate('isMigration', false);
        Logger.info(TAG, 'Migration data restored successfully');
      });
    } else if (migrationProgress !== undefined && migrationProgress > 0) {
      // 同一首歌，只恢复进度
      this.seek(migrationProgress);
      
      // 恢复播放状态
      if (migrationIsPlay === true) {
        this.play();
      }
      
      // 清除迁移标记
      AppStorage.setOrCreate('isMigration', false);
      Logger.info(TAG, 'Migration data restored successfully');
    } else {
      // 只恢复播放状态
      if (migrationIsPlay === true) {
        this.play();
      }
      
      // 清除迁移标记
      AppStorage.setOrCreate('isMigration', false);
      Logger.info(TAG, 'Migration data restored successfully');
    }
  }

  public release() {
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    if (!this.avSessionController) {
      Logger.error(TAG, 'avSessionController is undefined');
      return;
    }
    this.avSessionController.unregisterSessionListener();
    this.mediaControlCenterHandle.release();
    // 取消所有通知
    this.notificationManager.cancelAllNotifications();
  }

  // [Start StartContinuousTask]
  public async play(index: number = this.musicIndex) {
    Logger.info(TAG, `index is ${index},musicIndex is ${this.musicIndex}`)
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    if (index !== this.musicIndex) {
      this.updateMusicIndex(index);
      await this.stop();
      await this.loadSongAssent();
    }
    this.updateIsPlay(true);
    this.mediaControlCenterHandle.play();
    BackgroundUtil.startContinuousTask(this.context);
    // 发布通知
    this.notificationManager.publishNotification(this.songList[this.musicIndex], true);
  }

  public pause() {
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    this.mediaControlCenterHandle.pause();
    this.updateIsPlay(false);
    BackgroundUtil.stopContinuousTask(this.context!);
    // 更新通知为暂停状态
    this.notificationManager.publishNotification(this.songList[this.musicIndex], false);
  }

  // [End StartContinuousTask]

  // Obtain a secure random number between 0 and 1
  private getSecureRandom0To1(): number {
    const rand = cryptoFramework.createRandom();
    // Generate 1-byte random data (0-255)
    const randData = rand.generateRandomSync(1);
    // Convert floating-point numbers within the range
    let randomMum: number = randData.data[0] * 1 / 255;
    return randomMum;
  }

  // Set a secure random number
  private setRandom() {
    let random0To1 = this.getSecureRandom0To1();
    let num = Math.round(random0To1 * (this.songList.length - 1));
    Logger.info(TAG, `random num is ${num},max length is ${this.songList.length - 1}`)
    if (this.musicIndex === num) {
      this.setRandom();
    }
    return num;
  }

  // [Start playNext]
  public async playNext() {
    await this.stop();
    let nextIndex = this.musicIndex;
    switch (this.playMode) {
      case MusicPlayMode.SINGLE_CYCLE:
        break;
      case MusicPlayMode.ORDER:
        if (this.musicIndex === this.songList.length - 1) {
          nextIndex = 0;
        } else {
          nextIndex += 1;
        }
        break;
      case MusicPlayMode.RANDOM:
        nextIndex = this.setRandom();
        break;
      default:
        break;
    }
    this.updateMusicIndex(nextIndex);
    await this.loadSongAssent();
    Logger.info(TAG, `nextIndex is ${nextIndex}`);
    await this.play();
  }

  // [End playNext]

  public async playPrevious() {
    await this.stop();
    let preIndex = this.musicIndex;
    switch (this.playMode) {
      case MusicPlayMode.SINGLE_CYCLE:
        break;
      case MusicPlayMode.ORDER:
        if (this.musicIndex === 0) {
          preIndex = this.songList.length - 1;
        } else {
          preIndex -= 1;
          if (preIndex < 0) {
            preIndex = this.songList.length - 1
          }
        }
        break;
      case MusicPlayMode.RANDOM:
        preIndex = this.setRandom();
        break;
      default:
        break;
    }
    this.updateMusicIndex(preIndex);
    await this.loadSongAssent();
    await this.play();
  }

  public async stop() {
    if (!this.context) {
      return;
    }
    if (!this.mediaControlCenterHandle) {
      return;
    }
    AppStorage.setOrCreate('currentTime', '00:00');
    AppStorage.setOrCreate('progress', 0);
    await this.mediaControlCenterHandle.stop();
    Logger.info(TAG, 'stop success')
    BackgroundUtil.stopContinuousTask(this.context);
    // 取消通知
    this.notificationManager.cancelNotification();
  }

  // Set play model
  public setPlayModel(playMode: MusicPlayMode) {
    if (!this.avSessionController) {
      return;
    }
    this.playMode = playMode;
    this.avSessionController.setPlayModeToAVSession(playMode);
    this.setPlayModeToControlArea(playMode);
  }

  private setPlayModeToControlArea(playMode: MusicPlayMode) {
    AppStorage.setOrCreate('playMode', playMode);
  }

  public updateIsPlay(isPlay: boolean) {
    Logger.info(TAG, `avSessionController isPlay is ${isPlay}`)
    AppStorage.setOrCreate<boolean>('isPlay', isPlay);
    if (!this.avSessionController) {
      Logger.error(TAG, `avSessionController is undefined`);
      return;
    }
    this.avSessionController.setPlayState(isPlay);
  }

  public getVolume(): number {
    if (!this.mediaControlCenterHandle) {
      return 0;
    }
    return this.mediaControlCenterHandle.getVolume();
  }

  public setVolume(volume: number) {
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    this.mediaControlCenterHandle.setVolume(volume);
  }

  public setSpeed(speed: number) {
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    this.mediaControlCenterHandle.setSpeed(speed)
  }

  // Set silent mode
  public async setSilentMode(isSilentMode: boolean = false) {
    if (!this.context) {
      return;
    }
    if (!this.mediaControlCenterHandle) {
      Logger.info(TAG, 'mediaControlCenterHandle is undefined in setSilentModeAndMixWithOthers')
      return;
    }
    PreferencesUtil.getInstance().preferencesPut(SILENT_ID, isSilentMode);
    if (isSilentMode) {
      this.activateAudioSession(audio.AudioConcurrencyMode.CONCURRENCY_MIX_WITH_OTHERS)
    } else {
      this.activateAudioSession();
    }
    this.mediaControlCenterHandle.setSilentMode(isSilentMode);
  }

  private async setSilentModeFromPrefer() {
    if (!this.context) {
      return;
    }
    let isSupportSilent: boolean | undefined = PreferencesUtil.getInstance().getValue(SILENT_ID) as boolean | undefined;
    if (isSupportSilent === undefined) {
      isSupportSilent = false;
    }
    AppStorage.setOrCreate('isSilentMode', isSupportSilent);
    this.setSilentMode(isSupportSilent)
  }

  private async setVolumeFromPrefer() {
    if (!this.context) {
      return;
    }
    let volume: number | undefined = PreferencesUtil.getInstance().getValue(VOLUME_ID) as number | undefined;
    if (volume === undefined) {
      volume = DEFAULT_VOLUME;
    }
    Logger.info(TAG, `setVolumeFromPrefer volume is ${volume}`)
    this.setVolume(volume);
    AppStorage.setOrCreate('currentVolume', volume);
  }

  public seek(ms: number) {
    if (!this.mediaControlCenterHandle) {
      Logger.error(TAG, 'mediaControlCenterHandle is undefined');
      return;
    }
    this.mediaControlCenterHandle.seek(ms);
    this.updateProgress(ms);
  }

  public updateProgress(ms: number) {
    if (!this.avSessionController) {
      return;
    }
    this.avSessionController.setProgressState(ms);
    AppStorage.setOrCreate('progress', ms);
    AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(ms));
  }

  private updateMusicIndex(musicIndex: number) {
    Logger.info(TAG, 'updateMusicIndex ===> ' + musicIndex);
    this.musicIndex = musicIndex;
    AppStorage.setOrCreate('selectIndex', musicIndex);
    if (!this.avSessionController) {
      return;
    }
    this.avSessionController.setAVMetadata();
    this.avSessionController.getAndUpdateFavoriteState(this.musicIndex.toString());
    // 更新通知显示新歌曲
    let isPlaying = AppStorage.get('isPlay') as boolean;
    if (isPlaying) {
      this.notificationManager.publishNotification(this.songList[this.musicIndex], true);
    }
  }

  // 启动定时播放（参数为分钟）
  public startSleepTimer(minutes: number) {
    this.sleepTimerManager.startTimer(minutes);
    Logger.info(TAG, `Sleep timer started for ${minutes} minutes`);
  }

  // 停止定时播放
  public stopSleepTimer() {
    this.sleepTimerManager.stopTimer();
    Logger.info(TAG, 'Sleep timer stopped');
  }

  // 获取定时器剩余时间（秒）
  public getSleepTimerRemaining(): number {
    return this.sleepTimerManager.getRemainingTime();
  }

  // 定时器是否正在运行
  public isSleepTimerRunning(): boolean {
    return this.sleepTimerManager.isTimerRunning();
  }
}