//
//  MoviesViewController.h
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoviesViewController : UITableViewController

-(id)initWithSuffix:(NSString *)suffix;

@property (nonatomic, retain) NSMutableArray *movieList;

@property (nonatomic, copy)void (^tableBlock)(NSString *fileName);

@end
