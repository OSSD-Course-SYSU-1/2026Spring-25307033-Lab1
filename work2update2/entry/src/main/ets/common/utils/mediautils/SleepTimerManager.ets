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

import Logger from '../Logger';

const TAG = 'SleepTimerManager';

export class SleepTimerManager {
  private static instance: SleepTimerManager;
  private timerId: number = -1;
  private remainingTime: number = 0; // 剩余时间（秒）
  private totalDuration: number = 0; // 总时长（秒）
  private isTimerActive: boolean = false;
  private onTimerExpired: (() => void) | undefined = undefined;
  private intervalId: number = -1;

  private constructor() {
    AppStorage.setOrCreate('sleepTimerRemaining', 0);
    AppStorage.setOrCreate('sleepTimerActive', false);
  }

  public static getInstance(): SleepTimerManager {
    if (!SleepTimerManager.instance) {
      SleepTimerManager.instance = new SleepTimerManager();
    }
    return SleepTimerManager.instance;
  }

  // 设置定时器到期回调
  public setTimerExpiredCallback(callback: () => void): void {
    this.onTimerExpired = callback;
  }

  // 启动定时器（参数为分钟）
  public startTimer(minutes: number): void {
    if (minutes <= 0) {
      Logger.error(TAG, 'Invalid timer duration');
      return;
    }

    // 如果已有定时器在运行，先停止
    this.stopTimer();

    this.totalDuration = minutes * 60; // 转换为秒
    this.remainingTime = this.totalDuration;
    this.isTimerActive = true;

    Logger.info(TAG, `Starting sleep timer for ${minutes} minutes`);

    // 更新 AppStorage
    AppStorage.setOrCreate('sleepTimerRemaining', this.remainingTime);
    AppStorage.setOrCreate('sleepTimerActive', true);

    // 启动倒计时
    this.intervalId = setInterval(() => {
      this.remainingTime--;
      AppStorage.setOrCreate('sleepTimerRemaining', this.remainingTime);

      if (this.remainingTime <= 0) {
        this.onTimerComplete();
      }
    }, 1000);
  }

  // 停止定时器
  public stopTimer(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }

    this.isTimerActive = false;
    this.remainingTime = 0;
    this.totalDuration = 0;

    AppStorage.setOrCreate('sleepTimerRemaining', 0);
    AppStorage.setOrCreate('sleepTimerActive', false);

    Logger.info(TAG, 'Sleep timer stopped');
  }

  // 定时器完成
  private onTimerComplete(): void {
    Logger.info(TAG, 'Sleep timer completed, pausing playback');
    
    // 停止定时器
    this.stopTimer();

    // 执行回调（暂停播放）
    if (this.onTimerExpired) {
      this.onTimerExpired();
    }
  }

  // 获取剩余时间（秒）
  public getRemainingTime(): number {
    return this.remainingTime;
  }

  // 获取剩余时间格式化字符串 (MM:SS)
  public getRemainingTimeFormatted(): string {
    const minutes = Math.floor(this.remainingTime / 60);
    const seconds = this.remainingTime % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  // 是否正在计时
  public isTimerRunning(): boolean {
    return this.isTimerActive;
  }

  // 添加时间（分钟）
  public addTime(minutes: number): void {
    if (!this.isTimerActive) {
      // 如果定时器未启动，则启动定时器
      this.startTimer(minutes);
      return;
    }

    this.remainingTime += minutes * 60;
    this.totalDuration += minutes * 60;
    AppStorage.setOrCreate('sleepTimerRemaining', this.remainingTime);
    Logger.info(TAG, `Added ${minutes} minutes to sleep timer, new remaining: ${this.remainingTime} seconds`);
  }

  // 减少时间（分钟）
  public reduceTime(minutes: number): void {
    if (!this.isTimerActive) {
      return;
    }

    this.remainingTime = Math.max(0, this.remainingTime - minutes * 60);
    AppStorage.setOrCreate('sleepTimerRemaining', this.remainingTime);

    if (this.remainingTime <= 0) {
      this.onTimerComplete();
    } else {
      Logger.info(TAG, `Reduced ${minutes} minutes from sleep timer, new remaining: ${this.remainingTime} seconds`);
    }
  }
}
