//
//  ArticulateStockTrackerWindowController.m
//  ArticulateStockTracker
//
//  Created by Michael Dautermann on 11/4/14.
//  Copyright (c) 2014 Michael Dautermann. All rights reserved.
//

#import "ArticulateStockTrackerWindowController.h"
#import <Quartz/Quartz.h>
#import "AAPLStockPlotItem.h"

@interface ArticulateStockTrackerWindowController ()

@property (nonatomic, readwrite, strong) IBOutlet PlotView *hostingView;

@end

@implementation ArticulateStockTrackerWindowController

@synthesize hostingView;

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    [self.plotItem renderInView:self.hostingView withTheme:[CPTTheme themeNamed:@"Real Time Plot"] animated:YES];
}

- (void)awakeFromNib
{
    AAPLStockPlotItem *aaplPlotItem = [[AAPLStockPlotItem alloc] init];

    self.plotItem = aaplPlotItem;

    [aaplPlotItem renderInView:self.hostingView withTheme:[CPTTheme themeNamed:@"Real Time Plot"] animated:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    if ([self.plotItem respondsToSelector:@selector(setFrameSize:)])
    {
        [self.plotItem setFrameSize:newSize];
    }
}

@end
