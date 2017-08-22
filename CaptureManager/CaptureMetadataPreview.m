//
//  CaptureMetadataPreview.m
//  CaptureManager
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import "CaptureMetadataPreview.h"

@implementation CaptureMetadataPreview

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
        if (self.videoPreviewLayer.connection.supportsVideoStabilization == YES) {
            self.videoPreviewLayer.connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto; 
        }
    }
    return self;
}

- (void)setSession:(AVCaptureSession *)session {
    self.videoPreviewLayer.session = session;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
