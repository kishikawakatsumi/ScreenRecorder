//
//  SRScreenRecorder.m
//  ScreenRecorder
//
//  Created by kishikawa katsumi on 2012/12/26.
//  Copyright (c) 2012年 kishikawa katsumi. All rights reserved.
//

#import "SRScreenRecorder.h"
#import "KTouchPointerWindow.h"

#ifndef APPSTORE_SAFE
#define APPSTORE_SAFE 0
#endif

#define DEFAULT_FRAME_INTERVAL 2
#define DEFAULT_AUTOSAVE_DURATION 600
#define TIME_SCALE 600

static NSInteger counter;

#if !APPSTORE_SAFE
CGImageRef UICreateCGImageFromIOSurface(CFTypeRef surface);
#ifndef __IPHONE_11_0
CVReturn CVPixelBufferCreateWithIOSurface(
                                          CFAllocatorRef allocator,
                                          CFTypeRef surface,
                                          CFDictionaryRef pixelBufferAttributes,
                                          CVPixelBufferRef *pixelBufferOut);
#endif

@interface UIWindow (ScreenRecorder)
+ (IOSurfaceRef)createScreenIOSurface;
+ (IOSurfaceRef)createIOSurfaceFromScreen:(UIScreen *)screen;
- (IOSurfaceRef)createIOSurface;
- (IOSurfaceRef)createIOSurfaceWithFrame:(CGRect)frame;
@end
#endif

@interface SRScreenRecorder ()

@property (strong, nonatomic) AVAssetWriter *writer;
@property (strong, nonatomic) AVAssetWriterInput *writerInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *writerInputPixelBufferAdaptor;
@property (strong, nonatomic) CADisplayLink *displayLink;

@end

@implementation SRScreenRecorder {
	CFAbsoluteTime firstFrameTime;
    CFTimeInterval startTimestamp;
    BOOL shouldRestart;
    
    dispatch_queue_t queue;
    UIBackgroundTaskIdentifier backgroundTask;
}

- (instancetype)initWithWindow:(UIWindow *)window
{
    self = [super init];
    if (self) {
        _window = window;
        _frameInterval = DEFAULT_FRAME_INTERVAL;
        _autosaveDuration = DEFAULT_AUTOSAVE_DURATION;
        _showsTouchPointer = YES;

        counter++;
        NSString *label = [NSString stringWithFormat:@"com.kishikawakatsumi.screen_recorder-%@", @(counter)];
        queue = dispatch_queue_create([label cStringUsingEncoding:NSUTF8StringEncoding], NULL);

        [self setupNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopRecording];
}

#pragma mark Setup

- (void)setupAssetWriterWithURL:(NSURL *)outputURL
{
    NSError *error = nil;
    
    self.writer = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(self.writer);
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    UIScreen *mainScreen = [UIScreen mainScreen];
#if APPSTORE_SAFE
    CGSize size = mainScreen.bounds.size;
#else
    CGRect nativeBounds = [mainScreen nativeBounds];
    CGSize size = nativeBounds.size;
#endif
    
    NSDictionary *outputSettings = @{AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : @(size.width), AVVideoHeightKey : @(size.height)};
    self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
	self.writerInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *sourcePixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32ARGB)};
    self.writerInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerInput
                                                                                                          sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    NSParameterAssert(self.writerInput);
    NSParameterAssert([self.writer canAddInput:self.writerInput]);
    
    [self.writer addInput:self.writerInput];
    
	firstFrameTime = CFAbsoluteTimeGetCurrent();
    
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
}

- (void)setupTouchPointer
{
    if (self.showsTouchPointer) {
        KTouchPointerWindowInstall();
    } else {
        KTouchPointerWindowUninstall();
    }
}

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)setupTimer
{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(captureFrame:)];
    self.displayLink.frameInterval = self.frameInterval;
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark Recording

- (void)startRecording
{
    [self setupAssetWriterWithURL:[self outputFileURL]];
    
    [self setupTouchPointer];
    
    [self setupTimer];
}

- (void)stopRecording
{
    [self.displayLink invalidate];
    startTimestamp = 0.0;
    
    dispatch_async(queue, ^{
        if (self.writer.status != AVAssetWriterStatusCompleted && self.writer.status != AVAssetWriterStatusUnknown) {
            [self.writerInput markAsFinished];
        }
        [self.writer finishWritingWithCompletionHandler:^
         {
             [self finishBackgroundTask];
             [self restartRecordingIfNeeded];
         }];
    });
}

- (void)restartRecordingIfNeeded
{
    if (shouldRestart) {
        shouldRestart = NO;
        dispatch_async(queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [self startRecording];
                           });
        });
    }
}

- (void)rotateFile
{
    shouldRestart = YES;
    dispatch_async(queue, ^{
        [self stopRecording];
    });
}

- (void)captureFrame:(CADisplayLink *)displayLink
{
    dispatch_async(queue, ^{
        if (self.writerInput.readyForMoreMediaData) {
            CVReturn status = kCVReturnSuccess;
            CVPixelBufferRef buffer = NULL;
            CFTypeRef backingData;
#if APPSTORE_SAFE || TARGET_IPHONE_SIMULATOR
            __block UIImage *screenshot = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                screenshot = [self screenshot];
            });
            CGImageRef image = screenshot.CGImage;

            CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
            CFDataRef data = CGDataProviderCopyData(dataProvider);
            backingData = CFDataCreateMutableCopy(kCFAllocatorDefault, CFDataGetLength(data), data);
            CFRelease(data);

            const UInt8 *bytePtr = CFDataGetBytePtr(backingData);

            status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                  CGImageGetWidth(image),
                                                  CGImageGetHeight(image),
                                                  kCVPixelFormatType_32BGRA,
                                                  (void *)bytePtr,
                                                  CGImageGetBytesPerRow(image),
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  &buffer);
            NSParameterAssert(status == kCVReturnSuccess && buffer);
#else
            IOSurfaceRef surface = [self.window createIOSurface];
            backingData = surface;

            NSDictionary *pixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
            status = CVPixelBufferCreateWithIOSurface(NULL, surface, (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), &buffer);
            NSParameterAssert(status == kCVReturnSuccess && buffer);
#endif
            if (buffer) {
                CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
                CFTimeInterval elapsedTime = currentTime - firstFrameTime;

                CMTime presentTime =  CMTimeMake(elapsedTime * TIME_SCALE, TIME_SCALE);

                if(![self.writerInputPixelBufferAdaptor appendPixelBuffer:buffer withPresentationTime:presentTime]) {
                    [self stopRecording];
                }

                CVPixelBufferRelease(buffer);
            }

            CFRelease(backingData);
        }
    });
    
    if (startTimestamp == 0.0) {
        startTimestamp = displayLink.timestamp;
    }
    
    NSTimeInterval dalta = displayLink.timestamp - startTimestamp;
    
    if (self.autosaveDuration > 0 && dalta > self.autosaveDuration) {
        startTimestamp = 0.0;
        [self rotateFile];
    }
}

- (UIImage *)screenshot
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGSize imageSize = mainScreen.bounds.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (![window respondsToSelector:@selector(screen)] || window.screen == mainScreen) {
            CGContextSaveGState(context);
            
            CGContextTranslateCTM(context, window.center.x, window.center.y);
            CGContextConcatCTM(context, [window transform]);
            CGContextTranslateCTM(context,
                                  -window.bounds.size.width * window.layer.anchorPoint.x,
                                  -window.bounds.size.height * window.layer.anchorPoint.y);
            
            [window.layer.presentationLayer renderInContext:context];
            
            CGContextRestoreGState(context);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark Background tasks

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    UIApplication *application = [UIApplication sharedApplication];
    
    UIDevice *device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
        backgroundSupported = device.multitaskingSupported;
    }
    
    if (backgroundSupported) {
        backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [self finishBackgroundTask];
        }];
    }
    
    [self stopRecording];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self finishBackgroundTask];
    [self startRecording];
}

- (void)finishBackgroundTask
{
    if (backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark Utility methods

- (NSString *)documentDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

- (NSString *)defaultFilename
{
    time_t timer;
    time(&timer);
    NSString *timestamp = [NSString stringWithFormat:@"%ld", timer];
    return [NSString stringWithFormat:@"%@.mov", timestamp];
}

- (BOOL)existsFile:(NSString *)filename
{
    NSString *path = [self.documentDirectory stringByAppendingPathComponent:filename];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isDirectory;
    return [fileManager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory;
}

- (NSString *)nextFilename:(NSString *)filename
{
    static NSInteger fileCounter;
    
    fileCounter++;
    NSString *pathExtension = [filename pathExtension];
    filename = [[[filename stringByDeletingPathExtension] stringByAppendingString:[NSString stringWithFormat:@"-%@", @(fileCounter)]] stringByAppendingPathExtension:pathExtension];
    
    if ([self existsFile:filename]) {
        return [self nextFilename:filename];
    }
    
    return filename;
}

- (NSURL *)outputFileURL
{    
    if (!self.filenameBlock) {
        __block SRScreenRecorder *wself = self;
        self.filenameBlock = ^(void) {
            return [wself defaultFilename];
        };
    }
    
    NSString *filename = self.filenameBlock();
    if ([self existsFile:filename]) {
        filename = [self nextFilename:filename];
    }
    
    NSString *path = [self.documentDirectory stringByAppendingPathComponent:filename];
    return [NSURL fileURLWithPath:path];
}

@end
