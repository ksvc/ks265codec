//
//  GLView.h
//  HEVDecoder
//
//  Created by Shengbin Meng on 11/21/13.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLRenderer.h"

@interface GLView : UIView

@property (nonatomic, retain) GLRenderer *renderer;

@end
