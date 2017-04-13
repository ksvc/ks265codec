//
//  SettingsViewController.h
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "AYHCustomComboBox.h"

@interface SettingsEncoderViewController : BaseViewController<AYHCustomComboBoxDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate>

@property UILabel            *lblVideoEncoderUI;
@property UILabel            *lblEncoderProfileUI;
@property UILabel            *lblEncoderDelayedUI;
@property UILabel            *lblResolutionUI;
@property UILabel            *lblFpsUI;
@property UILabel            *lblBitRateUI;
@property UILabel            *lblTheadNumUI;
@property UISegmentedControl *videoEncoderUI; //
@property UISegmentedControl *encoderDelayedUI; //
@property UITextField *fps;
@property UITextField *theadNum;
@property UITextField *bitRate;
@property UITextField *resolutionText;
@property UIButton * resolutionButton;
@property AYHCustomComboBox* resolutionComboBox;
@property UIButton * profileButton;
@property AYHCustomComboBox* profileComboBox;

//默认编码器配置
- (id)initDefaultCfg;

@end
