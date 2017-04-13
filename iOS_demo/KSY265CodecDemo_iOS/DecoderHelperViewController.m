//
//  SettingsViewController.m
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "DecoderHelperViewController.h"

@implementation DecoderHelperViewController {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}


- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];

    //add helper title text
    UILabel  *lblSetting =  [self addLable:@"帮助"];
    [self addViews:@[lblSetting] withFrame:CGRectMake(self.view.frame.size.width/3, 40, self.view.frame.size.width/3, 40)];
    
    //编码器使用说明
    UILabel *encoderInstructions = [self addLable:@"解码器使用说明：先设置解码器参数(其中选择渲染频率为-1(off)时,是关闭渲染功能)，然后选择文件，最后确定即开始解码" ];
    encoderInstructions.numberOfLines = 0;
    encoderInstructions.textAlignment = NSTextAlignmentLeft;
    [self addViews:@[encoderInstructions] withFrame:CGRectMake(0, 100, self.view.frame.size.width, 40*4)];
    
    //github地址
    UILabel *gitHubSite = [self addLable:@"github: https://github.com/ksvc/ks265codec" ];
    gitHubSite.numberOfLines = 0;
    gitHubSite.textAlignment = NSTextAlignmentLeft;
    [self addViews:@[gitHubSite] withFrame:CGRectMake(0, 300, self.view.frame.size.width, 40*2)];

    UIButton *btnBack = [self addButtonWithTitle:@"返回" action:@selector(onDone:)];
    [self addViews:@[btnBack] withFrame:CGRectMake(self.view.frame.size.width*2/3, 450, self.view.frame.size.width/3, 40)];
}

#pragma mark - actions
- (void)onDone:(UIButton *)btn {
    [self dismissViewControllerAnimated:FALSE completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

