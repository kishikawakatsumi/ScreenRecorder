//
//  SRAppDelegate.m
//  ScreenRecorder
//
//  Created by kishikawa katsumi on 2012/12/26.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "SRAppDelegate.h"
#import "SRScreenRecorder.h"

@implementation SRAppDelegate {
    SRScreenRecorder *screenRecorder;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    screenRecorder = [[SRScreenRecorder alloc] initWithWindow:self.window];
    [screenRecorder startRecording];
    
    return YES;
}

@end
