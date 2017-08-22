//
//  CaptureRecorder.h
//  Capture
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

typedef NS_ENUM(NSInteger, VideoRecorderSetupResult) {
    VideoRecorderSetupResultSuccess,
    VideoRecorderSetupResultCameraNotAuthorized,
    VideoRecorderSetupResultFailure
};

@protocol CaptureSessionDelegate <NSObject>

@optional

- (void)captureSessionDidRunning;

- (void)captureSessionDidStopRunning;

- (void)captureSessionDidChangeCamera;

@end

@interface CaptureRecorder : NSObject

@property (strong,nonatomic) AVCaptureSession *session;

@property (strong,nonatomic) id <CaptureSessionDelegate> delegate;

@property (nonatomic, getter=isRunning , readonly) BOOL sessionRunning;

- (void)startRuning;
- (void)stopRuning;
- (void)changeCamera;

@end
