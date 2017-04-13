//
//  BaseViewController.h
//  KSYVideoClipsDemo
//
//  Created by iVermisseDich on 2017/2/15.
//  Copyright © 2017年 com.ksyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

- (UISegmentedControl *)segmentedControlWithItems:(NSArray<__kindof NSString *> *) items;

- (UIButton *)buttonWithTitle:(NSString *)title
                       action:(SEL)action;

- (UIButton *)addButtonWithTitle:(NSString *)title action:(SEL)action;

- (void)addViews:(NSArray<__kindof UIView *> *)btns
       withFrame:(CGRect)frame;

- (void)addViews2:(NSArray<__kindof UIView *> *)btns
       withFrame:(CGRect)frame;

- (void)addViews3:(NSArray<__kindof UIView *> *)btns
        withFrame:(CGRect)frame;

- (void)addViews4:(NSArray<__kindof UIView *> *)btns
        withFrame:(CGRect)frame;

- (UILabel *)addLable:(NSString*)title;

- (UITextField *)addTextField: (NSString*)text;

- (void) toast:(NSString*)message;
@end
