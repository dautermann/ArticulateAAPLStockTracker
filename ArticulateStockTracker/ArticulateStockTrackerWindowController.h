//
//  ArticulateStockTrackerWindowController.h
//  ArticulateStockTracker
//
//  Created by Michael Dautermann on 11/4/14.
//  Copyright (c) 2014 Michael Dautermann. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlotView.h"
#import "PlotItem.h"

@interface ArticulateStockTrackerWindowController : NSWindowController <PlotViewDelegate>

@property (nonatomic, strong) PlotItem *plotItem;

@end
