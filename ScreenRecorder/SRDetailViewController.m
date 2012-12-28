//
//  SRDetailViewController.m
//  ScreenRecorder
//
//  Created by kishikawa katsumi on 2012/12/26.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "SRDetailViewController.h"

@interface SRDetailViewController ()
- (void)configureView;
@end

@implementation SRDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        [self configureView];
    }
}

- (void)configureView
{
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
