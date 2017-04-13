//
//  SettingsViewController.h
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface SettingsDecoderViewController : BaseViewController

@property UILabel            *lblVideoDecoderUI;
@property UILabel            *lblDecoderThreadNumUI;
@property UILabel            *lblRenderFpsUI;
@property UILabel            *lblOutputFlagUI;
@property UISegmentedControl *videoDecoderUI; //
@property UISegmentedControl *decoderThreadNumUI; //
@property UISegmentedControl *renderFpsUI; //
@property UISegmentedControl *outputFlagUI; //

//默认解码器配置
- (id)initDefaultCfg;

@end
