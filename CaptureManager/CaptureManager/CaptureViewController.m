//
//  CaptureViewController.m
//  CaptureManager
//
//  Created by 杨国盛 on 2017/8/18.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import "CaptureViewController.h"
#import "CaptureMetadataPreview.h"
#import "VideoFileOutput.h"
#import "CapturePlayerViewController.h"

@interface CaptureViewController () <CAAnimationDelegate,VideoFileOutputDelegate,CaptureSessionDelegate>

@property (strong,nonatomic,readonly) CaptureMetadataPreview *preview;
@property (strong,nonatomic) VideoFileOutput *videoOutput;
@property (weak, nonatomic) IBOutlet UIView *button;
@property (weak, nonatomic) IBOutlet UIView *containver;
@property (strong,nonatomic) CAShapeLayer *progressLayer;

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CaptureRecorder *recorder = [[CaptureRecorder alloc]init];
    recorder.delegate = self;
    self.preview.session = recorder.session;
    
    _videoOutput = [[VideoFileOutput alloc]initWithRecorder:recorder];
    _videoOutput.delegate = self;
    
    UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(action_gestureLongpPress:)];
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(action_gestureTap:)];
    
    [_button addGestureRecognizer:longPressGR];
    [_button addGestureRecognizer:tapGR];
    [tapGR requireGestureRecognizerToFail:longPressGR];
}

- (IBAction)action_clickChangeCamera:(id)sender {
    [_videoOutput.recorder changeCamera];
}

- (void)action_gestureTap:(UITapGestureRecognizer *)sender {
    
    switch (sender.state) {
        
        case UIGestureRecognizerStateEnded: {
            
            [_videoOutput captureStillImage:^(UIImage *image) {
                CapturePlayerViewController *playerView = [[CapturePlayerViewController alloc]init];
                playerView.cover = image;
                [self presentViewController:playerView animated:NO completion:NULL];
            }];
        }
        default:
            break;
    }
}

- (void)action_gestureLongpPress:(UILongPressGestureRecognizer *)sender {
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            [_videoOutput startWriting];
            [self begenPressAnimation];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [_videoOutput stopWriting];
            [self endPressAnimation];
        }
        default:
            break;
    }
}

- (void)begenPressAnimation {
    
    CABasicAnimation *containerAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    containerAnimation.toValue = [NSNumber numberWithFloat:1.2];
    containerAnimation.duration = 0.25;
    containerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    containerAnimation.removedOnCompletion = NO;
    containerAnimation.fillMode = kCAFillModeForwards;
    [_containver.layer addAnimation:containerAnimation forKey:nil];

    CABasicAnimation *buttonAnimation = containerAnimation.copy;
    buttonAnimation.toValue = [NSNumber numberWithFloat:0.6];
    [_button.layer addAnimation:buttonAnimation forKey:nil];
    
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.lineWidth = 5;
    _progressLayer.strokeColor = [UIColor redColor].CGColor;
    _progressLayer.strokeStart = 0;
    
    UIBezierPath *bezierpath = [UIBezierPath bezierPathWithRoundedRect:UIEdgeInsetsInsetRect(_containver.bounds, UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5)) cornerRadius:CGRectGetMidX(_containver.bounds)];
    _progressLayer.path = bezierpath.CGPath;
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    [_containver.layer addSublayer:_progressLayer];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 9;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    pathAnimation.delegate = self;
    [_progressLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
}

- (void)endPressAnimation {
    
    CABasicAnimation *containerAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    containerAnimation.toValue = [NSNumber numberWithFloat:1];
    containerAnimation.duration = 0.25;
    containerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    containerAnimation.removedOnCompletion = NO;
    containerAnimation.fillMode = kCAFillModeForwards;
    [_containver.layer addAnimation:containerAnimation forKey:nil];
    [_button.layer addAnimation:containerAnimation.copy forKey:nil];
    [_progressLayer removeAllAnimations ];
    [_progressLayer removeFromSuperlayer];
    
    [self performSelector:@selector(removeAnimation) withObject:NULL afterDelay:0.25];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    if (flag == YES) {
        [_videoOutput stopWriting];
        [self endPressAnimation];
    }
}

#pragma -mark-  CaptureSessionDelegate
- (void)captureSessionDidChangeCamera {
    
}

#pragma -mark-  VideoFileOutputDelegate 

- (void)writingDidStart {
    NSLog(@"开始写入");
}

- (void)writingDidEnd {
    NSLog(@"结束写入");
}

- (void)outputFileCommpressDidFinish {
    NSLog(@"压缩完成");
    _button.userInteractionEnabled = YES;
    
    CapturePlayerViewController *playerView = [self.storyboard instantiateViewControllerWithIdentifier:@"CapturePlayerViewController"];
    playerView.cover = _videoOutput.previewImage;
    playerView.asset = _videoOutput.originVideoURL;
    [self presentViewController:playerView animated:NO completion:NULL];
}

- (void)removeAnimation {
    [_containver.layer removeAllAnimations];
    [_button.layer removeAllAnimations];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_videoOutput.recorder startRuning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_videoOutput.recorder stopRuning];
}

- (void)action_clickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (CaptureMetadataPreview *)preview {
    return (CaptureMetadataPreview *)self.view;
}

@end
