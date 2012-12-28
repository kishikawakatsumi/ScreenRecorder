//
//  TouchWindow.m
//
//  Created by Ito Kei on 12/03/02.
//  Copyright (c) 2012 itok. All rights reserved.
//

#import "KTouchPointerWindow.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL installed;

void KTouchPointerWindowInstall() 
{
	if (!installed) {
		installed = YES;
		
		Class _class = [UIWindow class];
		
		Method orig = class_getInstanceMethod(_class, sel_registerName("sendEvent:"));
		Method my = class_getInstanceMethod(_class, sel_registerName("k_sendEvent:"));
		method_exchangeImplementations(orig, my);
	}
}

void KTouchPointerWindowUninstall()
{
	if (installed) {
		installed = NO;
		
		Class _class = [UIWindow class];
		
		Method orig = class_getInstanceMethod(_class, sel_registerName("sendEvent:"));
		Method my = class_getInstanceMethod(_class, sel_registerName("k_sendEvent:"));
		method_exchangeImplementations(orig, my);
        
        NSArray *windows = [[UIApplication sharedApplication] windows];
        [windows makeObjectsPerformSelector:@selector(setNeedsDisplay)];
	}
}

static char s_key;

@interface __KTouchPointerView : UIView

@property (nonatomic, retain) NSSet *touches;

@end

@interface UIWindow (KTouchPointerWindow)

@property (nonatomic, retain) __KTouchPointerView* k_touchPointerView;

@end

@implementation UIWindow (KTouchPointerWindow)

- (__KTouchPointerView*) k_touchPointerView
{
	return objc_getAssociatedObject(self, &s_key);
}

-(void) setK_touchPointerView:(__KTouchPointerView *)value
{
	objc_setAssociatedObject(self, &s_key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void) k_sendEvent:(UIEvent *)event
{
	if (!self.k_touchPointerView) {
		self.k_touchPointerView = [[__KTouchPointerView alloc] initWithFrame:self.bounds];
		self.k_touchPointerView.backgroundColor = [UIColor clearColor];
		self.k_touchPointerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.k_touchPointerView.userInteractionEnabled = NO;
		[self addSubview:self.k_touchPointerView];
	}
	
	[self bringSubviewToFront:self.k_touchPointerView];
	
	NSMutableSet *began = nil;
	NSMutableSet *moved = nil;
	NSMutableSet *ended = nil;
	NSMutableSet *cancelled = nil;
	for (UITouch *touch in [event allTouches]) {
		switch (touch.phase) {
			case UITouchPhaseBegan:
				if (!began) {
					began = [NSMutableSet set];
				}
				[began addObject:touch];
				break;
			case UITouchPhaseEnded:
				if (!ended) {
					ended = [NSMutableSet set];
				}
				[ended addObject:touch];
				break;
			case UITouchPhaseCancelled:
				if (!cancelled) {
					cancelled = [NSMutableSet set];
				}
				[cancelled addObject:touch];
				break;
			case UITouchPhaseMoved:
				if (!moved) {
					moved = [NSMutableSet set];
				}
				[moved addObject:touch];
				break;
			default:
				break;
		}
	}
	if (began) {
		[self.k_touchPointerView touchesBegan:began withEvent:event];
	}
	if (moved) {
		[self.k_touchPointerView touchesMoved:moved withEvent:event];
	}
	if (ended) {
		[self.k_touchPointerView touchesEnded:ended withEvent:event];
	}
	if (cancelled) {
		[self.k_touchPointerView touchesCancelled:cancelled withEvent:event];
	}
	[self k_sendEvent:event];
}

@end

@implementation __KTouchPointerView

@synthesize touches;

- (void)drawRect:(CGRect)rect
{
	for (UITouch* touch in self.touches) {
		CGRect touchRect = CGRectZero;
		touchRect.origin = [touch locationInView:self];
		UIBezierPath* bp = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(touchRect, -10, -10)];
		[[UIColor colorWithRed:1 green:0 blue:0 alpha:0.6] set];
		[bp fill];
	}
}

- (void)touchesBegan:(NSSet *)_touches withEvent:(UIEvent *)event
{
	self.touches = _touches;
	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)_touches withEvent:(UIEvent *)event
{
	self.touches = _touches;
	[self setNeedsDisplay];	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.touches = nil;
	[self setNeedsDisplay];	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.touches = nil;
	[self setNeedsDisplay];
}

@end
