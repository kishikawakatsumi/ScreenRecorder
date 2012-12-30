ScreenRecorder
==============
Capturing a screen as videos on iOS devices for user testing.

## Features
* Screen capture
* Show touch pointer
* Autosave and file rotation
* Change FPS

## Setup

###1. Add the files  
Copy the files you need to your project folder, and add them to your Xcode project.
  * Lib/SRScreenRecorder.h
  * Lib/SRScreenRecorder.m
  * Vendor/KTouchPointerWindow.h
  * Vendor/KTouchPointerWindow.m

###2. Link with the frameworks
  * QuartzCore.framework
  * CoreVideo.framework
  * CoreMedia.framework
  * AVFoundation.framework

## Usage
###Basic  
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[SRScreenRecorder sharedInstance] startRecording];
    return YES;
}
 ```

In default settings, 
* save movie file automatically on enter background
* and auto rotate save files every 10 minutes
* movie file saved at document directory, named 'TIMESTAMP.mov'
* 30 FPS
* shows touch pointer

###Customize  
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SRScreenRecorder *recorder = [SRScreenRecorder sharedInstance];
    recorder.frameInterval = 1; // 60 FPS
    recorder.autosaveDuration = 1800; // 30 minutes
    recorder.showsTouchPointer = NO; // hidden touch pointer
    recorder.filenameBlock = ^(void) {
        return @"screencast.mov";
    }; // change filename
    
    [recorder startRecording];
    
    return YES;
}
 ```

###When submit to AppStore if includes this library, define APPSTORE_SAFE macro to eliminate using undocumented API
```objective-c
#define APPSTORE_SAFE 1
 ```

## 3rd party libraries

**KTouchPointerWindow**  
[https://github.com/itok/KTouchPointerWindow](https://github.com/itok/KTouchPointerWindow)  
 
[Apache]: http://www.apache.org/licenses/LICENSE-2.0
[MIT]: http://www.opensource.org/licenses/mit-license.php
[GPL]: http://www.gnu.org/licenses/gpl.html
[BSD]: http://opensource.org/licenses/bsd-license.php

## License

ScreenRecorder is available under the [MIT license][MIT]. See the LICENSE file for more info.
