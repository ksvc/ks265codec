//
//  MoviePlayer.h
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLRenderer.h"
#import "GLView.h"
#import "MoviePlayer.h"
@interface KSYMoviePlayer : NSObject <RenderStateListener>

@property (nonatomic, retain) GLRenderer *renderer;
@property NSInteger width;
@property NSInteger height;
@property NSInteger frameNum;
@property float realFPS;
@property float real_time;
@property bool decodeEnd;
@property NSString *out_file_string;

- (int) openMovie:(NSString*) path;

- (int) play;

- (int) stop;

- (int)test:(int) thread_num;

@end
