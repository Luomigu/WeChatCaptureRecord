//
//  CapturePlayeViewController.h
//  BBLand
//
//  Created by 杨国盛 on 2017/7/21.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVKit;

@interface CapturePlayerViewController : AVPlayerViewController

@property (strong,nonatomic) NSURL *asset;

@property (strong,nonatomic) UIImage *cover;

@end
