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
import { curves, PromptAction } from '@kit.ArkUI';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { ContentConstants } from '../common/constants/ContentConstants';
import { MusicPlayMode, PlayerConstants, PlayModeSwitchList, VOLUME_ID } from '../common/constants/PlayerConstants';
import { StyleConstants } from '../common/constants/StyleConstants';
import { BreakpointType } from '../common/utils/BreakpointSystem';
import Logger from '../common/utils/Logger';
import { ResourceConversion } from '../common/utils/ResourceConversion';
import { SongItem } from '../viewmodel/SongData';
import { SongDataSource } from '../viewmodel/SongDataSource';
import { MediaControlCenter } from '../common/utils/mediautils/MediaControlCenter';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { MediaTools } from '../common/utils/mediautils/MediaTools';

const TAG = 'ControlAreaComponent';

@Component
export struct ControlAreaComponent {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('isPlay') isPlay: boolean = false;
  @StorageLink('currentTime') currentTime: string = '00:00';
  @StorageLink('totalTime') totalTime: string = '00:00';
  @StorageLink('progress') value: number = 0;
  @StorageLink('progressMax') max: number = 0;
  @State playModeIndex: number = 0;
  @StorageLink('imageColor') imageColor: string = '';
  @StorageLink('pageShowTime') pageShowTime: number = 0;
  @StorageLink('songList') songList: SongItem[] = [];
  @State isShowPlayList: boolean = false;
  @StorageLink('playMode') playMode: MusicPlayMode = PlayModeSwitchList[this.playModeIndex];
  @StorageLink('selectIndex') selectIndex: number = 0;
  @StorageLink('isSilentMode') @Watch('isSilentModeChange') isSilentMode: boolean = false;
  @State speed: number = 1;
  @StorageLink('currentVolume') @Watch('currentVolumeChange') volume: number = 0;
  @State isShowSpeedBuild: boolean = false;
  @State isShowVolumeBuild: boolean = false;
  @State songTimeFontSize: number = 10;
  @State songTimeFontColor: Resource = $r('app.color.play_text_color');
  @State trackThickness: number = 6;
  private scroller: Scroller = new Scroller();
  private resourceConversion: ResourceConversion = new ResourceConversion();
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  uiContext: UIContext = this.getUIContext();
  promptAction: PromptAction = this.uiContext.getPromptAction();

  isSilentModeChange() {
    Logger.info(TAG, `isSilentMode is change,current isSilentMode is ${this.isSilentMode}`)
    MediaControlCenter.getInstance().setSilentMode(this.isSilentMode)
  }

  currentVolumeChange() {
    Logger.info(TAG, `volume is change, current volume is ${this.volume}`)
    MediaControlCenter.getInstance().setVolume(this.volume)
  }

  switchPlayMode() {
    if (this.playModeIndex === PlayModeSwitchList.length - 1) {
      this.playModeIndex = 0;
    } else {
      this.playModeIndex++;
    }
    this.playMode = PlayModeSwitchList[this.playModeIndex];
    Logger.info(TAG, 'playModeIndex is' + this.playModeIndex);
    this.promptAction.openToast({
      message: `${this.playMode === MusicPlayMode.ORDER ?
        this.resourceConversion.getStringValueFromResource($r('app.string.sequential_playback')) :
        this.playMode === MusicPlayMode.RANDOM ?
          this.resourceConversion.getStringValueFromResource($r('app.string.random_playback')) :
          this.resourceConversion.getStringValueFromResource($r('app.string.single_playback'))}`
    });
    MediaControlCenter.getInstance().setPlayModel(this.playMode);
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph(this.playMode === MusicPlayMode.ORDER ? $r('sys.symbol.order_play') :
          this.playMode === MusicPlayMode.RANDOM ? $r('sys.symbol.shuffle') : $r('sys.symbol.repeat_1'))
          .fontSize(26)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([Color.White])
          .opacity(0.86)
          .onClick(() => {
            this.switchPlayMode()
          })

        SymbolGlyph($r('sys.symbol.music_note_list'))
          .fontSize(26)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([Color.White])
          .opacity(0.86)
          .onClick(() => {
            this.isShowPlayList = true;
          })
          .bindSheet($$this.isShowPlayList, this.musicListBuilder(), {
            detents: [SheetSize.MEDIUM],
            dragBar: false,
            showClose: true,
            preferType: SheetType.CENTER,
            onWillAppear: () => {
              Logger.info(TAG, 'musicListBuilder');
              this.scroller.scrollToIndex(this.selectIndex, false, ScrollAlign.CENTER);
            }
          })

        SymbolGlyph(this.isSilentMode ? $r('sys.symbol.bell_slash') : $r('sys.symbol.bell'))
          .fontSize(26)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([Color.White])
          .opacity(0.86)
          .onClick(() => {
            this.isSilentMode = !this.isSilentMode;
            if (this.isSilentMode) {
              this.volume = 0;
            } else {
              let preVolume: number = PreferencesUtil.getInstance().getValue(VOLUME_ID) as number;
              this.volume = preVolume ? preVolume : 0.1;
            }
            MediaControlCenter.getInstance().setSilentMode(this.isSilentMode)
          })

        SymbolGlyph($r('sys.symbol.video_speed'))
          .fontSize(26)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([Color.White])
          .opacity(0.86)
          .onClick(() => {
            this.isShowSpeedBuild = true;
          })
          .bindSheet($$this.isShowSpeedBuild, this.speedBuilder(), {
            detents: [SheetSize.FIT_CONTENT],
            dragBar: false,
            showClose: true,
            preferType: SheetType.CENTER,
            onWillAppear: () => {
              Logger.info(TAG, 'speedBuilder');
            }
          })
        SymbolGlyph($r('sys.symbol.speaker_wave_3'))
          .fontSize(26)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([Color.White])
          .opacity(0.86)
          .bindSheet($$this.isShowVolumeBuild, this.volumeBuilder(), {
            detents: [SheetSize.FIT_CONTENT],
            dragBar: false,
            showClose: true,
            preferType: SheetType.CENTER,
            onWillAppear: async () => {
              Logger.info(TAG, 'volumeBuilder');
              try {
                if (this.isSilentMode) {
                  this.volume = 0;
                } else {
                  this.volume = MediaControlCenter.getInstance().getVolume();
                }
              } catch (error) {
                Logger.info(TAG, `failed to get volume, error is ${error}`)
              }
            }
          })
          .onClick(() => {
            this.isShowVolumeBuild = true;
          })
      }
      .width(StyleConstants.FULL_WIDTH)
      .justifyContent(FlexAlign.SpaceBetween)

      Column() {
        Slider({
          min: 0,
          max: this.max,
          step: 1,
          style: SliderStyle.NONE,
          value: this.value
        })
          .trackThickness(this.trackThickness)
          .selectedColor($r('app.color.slider_select'))
          .trackColor($r('app.color.slider_track'))
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.End) {
              MediaControlCenter.getInstance().seek(value);
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.trackThickness = 6;
                this.songTimeFontSize = 10;
                this.songTimeFontColor = $r('app.color.play_text_color');
              })
            }
            if (mode === SliderChangeMode.Moving) {
              this.currentTime = MediaTools.msToCountdownTime(value)
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.trackThickness = 10;
                this.songTimeFontSize = 12;
                this.songTimeFontColor = $r('app.color.slider_select');
              })
            }
            this.pageShowTime = 0;
          })
          .height($r('app.float.slider_height'))
          .margin({
            left: new BreakpointType({
              sm: $r('app.float.slider_margin_sm'),
              md: $r('app.float.slider_margin_md'),
              lg: $r('app.float.slider_margin_lg')
            }).getValue(this.currentBreakpoint),
            right: new BreakpointType({
              sm: $r('app.float.slider_margin_sm'),
              md: $r('app.float.slider_margin_md'),
              lg: $r('app.float.slider_margin_lg')
            }).getValue(this.currentBreakpoint)
          })
          .width(StyleConstants.FULL_WIDTH)
          .hitTestBehavior(HitTestMode.Block)
        Row() {
          Text(this.currentTime)
            .fontColor(this.songTimeFontColor)
            .fontSize(this.songTimeFontSize)
            .fontFamily(PlayerConstants.FONT_FAMILY_BLACK)
            .lineHeight('14vp')
          Text(this.totalTime)
            .fontColor(this.songTimeFontColor)
            .fontSize(this.songTimeFontSize)
            .fontFamily(PlayerConstants.FONT_FAMILY_BLACK)
            .lineHeight('14vp')
        }
        .width(StyleConstants.FULL_WIDTH)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .margin({
        top: $r('app.float.slider_margin_top'),
        bottom: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
          $r('app.float.slider_margin_bottom_lg') : $r('app.float.slider_margin_bottom')
      })

      Row() {
        Image($r('app.media.ic_public_forward'))
          .controlImageBuilder()
          .width(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
            $r('app.float.control_width_lg') : $r('app.float.control_width'))
          .onClick(() => {
            MediaControlCenter.getInstance().playPrevious();
            this.pageShowTime = 0;
          })
        Image(this.isPlay ? $r('app.media.ic_public_play') : $r('app.media.ic_public_pause'))
          .controlImageBuilder()
          .width(new BreakpointType({
            sm: $r('app.float.image_play_width'),
            md: $r('app.float.image_play_width'),
            lg: $r('app.float.image_play_width_lg')
          }).getValue(this.currentBreakpoint))
          .onClick(() => {
            if (this.isPlay) {
              MediaControlCenter.getInstance().pause()
            } else {
              MediaControlCenter.getInstance().play()
            }
            this.pageShowTime = 0;
          })
        Image($r('app.media.ic_public_next'))
          .controlImageBuilder()
          .width(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
            $r('app.float.control_width_lg') : $r('app.float.control_width'))
          .onClick(() => {
            MediaControlCenter.getInstance().playNext();
            this.pageShowTime = 0;
          })
      }
      .width(StyleConstants.FULL_WIDTH)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: $r('app.float.control_padding'),
        right: $r('app.float.control_padding')
      })
    }
  }

  @Builder
  musicListBuilder() {
    Column() {
      this.playListTitle();
      List({ scroller: this.scroller }) {
        LazyForEach(new SongDataSource(this.songList), (item: SongItem, index: number) => {
          ListItem() {
            MusicListContainer({ item: item, index: index })
              .reuseId(this.context?.resourceManager.getStringSync(item.title?.id));
          }
        }, (item: SongItem, index: number) => item.toString() + index.toString())
      }
      .height(StyleConstants.FULL_HEIGHT)
      .width(StyleConstants.FULL_WIDTH)
      .backgroundColor(Color.White)
      .margin({ top: $r('app.float.list_area_margin_top') })
      .lanes(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
        ContentConstants.COL_TWO : ContentConstants.COL_ONE)
      .layoutWeight(1)
      .divider({
        color: $r('app.color.list_divider'),
        strokeWidth: $r('app.float.stroke_width'),
        startMargin: $r('app.float.list_item_padding'),
        endMargin: $r('app.float.list_item_padding')
      })
    }
    .padding({
      top: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ? 0 : $r('app.float.list_area_padding_top'),
      bottom: $r('app.float.list_area_padding_bottom')
    })
    .backgroundColor(Color.White)
  }

  @Builder
  volumeBuilder() {
    Column() {
      this.volumeTitle()
      Row() {
        // [Start volumeBuilder]
        Slider({
          value: this.volume,
          min: 0,
          max: 1,
          step: 0.1,
          style: SliderStyle.InSet
        })
          .showTips(false)
          .layoutWeight(1)
          .onChange((value: number, mode: SliderChangeMode) => {
            this.volume = value;
            if (this.volume === 0) {
              this.isSilentMode = true
            } else {
              this.isSilentMode = false;
            }
          })
        // [End volumeBuilder]
      }
      .padding({
        left: 8,
        right: 8
      })

    }
    .backgroundColor(Color.White)
    .padding({
      top: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ? 0 : $r('app.float.list_area_padding_top'),
      bottom: $r('app.float.list_area_padding_bottom')
    })
  }

  @Builder
  volumeTitle() {
    Row() {
      Text($r('app.string.volume_setting'))
        .maxLines(ContentConstants.PLAY_ALL_MAX_LINES)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .fontSize(new BreakpointType({
          sm: $r('app.float.play_font_sm'),
          md: $r('app.float.play_font_md'),
          lg: $r('app.float.play_font_lg')
        }).getValue(this.currentBreakpoint))
    }
    .height($r('app.float.play_all_area_height'))
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor(Color.White)
    .padding({
      top: 18,
      left: $r('app.float.play_all_area_padding'),
      right: $r('app.float.play_all_area_padding')
    })
    .borderRadius({
      topRight: $r('app.float.play_all_border_radius'),
      topLeft: $r('app.float.play_all_border_radius')
    })
  }

  @Builder
  speedBuilder() {
    Column() {
      this.speedTitle()
      Row() {
        Text($r('app.string.playback_speed'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Text(` ${this.speed.toString()}x`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .padding({
        top: 20,
        left: 12,
        right: 12,
        bottom: 10
      })

      Row() {
        // [Start speedBuilder]
        Slider({
          value: this.speed,
          min: 0.25,
          max: 2,
          step: 0.25,
          style: SliderStyle.InSet,
        })
          .blockSize(
            {
              width: 28,
              height: 28
            }
          )
          .trackThickness(35)
          .trackColor($r('sys.color.button_background_color_transparent'))
          .selectedColor(Color.Transparent)
          .layoutWeight(1)
          .width('100%')
          .showTips(false)
          .showSteps(true)
          .onChange((value: number, mode: SliderChangeMode) => {
            this.speed = value;
            MediaControlCenter.getInstance().setSpeed(this.speed);
            console.info('value:' + value + 'mode:' + mode.toString());
          })
        // [End speedBuilder]
      }
      .padding({
        left: 8,
        right: 8
      })
    }
    .backgroundColor(Color.White)
    .padding({
      top: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ? 0 : $r('app.float.list_area_padding_top'),
      bottom: $r('app.float.list_area_padding_bottom')
    })
  }

  @Builder
  speedTitle() {
    Row() {
      Text($r('app.string.speed_setting'))
        .maxLines(ContentConstants.PLAY_ALL_MAX_LINES)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .fontSize(new BreakpointType({
          sm: $r('app.float.play_font_sm'),
          md: $r('app.float.play_font_md'),
          lg: $r('app.float.play_font_lg')
        }).getValue(this.currentBreakpoint))
    }
    .height($r('app.float.play_all_area_height'))
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor(Color.White)
    .padding({
      top: 18,
      left: $r('app.float.play_all_area_padding'),
      right: $r('app.float.play_all_area_padding')
    })
    .borderRadius({
      topRight: $r('app.float.play_all_border_radius'),
      topLeft: $r('app.float.play_all_border_radius')
    })
  }

  @Builder
  playListTitle() {
    Row() {
      Text($r('app.string.play_list', this.songList.length))
        .maxLines(ContentConstants.PLAY_ALL_MAX_LINES)
        .padding({ left: $r('app.float.play_all_text_padding') })
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .fontSize(new BreakpointType({
          sm: $r('app.float.play_font_sm'),
          md: $r('app.float.play_font_md'),
          lg: $r('app.float.play_font_lg')
        }).getValue(this.currentBreakpoint))
    }
    .height($r('app.float.play_all_area_height'))
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor(Color.White)
    .padding({
      top: 18,
      left: $r('app.float.play_all_area_padding'),
      right: $r('app.float.play_all_area_padding')
    })
    .borderRadius({
      topRight: $r('app.float.play_all_border_radius'),
      topLeft: $r('app.float.play_all_border_radius')
    })
    .position({
      x: 0,
      y: 0
    })
  }
}

@Extend(Image)
function controlImageBuilder() {
  .aspectRatio(1)
  .opacity(0.86)
  .objectFit(ImageFit.Contain)
}

@Reusable
@Component
struct MusicListContainer {
  @StorageLink('isPlay') isPlay: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('selectIndex') selectIndex: number = 0;
  item: SongItem | undefined = undefined;
  index: number | undefined = undefined;

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.item!.title)
            .fontColor(this.selectIndex === this.index && this.isPlay ? Color.Red : Color.Black)
            .fontSize(new BreakpointType({
              sm: $r('app.float.item_font_sm'),
              md: $r('app.float.item_font_md'),
              lg: $r('app.float.item_font_lg')
            }).getValue(this.currentBreakpoint))
            .margin({ bottom: $r('app.float.list_item_title_margin') })
          Row() {
            Image(this.item!.mark)
              .width($r('app.float.list_item_image_size'))
              .height($r('app.float.list_item_image_size'))
              .margin({ right: $r('app.float.list_item_image_margin') })
            Text(this.item!.singer)
              .opacity($r('app.float.singer_opacity'))
              .fontColor(this.selectIndex === this.index && this.isPlay ? Color.Red : Color.Black)
              .fontSize(new BreakpointType({
                sm: $r('app.float.singer_title_sm'),
                md: $r('app.float.singer_title_md'),
                lg: $r('app.float.singer_title_lg')
              }).getValue(this.currentBreakpoint))
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .onClick(() => {
        MediaControlCenter.getInstance().play(this.index!)
      })
      .height($r('app.float.list_item_height'))
      .width(StyleConstants.FULL_WIDTH)
    }
    .padding({
      left: $r('app.float.list_item_padding'),
      right: $r('app.float.list_item_padding')
    })
  }
}