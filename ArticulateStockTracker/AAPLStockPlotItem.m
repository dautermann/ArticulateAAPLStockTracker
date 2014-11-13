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
static NSTimeInterval kOneDay = 24 * 60 * 60;

@interface AAPLStockPlotItem ()

@property (nonatomic, readwrite, strong) CPTPlotSpaceAnnotation *symbolTextAnnotation;

@property (strong) NSArray *stockDataArray;
@property (nonatomic, readwrite, strong) NSMutableArray *plotData;
@property (nonatomic, readwrite, assign) NSUInteger currentIndex;
@property (nonatomic, readwrite, strong) NSTimer *dataTimer;

@end

@implementation AAPLStockPlotItem

@synthesize symbolTextAnnotation;
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
    
    if([self.graphs count])
    {
        CPTGraph *graph = (self.graphs)[0];

        CPTPlotSpaceAnnotation *annotation = self.symbolTextAnnotation;
        if ( annotation ) {
            [graph.plotAreaFrame.plotArea removeAnnotation:annotation];
            self.symbolTextAnnotation = nil;
        }
    }
    
    [super killGraph];
}

- (void)generateData
{
    [self.plotData removeAllObjects];

    // we could load the data from some remote website (and this may be on deck for when I talk to you guys in real-time),
    // but for the purposes of this demo we'll just load the JSON data that you provided
#if 1
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
            NSLog(@"error parsing JSON from URL %@ - %@", [applStockDataFile absoluteString], [error localizedDescription]);
        }
    }
    else
    {
        NSLog(@"error loading data from URL %@ - %@", [applStockDataFile absoluteString], [error localizedDescription]);
    }
#else
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    NSDate *fiftyDaysAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:kOneDay * -20];
    NSString *todayDateString = [dateFormatter stringFromDate:[NSDate date]];
    NSString *fiftyDaysAgoString = [dateFormatter stringFromDate:fiftyDaysAgo];
    NSURL *applStockDataURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://query.yahooapis.com/v1/public/yql?q=select%%20*%%20from%%20yahoo.finance.historicaldata%%20where%%20symbol%%20%%3D%%20%%22AAPL%%22%%20and%%20startDate%%20%%3D%%20%%2220%@%%22%%20and%%20endDate%%20%%3D%%20%%2220%@%%22&diagnostics=true&format=json&env=store%%3A%%2F%%2Fdatatables.org%%2Falltableswithkeys",fiftyDaysAgoString,todayDateString]];
    NSError *error = nil;
    NSData *dataFromYahoo = [[NSData alloc] initWithContentsOfURL:applStockDataURL options:NSUncachedRead error:&error];
    if(dataFromYahoo)
    {
        NSDictionary *historyDict = [NSJSONSerialization JSONObjectWithData:dataFromYahoo options:0 error:&error];
        if(historyDict)
        {
            NSLog(@"historyDict is %@", historyDict);
            
        }
        else
        {
            NSLog(@"error parsing JSON from URL %@ - %@", [applStockDataURL absoluteString], [error localizedDescription]);
        }
    }
    else
    {
        NSLog(@"error loading data from URL %@ - %@", [applStockDataURL absoluteString], [error localizedDescription]);
    }
#endif
}

- (unsigned int)getLowestPriceBoundary
{
    unsigned int minimumPrice = 1000;
    
    for(NSDictionary *priceOnADate in self.stockDataArray)
    {
        NSString *closingPriceString = priceOnADate[@"close"];
        double closingPrice = [closingPriceString doubleValue];
        
        if(floor(closingPrice) < minimumPrice)
        {
            minimumPrice = floor(closingPrice);
            
            unsigned int remainder = minimumPrice % 5;
            
            if(remainder != 0)
            {
                minimumPrice = (minimumPrice - remainder);
            }
        }
    }
    return minimumPrice;
}

- (unsigned int)getYAxisRange
{
    unsigned int minimumPrice = [self getLowestPriceBoundary];
    unsigned int maximumPrice = 0;
    
    for(NSDictionary *priceOnADate in self.stockDataArray)
    {
        NSString *closingPriceString = priceOnADate[@"close"];
        double closingPrice = [closingPriceString doubleValue];
        
        if(ceil(closingPrice) > maximumPrice)
        {
            maximumPrice = ceil(closingPrice);
            
            unsigned int remainder = maximumPrice % 5;
            
            if(remainder != 0)
            {
                maximumPrice = (maximumPrice + remainder);
            }
        }
    }

    return(maximumPrice - minimumPrice) + 1;
}


- (void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
    CGRect bounds = NSRectToCGRect(layerHostingView.bounds);

    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    [self addGraph:graph toHostingView:layerHostingView];
    [self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];

    [self setTitleDefaultsForGraph:graph withBounds:bounds];
    [self setPaddingDefaultsForGraph:graph withBounds:bounds];

    // Plot area delegate
    graph.plotAreaFrame.plotArea.delegate = self;
    
    graph.plotAreaFrame.paddingTop    = 75.0;
    graph.plotAreaFrame.paddingRight  = 75.0;
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
    
    graph.title = @"Apple Stock Price";

    // Axes
    // X axis
    
#define DIRECTDATE
    
#ifdef DIRECTDATE
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];

    [dateComponents setMonth:9];
    [dateComponents setDay:8];
    [dateComponents setYear:2014];
    [dateComponents setHour:12];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *refDate = [gregorian dateFromComponents:dateComponents];

    NSTimeInterval xLow             = 0.0;

    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(xLow) length:CPTDecimalFromDouble(kOneDay * 4.0)];

    CPTXYAxisSet *axisSet           = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x                    = axisSet.xAxis;
    x.title                         = @"Date";
    x.majorIntervalLength           = CPTDecimalFromDouble(kOneDay);
    x.majorGridLineStyle            = majorGridLineStyle;
    x.minorGridLineStyle            = minorGridLineStyle;
    x.orthogonalCoordinateDecimal   = CPTDecimalFromUnsignedInteger(90);
    x.minorTicksPerInterval         = 4;
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle         = kCFDateFormatterShortStyle;
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate     = refDate;
    x.labelFormatter                = timeFormatter;

#else
    
    // if I wanted to cheat by using custom labels
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
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger([self getLowestPriceBoundary]) length:CPTDecimalFromUnsignedInteger([self getYAxisRange])];

    // Y axis
    
    // first set a number formatter to the prices along the Y axis
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    CPTXYAxis *y                  = axisSet.yAxis;
    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    y.majorGridLineStyle          = majorGridLineStyle;
    y.minorGridLineStyle          = minorGridLineStyle;
    y.minorTicksPerInterval       = 5;
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
    
    // Add plot symbols
    CPTGradient *symbolGradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithComponentRed:0.75 green:0.75 blue:1.0 alpha:1.0]
                                                              endingColor:[CPTColor blueColor]];
    symbolGradient.gradientType = CPTGradientTypeRadial;
    symbolGradient.startAnchor  = CPTPointMake(0.25, 0.75);
    
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill               = [CPTFill fillWithGradient:symbolGradient];
    plotSymbol.lineStyle          = nil;
    plotSymbol.size               = CGSizeMake(12.0, 12.0);
    dataSourceLinePlot.plotSymbol = plotSymbol;
    
    // Set plot delegate, to know when symbols have been touched
    // We will display an annotation when a symbol is touched
    dataSourceLinePlot.delegate                        = self;
    dataSourceLinePlot.plotSymbolMarginForHitDetection = 5.0;
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

        NSDictionary *priceOnADate = [self.stockDataArray objectAtIndex:self.currentIndex];
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
#ifdef DIRECTDATE
                num = @(self.currentIndex++ * kOneDay);
#else
                num = @(index + self.currentIndex - self.plotData.count);
#endif
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

#pragma mark -
#pragma mark CPTScatterPlot delegate methods

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    CPTXYGraph *graph = (self.graphs)[0];
    
    CPTPlotSpaceAnnotation *annotation = self.symbolTextAnnotation;
    
    if ( annotation ) {
        [graph.plotAreaFrame.plotArea removeAnnotation:annotation];
        self.symbolTextAnnotation = nil;
    }
    
    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color    = [CPTColor whiteColor];
    hitAnnotationTextStyle.fontSize = 16.0;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
    // Determine point of symbol in plot coordinates
    NSNumber *dataPoint = self.plotData[index];
    
    //NSNumber *x = dataPoint[@"x"];
    //NSNumber *y = dataPoint[@"y"];
    NSNumber *x = @(index * kOneDay);
    NSNumber *y = @(90); // [NSNumber numberWithDouble:(index * kOneDay)];
    
    NSArray *anchorPoint = @[x, y];
    
    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    NSString *yString = [NSString stringWithFormat:@"closing price: $%4.2f", [dataPoint doubleValue]];
    //[formatter stringFromNumber:y];
    
    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle];
    CPTImage *background    = [CPTImage imageNamed:@"BlueBackground"];
    background.edgeInsets   = CPTEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);
    textLayer.fill          = [CPTFill fillWithImage:background];
    textLayer.paddingLeft   = 2.0;
    textLayer.paddingTop    = 2.0;
    textLayer.paddingRight  = 2.0;
    textLayer.paddingBottom = 2.0;
    
    annotation                    = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
    annotation.contentLayer       = textLayer;
    annotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
    annotation.displacement       = CGPointMake(0.0, 10.0);
    [graph.plotAreaFrame.plotArea addAnnotation:annotation];
}



@end
