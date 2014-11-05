//
//  AAPLStockPlotItem.m
//  ArticulateStockTracker
//
//  Created by Michael Dautermann on 11/4/14.
//  Copyright (c) 2014 Michael Dautermann. All rights reserved.
//

#import "AAPLStockPlotItem.h"

static const double kFrameRate = 5.0;  // frames per second

static const NSUInteger kMaxDataPoints = 15;
static NSString *const kPlotIdentifier = @"AAPL Stock Plot";

@interface AAPLStockPlotItem ()

@property (strong) NSArray *stockDataArray;
@property (nonatomic, readwrite, strong) NSMutableArray *plotData;
@property (nonatomic, readwrite, assign) NSUInteger currentIndex;
@property (nonatomic, readwrite, strong) NSTimer *dataTimer;

@end

@implementation AAPLStockPlotItem

@synthesize plotData;
@synthesize currentIndex;
@synthesize dataTimer;

- (id)init
{
    if ((self = [super init]))
    {
        plotData  = [[NSMutableArray alloc] initWithCapacity:kMaxDataPoints];
        dataTimer = nil;
    }

    return self;
}

- (void)killGraph
{
    [self.dataTimer invalidate];
    self.dataTimer = nil;

    [super killGraph];
}

- (void)generateData
{
    [self.plotData removeAllObjects];

    // we could load the data from some remote website, but for the purposes of this demo we'll just load the JSON data....
    NSURL *applStockDataFile = [[NSBundle mainBundle] URLForResource:@"stockprices" withExtension:@"json"];
    NSError *error = nil;
    NSData *applStockData = [[NSData alloc] initWithContentsOfURL:applStockDataFile options:0 error:&error];
    if (applStockData)
    {
        NSDictionary *stockDataDictionary = [NSJSONSerialization JSONObjectWithData:applStockData options:0 error:&error];
        if (stockDataDictionary)
        {
            self.stockDataArray = [stockDataDictionary objectForKey:@"stockdata"];
            self.currentIndex = 0;
        }
        else
        {
            NSLog(@"error parsing jason from URL %@ - %@", [applStockDataFile absoluteString], [error localizedDescription]);
        }
    }
    else
    {
        NSLog(@"error loading data from URL %@ - %@", [applStockDataFile absoluteString], [error localizedDescription]);
    }
}

- (void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
    CGRect bounds = NSRectToCGRect(layerHostingView.bounds);

    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    [self addGraph:graph toHostingView:layerHostingView];
    [self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];

    [self setTitleDefaultsForGraph:graph withBounds:bounds];
    [self setPaddingDefaultsForGraph:graph withBounds:bounds];

    graph.plotAreaFrame.paddingTop    = 15.0;
    graph.plotAreaFrame.paddingRight  = 15.0;
    graph.plotAreaFrame.paddingBottom = 105.0;
    graph.plotAreaFrame.paddingLeft   = 105.0;
    graph.plotAreaFrame.masksToBorder = NO;

    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:CPTFloat(0.2)] colorWithAlphaComponent:CPTFloat(0.75)];

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:CPTFloat(0.1)];

    // Plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;

    // Axes
    // X axis
#if 0
    // this is the x-axis plotting & labeling scheme I'd ***really*** love to use, but I haven't figured out the
    // orthogonal & interval magic between the X & Y axis, so I'm cheating below by using custom labels.
    // I'm sorry you have to see it like this.
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];

    [dateComponents setMonth:9];
    [dateComponents setDay:8];
    [dateComponents setYear:2014];
    [dateComponents setHour:12];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];

    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *refDate = [gregorian dateFromComponents:dateComponents];

    NSTimeInterval oneDay = 24 * 60 * 60;

    NSTimeInterval xLow       = 0.0;

    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(xLow) length:CPTDecimalFromDouble(oneDay * 5.0)];

    CPTXYAxisSet *axisSet           = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x                    = axisSet.xAxis;
    x.title                         = @"Date";
    x.majorIntervalLength           = CPTDecimalFromDouble(oneDay);
    x.majorGridLineStyle            = majorGridLineStyle;
    x.minorGridLineStyle            = minorGridLineStyle;
    x.orthogonalCoordinateDecimal   = CPTDecimalFromUnsignedInteger(90);
    x.minorTicksPerInterval         = 4;
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle         = kCFDateFormatterShortStyle;
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate     = refDate;
    x.labelFormatter                = timeFormatter;
    // Rotate the labels by 45 degrees, just to show it can be done.
    //x.labelRotation                 = CPTFloat(M_PI_4);

#endif

#if 1
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(5)];
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = [[NSDecimalNumber decimalNumberWithString:@"1"] decimalValue];
    x.majorGridLineStyle          = majorGridLineStyle;
    x.minorGridLineStyle          = minorGridLineStyle;
    x.minorTicksPerInterval       = 4;

    CPTPlotRange *xAxisRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromString(@"0.0") length:CPTDecimalFromString(@"5.0")];
    x.visibleRange = xAxisRange;

    // starts the X axis at the low end of the stock range
    x.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(90);
    x.title = @"Date";
    //x.titleOffset=47.0f;
    // x.labelRotation=M_PI/4;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    NSArray *xAxisLabels = [NSArray arrayWithObjects:@"9/8/2014", @"9/9/2014", @"9/10/2014", @"9/11/2014", @"9/12/2014", nil];
    NSUInteger labelLocation = 0;
    NSArray *customTickLocations = [NSArray arrayWithObjects:@(0.0), @(1.0), @(2.0), @(3.0), @(4.0), nil];

    NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:[xAxisLabels count]];
    for (NSNumber *tickLocation in customTickLocations)
    {
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[xAxisLabels objectAtIndex:labelLocation++] textStyle:x.labelTextStyle];
        newLabel.tickLocation = [tickLocation decimalValue];
        newLabel.offset = x.labelOffset + x.majorTickLength;
        newLabel.rotation = M_PI / 4;
        [customLabels addObject:newLabel];
    }
    x.axisLabels =  [NSSet setWithArray:customLabels];
#endif

    // find minimum and maximum possible values for the stock price in our data set
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(90) length:CPTDecimalFromUnsignedInteger(110 - 90)];

    // Y axis
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    CPTXYAxis *y                  = axisSet.yAxis;
    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    y.majorGridLineStyle          = majorGridLineStyle;
    y.minorGridLineStyle          = minorGridLineStyle;
    y.minorTicksPerInterval       = 3;
    y.labelOffset                 = 5.0;
    y.title                       = @"Stock Price";
    y.titleOffset                 = 70.0;
    y.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
    y.labelFormatter              = numberFormatter;

    // Create the plot
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier     = kPlotIdentifier;
    dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionDecimal;

    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 3.0;
    lineStyle.lineColor              = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;

    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];

    [self.dataTimer invalidate];

    if (animated)
    {
        self.dataTimer = [NSTimer timerWithTimeInterval:1.0 / kFrameRate
                                                 target:self
                                               selector:@selector(newData:)
                                               userInfo:nil
                                                repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.dataTimer forMode:NSRunLoopCommonModes];
    }
    else
    {
        self.dataTimer = nil;
    }
}

- (void)dealloc
{
    [dataTimer invalidate];
}

#pragma mark -
#pragma mark Timer callback

- (void)newData:(NSTimer *)theTimer
{
    CPTGraph *theGraph = (self.graphs)[0];
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];

    if (thePlot)
    {
        if (self.plotData.count >= self.stockDataArray.count)
        {
            [theTimer invalidate];
            return;
        }

        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)theGraph.defaultPlotSpace;
        NSUInteger location       = (self.currentIndex >= kMaxDataPoints ? self.currentIndex - kMaxDataPoints + 2 : 0);

        CPTPlotRange *oldRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger((location > 0) ? (location - 1) : 0)
                                                              length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];
        CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
                                                              length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];

        [CPTAnimation animate:plotSpace
                     property:@"xRange"
                fromPlotRange:oldRange
                  toPlotRange:newRange
                     duration:CPTFloat(1.0 / kFrameRate)];

        NSDictionary *priceOnADate = [self.stockDataArray objectAtIndex:self.currentIndex++];
        NSString *closingPriceString = priceOnADate[@"close"];
        double closingPrice = [closingPriceString doubleValue];

        [self.plotData addObject:@(closingPrice)];
        [thePlot insertDataAtIndex:self.plotData.count - 1 numberOfRecords:1];
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.plotData.count;
}

- (id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num = nil;

    if (self.plotData.count)
    {
        switch (fieldEnum) {
            case CPTScatterPlotFieldX:
                num = @(index + self.currentIndex - self.plotData.count);
                break;

            case CPTScatterPlotFieldY:
                num = self.plotData[index];
                break;

            default:
                break;
        }
    }
    return num;
}

@end
