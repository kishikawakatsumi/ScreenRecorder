//
//  SRScreenRecorder.h
//  ScreenRecorder
//
//  Created by kishikawa katsumi on 2012/12/26.
//  Copyright (c) 2012年 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

typedef NSString *(^SRScreenRecorderOutputFilenameBlock)(void);

@interface SRScreenRecorder : NSObject

@property (retain, nonatomic, readonly) UIWindow *window; // A window to be recorded.
@property (assign, nonatomic) NSInteger frameInterval;
@property (assign, nonatomic) NSUInteger autosaveDuration; // in second, default value is 600 (10 minutes).
@property (assign, nonatomic) BOOL showsTouchPointer;
@property (copy, nonatomic) SRScreenRecorderOutputFilenameBlock filenameBlock;

- (instancetype)initWithWindow:(UIWindow *)window;

- (void)startRecording;
- (void)stopRecording;

@end
