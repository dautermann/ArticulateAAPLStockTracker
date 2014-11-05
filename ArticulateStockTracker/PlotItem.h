//
//  PlotItem.h
//  CorePlotGallery
//
//

#import <Foundation/Foundation.h>

#import <CorePlot/CorePlot.h>
typedef NSRect CGNSRect;

@class CPTGraph;
@class CPTTheme;

@interface PlotItem : NSObject

@property (nonatomic, readwrite, strong) CPTGraphHostingView *defaultLayerHostingView;

@property (nonatomic, readwrite, strong) NSMutableArray *graphs;
@property (nonatomic, readwrite, strong) NSString *section;
@property (nonatomic, readwrite, strong) NSString *title;

- (void)renderInView:(NSView *)hostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated;
- (void)setFrameSize:(NSSize)size;

- (CPTNativeImage *)image;

- (void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated;

- (void)setTitleDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds;
- (void)setPaddingDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds;

- (void)reloadData;
- (void)applyTheme:(CPTTheme *)theme toGraph:(CPTGraph *)graph withDefault:(CPTTheme *)defaultTheme;

- (void)addGraph:(CPTGraph *)graph;
- (void)addGraph:(CPTGraph *)graph toHostingView:(CPTGraphHostingView *)layerHostingView;
- (void)killGraph;

- (void)generateData;

- (NSComparisonResult)titleCompare:(PlotItem *)other;

@end
