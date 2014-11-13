ArticulateAAPLStockTracker
==========================

I've already [answered a couple questions on Stackoverflow about CorePlot already](http://stackoverflow.com/search?q=user:981049+[core-plot]), so it only made sense that I should actually have the pleasure of using [CorePlot](https://github.com/core-plot) for the first time ever in this code test for Articulate.

Basically the test goes like this:

>Given a JSON file with Apple's closing stock prices on a range of days, draw an animated plot.

The bulk of the work can be found in AAPLStockPlotItem.

The window controller is pretty simple and standard, while PlotItem & PlotView are stolen directly from the CorePlot sample app.

The full description of this project can be found [in this repo's wiki](https://github.com/dautermann/ArticulateAAPLStockTracker/wiki). 
