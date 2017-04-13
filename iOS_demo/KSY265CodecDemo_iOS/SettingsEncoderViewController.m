//
//  SettingsViewController.m
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "SettingsEncoderViewController.h"

#define KINTEVAL 30

@implementation SettingsEncoderViewController {
    NSArray *arrayOfStringsEnc;
    NSArray *arrayOfStringsProfile;
    NSArray *arrayOfStringsDelay;
    BOOL isVisibleResolution;
    BOOL isVisibleProfile;
}

- (id)initDefaultCfg {
    self = [super init];
    arrayOfStringsEnc = [NSArray arrayWithObjects:@"ksc265enc", @"x264", nil];
    arrayOfStringsProfile = [NSArray arrayWithObjects:@"superfast",@"veryfast",@"fast",@"medium",@"slow",@"veryslow",@"placebo", nil];
    arrayOfStringsDelay = [NSArray arrayWithObjects:@"zerolatency",@"livestreaming",@"offline", nil];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsEnc objectAtIndex:0] forKey:@"encoder"];
    [[NSUserDefaults standardUserDefaults] setValue:@"1280*720" forKey:@"resolution"];
    [[NSUserDefaults standardUserDefaults] setValue:@"15" forKey:@"fps"];
    [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"threads"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsProfile objectAtIndex:1] forKey:@"profile"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsDelay objectAtIndex:2] forKey:@"delayed"];
    
    isVisibleResolution = NO;
    isVisibleProfile = NO;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];

    //add set title text
    UILabel  *lblSetting =  [self addLable:@"设置"];
    [self addViews:@[lblSetting] withFrame:CGRectMake(self.view.frame.size.width/3, KINTEVAL, self.view.frame.size.width/3, KINTEVAL)];
    //encoder
    _lblVideoEncoderUI = [self addLable:@"视频编码器"];
    _videoEncoderUI = [self addSegCtrlWithItems:arrayOfStringsEnc];
    [self addViews3:@[_lblVideoEncoderUI, _videoEncoderUI] withFrame:CGRectMake(0, KINTEVAL*3, self.view.frame.size.width, KINTEVAL)];
    //Resolution
    _lblResolutionUI = [self addLable:@"分辨率"];
    _resolutionButton = [self addButtonWithTitle:@"1280*720" action:@selector(buttonclick:)];
    _resolutionButton.tag = 100;
    [self addViews3:@[_lblResolutionUI, _resolutionButton] withFrame:CGRectMake(0, KINTEVAL*5, self.view.frame.size.width, KINTEVAL)];
    //Resolution 自定义
    _resolutionText = [self addTextField:@""];
    _resolutionText.delegate = self;
    [_resolutionText removeFromSuperview];

    _resolutionComboBox = [[AYHCustomComboBox alloc] initWithFrame:CGRectMake(_resolutionButton.frame.origin.x, _resolutionButton.frame.origin.y+_resolutionButton.frame.size.height, _resolutionButton.frame.size.width, 100) DataCount:4 NotificationName:@"AYHComboBoxNationChanged"];
    [_resolutionComboBox setTag:200];
    [_resolutionComboBox setDelegate:self];
    [_resolutionComboBox addItemsData: [[NSArray alloc] initWithObjects:@"1280*720",@"960*540",@"640*360",@"640*480",@"自定义",nil]];
    [_resolutionComboBox flushData];
    
    //fps
    _lblFpsUI = [self addLable:@"帧率"];
    _fps = [self addTextField:@"15"];
    [self addViews3:@[_lblFpsUI, _fps] withFrame:CGRectMake(0, KINTEVAL*7, self.view.frame.size.width, KINTEVAL)];
    
    //bitrate
    _lblBitRateUI = [self addLable:@"码率(kbps)"];
    _bitRate =[self addTextField:@"800"];
    [self addViews3:@[_lblBitRateUI, _bitRate] withFrame:CGRectMake(0, KINTEVAL*9, self.view.frame.size.width, KINTEVAL)];

    //encoder threads
    _lblTheadNumUI = [self addLable:@"编码线程"];
    _theadNum = [self addTextField:@"0" ];
    [self addViews3:@[_lblTheadNumUI, _theadNum] withFrame:CGRectMake(0, KINTEVAL*11, self.view.frame.size.width, KINTEVAL)];
    //encoder profile
    _lblEncoderProfileUI = [self addLable:@"编码档次"];
    _profileButton = [self addButtonWithTitle:@"veryfast" action:@selector(buttonclick:)];
    _profileButton.tag = 101;
    [self addViews3:@[_lblEncoderProfileUI, _profileButton] withFrame:CGRectMake(0, KINTEVAL*13, self.view.frame.size.width, KINTEVAL)];
    
    _profileComboBox = [[AYHCustomComboBox alloc] initWithFrame:CGRectMake(_profileButton.frame.origin.x, _profileButton.frame.origin.y+_profileButton.frame.size.height, _profileButton.frame.size.width, 100) DataCount:4 NotificationName:@"AYHComboBoxNationChanged"];
    [_profileComboBox setTag:201];
    [_profileComboBox setDelegate:self];
    [_profileComboBox addItemsData:arrayOfStringsProfile];
    [_profileComboBox flushData];
    
    //encoder delayed
    _lblEncoderDelayedUI = [self addLable:@"延时"];
    _encoderDelayedUI = [self addSegCtrlWithItems:arrayOfStringsDelay];
    _encoderDelayedUI.selectedSegmentIndex = 2;

    [self addViews3:@[_lblEncoderDelayedUI, _encoderDelayedUI] withFrame:CGRectMake(0, KINTEVAL*15, self.view.frame.size.width, KINTEVAL)];
    //add done button
    UIButton *btnDone = [self addButtonWithTitle:@"确定" action:@selector(onDone:)];
    [self addViews:@[btnDone] withFrame:CGRectMake(self.view.frame.size.width*2/3, KINTEVAL*17, self.view.frame.size.width/3, KINTEVAL)];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    tapGes.delegate = self;
    [self.view addGestureRecognizer:tapGes];
}

#pragma mark AYHCustomComboBoxDelegate
- (void) CustomComboBoxChanged:(id) sender SelectedItem:(NSString *)selectedItem
{
    AYHCustomComboBox* ccb = (AYHCustomComboBox*) sender;
    if ([ccb tag]==200)
    {
        if([selectedItem isEqualToString:@"自定义"]){
            [_resolutionButton removeFromSuperview];
            [_resolutionComboBox removeFromSuperview];
            [self addViews3:@[_lblResolutionUI, _resolutionText] withFrame:CGRectMake(0, KINTEVAL*5, self.view.frame.size.width, KINTEVAL)];
        }else{
            [_resolutionButton setTitle:selectedItem forState:UIControlStateNormal];
            [_resolutionComboBox removeFromSuperview];
        }
        isVisibleResolution = NO;
    }
    else if([ccb tag]==201)
    {
        [_profileButton setTitle:selectedItem forState:UIControlStateNormal];
        [_profileComboBox removeFromSuperview];
        isVisibleProfile = NO;
    }
}

#pragma mark - actions
- (void)onDone:(UIButton *)btn {
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsEnc objectAtIndex:_videoEncoderUI.selectedSegmentIndex] forKey:@"encoder"];
    [[NSUserDefaults standardUserDefaults] setValue:_fps.text forKey:@"fps"];
    [[NSUserDefaults standardUserDefaults] setValue:_theadNum.text forKey:@"threads"];
    [[NSUserDefaults standardUserDefaults] setValue:_bitRate.text forKey:@"bitRate"];
    [[NSUserDefaults standardUserDefaults] setValue:_profileButton.titleLabel.text forKey:@"profile"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsDelay objectAtIndex:_encoderDelayedUI.selectedSegmentIndex] forKey:@"delayed"];

    if([self.view.subviews containsObject:_resolutionText])
    {
        [_resolutionText removeFromSuperview];
        [self addViews3:@[_lblResolutionUI, _resolutionButton] withFrame:CGRectMake(0, KINTEVAL*5, self.view.frame.size.width, KINTEVAL)];
        if(_resolutionText.text.length)
        {
            [[NSUserDefaults standardUserDefaults] setValue:_resolutionText.text forKey:@"resolution"];
        }
    }
    else{
        [[NSUserDefaults standardUserDefaults] setValue:_resolutionButton.titleLabel.text forKey:@"resolution"];
    }

    [self dismissViewControllerAnimated:FALSE completion:nil];
}

-(void)buttonclick:(UIButton *)sender {
    UIButton* button = (UIButton*) sender;
    if ([button tag]==100)
    {
        if (isVisibleResolution==NO)
        {
            [self.view addSubview:_resolutionComboBox];
            isVisibleResolution = YES;
        }
    }
    else if ([button tag]==101)
    {
        if (isVisibleProfile==NO)
        {
            [self.view addSubview:_profileComboBox];
            isVisibleProfile = YES;
        }
    }
}

#pragma mark - tool funcs
- (UISegmentedControl *)addSegCtrlWithItems: (NSArray *) items {
    UISegmentedControl * segC;
    segC = [[UISegmentedControl alloc] initWithItems:items];
    segC.selectedSegmentIndex = 0;
    segC.layer.cornerRadius = 5;
    segC.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:segC];
    return segC;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField == _resolutionText)
    {
        [[NSUserDefaults standardUserDefaults] setValue:_resolutionText.text forKey:@"resolution"];
    }
}

@end

