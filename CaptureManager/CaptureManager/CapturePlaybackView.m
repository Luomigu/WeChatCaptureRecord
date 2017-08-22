//
//  CapturePlaybackView.m
//  BBLand
//
//  Created by 杨国盛 on 2017/7/21.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import "CapturePlaybackView.h"
#import <AVFoundation/AVFoundation.h>

@implementation CapturePlaybackView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}

/* Specifies how the video is displayed within a player layer’s bounds.
 (AVLayerVideoGravityResizeAspect is default) */
- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
