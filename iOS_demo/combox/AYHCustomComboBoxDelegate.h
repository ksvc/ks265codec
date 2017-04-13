//
//  AYHCustomComboBoxDelegate.h
//  TestCustomComboBox
//
//  Created by AlimysoYang on 12-4-25.
//  Copyright (c) 2012年 __Alimyso Software Ltd__. All rights reserved.
//	QQ:86373007

#import <Foundation/Foundation.h>

@protocol AYHCustomComboBoxDelegate <NSObject>

- (void) CustomComboBoxChanged:(id) sender SelectedItem:(NSString*) selectedItem;

@end
