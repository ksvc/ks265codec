//
//  AYHCustomComboBox.h
//  TestCustomComboBox
//
//  Created by AlimysoYang on 12-4-25.
//  Copyright (c) 2012年 __Alimyso Software Ltd__. All rights reserved.
//	QQ:86373007

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "AYHCustomComboBoxDelegate.h"

#define kTableViewCellHeight 28.0f

@interface AYHCustomComboBox : UIView<UITableViewDelegate, UITableViewDataSource>
{
    NSString* NotificationName;
}

@property (strong, nonatomic) UITableView* ccbtableView;
@property (strong, nonatomic) NSMutableArray* ccbListData;
@property (assign, nonatomic) id<AYHCustomComboBoxDelegate> delegate;

//初始化
- (id) initWithFrame:(CGRect)frame DataCount:(int) count NotificationName:(NSString*) notificationName;
//添加一个数据
- (void) addItemData:(NSString*) itemData;
//添加一组数据
- (void) addItemsData:(NSArray*) itemsData;
- (NSString*) getItemData;
//UITableView数据刷新
- (void) flushData;

@end
