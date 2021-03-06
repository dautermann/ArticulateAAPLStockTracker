//
//  PlotItem.m
//  CorePlotGallery
//
//

#import "PlotItem.h"

#import <tgmath.h>

@interface PlotItem ()

@property (nonatomic, readwrite, strong) CPTNativeImage *cachedImage;

@end

@implementation PlotItem

@synthesize defaultLayerHostingView;
@synthesize graphs;
@synthesize section;
@synthesize title;
@synthesize cachedImage;

- (id)init
{
    if ((self = [super init]))
    {
        defaultLayerHostingView = nil;
        graphs                  = [[NSMutableArray alloc] init];
        section                 = nil;
        title                   = nil;
    }

    return self;
}

- (void)addGraph:(CPTGraph *)graph toHostingView:(CPTGraphHostingView *)layerHostingView
{
    [self.graphs addObject:graph];

    if (layerHostingView)
    {
        layerHostingView.hostedGraph = graph;
    }
}

- (void)addGraph:(CPTGraph *)graph
{
    [self addGraph:graph toHostingView:nil];
}

- (void)killGraph
{
    [[CPTAnimation sharedInstance] removeAllAnimationOperations];

    // Remove the CPTLayerHostingView
    CPTGraphHostingView *hostingView = self.defaultLayerHostingView;
    if (hostingView)
    {
        [hostingView removeFromSuperview];

        hostingView.hostedGraph      = nil;
        self.defaultLayerHostingView = nil;
    }

    self.cachedImage = nil;

    [self.graphs removeAllObjects];
}

- (void)dealloc
{
    [self killGraph];
}

// override to generate data for the plot if needed
- (void)generateData
{
}

- (NSComparisonResult)titleCompare:(PlotItem *)other
{
    NSComparisonResult comparisonResult = [self.section caseInsensitiveCompare:other.section];

    if (comparisonResult == NSOrderedSame)
    {
        comparisonResult = [self.title caseInsensitiveCompare:other.title];
    }

    return comparisonResult;
}

- (void)setTitleDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
    graph.title = self.title;
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color                = [CPTColor grayColor];
    textStyle.fontName             = @"Helvetica-Bold";
    textStyle.fontSize             = round(bounds.size.height / CPTFloat(20.0));
    graph.titleTextStyle           = textStyle;
    graph.titleDisplacement        = CPTPointMake(0.0, textStyle.fontSize * CPTFloat(1.5));
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
}

- (void)setPaddingDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
    CGFloat boundsPadding = round(bounds.size.width / CPTFloat(20.0));   // Ensure that padding falls on an integral pixel

    graph.paddingLeft = boundsPadding;

    if (graph.titleDisplacement.y > 0.0)
    {
        graph.paddingTop = graph.titleTextStyle.fontSize * CPTFloat(2.0);
    }
    else
    {
        graph.paddingTop = boundsPadding;
    }

    graph.paddingRight  = boundsPadding;
    graph.paddingBottom = boundsPadding;
}

- (NSImage *)image
{
    if (self.cachedImage == nil)
    {
        CGRect imageFrame = CGRectMake(0, 0, 400, 300);

        NSView *imageView = [[NSView alloc] initWithFrame:NSRectFromCGRect(imageFrame)];
        [imageView setWantsLayer:YES];

        [self renderInView:imageView withTheme:nil animated:NO];

        CGSize boundsSize = imageFrame.size;

        NSBitmapImageRep *layerImage = [[NSBitmapImageRep alloc]
                                        initWithBitmapDataPlanes:NULL
                                                      pixelsWide:(NSInteger)boundsSize.width
                                                      pixelsHigh:(NSInteger)boundsSize.height
                                                   bitsPerSample:8
                                                 samplesPerPixel:4
                                                        hasAlpha:YES
                                                        isPlanar:NO
                                                  colorSpaceName:NSCalibratedRGBColorSpace
                                                     bytesPerRow:(NSInteger)boundsSize.width * 4
                                                    bitsPerPixel:32];

        NSGraphicsContext *bitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:layerImage];
        CGContextRef context             = (CGContextRef)[bitmapContext graphicsPort];

        CGContextClearRect(context, CGRectMake(0.0, 0.0, boundsSize.width, boundsSize.height));
        CGContextSetAllowsAntialiasing(context, true);
        CGContextSetShouldSmoothFonts(context, false);
        [imageView.layer renderInContext:context];
        CGContextFlush(context);

        self.cachedImage = [[NSImage alloc] initWithSize:NSSizeFromCGSize(boundsSize)];
        [self.cachedImage addRepresentation:layerImage];
    }

    return self.cachedImage;
}

- (void)applyTheme:(CPTTheme *)theme toGraph:(CPTGraph *)graph withDefault:(CPTTheme *)defaultTheme
{
    if (theme == nil)
    {
        [graph applyTheme:defaultTheme];
    }
    else if (![theme isKindOfClass:[NSNull class]])
    {
        [graph applyTheme:theme];
    }
}

- (void)setFrameSize:(NSSize)size
{
}

- (void)renderInView:(NSView *)inView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
    [self killGraph];

    CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] initWithFrame:inView.bounds];

    [hostingView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [hostingView setAutoresizesSubviews:YES];

    [inView addSubview:hostingView];
    [self generateData];
    [self renderInLayer:hostingView withTheme:theme animated:animated];

    self.defaultLayerHostingView = hostingView;
}

- (void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
    NSLog(@"PlotItem:renderInLayer: Override me");
}

- (void)reloadData
{
    for (CPTGraph *graph in self.graphs)
    {
        [graph reloadData];
    }
}

@end
