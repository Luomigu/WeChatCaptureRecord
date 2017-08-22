//
//  CaptureMetadataPreview.h
//  CaptureManager
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;
@class AVCaptureSession;


@interface CaptureMetadataPreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) AVCaptureSession *session;


@end
