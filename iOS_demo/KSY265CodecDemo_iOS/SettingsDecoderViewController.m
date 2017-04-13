//
//  SettingsViewController.m
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "SettingsDecoderViewController.h"

@implementation SettingsDecoderViewController {
    //Say you have an array of strings you want to present in the pickerview like this
    UILabel  *lblSetting;
    UIButton *btnDone;
    NSArray *arrayOfStrings;
    NSArray *arrayOfStringsFPS;
    NSArray *arrayOfStringsOutputFlag;
    NSArray *decStrings;
}

- (id)initDefaultCfg {
    self = [super init];
    decStrings = [NSArray arrayWithObjects:@"ksc265dec", @"lenthevcdec", nil];
    arrayOfStrings = [NSArray arrayWithObjects:@"0 (auto)", @"1", @"2", @"4", nil];
    arrayOfStringsFPS = [NSArray arrayWithObjects:@"0 (full speed)", @"24", @"-1 (off)", nil];
    arrayOfStringsOutputFlag = [NSArray arrayWithObjects:@"NO", @"YES", nil];
    [[NSUserDefaults standardUserDefaults] setValue:[decStrings objectAtIndex:0] forKey:@"codec"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStrings objectAtIndex:0] forKey:@"threadNum"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsFPS objectAtIndex:0] forKey:@"renderFPS"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsOutputFlag objectAtIndex:0] forKey:@"outputFlag"];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];

    //add set title text
    lblSetting =  [self addLable:@"设置"];
    [self addViews:@[lblSetting] withFrame:CGRectMake(self.view.frame.size.width/3, 40, self.view.frame.size.width/3, 40)];
    
    //decoder
    _lblVideoDecoderUI = [self addLable:@"视频解码器"];
    _videoDecoderUI = [self addSegCtrlWithItems:decStrings];
    [self addViews3:@[_lblVideoDecoderUI, _videoDecoderUI] withFrame:CGRectMake(0, 120, self.view.frame.size.width, 40)];

    //decoder threads
    _lblDecoderThreadNumUI = [self addLable:@"解码线程数"];
    _decoderThreadNumUI = [self addSegCtrlWithItems:arrayOfStrings];
    [self addViews3:@[_lblDecoderThreadNumUI, _decoderThreadNumUI] withFrame:CGRectMake(0, 200, self.view.frame.size.width, 40)];

    //render fps
    _lblRenderFpsUI = [self addLable:@"渲染帧率"];
    _renderFpsUI = [self addSegCtrlWithItems:arrayOfStringsFPS];
    [self addViews3:@[_lblRenderFpsUI, _renderFpsUI] withFrame:CGRectMake(0, 280, self.view.frame.size.width, 40)];
    
    //output yuv settings
    _lblOutputFlagUI = [self addLable:@"输出yuv"];
    _outputFlagUI = [self addSegCtrlWithItems:arrayOfStringsOutputFlag];
    [self addViews3:@[_lblOutputFlagUI, _outputFlagUI] withFrame:CGRectMake(0, 360, self.view.frame.size.width, 40)];
    
    //add done button
    btnDone = [self addButtonWithTitle:@"确定" action:@selector(onDone:)];
    [self addViews:@[btnDone] withFrame:CGRectMake(self.view.frame.size.width*2/3, 440, self.view.frame.size.width/3, 40)];
}

#pragma mark - actions
- (void)onDone:(UIButton *)btn {
    [[NSUserDefaults standardUserDefaults] setValue:[decStrings objectAtIndex:_videoDecoderUI.selectedSegmentIndex] forKey:@"codec"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStrings objectAtIndex:_decoderThreadNumUI.selectedSegmentIndex] forKey:@"threadNum"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsFPS objectAtIndex:_renderFpsUI.selectedSegmentIndex] forKey:@"renderFPS"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsOutputFlag objectAtIndex:_outputFlagUI.selectedSegmentIndex] forKey:@"outputFlag"];
    
    /*
    NSString *decoder = [[NSUserDefaults standardUserDefaults] valueForKey:@"codec"];
    NSString *threadNum = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
    NSString *renderFPS = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
    
    NSLog(@"set cfg:\n codec %@, threadNum %@, renderFPS %@", decoder, threadNum, renderFPS);
     */
    
    [self dismissViewControllerAnimated:FALSE completion:nil];
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

@end

