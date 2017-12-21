//
//  AudioResPlayer.h
//  iOSWavAudioPlayer
//
//  Created by BJQingniuJJ on 2017/12/15.
//  Copyright © 2017年 周建. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZJPlayer.h"

@class AudioResPlayer;

@protocol AudioResPlayerDelegate <NSObject>

-(void)audioPlayer:(AudioResPlayer *)player playStateChanged:(ZJPlayerState)state;

@end


@interface AudioResPlayer : NSObject

- (void)playingUrl:(NSURL *)url;

- (void)pause;

- (void)stop;

@end
