//
//  BaseViewController.m
//  KSYVideoClipsDemo
//
//  Created by iVermisseDich on 2017/2/15.
//  Copyright © 2017年 com.ksyun. All rights reserved.
//

#import "BaseViewController.h"

#define kSpace 20

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - tool funcs

- (UIButton *)addButtonWithTitle:(NSString *)title action:(SEL)action{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:title forState: UIControlStateNormal];
    button.backgroundColor = [UIColor lightGrayColor];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.layer.masksToBounds  = YES;
    button.layer.cornerRadius   = 5;
    button.layer.borderColor    = [UIColor blackColor].CGColor;
    button.layer.borderWidth    = 1;
    [self.view addSubview:button];
    return button;
}

// custom segmentedContrl
- (UISegmentedControl *)segmentedControlWithItems: (NSArray<__kindof NSString *> *) items {
    UISegmentedControl * segC;
    segC = [[UISegmentedControl alloc] initWithItems:items];
    segC.selectedSegmentIndex = 0;
    segC.layer.cornerRadius = 5;
    segC.backgroundColor = [UIColor lightGrayColor];
    [segC addTarget:self
             action:@selector(didSegCtrlValueChanged:)
   forControlEvents:UIControlEventValueChanged];
    return segC;
}

// custom button
- (void)addViews:(NSArray<__kindof UIView *> *)btns withFrame:(CGRect)frame{
    CGFloat width = (frame.size.width - (btns.count + 1) * 5) / btns.count;
    CGFloat height = frame.size.height;
    CGFloat xPos = frame.origin.x+5;
    CGFloat yPos = frame.origin.y;
    
    for (UIView *view in btns) {
        view.frame = CGRectMake(xPos, yPos, width, height);
        [self.view addSubview:view];
        xPos += width + 5;
    }
}

- (void)addViews2:(NSArray<__kindof UIView *> *)btns withFrame:(CGRect)frame{
    CGFloat width  = frame.size.width;
    CGFloat height = frame.size.height;
    CGFloat xPos = frame.origin.x+5;
    CGFloat yPos = frame.origin.y;
    
    btns[0].frame = CGRectMake(xPos, yPos, width*2/3-10, height);
    [self.view addSubview:btns[0]];
    xPos += width*2/3;
    btns[1].frame = CGRectMake(xPos, yPos, width/3-10, height);
    [self.view addSubview:btns[1]];
}

- (void)addViews3:(NSArray<__kindof UIView *> *)btns withFrame:(CGRect)frame{
    CGFloat width  = frame.size.width;
    CGFloat height = frame.size.height;
    CGFloat xPos = frame.origin.x+5;
    CGFloat yPos = frame.origin.y;
    
    btns[0].frame = CGRectMake(xPos, yPos, width*1/3-10, height);
    [self.view addSubview:btns[0]];
    xPos += width*1/3;
    btns[1].frame = CGRectMake(xPos, yPos, width*2/3-10, height);
    [self.view addSubview:btns[1]];
}

- (void)addViews4:(NSArray<__kindof UIView *> *)btns withFrame:(CGRect)frame{
    CGFloat width  = frame.size.width;
    CGFloat height = frame.size.height;
    CGFloat xPos = frame.origin.x+5;
    CGFloat yPos = frame.origin.y;
    
    btns[0].frame = CGRectMake(xPos, yPos, width*1/3-10, height);
    [self.view addSubview:btns[0]];
    xPos += width*1/3;
    btns[1].frame = CGRectMake(xPos, yPos, width*1/2-10, height);
    [self.view addSubview:btns[1]];
    xPos += width*1/2;
    btns[2].frame = CGRectMake(xPos, yPos, width*1/6-10, height);
    [self.view addSubview:btns[2]];
}
/*
- (void)addMidViews:(NSArray<__kindof UIView *> *)btns withFrame:(CGRect)frame{
    CGFloat width  = frame.size.width;
    CGFloat height = frame.size.height;
    CGFloat xPos = 5;
    CGFloat yPos = frame.origin.y;
    
    btns[0].frame = CGRectMake(xPos, yPos, width*2/3-10, height);
    [self.view addSubview:btns[0]];
}*/

- (UILabel *)addLable:(NSString*)title{
    UILabel *  lbl = [[UILabel alloc] init];
    lbl.text = title;
    lbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:lbl];
    lbl.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    return lbl;
}

- (UITextField *)addTextField: (NSString*)text{
    UITextField * textF;
    textF = [[UITextField alloc] init];
    textF.text =  text;
    textF.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:textF];
    return textF;
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = [UIColor lightGrayColor];
    button.alpha = 0.9;
    button.layer.cornerRadius = 10;
    button.clipsToBounds = YES;
    [button addTarget:self
               action:action
     forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void) toast:(NSString*)message{
    UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil, nil];
    [toast show];
    
    double duration = 0.5; // duration in seconds
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast dismissWithClickedButtonIndex:0 animated:YES];
    });
}

@end
