//
//  AYHCustomComboBox.m
//  TestCustomComboBox
//
//  Created by AlimysoYang on 12-4-25.
//  Copyright (c) 2012年 __Alimyso Software Ltd__. All rights reserved.
//	QQ:86373007

#import "AYHCustomComboBox.h"

@implementation AYHCustomComboBox

@synthesize ccbtableView, ccbListData;//, ccbTitle;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame DataCount:(int)count NotificationName:(NSString *)notificationName
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        NotificationName = [[NSString alloc] initWithString:notificationName];
        ccbListData = [[NSMutableArray alloc] initWithCapacity:0];
        //ccbTitle = [[NSString alloc] initWithString:@""];
        ccbtableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [ccbtableView setDelegate:self];
        [ccbtableView setDataSource:self];
        [ccbtableView setBackgroundColor:[UIColor grayColor]];
        [self addSubview:ccbtableView];
        [self setBackgroundColor:[UIColor grayColor]];
        self.layer.cornerRadius = 5.0f;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void) addItemData:(NSString *)itemData
{
	[ccbListData addObject:itemData];    
}

- (void) addItemsData:(NSArray *)itemsData
{
    [ccbListData addObjectsFromArray:itemsData];
}

- (NSString*) getItemData
{
    return @"";
    //return ccbTitle;
}

- (void) flushData
{
    [self.ccbtableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [ccbListData count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableViewCellHeight;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* CellIdentifier = @"CustomComboBoxCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = [ccbListData objectAtIndex:[indexPath row]];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* selectItem = [ccbListData objectAtIndex:[indexPath row]];
    
    //协议执行
    [delegate CustomComboBoxChanged:self SelectedItem:selectItem];
    //通知消息返回
    //[[NSNotificationCenter defaultCenter] postNotificationName:NotificationName object:nil];
}

- (void) dealloc
{
}
@end
