//
//  KTouchPointerWindow.h
//
//  Created by Ito Kei on 12/03/02.
//  Copyright (c) 2012 itok. All rights reserved.
//
/*
 * call this function to start show pointer
 * 
 * ex)
 * - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 *      KTouchPointerWindowInstall();
 *      ...
 * }
 */
void KTouchPointerWindowInstall(void);
void KTouchPointerWindowUninstall(void);
