# NRSPieChart

[![CI Status](http://img.shields.io/travis/neils4fun/NRSPieChart.svg?style=flat)](https://travis-ci.org/neils4fun/NRSPieChart)
[![Version](https://img.shields.io/cocoapods/v/NRSPieChart.svg?style=flat)](http://cocoapods.org/pods/NRSPieChart)
[![License](https://img.shields.io/cocoapods/l/NRSPieChart.svg?style=flat)](http://cocoapods.org/pods/NRSPieChart)
[![Platform](https://img.shields.io/cocoapods/p/NRSPieChart.svg?style=flat)](http://cocoapods.org/pods/NRSPieChart)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

NRSPieChart is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NRSPieChart"
```

## Author

neils4fun, macneil@neils4fun.com

## License

NRSPieChart is available under the MIT license. See the LICENSE file for more info.

## Features:
- Supports major and minor slices
- Select and highlight slices
- Animates slice size and color changes
- Configurable in interface builder (IBInspectable)

## Usage

###Basic chart:

```objectivec
@property (weak) IBOutlet NRSPieChartView          *pieChartView;

#pragma mark - PieChartViewDataSource

- (NSUInteger) numberOfMajorSlicesInPieChartView:(NRSPieChartView *)pieCharView {
return 10; // Total number of major slices
}

- (NSUInteger) numberOfMinorSlicesInPieChartView:(NRSPieChartView *)pieCharView forMajorSlice:(NSUInteger)majorSlice {
return 1; // Number of minor slices per major slice
}

- (CGColorRef) pieChartColorForSlice:(NRSPieChartView *)pieChartView sliceIndex:(NRSPieChartViewSliceIndex * _Nonnull)sliceIndex {

return [UIColor redColor] CGColor]; // Return the color for the given major.minor slice
}


- (NRSPieChartViewEndPoints *) pieChartEndPointsForSlice:(NRSPieChartView *)pieChartView sliceIndex:(NRSPieChartViewSliceIndex * _Nonnull)sliceIndex {
return [[NRSPieChartViewEndPoints alloc] initWithStart:(10 + 0.05)  end:(30 - 0.05)];j // Return an "End Point", based on 0...100 range. 0 corresponds to 12 o'clock position in chart
}

- (BOOL)pieChartShouldHighlightSlice:(NRSPieChartView *)pieChartView sliceIndex:(NRSPieChartViewSliceIndex *)sliceIndex {
return NO; // return if given slice should be highlighted. Highlighted slices are displayed with extend width
}

#pragma mark - PieChartViewDelegate

- (void)pieChartDidSingleTapSlice:(NRSPieChartView *)pieChartView sliceIndex:(NRSPieChartViewSliceIndex *)sliceIndex {
// called on single tap of chart. Example, can capture selection here and use that highlight the tapped slice. NOTE: remember to refresh pieChart in order to show the highlighted slice.
[pieChartView refreshSlices];
}

```

