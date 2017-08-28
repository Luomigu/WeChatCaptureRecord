//
//  VideoFileOutput.h
//  Capture
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureRecorder.h"

@import AVFoundation;
@import UIKit;


@protocol VideoFileOutputDelegate <NSObject>

@optional;

- (void)writingDidStart;

- (void)writingDidEnd;

- (void)outputFileCommpressDidFinish;

@end


@interface VideoFileOutput : NSObject

@property (strong,nonatomic)AVAssetWriter *assetWriter;

@property (strong,nonatomic,readonly) NSURL *originVideoURL;

@property (strong,nonatomic,readonly) NSURL *compressVideoURL;

@property (strong,nonatomic)CaptureRecorder *recorder;

@property (strong,nonatomic) id <VideoFileOutputDelegate> delegate;

// 封面图
@property (strong,nonatomic,readonly) UIImage *previewImage;

@property (atomic,readonly,getter=isWriting) BOOL writing;

- (instancetype)initWithRecorder:(CaptureRecorder *)recorder;

- (instancetype)initWithRecorder:(CaptureRecorder *)recorder originURL:(NSURL *)originURL compressURL:(NSURL *)compressURL;

- (void)startWriting;

- (void)stopWriting;

- (void)captureStillImage:(void (^)(UIImage *image))callback;

@end
