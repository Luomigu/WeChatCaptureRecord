//
//  CapturePlaybackView.h
//  BBLand
//
//  Created by 杨国盛 on 2017/7/21.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface CapturePlaybackView : UIView

@property (nonatomic, strong) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
