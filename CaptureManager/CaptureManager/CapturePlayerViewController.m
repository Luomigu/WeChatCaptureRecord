//
//  CapturePlayeViewController.m
//  BBLand
//
//  Created by 杨国盛 on 2017/7/21.
//  Copyright © 2017年 yanggs. All rights reserved.
//

#import "CapturePlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CapturePlaybackView.h"
#import <Masonry/Masonry.h>

@interface CapturePlayerViewController ()

@property (strong,nonatomic) UIButton *back;
@property (strong,nonatomic) UIButton *commit;

@property (strong,nonatomic) UIImageView *placeHolder;

@end

@implementation CapturePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (_asset == nil && _cover) {
        _placeHolder = [[UIImageView alloc]initWithImage:_cover];
        _placeHolder.frame = [UIScreen mainScreen].bounds;
        [self.view addSubview:_placeHolder];
    }else if (_asset && _cover) {
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:_asset];
        AVPlayer * player = [[AVPlayer alloc]initWithPlayerItem:item];
        self.showsPlaybackControls = NO;
        self.player = player;
        [player play];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
    
    _back = [[UIButton alloc]init];
    [_back addTarget:self action:@selector(action_dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_back];
    [_back setTitle:@"◼︎" forState:UIControlStateNormal];
    _back.titleLabel.font = [UIFont boldSystemFontOfSize:48];
    
    [_back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.width.height.mas_equalTo(50);
        make.bottom.mas_equalTo(-80);
    }];
    
    _commit = [[UIButton alloc]init];
    [_commit addTarget:self action:@selector(action_clickCommit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_commit];
    [_commit setTitle:@"✔︎" forState:UIControlStateNormal];
    _commit.titleLabel.font = [UIFont boldSystemFontOfSize:48];

    [_commit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_back.mas_bottom);
        make.width.height.mas_equalTo(50);
        make.right.equalTo(self.view).offset(-40);
    }];

}

-(void)playbackFinished:(NSNotification *)notification {
    
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

- (void)endPlayRemoveObserver {
    
    self.player.rate = 0;
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

- (BOOL)isPlayr{
    return [self.player rate] > 0;
}

- (void)action_dismiss {
    
    [self endPlayRemoveObserver];
    [self dismissViewControllerAnimated:NO completion:NULL];
}

- (void)action_clickCommit {
    
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
//    NSURL *copyAsset = _asset.copy;
    [self endPlayRemoveObserver];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
