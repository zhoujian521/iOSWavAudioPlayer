//
//  ViewController.m
//  iOSWavAudioPlayer
//
//  Created by BJQingniuJJ on 2017/12/15.
//  Copyright © 2017年 周建. All rights reserved.
//

#import "ViewController.h"
#import "AudioResPlayer.h"
#import "AFFileDownLoader.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *iOSTextView;

@property (nonatomic, strong) AudioResPlayer *audioPlayer;


@end

@implementation ViewController

//30S：
//http://saas.ccod.com:9090/record/LTBD2017050502/Agent/20171201/TEL-13811749890_BFYTT_6718_20171201150942.wav
//2分钟：
//http://saas.ccod.com:9090/record/LTBD2017050502/Agent/20171201/TEL-13811749890_BFYTT_6718_20171201150942.wav
//10分钟：
//http://saas.ccod.com:9090/record/LTBD2017050502/Agent/20171031/TEL-17600669657_BFYTT_6506_20171031150303.wav
//30分钟以上：
//http://saas.ccod.com:9090/record/LTBD2017050502/Agent/20171010/TEL-13986180975_BFYTT_5411_20171010145757.wav
//
// http://wyxcdn.ccod.com/server/audio/TEL-18601908304_QNCSH_910016_20171214101435.wav

- (void)viewDidLoad {
    [super viewDidLoad];
    self.iOSTextView.text = @"http://saas.ccod.com:9090/record/LTBD2017050502/Agent/20171010/TEL-13986180975_BFYTT_5411_20171010145757.wav";
}

// 播放
- (IBAction)playBtn:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:self.iOSTextView.text];
    [self.audioPlayer playingUrl:url];
}

// 停止
- (IBAction)stopBtn:(UIButton *)sender {
    [self.audioPlayer stop];
}

- (AudioResPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [[AudioResPlayer alloc] init];
    }
    return _audioPlayer;
}


@end
