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

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { MusicPlayMode } from '../common/constants/PlayerConstants';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

// 迁移数据接口定义
interface MigrationData {
  musicIndex: number;      // 当前播放歌曲索引
  progress: number;        // 播放进度（毫秒）
  isPlay: boolean;         // 播放状态
  playMode: MusicPlayMode; // 播放模式
  volume: number;          // 音量
}

export default class EntryAbility extends UIAbility {
  private windowObj?: window.Window;
  storage: LocalStorage = new LocalStorage();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      AppStorage.setOrCreate('context', this.context)
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      
      // 处理跨端迁移启动
      if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
        hilog.info(DOMAIN, TAG, 'Ability onCreate by CONTINUATION');
        // 设置迁移状态为激活
        this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE, (result) => {
          hilog.info(DOMAIN, TAG, `setMissionContinueState: ${JSON.stringify(result)}`);
        });
        
        // 恢复迁移数据
        this.restoreMigrationData(want);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  // 跨端迁移：源端保存数据
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, 'onContinue called');
    
    try {
      // 从AppStorage获取当前播放状态
      const migrationData: MigrationData = {
        musicIndex: AppStorage.get<number>('selectIndex') ?? 0,
        progress: AppStorage.get<number>('progress') ?? 0,
        isPlay: AppStorage.get<boolean>('isPlay') ?? false,
        playMode: AppStorage.get<MusicPlayMode>('playMode') ?? MusicPlayMode.ORDER,
        volume: AppStorage.get<number>('currentVolume') ?? 1
      };
      
      // 将迁移数据保存到wantParam
      wantParam['migrationData'] = JSON.stringify(migrationData);
      hilog.info(DOMAIN, TAG, `onContinue saved data: ${JSON.stringify(migrationData)}`);
      
      return AbilityConstant.OnContinueResult.AGREE;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `onContinue error: ${JSON.stringify(error)}`);
      return AbilityConstant.OnContinueResult.REJECT;
    }
  }

  // 跨端迁移：对端恢复数据
  private restoreMigrationData(want: Want): void {
    if (want.parameters === undefined) {
      hilog.error(DOMAIN, TAG, 'want.parameters is undefined');
      return;
    }
    
    try {
      const migrationDataStr = want.parameters['migrationData'] as string;
      if (migrationDataStr) {
        const migrationData: MigrationData = JSON.parse(migrationDataStr);
        hilog.info(DOMAIN, TAG, `restoreMigrationData: ${JSON.stringify(migrationData)}`);
        
        // 恢复到AppStorage
        AppStorage.setOrCreate('migrationMusicIndex', migrationData.musicIndex);
        AppStorage.setOrCreate('migrationProgress', migrationData.progress);
        AppStorage.setOrCreate('migrationIsPlay', migrationData.isPlay);
        AppStorage.setOrCreate('migrationPlayMode', migrationData.playMode);
        AppStorage.setOrCreate('migrationVolume', migrationData.volume);
        AppStorage.setOrCreate('isMigration', true); // 标记为迁移启动
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `restoreMigrationData error: ${JSON.stringify(error)}`);
    }
  }

  // 热启动时处理迁移
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant called');
    
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      hilog.info(DOMAIN, TAG, 'onNewWant by CONTINUATION');
      // 设置迁移状态为激活
      this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE, (result) => {
        hilog.info(DOMAIN, TAG, `setMissionContinueState: ${JSON.stringify(result)}`);
      });
      
      // 恢复迁移数据
      this.restoreMigrationData(want);
      // 触发页面恢复
      this.context.restoreWindowStage(this.storage);
    }
  }

  private updateBreakpoint(windowWidth: number): void {
    let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
    let curBp: string = '';
    if (windowWidthVp < BreakpointConstants.BREAKPOINT_VALUE_NUMBER[1]) {
      curBp = BreakpointConstants.BREAKPOINT_SM;
    } else if (windowWidthVp < BreakpointConstants.BREAKPOINT_VALUE_NUMBER[2]) {
      curBp = BreakpointConstants.BREAKPOINT_MD;
    } else {
      curBp = BreakpointConstants.BREAKPOINT_LG;
    }
    AppStorage.setOrCreate('currentBreakpoint', curBp);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      AppStorage.setOrCreate('windowStage', windowStage)
      windowStage.getMainWindow().then((data: window.Window) => {
        this.windowObj = data;
        AppStorage.setOrCreate<window.Window>('window', data);
        data.setWindowLayoutFullScreen(true);
        const uiContext = data.getUIContext();
        AppStorage.setOrCreate("uiContext", uiContext);
        let topArea = this.windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        let bottomArea = this.windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
        let topHeight: number;
        let bottomHeight: number;
        if (!topArea) {
          topHeight = 0;
        } else {
          topHeight = uiContext.px2vp(topArea.topRect.height)
        }
        if (!bottomArea) {
          bottomHeight = 0;
        } else {
          bottomHeight = uiContext.px2vp(bottomArea.bottomRect.height)
        }
        AppStorage.setOrCreate('topHeight', topHeight)
        AppStorage.setOrCreate('bottomHeight', bottomHeight)
        this.updateBreakpoint(this.windowObj.getWindowProperties().windowRect.width);
        this.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
          this.updateBreakpoint(windowSize.width);
        })
      })
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    if (this.windowObj) {
      this.windowObj.destroyWindow();
    }
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
