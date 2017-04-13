//
//  GLView.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 11/21/13.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "GLView.h"

@implementation GLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

// this is called when the view is loaded from xib files
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // configure the properties of the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        self.renderer = [[GLRenderer alloc] init];
        if (self.renderer == nil) {
            return nil;
        }
    }
    return self;
}


- (void)layoutSubviews
{
    [self.renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [super layoutSubviews];
}


@end
