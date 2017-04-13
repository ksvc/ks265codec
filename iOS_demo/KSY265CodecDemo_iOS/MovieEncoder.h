//
//  MoviePlayer.h
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MovieEncoder : NSObject
@property NSInteger width;
@property NSInteger height;
@property NSInteger frameNum;
@property float realFPS;
@property float real_time;
@property double avg_psnr;
@property NSString *out_file_string;

- (int) openMovie:(NSString*) path;

- (int) encoder;

@end
