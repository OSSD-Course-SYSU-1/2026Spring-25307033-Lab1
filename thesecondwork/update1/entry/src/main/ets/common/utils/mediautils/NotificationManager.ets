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

import { notificationManager } from '@kit.NotificationKit';
import { wantAgent } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import Logger from '../Logger';
import { SongItem } from '../../../viewmodel/SongData';
import { MediaTools } from './MediaTools';

const TAG = 'NotificationManager';

export class NotificationManager {
  private static instance: NotificationManager;
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  private notificationId: number = 1000; // 固定通知ID
  private isNotificationEnabled: boolean = false;

  private constructor() {
    // 私有构造函数
  }

  public static getInstance(): NotificationManager {
    if (!NotificationManager.instance) {
      NotificationManager.instance = new NotificationManager();
    }
    return NotificationManager.instance;
  }

  // 检查通知权限
  public async checkNotificationPermission(): Promise<boolean> {
    try {
      this.isNotificationEnabled = await notificationManager.isNotificationEnabled();
      Logger.info(TAG, `checkNotificationPermission: ${this.isNotificationEnabled}`);
      return this.isNotificationEnabled;
    } catch (error) {
      Logger.error(TAG, `checkNotificationPermission error: ${JSON.stringify(error)}`);
      return false;
    }
  }

  // 请求通知权限
  public async requestNotificationPermission(): Promise<void> {
    if (!this.context) {
      Logger.error(TAG, 'context is undefined');
      return;
    }
    try {
      await notificationManager.requestEnableNotification(this.context);
      this.isNotificationEnabled = true;
      Logger.info(TAG, 'requestNotificationPermission success');
    } catch (error) {
      const err = error as BusinessError;
      Logger.error(TAG, `requestNotificationPermission failed: code ${err.code}, message ${err.message}`);
    }
  }

  // 发布或更新通知
  public async publishNotification(song: SongItem, isPlaying: boolean, currentPosition: number = 0, duration: number = 0): Promise<void> {
    if (!this.context) {
      Logger.error(TAG, 'context is undefined');
      return;
    }

    // 确保有通知权限
    if (!this.isNotificationEnabled) {
      const enabled = await this.checkNotificationPermission();
      if (!enabled) {
        await this.requestNotificationPermission();
        // 如果用户拒绝，则跳过通知发布
        if (!this.isNotificationEnabled) {
          Logger.warn(TAG, 'Notification permission denied, skipping notification');
          return;
        }
      }
    }

    try {
      // 获取歌曲信息
      let title = '';
      let artist = '';
      if (song.title !== undefined) {
        title = this.context.resourceManager.getStringSync(song.title.id);
      }
      if (song.singer !== undefined) {
        artist = this.context.resourceManager.getStringSync(song.singer.id);
      }

      // 获取专辑封面
      let mediaImage: image.PixelMap | undefined = undefined;
      if (song.label) {
        mediaImage = await MediaTools.getPixelMapFromResource(this.context, song.label);
      }

      // 创建WantAgent用于点击通知时打开应用
      let wantAgentObj: Object | undefined = undefined;
      try {
        const wantAgentInfo: wantAgent.WantAgentInfo = {
          wants: [
            {
              bundleName: this.context.abilityInfo.bundleName,
              abilityName: this.context.abilityInfo.name,
              action: 'ohos.want.action.home'
            }
          ],
          operationType: wantAgent.OperationType.START_ABILITY,
          requestCode: 0,
          wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
        };
        wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);
      } catch (error) {
        Logger.error(TAG, `create WantAgent failed: ${JSON.stringify(error)}`);
      }

      // 构建通知内容
      const notificationRequest: notificationManager.NotificationRequest = {
        id: this.notificationId,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: artist,
            additionalText: isPlaying ? '正在播放' : '已暂停'
          }
        },
        wantAgent: wantAgentObj,
        // 设置持续通知，以便在后台显示
        tapDismissed: false,
        autoDeletedTime: 0 // 不自动删除
      };

      // 如果有专辑封面，设置为大图
      if (mediaImage) {
        notificationRequest.largeIcon = mediaImage;
      }

      // 发布通知
      await notificationManager.publish(notificationRequest);
      Logger.info(TAG, 'Notification published successfully');
    } catch (error) {
      Logger.error(TAG, `publishNotification error: ${JSON.stringify(error)}`);
    }
  }

  // 更新播放状态
  public async updatePlaybackState(isPlaying: boolean, currentPosition?: number, duration?: number): Promise<void> {
    // 这里可以更新现有通知的播放状态
    // 由于HarmonyOS通知API限制，可能需要重新发布通知
    // 暂时留空，后续根据实际需求实现
    Logger.info(TAG, `updatePlaybackState: isPlaying=${isPlaying}, position=${currentPosition}, duration=${duration}`);
  }

  // 取消通知
  public async cancelNotification(): Promise<void> {
    try {
      await notificationManager.cancel(this.notificationId);
      Logger.info(TAG, 'Notification cancelled');
    } catch (error) {
      Logger.error(TAG, `cancelNotification error: ${JSON.stringify(error)}`);
    }
  }

  // 清除所有通知
  public async cancelAllNotifications(): Promise<void> {
    try {
      await notificationManager.cancelAll();
      Logger.info(TAG, 'All notifications cancelled');
    } catch (error) {
      Logger.error(TAG, `cancelAllNotifications error: ${JSON.stringify(error)}`);
    }
  }
}