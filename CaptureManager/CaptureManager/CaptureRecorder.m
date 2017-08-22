
//
//  CaptureRecorder.m
//  Capture
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import "CaptureRecorder.h"

@interface CaptureRecorder ()

@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) VideoRecorderSetupResult setupResult;

@end

@implementation CaptureRecorder

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        _sessionQueue =  dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        
        [self checkAuthorizationStatus];
        
        _session = [[AVCaptureSession alloc]init];
        dispatch_async(_sessionQueue, ^{
            [self configurationSession];
        });
    }
    return self;
}

- (void)checkAuthorizationStatus {
    
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ) {
            
        case AVAuthorizationStatusAuthorized:  break;
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( granted ) {
                    self.setupResult = VideoRecorderSetupResultSuccess;
                }else{
                    self.setupResult = VideoRecorderSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            self.setupResult = VideoRecorderSetupResultCameraNotAuthorized;
        }
    }
}

- (void)setSessionPresetWithPostion:(AVCaptureDevicePosition )position {
    
    // 默认相机为高等级分辨率
    NSString *preferredPreset = AVCaptureSessionPresetHigh;
    
    if (position == AVCaptureDevicePositionBack) {
        
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            preferredPreset = AVCaptureSessionPreset1920x1080;
        }
    }
    
    [self.session setSessionPreset:preferredPreset];
}

- (void)configurationSession {
    
    if ( self.setupResult != VideoRecorderSetupResultSuccess ) {
        return;
    }
    
    NSError *error = nil;
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    if (videoDevice == nil) {
        
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        
        if (videoDevice == nil) {
            
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        }
    }
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    [self.session beginConfiguration];
    [self setSessionPresetWithPostion:videoDevice.position];
    
    if (videoDeviceInput == nil ) {
        
        NSLog(@"Could not create video deivce input error with : %@", error);
        _setupResult = VideoRecorderSetupResultFailure;
        return;
        
    }else {
        
        if ([self addCaptureInput:videoDeviceInput]) {
            _videoDeviceInput = videoDeviceInput;
        }else{
            NSLog(@"Could not add videoInput error with : %@", error);
        }
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (audioDeviceInput == nil ) {
        NSLog(@"Could not create audio deivce input error with : %@", error);
    }else {
        
        if ([self addCaptureInput:audioDeviceInput] == NO) {
            NSLog(@"Could not add audio deivce input error with : %@", error);
        }
    }
    
    [self.session commitConfiguration];
}

- (BOOL )addCaptureInput:(AVCaptureInput *)captureInput {
    
    BOOL result =  [_session canAddInput:captureInput];
    
    if ([_session canAddInput:captureInput]) {
        [_session addInput:captureInput];
    }
    return result;
}

- (void)changeCamera {
    
    dispatch_async(_sessionQueue, ^{
        
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        AVCaptureDeviceType preferredDeviceType;
        AVCaptureDevicePosition preferredPosition;
        
        switch (currentPosition) {
                
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
            {
                preferredPosition = AVCaptureDevicePositionBack;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
                break;
            }
            case AVCaptureDevicePositionBack:
            {
                preferredPosition = AVCaptureDevicePositionFront;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
                break;
            }
        }
        
        NSArray <AVCaptureDevice *> *devices = [AVCaptureDevice devices];
        AVCaptureDevice *newVideoDevice = nil;
        
        for (AVCaptureDevice *device  in devices) {
            if (device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType]) {
                newVideoDevice = device;
                break;
            }
        }
        
        if (newVideoDevice == nil) {
            for (AVCaptureDevice *device in devices) {
                if (device.position == preferredPosition) {
                    newVideoDevice = device;
                    break;
                }
            }
        }
    
        if (newVideoDevice) {
            
            AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
            
            [self setSessionPresetWithPostion:newVideoDevice.position];
            
            [self.session beginConfiguration];
            
            [self.session removeInput:_videoDeviceInput];
            
            if ([self addCaptureInput:videoInput]) {
                
                self.videoDeviceInput = videoInput;
                
                if ([self.delegate respondsToSelector:@selector(captureSessionDidChangeCamera)]) {
                    [self.delegate captureSessionDidChangeCamera];
                }
                
            }else {
                [self addCaptureInput:self.videoDeviceInput];
            }
            
            [self.session commitConfiguration];
        }
    });
}

- (void)startRuning {
    
    dispatch_async(_sessionQueue, ^{
        
        switch (self.setupResult) {
            case VideoRecorderSetupResultSuccess:
            {
                [self addObservers];
                _sessionRunning = YES;
                [_session startRunning];
                
                if ([self.delegate respondsToSelector:@selector(captureSessionDidRunning)]) {
                    [self.delegate captureSessionDidRunning];
                }
                
                break;
            }
            case VideoRecorderSetupResultFailure:
                NSLog(@"video start failure ");
                break;
            case VideoRecorderSetupResultCameraNotAuthorized:
                NSLog(@"video not authorized ");
                break;
        }
    });
}

- (void)stopRuning {
    
    dispatch_async( self.sessionQueue, ^{
        
        if ( self.setupResult == VideoRecorderSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
            if ([self.delegate respondsToSelector:@selector(captureSessionDidStopRunning)]) {
                [self.delegate captureSessionDidStopRunning];
            }
        }
    } );
}

- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sessionRuntimeError:(NSNotification *)notification {
    
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    /*
     Automatically try to restart the session running if media services were
     reset and the last start running succeeded. Otherwise, enable the user
     to try to resume the session running.
     */
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isRunning ) {
                [self.session startRunning];
                _sessionRunning = self.session.isRunning;
            }
            else {
                //                dispatch_async( dispatch_get_main_queue(), ^{
                
                //                } );
            }
        } );
    }
    else {
        //  has been stop hanlder
    }
}

/**
 其他系统服务优先中断 session通知处理  for example, when a phone call ends, and hardware resources needed to run the session are again available will automatically restart once the interruption ends
 */
- (void)sessionInterruptionEnded:(NSNotification *)notification {
    NSLog( @"Capture session interruption ended" );
}

/**
 for example, by an incoming phone call, or alarm, or another application taking control of needed hardware resources. When appropriate, the AVCaptureSession instance will stop running automatically in response to an interruption
 */
- (void)sessionWasInterrupted:(NSNotification *)notification {
    
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
    
    if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
        reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
        // Simply fade-in a button to enable the user to try to resume the session running.
    }
    else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
        // Simply fade-in a label to inform the user that the camera is unavailable.
        
    }
}
@end
