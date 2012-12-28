//
//  SRAppDelegate.m
//  ScreenRecorder
//
//  Created by kishikawa katsumi on 2012/12/26.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "SRAppDelegate.h"
#import "SRScreenRecorder.h"

@implementation SRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[SRScreenRecorder sharedInstance] startRecording];
    return YES;
}

@end
