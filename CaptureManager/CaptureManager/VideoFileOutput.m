//
//  VideoFileOutput.m
//  Capture
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import "VideoFileOutput.h"
#import "CaptureRecorder.h"

@interface VideoFileOutput ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureVideoOrientation    _referenceOrientation;
    
    BOOL				_readyToRecordAudio;
    BOOL				_readyToRecordVideo;
}

@property (strong,nonatomic)dispatch_queue_t writingQueue;

@property (strong,nonatomic)AVAssetWriterInput     *assetWriterAudioIn;
@property (strong,nonatomic)AVAssetWriterInput	   *assetWriterVideoIn;

@property (strong,nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (strong,nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property (strong,nonatomic) AVCaptureStillImageOutput *imageOutput;

@end

@implementation VideoFileOutput

- (instancetype)initWithRecorder:(CaptureRecorder *)recorder {
    
    NSString *baseURL =  [NSTemporaryDirectory() stringByAppendingPathComponent:@"yanggs_video_capture"];
    NSString *outputFilepath = [baseURL stringByAppendingString:@".mov"];
    NSString *compressFilepath =  [baseURL stringByAppendingString:@".mp4"];
    NSURL *originURL = [NSURL fileURLWithPath:outputFilepath];
    NSURL *compressURL = [NSURL fileURLWithPath:compressFilepath];
    
    return [self initWithRecorder:recorder originURL:originURL compressURL:compressURL];
}

- (instancetype)initWithRecorder:(CaptureRecorder *)recorder originURL:(NSURL *)originURL compressURL:(NSURL *)compressURL
{
    self = [super init];
    if (self) {
    
        NSAssert2(originURL.isFileURL == YES && compressURL.isFileURL == YES,@"invalid fileURL", originURL, compressURL);
    
        _originVideoURL = originURL;
        _compressVideoURL = compressURL;
        _writingQueue = dispatch_queue_create("write_queue", DISPATCH_QUEUE_SERIAL);
        _referenceOrientation = AVCaptureVideoOrientationPortrait;
        _recorder = recorder;
        [self setupOutput];
    }

    return self;
}

- (void)setupOutput {
    
    dispatch_queue_t videoQueue = dispatch_queue_create("video_output", DISPATCH_QUEUE_SERIAL);
    _videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [_videoOutput setVideoSettings:@{
                                     (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                     }];
    
    [_videoOutput setSampleBufferDelegate:self queue:videoQueue];

    dispatch_queue_t audioQueue = dispatch_queue_create("audio_output", DISPATCH_QUEUE_SERIAL);
    _audioOutput = [[AVCaptureAudioDataOutput alloc]init];
    [_audioOutput setSampleBufferDelegate:self queue:audioQueue];
    
    _imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [_imageOutput setOutputSettings:outputSettings];
    
    [_recorder.session beginConfiguration];
        [self addCaptureOutput:_videoOutput];
        [self addCaptureOutput:_audioOutput];
        [self addCaptureOutput:_imageOutput];
    [_recorder.session commitConfiguration];
}

- (void)addCaptureOutput:(AVCaptureOutput *)output {
    
    if ([_recorder.session canAddOutput:output]) {
        [_recorder.session addOutput:output];
    } else {
        NSLog(@"Could not add capture output  ");
    }
}

- (void)startWriting {
    
    if (self.isWriting == YES) { return; }

    dispatch_async(_writingQueue, ^{
        
        NSError *error;
        
        [self removeFile:_originVideoURL];
        [self removeFile:_compressVideoURL];
        
        _assetWriter = [AVAssetWriter assetWriterWithURL:_originVideoURL fileType:AVFileTypeMPEG4 error:&error];
        
        if (_assetWriter == nil) {
            NSLog(@"AssetWriter init failure %@",error);
        }
    });
}

- (void)stopWriting {
    
    if (_writing == NO || _assetWriter == nil)    return;
    
    dispatch_suspend(_writingQueue);
    
    [_assetWriter finishWritingWithCompletionHandler:^{
        
        AVAssetWriterStatus completionStats = _assetWriter.status;
        
        switch (completionStats) {
            case AVAssetWriterStatusCompleted:
                
                _readyToRecordVideo = NO;
                _readyToRecordAudio = NO;
                _assetWriter = nil;
                _writing = NO;
            {
                if ([self.delegate respondsToSelector:@selector(writingDidEnd)]) {
                    [self.delegate writingDidEnd];
                }
                
                [self compressHandler];
            }
                break;
                
            case AVAssetWriterStatusFailed:
                
                NSLog(@"Writer status failed  %@",_assetWriter.error);
                break;
            default:
                break;
        }
        _assetWriter = nil;
        
        dispatch_resume(_writingQueue);
    }];
}

// 获取视频第一帧
- (UIImage *)previewImage {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_originVideoURL options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

- (void)captureStillImage:(void (^)(UIImage *))callback  {
    
    AVCaptureConnection *videoConnection =  [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [_imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        callback(image);
    }];
}

- (void)compressHandler {
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:_originVideoURL options:nil];
    
    NSString *presetName = AVAssetExportPreset960x540;
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:presetName];
    exportSession.outputURL = _compressVideoURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if ([self.delegate respondsToSelector:@selector(outputFileCommpressDidFinish)]) {
            [self.delegate outputFileCommpressDidFinish];
        }
    }];
}

- (void)removeFile:(NSURL *)fileURL {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = fileURL.path;
    if ([fileManager fileExistsAtPath:filePath])
    {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success)
            NSLog(@"FileManger remove file %@",error);
    }
}

- (BOOL)setupAssetWirterVideoInput:(CMFormatDescriptionRef )currentFormatDescription {
    
    CGFloat bitsPerPixel ;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    NSUInteger numPixels = dimensions.width * dimensions.height;
    NSUInteger bitsPerSecond;
    
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 3.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary * videoCompressionSettings = @{
                                                AVVideoCodecKey: AVVideoCodecH264,
                                                AVVideoWidthKey : [NSNumber numberWithInteger:dimensions.width],
                                                AVVideoHeightKey : [NSNumber numberWithInteger:dimensions.height],
                                                AVVideoCompressionPropertiesKey: @{
                                                        AVVideoAverageBitRateKey : [NSNumber numberWithInteger:bitsPerSecond],
                                                        AVVideoMaxKeyFrameIntervalKey: @(150),
                                                        AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
                                                        AVVideoAllowFrameReorderingKey: @NO,
                                                        AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC,
                                                        AVVideoExpectedSourceFrameRateKey: @(30),
                                                        AVVideoAverageNonDroppableFrameRateKey: @(30)
                                                        }
                                                };
    
    if ([_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        _assetWriterVideoIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        _assetWriterVideoIn.expectsMediaDataInRealTime = YES;
        _assetWriterVideoIn.transform = [self transformFromCurrentVideoOrientationToOrientation:_referenceOrientation];
        
        if ([_assetWriter canAddInput:_assetWriterVideoIn]) {
            [_assetWriter addInput:_assetWriterVideoIn];
        }else{
            NSLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }else{
        
        NSLog(@"Couldn't apply video output settings.");
        return NO;
    }
    
    return  YES;
}

- (BOOL)setupAssetWirterAudioInput:(CMFormatDescriptionRef )currentFormatDescription {
    
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    
    NSData *currentChannelLayoutData =  nil;
    
    if (currentChannelLayout && aclSize > 0) {
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    }else {
        currentChannelLayoutData = [NSData data];
    }
    
    NSDictionary *audioCompressionSettins = @{AVFormatIDKey : [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],
                                              AVSampleRateKey : [NSNumber numberWithFloat:currentASBD->mSampleRate],
                                              AVEncoderBitRatePerChannelKey : [NSNumber numberWithInt:64000],
                                              AVNumberOfChannelsKey : [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame],
                                              AVChannelLayoutKey : currentChannelLayoutData};
    
    if ([_assetWriter canApplyOutputSettings:audioCompressionSettins forMediaType:AVMediaTypeAudio]) {
        
        _assetWriterAudioIn = [[AVAssetWriterInput alloc]initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettins];
        _assetWriterAudioIn.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_assetWriterAudioIn]) {
            [_assetWriter addInput:_assetWriterAudioIn];
        }else{
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }else{
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    return  YES;
}

- (void)writeSampleBuffer:(CMSampleBufferRef )sampleBuffer type:(NSString *)type {
    
    if (_assetWriter.status == AVAssetWriterStatusUnknown) {
        
        // If the asset writer status is unknown, implies writing hasn't started yet, hence start writing with start time as the buffer's presentation timestamp
        if ([_assetWriter startWriting])
            [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        else {
            NSLog(@"AssetWriter failure With %@",_assetWriter.error);
        }
    }
    
    if (_assetWriter.status == AVAssetWriterStatusWriting) {
        
        if (type == AVMediaTypeVideo) {
            
            if (_assetWriterVideoIn.isReadyForMoreMediaData) {
                
                if ([_assetWriterVideoIn appendSampleBuffer:sampleBuffer] == NO) {
                    NSLog(@"AssetWriter append video failure With %@",_assetWriter.error);
                }
            }
        }
        
        if (type == AVMediaTypeAudio) {
            
            if (_assetWriterAudioIn.isReadyForMoreMediaData) {
                
                if ([_assetWriterAudioIn appendSampleBuffer:sampleBuffer] == NO) {
                    NSLog(@"AssetWriter append audio failure With %@",_assetWriter.error);
                }
            }
        }
    }
}

- (BOOL)inputsReadyToRecord {
    return  _readyToRecordAudio && _readyToRecordVideo;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
        
    CFRetain(sampleBuffer);
    dispatch_async(_writingQueue, ^{
        
        if (_assetWriter) {
            
            BOOL wasReadyToRecord = [self inputsReadyToRecord];
            
            if (connection == [captureOutput connectionWithMediaType:AVMediaTypeAudio]) {
                
                if (_readyToRecordAudio == NO) {
                    _readyToRecordAudio =  [self setupAssetWirterAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                }
                
                if ([self inputsReadyToRecord] == YES) {
                    [self writeSampleBuffer:sampleBuffer type:AVMediaTypeAudio];
                }
            }else if (connection == [captureOutput connectionWithMediaType:AVMediaTypeVideo]) {
                
                if (_readyToRecordVideo == NO ) {
                    _readyToRecordVideo = [self setupAssetWirterVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                }
                
                if ([self inputsReadyToRecord] == YES) {
                    [self writeSampleBuffer:sampleBuffer type:AVMediaTypeVideo];
                }
            }
            
            BOOL isReadyToRecord = [self inputsReadyToRecord];
            
            if (wasReadyToRecord == NO && isReadyToRecord) {
                _writing = YES;
                
                if ([self.delegate respondsToSelector:@selector(writingDidStart)]) {
                    [self.delegate writingDidStart];
                }
            }
        }
        
        CFRelease(sampleBuffer);
    });
}

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGFloat angle = 0.0;
    
    switch (orientation)
    {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
    
    AVCaptureConnection *videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:videoConnection.videoOrientation];
    
    // Find the difference in angle between the passed in orientation and the current video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation(angleOffset);
    
    return transform;
}

@end
